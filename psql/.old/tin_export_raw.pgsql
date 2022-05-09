create temporary table tranches_to_export (tranche_id smallint);

copy tranches_to_export from :'tranche_selection_f';

create temporary table catsub_to_export (tranche_id smallint, sub_id_fk int, cat_content_fk int, cat_sub_itm_id int);

insert into catsub_to_export (select tranche_id, sub_id_fk, cat_content_fk, cat_sub_itm_id from catalog_substance where tranche_id in (select tranche_id from tranches_to_export));

copy (select sub_id, smiles, date_updated, tranche_id from substance where tranche_id in (select tranche_id from tranches_to_export)) to :'rawsub_outf' with format binary;

copy (select cat_content_id, cat_id_fk, supplier_code, depleted, tranche_id from catalog_content where cat_content_id in (select cat_content_fk from catsub_to_export)) to :'rawsup_outf' with format binary;

copy (select sub_id_fk, cat_content_fk, cat_sub_itm_id, tranche_id from catsub_to_export) to :'rawcsb_outf' with format binary;

copy (select cat_id, name, short_name, updated from catalog) to :'rawcat_outf' with format binary;
