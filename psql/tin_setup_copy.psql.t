// we used to perform the copy/index operation on the same table one would run a select query on
// problem is that this locks 
create table substance_t as table substance;
create table catalog_content_t as table catalog_content;
create table catalog_substance_t as table catalog_substance;
/*
update pg_index set indisvalid = false where indrelid = ( select oid from pg_class where relname = 'substance' );
update pg_index set indisready = false where indrelid = ( select oid from pg_class where relname = 'substance' );
update pg_index set indisvalid = false where indrelid = ( select oid from pg_class where relname = 'catalog_content' );
update pg_index set indisready = false where indrelid = ( select oid from pg_class where relname = 'catalog_content' );
update pg_index set indisvalid = false where indrelid = ( select oid from pg_class where relname = 'catalog_substance' );
update pg_index set indisready = false where indrelid = ( select oid from pg_class where relname = 'catalog_substance' );
update pg_index set indisvalid = false where indrelid = ( select oid from pg_class where relname = 'catalog' );
update pg_index set indisready = false where indrelid = ( select oid from pg_class where relname = 'catalog' );
drop index substance3_logp_idx;
drop index substance3_mwt_idx;
drop index substance_sub_id_idx;
alter table substance drop constraint substance_pkey;
alter table catalog disable trigger all;
alter table substance disable trigger all;
alter table catalog_content disable trigger all;
alter table catalog_substance disable trigger all;
*/
