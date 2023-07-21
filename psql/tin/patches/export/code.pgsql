CREATE OR REPLACE FUNCTION cols_declare_type (cols text[])
        RETURNS text
        AS $$
DECLARE
        coldecl text[];
BEGIN
        SELECT
                INTO coldecl array_agg(replace(t.col, ':', ' '))
        FROM
                unnest(cols) as t (col);
        RETURN array_to_string(coldecl, ', ');
END;
$$
LANGUAGE plpgsql;

create or replace procedure rename_table_partitions (tabname text, desiredname text)
language plpgsql
as $$
declare
        n_partitions int;
        i int;
begin
        select
                ivalue
        from
                meta
        where
                svalue = 'n_partitions'
        limit 1 into n_partitions;
        for i in 0.. (n_partitions - 1)
        loop
                execute (format('alter table if exists %s_p%s rename to %s_p%s', tabname, i, desiredname, i));
		execute (format('alter table if exists %1$sp%2$s rename to %s_p%s', tabname, i, desiredname, i));
        end loop;
end;
$$;



	create or replace procedure get_many_codes_by_id_ (code_id_input_tabname text, code_output_tabname text, input_pre_partitioned boolean) as $$

                declare
                        retval text[];
                        n_partitions int;
                        i int;
                        t_start timestamptz;
			extra_columns text[];
			extra_cols_decl_type text;
			extra_cols_decl text;
			extra_cols_decl_cc text;
			extra_cols_decl_cp text;
                begin
			set enable_partitionwise_join = ON;

			extra_columns := get_shared_columns(code_id_input_tabname, code_output_tabname, 'cat_content_id', '{}');

			if array_length(extra_columns, 1) > 0 then
				extra_cols_decl_type := ',' || cols_declare_type(extra_columns);
				extra_cols_decl := ',' || cols_declare(extra_columns, '');
				extra_cols_decl_cc := ',' || cols_declare(extra_columns, 'cc.');
				extra_cols_decl_cp := ',' || cols_declare(extra_columns, 'cp.');
			else
				extra_cols_decl := '';
				extra_cols_decl_cc := '';
				extra_cols_decl_cp := '';
			end if;

                        t_start := clock_timestamp();
			if input_pre_partitioned then
				execute(format('alter table %s rename to catids_by_catid', code_id_input_tabname));
				call rename_table_partitions(code_id_input_tabname, 'catids_by_catid');
			else
				execute(format('create temporary table catids_by_catid (cat_content_id bigint %1$s) partition by hash(cat_content_id)', extra_cols_decl_type));
/*                      create temporary table catids_by_catid (
                                cat_content_id bigint
                        ) partition by hash(cat_content_id);*/

	                        call create_table_partitions('catids_by_catid'::text, 'temporary'::text);
				execute(format('insert into catids_by_catid (select cat_content_id %s from %s)', extra_cols_decl, code_id_input_tabname));
			end if;

			execute(format('create temporary table catids_by_pfk (cat_content_id bigint, cat_partition_fk smallint %1$s) partition by list(cat_partition_fk)', extra_cols_decl_type));
/*                      create temporary table catids_by_pfk (
                                cat_content_id bigint,
                                cat_partition_fk smallint
                        ) partition by list(cat_partition_fk);*/

                        select ivalue from meta where svalue = 'n_partitions' limit 1 into n_partitions;
                        for i in 0..(n_partitions-1) loop
                                execute(format('create temporary table catids_by_pfk_p%s partition of catids_by_pfk for values in (%s)', i, i));
                        end loop;

                        create temporary table catids_by_pfk_pn partition of catids_by_pfk for values in (null);

                        for i in 0..(n_partitions-1) loop
                                execute(format('insert into catids_by_pfk(cat_content_id, cat_partition_fk %3$s) (select cc.cat_content_id, ccid.cat_partition_fk %4$s from catids_by_catid_p%1$s cc left join catalog_id_p%1$s ccid on cc.cat_content_id = ccid.cat_content_id)', i, i, extra_cols_decl, extra_cols_decl_cc));
                        end loop;

                        for i in REVERSE (n_partitions-1)..0 loop
                                execute(format('insert into %1$s (cat_content_id, supplier_code, cat_id_fk %4$s) (select cp.cat_content_id, cc.supplier_code, cc.cat_id_fk %5$s from catids_by_pfk_p%2$s cp left join catalog_content_p%2$s cc on cp.cat_content_id = cc.cat_content_id)', code_output_tabname, i, i, extra_cols_decl, extra_cols_decl_cp));
                        end loop;

                        execute(format('insert into %1$s (cat_content_id %2$s) (select cat_content_id %2$s from catids_by_pfk_pn)', code_output_tabname, extra_cols_decl));

			if input_pre_partitioned then
				execute(format('alter table catids_by_catid rename to %s', code_id_input_tabname));
				call rename_table_partitions('catids_by_catid', code_id_input_tabname);
			else
                        	drop table catids_by_catid;
			end if;
                        drop table catids_by_pfk;

                        raise notice 'time spent=%s', clock_timestamp() - t_start;
                end;

        $$ language plpgsql;

	create or replace procedure get_many_codes_by_id(code_id_input_tabname text, code_output_tabname text) as $$
		begin
			call get_many_codes_by_id_(code_id_input_tabname, code_output_tabname, false);
		end;
	$$ language plpgsql;

	create or replace procedure get_many_substances_by_id_ (sub_id_input_tabname text, substance_output_tabname text, input_pre_partitioned boolean) as $$

                declare
                        retval text[];
                        n_partitions int;
                        i int;
                        t_start timestamptz;
			extra_cols text[];
			extra_cols_decl text;
			extra_cols_decl_type text;
			extra_cols_decl_ss text;
			extra_cols_decl_sp text;
                begin
                        t_start := clock_timestamp();

			extra_cols := get_shared_columns(sub_id_input_tabname, substance_output_tabname, '', '{{"tranche_id"},{"smiles"},{"sub_id"}}');

			if array_length(extra_cols, 1) > 0 then
				extra_cols_decl_type := ',' || cols_declare_type(extra_cols);
				extra_cols_decl := ',' || cols_declare(extra_cols, '');
				extra_cols_decl_ss := ',' || cols_declare(extra_cols, 'ss.');
				extra_cols_decl_sp := ',' || cols_declare(extra_cols, 'sp.');
			else
				extra_cols_decl := '';
				extra_cols_decl_type := '';
				extra_cols_decl_ss := '';
				extra_cols_decl_sp := '';
			end if;

			if input_pre_partitioned then
				execute(format('alter table %s rename to subids_by_subid', sub_id_input_tabname));
				call rename_table_partitions(sub_id_input_tabname, 'subids_by_subid');
			else
				execute(format('create temporary table subids_by_subid (sub_id bigint %1$s) partition by hash(sub_id)', extra_cols_decl_type));
/*			create temporary table subids_by_subid (
				sub_id bigint
			) partition by hash(sub_id);*/

	                        call create_table_partitions('subids_by_subid'::text, 'temporary'::text);
				execute(format('insert into subids_by_subid (select sub_id %s from %s)', extra_cols_decl, sub_id_input_tabname));
			end if;

			execute(format('create temporary table subids_by_pfk (sub_id bigint, sub_partition_fk smallint %1$s) partition by list(sub_partition_fk)', extra_cols_decl_type));
/*			create temporary table subids_by_pfk (
				sub_id bigint,
				sub_partition_fk smallint
			) partition by list(sub_partition_fk);*/

                        select ivalue from meta where svalue = 'n_partitions' limit 1 into n_partitions;
                        for i in 0..(n_partitions-1) loop
                                execute(format('create temporary table subids_by_pfk_p%s partition of subids_by_pfk for values in (%s)', i, i));
                        end loop;

                        create temporary table subids_by_pfk_pn partition of subids_by_pfk for values in (null);

                        for i in 0..(n_partitions-1) loop
                                execute(format('insert into subids_by_pfk (select ss.sub_id, sbid.sub_partition_fk %3$s from subids_by_subid_p%1$s ss left join substance_id_p%1$s sbid on ss.sub_id = sbid.sub_id)', i, i, extra_cols_decl_ss));
				if not input_pre_partitioned then
					execute(format('drop table subids_by_subid_p%s', i));
				end if;
                        end loop;


			-- I theorize that going in reverse on the next iteration will improve cache access
			-- partition populated more recently == more likely in cache
                        for i in REVERSE (n_partitions-1)..0 loop
                                execute(format('insert into %1$s (sub_id, smiles, tranche_id %5$s) (select sp.sub_id, sb.smiles, sb.tranche_id %4$s from subids_by_pfk_p%2$s sp left join substance_p%2$s sb on sp.sub_id = sb.sub_id)', substance_output_tabname, i, i, extra_cols_decl_sp, extra_cols_decl));
				execute(format('drop table subids_by_pfk_p%s', i));
                        end loop;

                        execute(format('insert into %1$s (sub_id, smiles, tranche_id %2$s) (select sub_id, get_substance_by_id(sub_id) as smiles, get_tranche_by_id(sub_id) as tranche_id %2$s from subids_by_pfk_pn)', substance_output_tabname, extra_cols_decl));

			if input_pre_partitioned then
				execute(format('alter table subids_by_subid rename to %s', sub_id_input_tabname));
				call rename_table_partitions('subids_by_subid', sub_id_input_tabname);
			else
                        	drop table subids_by_subid;
			end if;
                        drop table subids_by_pfk;

                        raise notice 'time spent=%s', clock_timestamp() - t_start;
                end;

        $$ language plpgsql;

	create or replace procedure get_many_substances_by_id(sub_id_input_tabname text, substance_output_tabname text) as $$
	begin
		call get_many_substances_by_id_(sub_id_input_tabname, substance_output_tabname, false);
	end;
	$$ language plpgsql;

	create or replace procedure get_many_pairs_by_id_(pair_ids_input_tabname text, pairs_output_tabname text, input_pre_partitioned boolean) as $$
	declare msg text;
	begin
		/* (sub_id bigint, cat_content_id bigint) -> (smiles text, code text, sub_id bigint, tranche_id smallint, cat_id_fk smallint) */
		create temporary table pairs_tempload (smiles text, sub_id bigint, cat_content_id bigint, tranche_id smallint) partition by hash(cat_content_id);
		call create_table_partitions('pairs_tempload', 'temporary');

		call get_many_substances_by_id_(pair_ids_input_tabname, 'pairs_tempload', input_pre_partitioned);

		call get_many_codes_by_id_('pairs_tempload', pairs_output_tabname, true);

		drop table pairs_tempload;

	end;
	$$ language plpgsql;

	create or replace procedure get_many_pairs_by_id(pair_ids_input_tabname text, pairs_output_tabname text) as $$
	begin
		call get_many_pairs_by_id_(pair_ids_input_tabname, pairs_output_tabname, false);
	end;
	$$ language plpgsql;

	create or replace procedure get_some_pairs_by_sub_id(sub_ids_input_tabname text, pairs_output_tabname text) as $$
	declare cols text[];
	begin
		create temporary table pairs_tempload_p1 (sub_id bigint, cat_content_id bigint, tranche_id smallint);
		create temporary table pairs_tempload_p2 (smiles text, sub_id bigint, tranche_id smallint, cat_content_id bigint);

		execute(format('insert into pairs_tempload_p1(sub_id, cat_content_id, tranche_id) (select sub_id_fk, cat_content_fk, tranche_id from %s i left join catalog_substance cs on i.sub_id = cs.sub_id_fk)', sub_ids_input_tabname));

		call get_some_substances_by_id('pairs_tempload_p1', 'pairs_tempload_p2');

		call get_some_codes_by_id('pairs_tempload_p2', pairs_output_tabname);
	end;
	$$ language plpgsql;

