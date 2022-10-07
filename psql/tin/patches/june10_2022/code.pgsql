---------------------------------------------------------------------------------------------
-- function to look up just one substance by cat_content_id. faster for small batches
create or replace function get_code_by_id (cc_id_q bigint) returns text as $$

declare
	part_id int;
	code text;
begin
	if cc_id_q is null then
		return null;
	end if;
	select cat_partition_fk from catalog_id ccid where ccid.cat_content_id = cc_id_q into part_id;
	execute(format('select supplier_code from catalog_content_p%s where cat_content_id = %s', part_id, cc_id_q)) into code;
	return code;
end;

$$ language plpgsql;

create or replace function get_code_by_id_pfk (cc_id_q bigint, cat_partition_fk int) returns text as $$
declare
	code text;
begin
	if cat_partition_fk is null then
		return null;
	end if;
	execute(format('select supplier_code from catalog_content_p%s where cat_content_id = %s', cat_partition_fk, cc_id_q)) into code;
	return code;
end;
$$ language plpgsql;

create or replace function get_cat_id_by_id_pfk (cc_id_q bigint, cat_partition_fk int) returns smallint as $$
declare
	cat_id smallint;
begin
	if cat_partition_fk is null then
		return null;
	end if;
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

drop function if exists get_substance_by_id;
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
	execute(format('select smiles::varchar from substance_p%s where sub_id = %s', part_id, sub_id_q)) into sub;
	return sub;
end;

$$ language plpgsql;

drop function if exists get_substance_by_id_pfk;
create or replace function get_substance_by_id_pfk (sub_id_q bigint, part_id smallint) returns text as $$
declare
	sub text;
begin
	if part_id is null then
		return get_substance_by_id(sub_id_q);
	end if;
	execute(format('select smiles::varchar from substance_p%s where sub_id = %s', part_id, sub_id_q)) into sub;
	return sub;
end;

$$ language plpgsql;

create or replace function get_tranche_by_id (sub_id_q bigint) returns smallint as $$
declare
	tranche_id smallint;
	part_id smallint;
begin
	select sub_partition_fk from substance_id sbid where sbid.sub_id = sub_id_q into part_id;
	if part_id is null then
		select sub_id_right from sub_dups_corrections where sub_id_wrong = sub_id_q into sub_id_q;
		if sub_id_q is null then
			return null;
		end if;
		select sub_partition_fk from substance_id sbid where sbid.sub_id = sub_id_q into part_id;
	end if;
	execute(format('select tranche_id::smallint from substance_p%s where sub_id = %s', part_id, sub_id_q)) into tranche_id;
	return tranche_id;
end;
$$ language plpgsql;

create or replace function get_tranche_by_id_pfk (sub_id_q bigint, part_id smallint) returns smallint as $$
declare
	tranche_id smallint;
begin
	if part_id is null then
		return get_tranche_by_id(sub_id_q);
	end if;
	execute(format('select tranche_id::smallint from substance_p%s where sub_id = %s', part_id, sub_id_q)) into tranche_id;
	return tranche_id;
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
	extrafields := get_shared_columns(sub_id_input_tabname, substance_output_tabname, 'sub_id', '{{"tranche_id:smallint"}}');

	if array_length(extrafields, 1) > 0 then
		extrafields_decl_it := ',' || cols_declare(extrafields, 'it.');
		extrafields_decl := ',' || cols_declare(extrafields, '');
	else
		extrafields_decl := '';
		extrafields_decl_it := '';
	end if;

	subquery_1 := format('select it.sub_id, sid.sub_partition_fk %1$s from %2$s it left join substance_id sid on it.sub_id = sid.sub_id order by sub_partition_fk', extrafields_decl_it, sub_id_input_tabname);

	subquery_2 := format('select get_substance_by_id_pfk(sub_id, sub_partition_fk) as smiles, get_tranche_by_id_pfk(sub_id, sub_partition_fk) tranche_id, sub_id %1$s from (%2$s) t', extrafields_decl, subquery_1);

	query := format('insert into %3$s (smiles, tranche_id, sub_id %1$s) (%2$s)', extrafields_decl, subquery_2, substance_output_tabname);
	execute(query);
end;
$$ language plpgsql;

---------------------------------------------------------------------------------------------

-- expects tables "vendor_input" and "pairs_output" to have been created
-- cb_vendor_input (supplier_code text);
-- cb_pairs_output (smiles text, sub_id bigint, tranche_id smallint, supplier_code text, cat_id_fk smallint);
-- antimony stores cat_content_id of stored supplier codes, but we don't use that here on the off chance that cat_content_id is/becomes unstable
-- more reliable to directly look up by code value
create or replace procedure cb_get_some_pairs_by_vendor() as $$
begin
	create temporary table pairs_tempload_p1(supplier_code text, sub_id bigint, cat_id smallint);
	--create temporary table pairs_tempload_p2(smiles text, sub_id bigint, tranche_id smallint, supplier_code text, cat_id_fk smallint);

	insert into pairs_tempload_p1 (select i.supplier_code, cs.sub_id_fk, cc.cat_id_fk from cb_vendor_input i left join catalog_content cc on i.supplier_code = cc.supplier_code left join catalog_substance_cat cs on cs.cat_content_fk = cc.cat_content_id);

	call get_some_substances_by_id('pairs_tempload_p1', 'cb_pairs_output');

	drop table pairs_tempload_p1;
end;
$$ language plpgsql;

-- expects tables "q_sub_id_input" and "pairs_output" to have been created - just so we don't need to use ugly "execute" statements for certain logic
-- cb_sub_id_input (sub_id bigint, tranche_id_orig smallint)
-- cb_pairs_output (smiles text, sub_id bigint, tranche_id smallint, supplier_code text, cat_id smallint, tranche_id_orig smallint)
-- need to keep track of the original tranche provided by the searched zinc id, is useful in case id does not look up or there is a mismatch
create or replace procedure cb_get_some_pairs_by_sub_id() as $$
begin
	create temporary table pairs_tempload_p1(smiles text, sub_id bigint, tranche_id smallint, tranche_id_orig smallint);
	create temporary table pairs_tempload_p2(smiles text, sub_id bigint, tranche_id smallint, cat_content_id bigint, tranche_id_orig smallint);

	call get_some_substances_by_id('cb_sub_id_input', 'pairs_tempload_p1');

	insert into pairs_tempload_p2 (select p1.smiles, p1.sub_id, p1.tranche_id, cs.cat_content_fk, p1.tranche_id_orig from pairs_tempload_p1 p1 left join catalog_substance cs on cs.sub_id_fk = p1.sub_id);

	call get_some_codes_by_id('pairs_tempload_p2', 'cb_pairs_output');

	drop table pairs_tempload_p1;
	drop table pairs_tempload_p2;
end;
$$ language plpgsql;
-- by the way- "cb" stands for "cartblanche" the name of the frontend site, given that these functions are used by the frontend

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

create or replace procedure get_some_pairs_by_sub_id(sub_ids_input_tabname text, pairs_output_tabname text) as $$
declare cols text[];
begin
	create temporary table pairs_tempload_p1 (sub_id bigint, cat_content_id bigint);
	create temporary table pairs_tempload_p2 (smiles text, sub_id bigint, tranche_id smallint, cat_content_id bigint);

	execute(format('insert into pairs_tempload_p1(sub_id, cat_content_id) (select i.sub_id, cat_content_fk from %s i left join catalog_substance cs on i.sub_id = cs.sub_id_fk)', sub_ids_input_tabname));

	call get_some_substances_by_id('pairs_tempload_p1', 'pairs_tempload_p2');

	call get_some_codes_by_id('pairs_tempload_p2', pairs_output_tabname);
end;
$$ language plpgsql;
