LOAD 'auto_explain';
SET auto_explain.log_nested_statements = ON;
SET auto_explain.log_min_duration = 10;
SET client_min_messages to log;
set enable_partitionwise_aggregate=on;

begin;

	create temporary table source_t (smiles text, supplier_code text, cat_id smallint, tranche_id smallint);
	copy source_t from :'source_f' delimiter ' ';

	create temporary table smiles_update_src (smiles text, tranche_id smallint) partition by hash(smiles);
	create temporary table supplier_update_src (supplier_code text, cat_id smallint) partition by hash(supplier_code);

	call create_table_partitions('smiles_update_src', 'temporary');
	call create_table_partitions('supplier_update_src', 'temporary');

	create temporary table substance_update_diff (sub_id int, tranche_id smallint, tranche_id_old smallint);
	create temporary table supplier_update_diff (cat_content_id int, cat_id smallint, cat_id_old smallint);

	insert into smiles_update_src(smiles, tranche_id) (select smiles, tranche_id from source_t);
	insert into supplier_update_src(supplier_code, cat_id) (select supplier_code, cat_id from source_t);
	drop table source_t;

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

				select concat(diff_destination, '/sub_update_tranche_id/', format('%s', i)) into diff_fn;
				execute(format('copy (update substance_p%s sb set tranche_id = su.tranche_id from (select sb.smiles, su.tranche_id, sb.tranche_id as tranche_id_old from (select max(tranche_id) as tranche_id, smiles from smiles_update_src_p%s group by smiles) su left join (select tranche_id, smiles from substance_p%s) sb on su.smiles = sb.smiles where su.tranche_id != sb.tranche_id) su where sb.smiles = su.smiles returning sb.sub_id, sb.tranche_id, su.tranche_id_old) to ''%s'' delimiter '' ''', i, i, i, diff_fn));


				select concat(diff_destination, '/sup_update_cat_id/', format('%s', i)) into diff_fn;
				execute(format('copy (update catalog_content_p%s cc set cat_id_fk = cu.cat_id from (select cc.supplier_code, cu.cat_id, cc.cat_id_fk as cat_id_old from (select max(cat_id) as cat_id, supplier_code from supplier_update_src_p%s group by supplier_code) cu left join (select cat_id_fk, supplier_code from catalog_content_p%s) cc on cu.supplier_code = cc.supplier_code where cu.cat_id != cc.cat_id_fk) cu where cc.supplier_code = cu.supplier_code returning cc.cat_content_id, cc.cat_id_fk, cu.cat_id_old) to ''%s'' delimiter '' ''', i, i, i, diff_fn));

			end loop;
		end;
	$$ language plpgsql;

	call do_update(:'diff_destination');

commit;
