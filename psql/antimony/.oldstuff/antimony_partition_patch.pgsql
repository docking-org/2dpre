create or replace procedure create_table_partitions (tabname text, tmp text) language plpgsql AS $$

	declare
		n_partitions int;
		i int;
	begin
		select ivalue from tin_meta where svalue = 'n_partitions' limit 1 into n_partitions;

		for i in 0..(n_partitions-1) loop

			execute(format('create %s table %s_p%s partition of %s for values with (modulus %s, remainder %s)', tmp, tabname, i, tabname, n_partitions, i));

		end loop;

	end;

$$;

create table supplier_codes_t (like supplier_codes);

create table 
