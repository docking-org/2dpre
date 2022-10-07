-- full replacement of substance_id and catalog_id tables
begin;

	--create table substance_id_new (like substance_id including defaults) partition by list(sub_id_fk);

	create temporary table oid_to_pfk(toid int, pfk smallint);

	insert into oid_to_pfk(toid, pfk) (select inhrelid, replace(inhrelid::regclass::text, 'substance_p', '')::int from pg_catalog.pg_inherits where inhparent = 'public.substance'::regclass);

	insert into oid_to_pfk(toid, pfk) (select inhrelid, replace(inhrelid::regclass::text, 'catalog_content_p', '')::int from pg_catalog.pg_inherits where inhparent = 'public.catalog_content'::regclass);

	select * from oid_to_pfk;

	create table substance_id_new (sub_id bigint, sub_partition_fk smallint) partition by hash(sub_id);
	call create_table_partitions('substance_id_new', '');
	insert into substance_id_new(sub_id, sub_partition_fk) (select sb.sub_id, opfk.pfk from substance sb join oid_to_pfk opfk on sb.tableoid = opfk.toid);

	create table catalog_id_new (cat_content_id bigint, cat_partition_fk smallint) partition by hash(cat_content_id);
	call create_table_partitions('catalog_id_new', '');
	insert into catalog_id_new(cat_content_id, cat_partition_fk) (select cc.cat_content_id, opfk.pfk from catalog_content cc join oid_to_pfk opfk on cc.tableoid = opfk.toid);

	alter table substance_id_new add primary key (sub_id);
	alter table catalog_id_new add primary key (cat_content_id);

	alter table substance_id rename to substance_id_trash;
	alter table catalog_id rename to catalog_id_trash;

	alter table substance_id_new rename to substance_id;
	alter table catalog_id_new rename to catalog_id;

commit;
