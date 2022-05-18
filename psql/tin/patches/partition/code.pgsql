-- copy pasting this code in here too
-- most databases have already finished this patch (using different code), but it is nice to have a more up-to-date script for reference
create or replace procedure create_table_partitions (tabname text, tmp text)
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
		execute (format('create %s table %s_p%s partition of %s for values with (modulus %s, remainder %s)', tmp, tabname, i, tabname, n_partitions, i));
	end loop;
end;
$$;

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
	end loop;
end;
$$;

create or replace function get_table_partitions (parent_table varchar)
	returns table (
		partition_name text
	)
	as $$
begin
	return query execute ('select inhrelid::regclass::text as child from pg_catalog.pg_inherits where inhparent = ''' || parent_table || '''::regclass');
end;
$$
language plpgsql;

create or replace function find_duplicate_rows_substance ()
	returns int
	as $$
declare
	partition text;
	query text;
begin
	create temporary table tranche_id_corrections_t (
		sub_id bigint,
		tranche_id_max smallint
	);
	create temporary table sub_dups_corrections_t (
		like sub_dups_corrections
	);
	for partition in
	select
		*
	from
		get_table_partitions ('substance_t') loop
			query := format('insert into sub_dups_corrections_t (select t.sub_id, t.sub_id_min from (select sub_id, min(sub_id) over (partition by smiles) as sub_id_min from %1$s) t where t.sub_id != t.sub_id_min)', partition);
			execute (query);
			query := format('delete from %1$s sb using sub_dups_corrections_t sdc where sb.sub_id = sdc.sub_id_wrong', partition);
			execute (query);
			-- needs some explanation
			-- sometimes there are duplicates of both sub_id and smiles in the table, with tranche_id being the only distinguishing field e.g (123, CCC, 1) & (123, CCC, 2)
			-- this is a rare occurence, but does seem to happen on occasion, so we deal with it here, only keeping the maximum tranche_id value
			-- we keep the max because sometimes tranche_id = 0 manages to be set, and we don't want to have any substances with tranche_id = 0
			-- make sure to keep record of anything deleted here, such that we can verify that a mismatched tranche_id for a zinc id lookup is valid
			query := format('insert into tranche_id_corrections_t(tranche_id_max, sub_id) (select max(tranche_id) as max_tranche_id, sub_id from %1$s group by sub_id having count(*) > 1)', partition);
			execute (query);
			-- performing this in a drawn out manner because apparently we can't "insert into X (delete from Y returning *)"
			query := format('insert into tranche_id_corrections(sub_id, tranche_id_wrong) (select sb.sub_id, sb.tranche_id from %1$s sb, tranche_id_corrections_t t where sb.sub_id = t.sub_id and sb.tranche_id <> t.tranche_id_max)', partition);
			execute (query);
			query := format('delete from %1$s sb using tranche_id_corrections_t t where sb.sub_id = t.sub_id and sb.tranche_id <> t.tranche_id_max', partition);
			execute (query);
			insert into sub_dups_corrections (
				select
					*
				from
					sub_dups_corrections_t);
			truncate sub_dups_corrections_t;
			truncate tranche_id_corrections_t;
			raise notice '%', partition;
		end loop;
	drop table sub_dups_corrections_t;
	drop table tranche_id_corrections_t;
	return 0;
end;
$$
language plpgsql;

create or replace function find_duplicate_rows_catcontent ()
	returns int
	as $$
declare
	partition text;
	query text;
begin
	create temporary table cat_dups_corrections_t (
		like cat_dups_corrections
	);
	for partition in
	select
		*
	from
		get_table_partitions ('catalog_content_t') loop
			query := format('insert into cat_dups_corrections_t (select t.code_id, t.code_id_min from (select cat_content_id as code_id, min(cat_content_id) over (partition by supplier_code) as code_id_min from %1$s) t where t.code_id != t.code_id_min)', partition);
			execute (query);
			query := format('delete from %1$s cc using cat_dups_corrections_t cdc where cc.cat_content_id = cdc.code_id_wrong', partition);
			execute (query);
			insert into cat_dups_corrections (
				select
					*
				from
					cat_dups_corrections_t);
			truncate table cat_dups_corrections_t;
			raise notice '%', partition;
		end loop;
	drop table cat_dups_corrections_t;
	return 0;
end;
$$
language plpgsql;

create or replace function find_duplicate_rows_catsubstance ()
	returns int
	as $$
declare
	partition text;
	query text;
begin
	create temporary table catsub_dups_corrections_t (
		cat_sub_itm_id bigint
	);
	for partition in
	select
		*
	from
		get_table_partitions ('catalog_substance_t') loop
			query := format('insert into catsub_dups_corrections_t (select t.cat_sub_itm_id from (select cat_sub_itm_id, min(cat_sub_itm_id) over (partition by sub_id_fk, cat_content_fk) as cat_sub_itm_id_min from %1$s) t where t.cat_sub_itm_id != t.cat_sub_itm_id_min)', partition);
			execute (query);
			query := format('delete from %1$s cs using catsub_dups_corrections_t csdc where cs.cat_sub_itm_id = csdc.cat_sub_itm_id', partition);
			execute (query);
			insert into catsub_dups_corrections (
				select
					*
				from
					catsub_dups_corrections_t);
			truncate table catsub_dups_corrections_t;
			raise notice '%', partition;
		end loop;
	drop table catsub_dups_corrections_t;
	return 0;
end;
$$
language plpgsql;

