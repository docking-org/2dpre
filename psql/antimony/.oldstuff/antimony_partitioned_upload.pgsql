	create or replace function upload_substance_bypart(part int, transid text) returns int as $$
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
	
			/* BEGIN GENERALIZATION REWRITE */
			-- inputs: loadtable::text, desttable::text, nexttable::text, keyfield::text, idfield::text, destseq::text

			/*
			destcolumns := loadtable & desttable - keyfield - idfield
			loadcolumns := loadtable - keyfield  - idfield
			nextcolumns := loadtable & nexttable - idfield*/

			create or replace function get_shared_columns (tab1, tab2, excl1, excl2) returns text[] as $$
				declare
					shared_cols text[];
				begin
					select into shared_cols array_agg(concat(t1.col, ':', t1.dtype)) from (select attname as col, atttypid::regtype as dtype from pg_attribute where attrelid = tab1) t1 inner join (select attname as col, atttypid::regtype as dtype from pg_attribute where attrelid = tab2) t2 on t1.col = t2.col where t1.col != excl1 and t1.col != excl2;
					return shared_cols;
				end;
			$$ language plpgsql;

			create or replace function sc_colname(scol text) returns text as $$
				begin
					return SPLIT_PART(scol, ':', 1)
				end;
			$$ language plpgsql;

			create or replace function sc_coltype(scol text) return text as $$
				begin
					return SPLIT_PART(scol, ':', 2)
				end;
			$$ language plpgsql;

			destcolumns := get_shared_columns(loadtable, desttable, idfield, keyfield);
			loadcolumns := get_shared_columns(loadtable, loadtable, idfield, keyfield);
			nextcolumns := get_shared_columns(loadtable, nexttable, idfield, '');

			execute(format('create temporary table temp_table_load(%s %s, %s %s)', sc_colname(idfield), sc_coltype(idfield), sc_colname(keyfield), sc_coltype(keyfield)));
			for col in loadcolumns loop
				execute(format('alter table temp_table_load add column %s %s', sc_colname(col), sc_coltype(col)));
			end loop;
			alter table temp_table_load add column temp_id int default nextval('temp_seq');

			execute(format('insert into temp_table_load(%1$s, %2$s, %3$s) (select t.%1$s, s.%2$s, %4$s from %5$s_p%6$s t left join %7$s s on t.%2$s = s.%2$s)', sc_colname(idfield), sc_colname(keyfield), sc_csv_join_names(loadcolumns, ''), sc_csv_join_names(loadcolumns, 't.'), loadtable, partition, desttable));

			execute(format('create temporary table new_entries (%1$s %2$s, %3$s %4$s, temp_id int)', sc_colname(idfield), sc_coltype(idfield), sc_colname(keyfield), sc_coltype(keyfield)));

			execute(format('insert into new_entries (select %1$s, min(%2$s) over w as %2$s, ROW_NUMBER() over w as rn, temp_id from (select t.%1$s, case when ROW_NUMBER() over w = 1 then nextval(''%3$s'') else null end as %2$s, t.temp_id from temp_table_load t where t.%2$s is null window w as (partition by t.%1$s', sc_colname(keyfield), sc_colname(idfield), destseq));


			create temporary sequence temp_seq;
			create temporary table temp_table_load;
			alter table temp_table_load add column keyfield keyfieldtype;
			alter table temp_table_load add column idfield idfieldtype;
			alter table temp_table_load add column destfields destfieldstype;
			alter table temp_table_load add column otherfields otherfieldstype;
			alter table temp_table_load add column temp_id int default nextval('temp_seq');

			insert into temp_table_load(keyfield, idfield, destfields, otherfields) (select t.keyfield, s.idfield, t.destfields, t.otherfields from load_table_p%s t left join source_table_p%s s on t.keyfield = s.keyfield);

			create temporary table new_entries (keyfield keyfieldtype, idfield idfieldtype, temp_id int);

			insert into new_entries (select keyfield, min(idfield) over w as idfield, ROW_NUMBER() over w as rn, temp_id from (select t.keyfield, case when ROW_NUMBER() over w = 1 then nextval('sub_id_seq') else null end as idfield, t.temp_id from temp_table_load t where t.idfield is null window w as (partition by t.keyfield));

			select count(*) from new_entries where rn = 1 into cntnew;

			insert into destination_p%s (keyfield, idfield, otherfields) (select n.keyfield, n.idfield, t.otherfields from new_entries n left join temp_table_load t on n.temp_id = t.temp_id where n.rn = 1);

			/* END GENERALIZATION REWRITE */

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
                        execute(format('insert into substance_p%s (smiles, sub_id, tranche_id) (select smiles, sub_id, tranche_id from new_substances ns where ns.rn = 1)', part));

                        -- now we move the processed data to the next stage
                        insert into temp_load_p2 (

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
