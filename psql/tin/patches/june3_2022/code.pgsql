---------------------------------------------------------------------------------------------
-- function to look up just one substance by cat_content_id. faster for small batches
create or replace function get_code_by_id (cc_id_q bigint) returns text as $$

declare
	part_id int;
	code text;
begin
	select cat_partition_fk from catalog_id ccid where ccid.cat_content_id = cc_id_q into part_id;
	execute(format('select supplier_code from catalog_content_p%s where cat_content_id = %s', part_id, cc_id_q)) into code;
	return code;
end;

$$ language plpgsql;

create or replace function get_code_by_id_pfk (cc_id_q bigint, cat_partition_fk int) returns text as $$
declare
	code text;
begin
	execute(format('select supplier_code from catalog_content_p%s where cat_content_id = %s', cat_partition_fk, cc_id_q)) into code;
	return code;
end;
$$ language plpgsql;

create or replace function get_cat_id_by_id_pfk (cc_id_q bigint, cat_partition_fk int) returns smallint as $$
declare
	cat_id smallint;
begin
	execute(format('select cat_id_fk from catalog_content_p%s where cat_content_id = %s', cat_partition_fk, cc_id_q)) into cat_id;
	return cat_id;
end;
$$ language plpgsql;

-- like get_many_substance_by_id, but chilling out with the temporary tables
-- for a lookup in the range of 10s of Ks it will be much simpler to ORDER BY on the partition key and let the cache handle things
create or replace procedure get_some_codes_by_id (code_id_input_tabname text, code_output_tabname text) as $$
declare
	extrafields text[];
	extrafields_decl_it text;
	extrafields_decl text;
	subquery_1 text;
	subquery_2 text;
	query text;
begin
	extrafields := get_shared_columns(code_id_input_tabname, code_output_tabname, 'cat_content_id', '{}');

	if array_length(extrafields, 1) > 0 then
		extrafields_decl_it := ',' || cols_declare(extrafields, 'it.');
		extrafields_decl := ',' || cols_declare(extrafields, '');
	else
		extrafields_decl := '';
		extrafields_decl_it := '';
	end if;

	subquery_1 := format('select cid.cat_content_id, cid.cat_partition_fk %1$s from %2$s it left join catalog_id cid on it.cat_content_id = cid.cat_content_id order by cat_partition_fk', extrafields_decl_it, code_id_input_tabname);

	subquery_2 := format('select get_code_by_id_pfk(cat_content_id, cat_partition_fk) supplier_code, cat_content_id, get_cat_id_by_id_pfk(cat_content_id, cat_partition_fk) cat_id %1$s from (%2$s) t', extrafields_decl, subquery_1);

	query := format('insert into %3$s (supplier_code, cat_content_id, cat_id_fk %1$s) (%2$s)', extrafields_decl, subquery_2, code_output_tabname);

	execute(query);
end;
$$ language plpgsql;

-----------------------------------------------------------------------------------------------

-- function to look up just one substance by sub_id. faster for small batches
create or replace function get_substance_by_id (sub_id_q bigint) returns text as $$
declare
	part_id int;
	sub text;
begin
	select sub_partition_fk from substance_id sbid where sbid.sub_id = sub_id_q into part_id;
	if part_id is null then
		select sub_id_right from sub_dups_corrections where sub_id_wrong = sub_id_q into sub_id_q;
		if sub_id_q is null then
			return null;
		end if;
		select sub_partition_fk from substance_id sbid where sbid.sub_id = sub_id_q into part_id;
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

	subquery_1 := format('select it.sub_id, sid.sub_partition_fk %1$s from %2$s it left join substance_id sid on it.sub_id = sid.sub_id order by sub_partition_fk', extrafields_decl_it, sub_id_input_tabname);

	subquery_2 := format('select case when t.sub_partition_fk is null then get_substance_by_id(t.sub_id) else get_substance_by_id_pfk(sub_id, sub_partition_fk) end, sub_id %1$s from (%2$s) t where not t.sub_partition_fk is null', extrafields_decl, subquery_1);

	query := format('insert into %3$s (smiles, sub_id %1$s) (%2$s)', extrafields_decl, subquery_2, substance_output_tabname);
	execute(query);
end;
$$ language plpgsql;

---------------------------------------------------------------------------------------------

create or replace procedure get_some_pairs_by_code_id(code_ids_input_tabname text, pairs_output_tabname text) as $$
declare cols text[];
begin
	create temporary table pairs_tempload_p1 (sub_id bigint, cat_content_id bigint, tranche_id smallint);
	create temporary table pairs_tempload_p2 (smiles text, sub_id bigint, tranche_id smallint, cat_content_id bigint);

	execute(format('insert into pairs_tempload_p1(sub_id, cat_content_id, tranche_id) (select sub_id_fk, cat_content_fk, tranche_id from %s i left join catalog_substance_cat cs on i.cat_content_id = cs.cat_content_fk)', code_ids_input_tabname));

	call get_some_substances_by_id('pairs_tempload_p1', 'pairs_tempload_p2');

	call get_some_codes_by_id('pairs_tempload_p2', pairs_output_tabname);
end;
$$ language plpgsql;
