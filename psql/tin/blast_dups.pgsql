-- full replacement of substance_id and catalog_id tables
-- this is a modified version of sync_id_tables.pgsql that (arbitrarily) blasts away any duplicate sub_ids+smiles in the substance table prior to synchronization
-- specifically this is due to a glitch from the zinc3Dv1_r1 update. overall the zincid_upload operation has not gone entirely to plan
-- it has succeeded in blasting away duplicates & remapping zinc ids correctly, but it is doing things that are a bit odd/may break the database, one of those artifacts being duplicate zinc ids in the substance table
-- this happened because the substance_id table was not updated throughout the course of the operation, meaning any newly inserted substances would not be visible via sub_id lookup for subsequent operation loops
-- thus, we get a bunch of duplicates, specifically from molecules whose sub_id wouldn't look up- case 4(3?) & 5
-- case 5     molecules cause duplicates in the substance table to appear
-- case 4(3?) molecules can cause humorous entries in sub_dups_corrections to appear, remapping an id to itself (it is assumed, never checked that case 4 molecules have different sub_ids- this is not the case if substance_id is not synchronized) 
begin;

	--create table substance_id_new (like substance_id including defaults) partition by list(sub_id_fk);

	create temporary table oid_to_pfk(toid int, pfk smallint);

	insert into oid_to_pfk(toid, pfk) (select inhrelid, replace(inhrelid::regclass::text, 'substance_p', '')::int from pg_catalog.pg_inherits where inhparent = 'public.substance'::regclass);

	insert into oid_to_pfk(toid, pfk) (select inhrelid, replace(inhrelid::regclass::text, 'catalog_content_p', '')::int from pg_catalog.pg_inherits where inhparent = 'public.catalog_content'::regclass);

	select * from oid_to_pfk;

	drop table if exists substance_id_new;
	create table substance_id_new (sub_id bigint, sub_partition_fk smallint, substance_ctid tid) partition by hash(sub_id);
	call create_table_partitions('substance_id_new', '');
	insert into substance_id_new(sub_id, sub_partition_fk, substance_ctid) (select sb.sub_id, opfk.pfk, sb.ctid from substance sb join oid_to_pfk opfk on sb.tableoid = opfk.toid);

	-- sub id, partition of sub id, ctid of substance row
	create temporary table substance_to_delete(sub_id bigint, sub_partition_fk smallint, sb_ctid tid) partition by list(sub_partition_fk);
	do $$
	declare n_partitions int;
	begin
		select ivalue from meta where svalue = 'n_partitions' limit 1 into n_partitions;
		for i in 0..(n_partitions-1) loop
			execute(format('create temporary table substance_to_delete_p%s partition of substance_to_delete for values in (%s)', i, i));
		end loop;
	end $$;

	-- as usual, we manually optimize partition queries
	create or replace procedure smash_duplicates(diff_destination text) as $$
	declare
		i int;
		n int;
	begin
		select ivalue from meta where svalue = 'n_partitions' into n;
		for i in 0..n-1 loop
			execute(format('with sub_to_del as (delete from substance_id_new_p%1$s si using (select ctid as si_ctid, ROW_NUMBER() over (partition by sub_id) as rn from substance_id_new_p%1$s si) t where t.rn > 1 and si.ctid = t.si_ctid returning *) insert into substance_to_delete(sub_id, sub_partition_fk, sb_ctid) (select sub_id, sub_partition_fk, substance_ctid from sub_to_del)', i::text));
		end loop;
		for i in 0..n-1 loop
			-- ctid should remain stable so long as all updates on the table using ctid are constrained to a single transaction
			-- we use multiple transactions, but only one per partition, meaning recorded row physical location (ctid) should not change over the course of the operation
			-- we shall see if this is the case...
			execute(format('copy (delete from substance_p%1$s sb using substance_to_delete_p%1$s sd where sd.sb_ctid = sb.ctid returning *) to ''%2$s/delsub/%1$s''', i::text, diff_destination));
		end loop;
	end $$ language plpgsql;
	call smash_duplicates(:'diff_destination');
	-- delete duplicates & self-referential entries from sub_dups_corrections
	delete from sub_dups_corrections where sub_id_wrong = sub_id_right;
	delete from sub_dups_corrections using (select ctid as mctid, sub_id_wrong, sub_id_right, ROW_NUMBER() over (partition by sub_id_wrong, sub_id_right) as rn from sub_dups_corrections) t where t.rn > 1 and ctid = t.mctid;

	drop table if exists catalog_id_new;
	create table catalog_id_new (cat_content_id bigint, cat_partition_fk smallint) partition by hash(cat_content_id);
	call create_table_partitions('catalog_id_new', '');
	insert into catalog_id_new(cat_content_id, cat_partition_fk) (select cc.cat_content_id, opfk.pfk from catalog_content cc join oid_to_pfk opfk on cc.tableoid = opfk.toid);

	alter table substance_id_new add primary key (sub_id);
	alter table catalog_id_new add primary key (cat_content_id);

	alter table substance_id rename to substance_id_trash;
	alter table catalog_id rename to catalog_id_trash;

	alter table substance_id_new rename to substance_id;
	alter table catalog_id_new rename to catalog_id;

	drop table substance_id_trash;
	drop table catalog_id_trash;

	call rename_table_partitions('substance_id_new', 'substance_id');
	call rename_table_partitions('catalog_id_new', 'catalog_id');

commit;
