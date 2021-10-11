begin;

CREATE OR REPLACE FUNCTION invalidate_index (indname text)
    RETURNS integer
    AS $$
BEGIN
    UPDATE
        pg_index
    SET
        indisvalid = FALSE,
        indisready = FALSE
    WHERE
        indexrelid = (
            SELECT
                oid
            FROM
                pg_class
            WHERE
                relname = indname);
    RETURN 0;
END;
$$
LANGUAGE plpgsql;

alter table substance alter column inchikey drop not null;

select invalidate_index('substance_pkey');
select invalidate_index('catalog_content_pkey');
select invalidate_index('catalog_content_supplier_code_idx');
select invalidate_index('catalog_substance_cat_id_fk_idx');
select invalidate_index('catalog_substance_sub_id_fk_idx');

alter table substance disable trigger all;
alter table catalog_content disable trigger all;
alter table catalog_substance disable trigger all;

truncate table catalog_substance, substance, catalog_content;

copy substance(smiles, sub_id, tranche_id) from :'raw_upload_sub' delimiter ' ';
copy catalog_content(supplier_code, cat_content_id, cat_id_fk) from :'raw_upload_sup' delimiter ' ';
copy catalog_substance(sub_id_fk, cat_content_fk, cat_sub_itm_id, tranche_id) from :'raw_upload_cat' delimiter ' ';

reindex table substance;
reindex table catalog_content;
reindex table catalog_substance;

alter table substance enable trigger all;
alter table catalog_content enable trigger all;
alter table catalog_substance enable trigger all;

commit;
