BEGIN;

create temporary table query_a(supplier_code varchar, smiles varchar, cat_content_id int, tranche_id smallint);

copy query_a(smiles, supplier_code, tranche_id) from :'source_f';

update query_a set supplier_code = replace(supplier_code, '____', '__') where supplier_code like '%\_\_\_\_%';

update query_a set cat_content_id = cc.cat_content_id, tranche_id = cc.tranche_id from catalog_content cc where cc.supplier_code = query_a.supplier_code and cc.tranche_id = query_a.tranche_id;

create temporary table query_b(smiles_real varchar, smiles_pot varchar, cat_content_id int, sub_id int, tranche_id smallint);

insert into query_b(smiles_real, cat_content_id, sub_id, tranche_id) (select q.smiles, cs.cat_content_fk, cs.sub_id_fk, cs.tranche_id from query_a q inner join catalog_substance cs on q.cat_content_id = cs.cat_content_fk and q.tranche_id = cs.tranche_id);

explain analyze update query_b set smiles_pot = sb.smiles from substance sb where sb.sub_id = query_b.sub_id and sb.tranche_id = query_b.tranche_id;

drop table query_a;

create table catalog_substance_t (like catalog_substance including defaults);

ALTER TABLE catalog_substance_t
    ADD CONSTRAINT "catalog_substance_cat_itm_fk_fkey_t" FOREIGN KEY (cat_content_fk, tranche_id) REFERENCES catalog_content (cat_content_id, tranche_id) ON DELETE CASCADE;

ALTER TABLE catalog_substance_t
    ADD CONSTRAINT "catalog_substance_sub_id_fk_fkey_t" FOREIGN KEY (sub_id_fk, tranche_id) REFERENCES substance (sub_id, tranche_id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

alter table catalog_substance_t disable trigger all;

insert into catalog_substance_t (select * from catalog_substance);

delete from catalog_substance_t where (cat_content_fk, sub_id_fk) not in (select cat_content_id, sub_id from query_b q where q.smiles_real = q.smiles_pot group by cat_content_id, sub_id);

CREATE INDEX catalog_substance_sub_id_fk_idx_t ON public.catalog_substance_t (sub_id_fk, tranche_id);

CREATE INDEX catalog_substance_cat_id_fk_idx_t ON public.catalog_substance_t (cat_content_fk, tranche_id);

alter table catalog_substance_t enable trigger all;

commit;
