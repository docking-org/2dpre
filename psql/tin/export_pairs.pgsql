LOAD 'auto_explain';
SET auto_explain.log_nested_statements = ON;
SET auto_explain.log_min_duration = 0;
SET client_min_messages to log;
-- o heavenly father, forgive me for what I'm about to do

begin;
-- my "flexible" functions for performing big queries rely on column names to pass data from one stage to the next
-- in order for the get_many_pairs_by_id function to recognize catalog_substance as a valid input, the fk columns need to have the same name as the entity they reference
alter table catalog_substance rename column sub_id_fk to sub_id;
alter table catalog_substance rename column cat_content_fk to cat_content_id;

create temporary table export_pairs_out (smiles text, supplier_code text, sub_id bigint, cat_content_id bigint, tranche_id smallint, cat_id_fk smallint);

call get_many_pairs_by_id_('catalog_substance', 'export_pairs_out', true);

alter table catalog_substance rename column sub_id to sub_id_fk;
alter table catalog_substance rename column cat_content_id to cat_content_fk;

copy (select smiles, supplier_code, sub_id, cat_content_id, tranche_name, short_name from export_pairs_out ex join tranches t on ex.tranche_id = t.tranche_id join catalog c on ex.cat_id_fk = c.cat_id) to :'output_file';
commit;
