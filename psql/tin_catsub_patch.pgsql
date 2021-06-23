BEGIN;

CREATE TEMPORARY TABLE query_a (
    supplier_code varchar,
    smiles varchar,
    cat_content_id int,
    tranche_id smallint
);

COPY query_a (smiles, supplier_code, tranche_id)
FROM
    :'source_f';

UPDATE
    query_a
SET
    supplier_code = replace(supplier_code, '____', '__')
WHERE
    supplier_code LIKE '%\_\_\_\_%';

UPDATE
    query_a
SET
    cat_content_id = cc.cat_content_id,
    tranche_id = cc.tranche_id
FROM
    catalog_content cc
WHERE
    cc.supplier_code = query_a.supplier_code
    AND cc.tranche_id = query_a.tranche_id;

CREATE TEMPORARY TABLE query_b (
    smiles_real varchar,
    smiles_pot varchar,
    cat_content_id int,
    sub_id int,
    tranche_id smallint
);

EXPLAIN ANALYZE INSERT INTO query_b (smiles_real, smiles_pot, cat_content_id, sub_id, tranche_id) (
    SELECT
        q.smiles,
        sb.smiles,
        cs.cat_content_fk,
        cs.sub_id_fk,
        cs.tranche_id
    FROM
        query_a q,
        substance sb,
        catalog_substance cs
    WHERE
        cs.cat_content_fk = q.cat_content_id
        AND sb.sub_id = cs.sub_id_fk
        AND sb.tranche_id = 1
        AND cs.tranche_id = 1);

DROP TABLE query_a;

CREATE TABLE catalog_substance_t (
    LIKE catalog_substance INCLUDING defaults
);

ALTER TABLE catalog_substance_t
    ADD CONSTRAINT "catalog_substance_cat_itm_fk_fkey_t" FOREIGN KEY (cat_content_fk, tranche_id) REFERENCES catalog_content (cat_content_id, tranche_id) ON DELETE CASCADE;

ALTER TABLE catalog_substance_t
    ADD CONSTRAINT "catalog_substance_sub_id_fk_fkey_t" FOREIGN KEY (sub_id_fk, tranche_id) REFERENCES substance (sub_id, tranche_id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE catalog_substance_t disable TRIGGER ALL;

INSERT INTO catalog_substance_t (
    SELECT
        *
    FROM
        catalog_substance);

DELETE FROM catalog_substance_t
WHERE (cat_content_fk, sub_id_fk)
    NOT IN (
        SELECT
            cat_content_id,
            sub_id
        FROM
            query_b q
        WHERE
            q.smiles_real = q.smiles_pot
        GROUP BY
            cat_content_id,
            sub_id);

CREATE INDEX catalog_substance_sub_id_fk_idx_t ON public.catalog_substance_t (sub_id_fk, tranche_id);

CREATE INDEX catalog_substance_cat_id_fk_idx_t ON public.catalog_substance_t (cat_content_fk, tranche_id);

ALTER TABLE catalog_substance_t enable TRIGGER ALL;

COMMIT;

