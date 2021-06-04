begin;
copy substance_t (smiles, inchikey, sub_id) from :'subp' with (delimiter ' ');
copy catalog_content_t (supplier_code, cat_content_id, cat_id_fk) from :'supp' with (delimiter ' ');
copy catalog_substance_t (sub_id_fk, cat_content_fk, cat_sub_itm_id) from :'catp' with (delimiter ' ');
commit;
