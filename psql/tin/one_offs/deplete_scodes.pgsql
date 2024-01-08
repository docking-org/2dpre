LOAD 'auto_explain';
SET auto_explain.log_nested_statements = ON;
SET auto_explain.log_min_duration = 10;
SET client_min_messages to log;
set enable_partitionwise_aggregate=on;

begin;

--	create temporary table source_t (smiles text, supplier_code text, cat_id int, tranche_id int);
--	copy source_t from :'source_f' delimiter ' ';

--	create temporary table supplier_update_src (supplier_code text) partition by hash(supplier_code);

--	call create_table_partitions('supplier_update_src', 'temporary');

	--create temporary table supplier_update_diff (cat_content_id int, cat_id smallint, cat_id_old smallint);

--	insert into supplier_update_src(supplier_code) (select supplier_code from source_t);
--	drop table source_t;

	create or replace procedure do_update(diff_destination text) as
		$$
		declare
			i int;
			n_update int;
			n_partitions int;
			diff_fn text;
		begin
			select ivalue from meta where svalue = 'n_partitions' limit 1 into n_partitions;

			for i in 0..(n_partitions-1) loop
				raise info '||| % ||| % |||', i, clock_timestamp();

				select concat(diff_destination, '/sup_update_depleted/', format('%s', i)) into diff_fn;
				execute(format('copy (update catalog_content_p%s cc set depleted = true where supplier_code like ''s_%%'' to ''%s'' delimiter '' ''', i, i, diff_fn));

			end loop;
		end;
	$$ language plpgsql;

	call do_update(:'diff_destination');

commit;
