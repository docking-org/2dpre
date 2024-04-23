LOAD 'auto_explain';
SET auto_explain.log_nested_statements = ON;
SET auto_explain.log_min_duration = 10;
SET client_min_messages to log;
set enable_partitionwise_aggregate=on;

--delete substance/cat_subs/cats using upload diffs
--using this in case a catalog gets uploaded in the wrong order, or if a catalog is outdated and needs to be delete_codes

create or replace procedure delete_codes(diff_path text) as
	$$
	declare n_partitions int;
	begin
		select ivalue from meta where svalue = 'n_partitions' limit 1 into n_partitions;
		-- delete everything in diff_path/cat/i 
		for i in 0..n_partitions-1 loop
			perform logg('deleting from partition ' || i);
			
			create temporary table if not exists delete_cats(cat_content_fk int, cat_id int, supplier_code text, notsure text, alsonotsure text);
			create temporary table if not exists delete_substances(smiles text, substance_id int, tranche text, notsure int);
			create temporary table if not exists delete_cat_subs(cat_content_fk int, sub_id_fk int, notsure bigint);

			execute(format('copy delete_cats(cat_content_fk, cat_id, supplier_code, notsure, alsonotsure) from %L', diff_path || '/cat/' || i));
			execute(format('copy delete_substances(smiles, substance_id, tranche, notsure) from %L', diff_path || '/sub/' || i || '.new'));
			execute(format('copy delete_cat_subs(cat_content_fk, sub_id_fk, notsure) from %L', diff_path || '/catsub/' || i));
		
			execute(format('delete from catalog_substance_p%s where cat_content_fk in (select cat_content_fk from delete_cats)', i));
			execute(format('delete from catalog_content_p%s where cat_content_id in (select cat_content_fk from delete_cats)', i));
			execute(format('delete from catalog where cat_id in (select cat_id from delete_cats)', i));
			execute(format('delete from substance_p%s where sub_id in (select substance_id from delete_substances)', i));
			execute(format('delete from substance_id where sub_id in (select substance_id from delete_substances)', i));

			drop table if exists delete_cats cascade;
			drop table if exists delete_substances cascade;
			drop table if exists delete_cat_subs cascade;
		end loop;

		--set sub_id sequence to max(sub_id) + 1
		--execute(format('select setval(''sub_id_seq'', (select max(sub_id) from substance) + 1)')); 
		--delete from meta where varname = 'upload_name' and svalue = 'chbr';

	end;
$$ language plpgsql;

call delete_codes(:'diff_path');
