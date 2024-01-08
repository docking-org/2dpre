LOAD 'auto_explain';
SET auto_explain.log_nested_statements = ON;
SET auto_explain.log_min_duration = 10;
SET client_min_messages to log;
begin; 
-- initialize hex values table
create temporary table hashvals_list(hashval char(2));
do $$
begin 
	for i in 0..255 loop
		insert into hashvals_list (values (lpad(to_hex(i), 2, '0')));
	end loop;
end $$ language plpgsql;

-- create partitions for the temporary sorting table
create temporary table for_hashvals (last2hash char(2), supplier_code text, cat_content_id bigint) partition by list (last2hash);
do $$
declare i text;
begin
	for i in select hashval from hashvals_list loop
		execute(format('create temporary table for_hashvals_%1$s partition of for_hashvals for values in (''%1$s'')', i));
	end loop;
end $$ language plpgsql;

-- copy into the temporary sorting table, splitting up by cat_content partitions to reduce memory usage
drop procedure if exists copy_in(num_digits text);
create or replace procedure copy_in(num_digits text) as $$
declare n_partitions int;
begin 
	select ivalue from meta where svalue = 'n_partitions' limit 1 into n_partitions;
	for i in 0..n_partitions-1 loop
		execute(format('insert into for_hashvals(last2hash, supplier_code, cat_content_id) (select left(right(sha256(catalog_content_p%s.supplier_code::bytea)::varchar, 4), %s) last2hash, supplier_code, cat_content_id from catalog_content_p%s)', i, num_digits, i));
	end loop;
end $$ language plpgsql;

-- copy out each partition
create or replace procedure copy_out(out_dest text, machine_id text) as $$
declare i text;
begin
	for i in select hashval from hashvals_list loop
		execute(format('copy (select supplier_code, (right(sha256(supplier_code::bytea)::varchar, 4)) last4hash, cat_content_id, ''%3$s'' machine_id from for_hashvals_%1$s) to ''%2$s/%1$s''', i, out_dest, machine_id));
	end loop;

end $$ language plpgsql;

call copy_in(:'num_digits');

call copy_out(:'output_file', :'machine_id');





