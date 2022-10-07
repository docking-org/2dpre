/*
master zinc22 upload script for catalog data

unfortunately, the upload procedure is a bit convoluted, because postgres in not yet smart enough to automatically speed up these sorts of operations
to speed up our database, we create a number of hash partitions for each table based on a specific key value from those tables

for the substance table, this is the smiles key
for the catalog_content, this is the supplier_code key
for catalog_substance, this is both sub_id_fk and cat_content_fk (we have two copies of this table)

the reason why this is done is to force postgres to do a ""hash join"" plan, which for huge data like ours is the preferred behaviour
on huge select queries, for example joining one huge table with another, postgres is happy to plan a hash join
however for some reason, on insert/update queries, postgres will almost always *refuse* to execute a hash join plan, instead opting for a merge sort or the like
our hash partitions function like hash buckets that would be created during the hash join plan, allowing us to perform our own "hash join" during an insert/update query
it's sort of crappy, but has definitely improved performance!
*/

LOAD 'auto_explain';
SET auto_explain.log_nested_statements = ON;
SET auto_explain.log_min_duration = 10;
SET client_min_messages to log;
set enable_partitionwise_aggregate=on; -- doesn't seem to do much, but may help certain queries
begin;

	--- tables that will be created beforehand in preparation for upload operation
	/*
	create table temp_load_p1 ( -- raw data, smiles+code
		smiles varchar,
		supplier_code varchar,
		tranche_id smallint,
		cat_id smallint
	) partition by hash (smiles);

	create table temp_load_p2 ( -- processed data 1, smiles id+code
		sub_id bigint,
		supplier_code varchar,
		tranche_id smallint,
		cat_id smallint
	) partition by hash (code);

	create table temp_load_p3 ( -- processed data 2, smiles id+code id
		sub_id bigint,
		cat_content_id bigint,
		tranche_id smallint
	) partition by hash (sub_id)

	*/

	/*
	call upload_bypart(partition_idx, 'temp_load_p1', 'substance', 'temp_load_p2', '{{"smiles:text"}}', 'sub_id:bigint', 'sub_id_seq', sub_diff_file);

	call upload_bypart(partition_idx, 'temp_load_p2', 'catalog_content', 'temp_load_p3', '{{"supplier_code:text"}}', 'cat_content_id:bigint', 'cat_content_id_seq', cat_diff_file);
	-- on python side, once everything has finished for p2:
	-- alter table temp_load_p3 alter column sub_id rename to sub_id_fk
	-- alter table temp_load_p3 alter column cat_content_id rename to cat_content_fk
	call upload_bypart(partition_idx, 'temp_load_p3', 'catalog_substance', null, '{{"sub_id_fk:bigint"},{"cat_content_fk:bigint"}}', 'cat_sub_itm_id:bigint', 'cat_sub_itm_id_seq', catsub_diff_file)
	*/

	create or replace function upload_substance_bypart(part int, transid text, diff_file_dest text) returns int as $$
		declare
			tempvar int;
			cntupload int;
			cntnew int;

		begin
			-- temporary objects are unique to each session, so no need to worry about name overlap when we're executing this in parallel
			create temporary sequence tl_temp_id_seq;

			create temporary table temp_load_part_sub (

				smiles varchar,
				code varchar,
				sub_id bigint,
				tranche_id smallint,
				cat_id smallint,
				temp_id int default nextval('tl_temp_id_seq')
			);

			-- dynamic execution
			/*insert into temp_load_part_sub(smiles, code, sub_id, tranche_id, cat_id) (

				select 
					tl.smiles, tl.code, sb.sub_id, tl.tranche_id
				from
					temp_load_p1_pXX tl
				left join
					substance_pXX sb
				on tl.smiles = sb.smiles
			);*/
			execute(format('insert into temp_load_part_sub(smiles, code, sub_id, tranche_id, cat_id) (select tl.smiles, tl.code, sb.sub_id, tl.tranche_id, tl.cat_id from temp_load_p1_p%s tl left join substance_p%s sb on tl.smiles = sb.smiles)', part, part));
			select count(*) from temp_load_part_sub into cntupload;

			alter table temp_load_part_sub add primary key (temp_id);

			create temporary table new_substances (

                                smiles varchar,
                                sub_id bigint,
				rn int, -- used to track unique substances. rn = 1 means this is a unique instance of a substance
                                tranche_id smallint,
                                temp_id int
                        );

			alter table new_substances add constraint temp_id_fk foreign key (temp_id) references temp_load_part_sub(temp_id);

			insert into new_substances (

				select 
					t.smiles, 
					min(sub_id) over w as sub_id,
					ROW_NUMBER() over w as rn,
					t.tranche_id, 
					t.temp_id 
				from
				(
					select
						tl.smiles,
						-- **technically** we could use currval when ROW_NUMBER != 1, however this is not the least bit thread safe
						-- this procedure is designed to support loading many partitions in parallel
						case when ROW_NUMBER() over w = 1 then nextval('sub_id_seq') else null end as sub_id, 
						tl.tranche_id,
						tl.temp_id
					from
						temp_load_part_sub tl
					where
						tl.sub_id is null
					window w as
						(partition by smiles)
				) t
				-- even though we need to apply the same window function twice, it seems postgres is smart enough to sort just once
				-- so this extra window operation doesn't incur a significant extra cost (except maybe some processing/planning overhead)
				window w as
					(partition by t.smiles)

			);

			select count(*) from new_substances where rn = 1 into cntnew;
			raise notice '# new substances: %', cntnew;

			-- dynamic execution
			-- once we've identified new substances, insert them to the table (only unique instances with rn = 1)
			/*insert into substance_pXX(smiles, sub_id, tranche_id) (

				select
					smiles, sub_id, tranche_id
				from
					new_substances ns
				where
					ns.rn = 1
			);*/
			execute(format('copy (insert into substance_p%s (smiles, sub_id, tranche_id) (select smiles, sub_id, tranche_id from new_substances ns where ns.rn = 1) returning *) to ''%s/sub/%s''', part, diff_file_dest, part));

			execute(format('insert into substance_id (sub_id, sub_partition_fk) (select sub_id, %s from new_substances ns where ns.rn = 1)', part));
					
			-- now we move the processed data to the next stage
			insert into temp_load_p2(sub_id, code, tranche_id, cat_id) (

				select
					case when tl.sub_id is null then ns.sub_id else tl.sub_id end,
					tl.code,
					tl.tranche_id,
					tl.cat_id
				from
					temp_load_part_sub tl
				left join
					new_substances ns
				on
					tl.temp_id = ns.temp_id

			);

			execute(format('insert into transaction_record_%s (stagei, parti, nnew, nupload) (values (1, %s, %s, %s))', transid, part, cntnew, cntupload));

			-- clean up our data
			--drop table temp_load_p1_pXX; -- dynamic execution
			execute(format('drop table temp_load_p1_p%s', part));
			drop table new_substances;
			drop table temp_load_part_sub;

			return 0;

		end;

	$$ language plpgsql;

	create or replace function upload_catcontent_bypart(part int, transid text, diff_file_dest text) returns int as $$
		declare
			tempvar int;
			cntnew int;
			cntupload int;

		begin
			create temporary sequence tl_temp_id_seq;

			create temporary table temp_load_part_cat (
				sub_id bigint,
				code varchar,
				code_id bigint,
				tranche_id smallint,
				cat_id smallint,
				temp_id int default nextval('tl_temp_id_seq')
			);

			-- dynamic execution
			/*
			insert into temp_load_part_cat(sub_id, code, code_id, tranche_id, cat_id) (
				select 
					tl.sub_id, tl.code, cc.cat_content_id, tl.tranche_id, tl.cat_id
				from
					temp_load_p2_pXX tl
				left join
					catalog_content_pXX cc
				on
					tl.code = cc.code
			);*/
			execute(format('insert into temp_load_part_cat(sub_id, code, code_id, tranche_id, cat_id) (select tl.sub_id, tl.code, cc.cat_content_id, tl.tranche_id, tl.cat_id from temp_load_p2_p%s tl left join catalog_content_p%s cc on tl.code = cc.supplier_code)', part, part));

			alter table temp_load_part_cat add primary key(temp_id);

			select count(*) from temp_load_part_cat into cntupload;

			create temporary table new_codes (
				code varchar,
				code_id bigint,
				cat_id smallint,
				rn int,
				temp_id int
			);

			alter table new_codes add constraint temp_id_fk foreign key (temp_id) references temp_load_part_cat(temp_id);

			insert into new_codes(code, code_id, cat_id, rn, temp_id) (
				select
					t.code,
					min(t.code_id) over w as code_id,
					t.cat_id,
					ROW_NUMBER() over w as rn,
					t.temp_id
				from
					(
						select
							tl.code,
							case when ROW_NUMBER() over w = 1 then nextval('cat_content_id_seq') else null end as code_id,
							tl.cat_id,
							tl.temp_id
						from
							temp_load_part_cat tl
						where
							tl.code_id is null
						window w as
					       		(partition by code)
					) t
				window w as
					(partition by code)
			);

			analyze new_codes;

			select count(*) from new_codes where rn = 1 into cntnew;

			raise notice '# new codes: %', cntnew;

			-- dynamic execution
			/*
			insert into catalog_content_pXX(supplier_code, cat_content_id, cat_id_fk) (
				select
					nc.code,
					nc.code_id,
					nc.cat_id
				from
					new_codes nc
				where
					nc.rn = 1
			);*/
			execute(format('copy (insert into catalog_content_p%s (supplier_code, cat_content_id, cat_id_fk) (select nc.code, nc.code_id, nc.cat_id from new_codes nc where nc.rn = 1) returning *) to ''%s/cat/%s''', part, diff_file_dest, part));
			execute(format('insert into catalog_id (cat_content_id, cat_partition_fk) (select code_id, %s from new_codes nc where nc.rn = 1)', part));

			insert into temp_load_p3(sub_id, code_id, tranche_id) (
				select 
					tl.sub_id,
					case when tl.code_id is null then nc.code_id else tl.code_id end,
					tl.tranche_id
				from
					temp_load_part_cat tl
				left join
					new_codes nc
				on
					tl.temp_id = nc.temp_id
			);

			execute(format('insert into transaction_record_%s (stagei, parti, nnew, nupload) (values (2, %s, %s, %s))', transid, part, cntnew, cntupload));

			-- cleanup
			execute(format('drop table temp_load_p2_p%s', part));
			drop table new_codes;
			drop table temp_load_part_cat;

			return 0;
		end;

	$$ language plpgsql;

	create or replace function upload_catsub_bypart(part int, transid text, diff_file_dest text) returns int as $$
		declare
			tempvar int;
			cntnew int;
			cntupload int;
		begin
			create temporary sequence tl_temp_id_seq;
			create temporary table temp_load_part_catsub (
				sub_id bigint,
				code_id bigint,
				cat_sub_itm_id bigint,
				tranche_id smallint,
				temp_id int default nextval('tl_temp_id_seq')
			);

			execute(format('insert into temp_load_part_catsub(sub_id, code_id, cat_sub_itm_id, tranche_id) (select tl.sub_id, tl.code_id, cs.cat_sub_itm_id, tl.tranche_id from temp_load_p3_p%s tl left join catalog_substance_p%s cs on tl.sub_id = cs.sub_id_fk and tl.code_id = cs.cat_content_fk)', part, part));
			alter table temp_load_part_catsub add primary key (temp_id);

			select count(*) from temp_load_part_catsub into cntupload;

			create temporary table new_entries (
				sub_id bigint,
				code_id bigint,
				cat_sub_itm_id bigint,
				tranche_id smallint,
				rn int,
				temp_id int
			);

			alter table new_entries add constraint temp_id_fk foreign key (temp_id) references temp_load_part_catsub(temp_id);

			insert into new_entries (
				select
					t.sub_id,
					t.code_id,
					min(t.cat_sub_itm_id) over w as cat_sub_itm_id,
					t.tranche_id,
					ROW_NUMBER() over w as rn,
					t.temp_id
				from
				(
					select
						tl.sub_id,
						tl.code_id,
						case when ROW_NUMBER() over w = 1 then nextval('cat_sub_itm_id_seq') else null end as cat_sub_itm_id,
						tl.tranche_id,
						tl.temp_id
					from
						temp_load_part_catsub tl
					where
						tl.cat_sub_itm_id is null
					window w as
						(partition by sub_id, code_id)
				) t
				window w as
					(partition by sub_id, code_id)
			);

			select count(*) from new_entries where rn = 1 into cntnew;

			-- dynamic execution
			/*
			insert into catalog_substance_pXX(sub_id_fk, cat_content_fk, tranche_id, cat_sub_itm_id) (
				select
					sub_id,
					code_id,
					tranche_id,
					cat_sub_itm_id
				from
					new_entries
				where
					rn = 1
			);
			*/

			execute(format('copy (insert into catalog_substance_p%s (sub_id_fk, cat_content_fk, tranche_id, cat_sub_itm_id) (select sub_id, code_id, tranche_id, cat_sub_itm_id from new_entries where rn = 1) returning *) to ''%s/catsub/%s''', part, diff_file_dest, part));

			execute(format('insert into transaction_record_%s (stagei, parti, nnew, nupload) (values (3, %s, %s, %s))', transid, part, cntnew, cntupload));

			execute(format('drop table temp_load_p3_p%s', part));
			drop table new_entries;
			drop table temp_load_part_catsub;

			return 0;

		end;
	$$ language plpgsql;

	create or replace function upload(stage int, part int, transid text, diff_file_dest text) returns int as $$
		begin
			case
				when stage = 1 then
					perform upload_substance_bypart(part, transid, diff_file_dest);
					raise notice 'finished substance bypart';
				when stage = 2 then
					perform upload_catcontent_bypart(part, transid, diff_file_dest);
				when stage = 3 then
					perform upload_catsub_bypart(part, transid, diff_file_dest);
				else
					raise EXCEPTION 'upload stage not defined! %', stage;
					return 1;
			end case;
			return 0;
		end;
	$$ language plpgsql;

	select upload(:stage, :part, :'transid', :'diff_file_dest');

commit;
