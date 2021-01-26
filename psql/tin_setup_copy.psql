
update pg_index set indisvalid = false where indrelid = ( select oid from pg_class where relname = 'substance' );
update pg_index set indisready = false where indrelid = ( select oid from pg_class where relname = 'substance' );
update pg_index set indisvalid = false where indrelid = ( select oid from pg_class where relname = 'catalog_content' );
update pg_index set indisready = false where indrelid = ( select oid from pg_class where relname = 'catalog_content' );
update pg_index set indisvalid = false where indrelid = ( select oid from pg_class where relname = 'catalog_substance' );
update pg_index set indisready = false where indrelid = ( select oid from pg_class where relname = 'catalog_substance' );
update pg_index set indisvalid = false where indrelid = ( select oid from pg_class where relname = 'catalog' );
update pg_index set indisready = false where indrelid = ( select oid from pg_class where relname = 'catalog' );
/*
drop index substance3_logp_idx;
drop index substance3_mwt_idx;
drop index substance_sub_id_idx;
alter table substance drop constraint substance_pkey;
*/
alter table substance disable trigger all;
alter table catalog_content disable trigger all;
alter table catalog_substance disable trigger all;
alter table catalog disable trigger all;
