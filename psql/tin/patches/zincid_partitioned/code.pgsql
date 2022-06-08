LOAD 'auto_explain';
SET auto_explain.log_nested_statements = ON;
SET auto_explain.log_min_duration = 0;
SET client_min_messages to LOG;

begin;

	create or replace procedure create_table_partitions (tabname text, tmp text) language plpgsql AS $$

		declare
			n_partitions int;
			i int;
		begin
			select ivalue from meta where svalue = 'n_partitions' limit 1 into n_partitions;

			for i in 0..(n_partitions-1) loop

				execute(format('create %s table %s_p%s partition of %s for values with (modulus %s, remainder %s)', tmp, tabname, i, tabname, n_partitions, i));

			end loop;

		end;

	$$;

	create or replace procedure export_ids_from_substance () language plpgsql as $$

		declare
			n_partitions int;
			i int;
		begin
			select ivalue from meta where svalue = 'n_partitions' limit 1 into n_partitions;

			for i in 0..(n_partitions-1) loop

				execute(format('insert into substance_id (sub_id, sub_partition_fk) (select sub_id, %s from substance_p%s)', i, i));

			end loop;

		end;

	$$;

	-- function to look up just one substance by sub_id. faster for small batches
	create or replace function get_substance_by_id (sub_id_q bigint) returns text as $$

		declare
			part_id int;
			sub text;
		begin
			select sub_partition_fk from substance_id sbid where sbid.sub_id = sub_id_q into part_id;
			if part_id is null then
				raise info '%', sub_id_q;
				select sub_id_right from sub_dups_corrections where sub_id_wrong = sub_id_q into sub_id_q;
				select sub_partition_fk from substance_id sbid where sbid.sub_id = sub_id_q into part_id;
				raise info '% %', sub_id_q, part_id;
			end if;
			execute(format('select smiles from substance_p%s where sub_id = %s', part_id, sub_id_q)) into sub;
			return sub;
		end;

	$$ language plpgsql;

	create or replace function get_substance_by_id_pfk (sub_id_q bigint, part_id smallint) returns text as $$
		declare 
			sub text;
		begin
			execute(format('select smiles from substance_p%s where sub_id = %s', part_id, sub_id_q)) into sub;
			return sub;
		end;

	$$ language plpgsql;


	-- like get_many_substance_by_id, but chilling out with the temporary tables
	-- for a lookup in the range of 10s of Ks it will be much simpler to ORDER BY on the partition key and let the cache handle things
	create or replace procedure get_some_substances_by_id (sub_id_input_tabname text, substance_output_tabname text) as $$
		declare
			extrafields text[];
			extrafields_decl_it text;
			extrafields_decl text;
			subquery_1 text;
			subquery_2 text;
			query text;
		begin
			extrafields := get_shared_columns(sub_id_input_tabname, substance_output_tabname, 'sub_id', '{}');

			if array_length(extrafields, 1) > 0 then
				extrafields_decl_it := ',' || cols_declare(extrafields, 'it.');
				extrafields_decl := ',' || cols_declare(extrafields, '');
			else
				extrafields_decl := '';
				extrafields_decl_it := '';
			end if;

			subquery_1 := format('select sid.sub_id, sid.sub_partition_fk %1$s from %2$s it left join substance_id sid on it.sub_id = sid.sub_id order by sub_partition_fk', extrafields_decl_it, sub_id_input_tabname);

			subquery_2 := format('select case when not sub_id is null then get_substance_by_id_pfk(sub_id, sub_partition_fk) else null end, sub_id %1$s from (%2$s) t', extrafields_decl, subquery_1);

			query := format('insert into %3$s (smiles, sub_id %1$s) (%2$s)', extrafields_decl, subquery_2, substance_output_tabname);

			execute(query);
		end;
	$$ language plpgsql;

	-- procedure to force data locality for large lookups by sub_id
	-- turns out I can use compiiler hints like /* USE_HASH(a) */ to force hash joins
	-- wish I had known that before I ripped the whole system up
	-- still, there are advantages to this partitioning strategy. For one, it allows incremental progress on the upload, and easier maintenance of indexes etc.
	create or replace procedure get_many_substances_by_id (sub_id_input_tabname text, substance_output_tabname text, extra_field text) as $$

		declare 
			retval text[];
			n_partitions int;
			i int;
			t_start timestamptz;
		begin
			t_start := clock_timestamp();

			if not extra_field is null then
				execute(format('create temporary table subids_by_subid (sub_id bigint, %s %s) partition by hash(sub_id)', sc_colname(extra_field), sc_coltype(extra_field)));
			else
				create temporary table subids_by_subid (
					sub_id bigint
				) partition by hash(sub_id);
			end if;

			call create_table_partitions('subids_by_subid'::text, 'temporary'::text);

			if not extra_field is null then
				execute(format('create temporary table subids_by_pfk (sub_id bigint, sub_partition_fk smallint, %s %s) partition by list(sub_partition_fk)', sc_colname(extra_field), sc_coltype(extra_field)));
			else
				create temporary table subids_by_pfk (
					sub_id bigint,
					sub_partition_fk smallint
				) partition by list(sub_partition_fk);
			end if;

			select ivalue from meta where svalue = 'n_partitions' limit 1 into n_partitions;
			for i in 0..(n_partitions-1) loop
				execute(format('create temporary table subids_by_pfk_p%s partition of subids_by_pfk for values in (%s)', i, i));
			end loop;

			create temporary table subids_by_pfk_pn partition of subids_by_pfk for values in (null);

			execute(format('insert into subids_by_subid (select sub_id%s from %s)', sub_id_input_tabname));

			for i in 0..(n_partitions-1) loop
				execute(format('insert into subids_by_pfk (select ss.sub_id, sbid.sub_partition_fk from subids_by_subid_p%s ss left join substance_id_p%s sbid on ss.sub_id = sbid.sub_id)', i, i));
			end loop;

			for i in 0..(n_partitions-1) loop
				execute(format('insert into %s (sub_id, smiles, tranche_id) (select sp.sub_id, sb.smiles, sb.tranche_id from subids_by_pfk_p%s sp left join substance_p%s sb on sp.sub_id = sb.sub_id)', substance_output_tabname, i, i));
			end loop;

			execute(format('insert into %s (sub_id) (select sub_id from subids_by_pfk_pn)', substance_output_tabname));

			drop table subids_by_subid;
			drop table subids_by_pfk;

			raise notice 'time spent=%s', clock_timestamp() - t_start;
		end;

	$$ language plpgsql;

	do $$
		declare
			i int;
			n_partitions int;
		begin
			select ivalue from meta where svalue = 'n_partitions' limit 1 into n_partitions;
			for i in 0..(n_partitions-1) loop
				execute(format('alter table if exists substance_tp%s rename to substance_p%s', i, i));
				execute(format('alter table if exists substance_t_p%s rename to substance_p%s', i, i));
			end loop;
		end;
	$$ language plpgsql;

commit;
