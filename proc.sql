create or replace procedure copy_in(folder text) as $$
declare n_partitions int;
begin 
    drop table if exists catalog_substance_cat_t;
    create table catalog_substance_cat_t (sub_id_fk bigint, cat_content_fk bigint, grp_id int, nope bigint) partition by hash(cat_content_fk);
    call create_table_partitions('catalog_substance_cat_t', '');
	
	-- import /nfs/exb/zinc22/upload_diffs/freedom/n-9-38:5440/catsub/combined first 2 cols into catalog_substance_cat

    execute(format('copy catalog_substance_cat_t(sub_id_fk, cat_content_fk, grp_id, nope) from ''%s'' with delimiter as E''\t'' null as ''\N''', folder));

    insert into catalog_substance_cat(select sub_id_fk, cat_content_fk from catalog_substance_cat_t);
    drop table if exists catalog_substance_cat_t;
end $$ language plpgsql;


call copy_in(:'folder');
