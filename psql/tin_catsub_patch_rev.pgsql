BEGIN;

CREATE TEMPORARY TABLE query_a (
    supplier_code varchar,
    smiles varchar,
    cat_content_id int,
    sub_id int,
    tranche_id smallint
);

COPY query_a (smiles, supplier_code, tranche_id)
FROM
    :'source_f';

select logg('correcting supplier codes');

UPDATE
    query_a
SET
    supplier_code = replace(supplier_code, '____', '__')
WHERE
    supplier_code LIKE '%\_\_\_\_%';

select logg('resolving smiles ids');

UPDATE
    query_a
SET
    sub_id = sb.sub_id
FROM
    substance sb
WHERE
    sb.smiles::varchar = query_a.smiles AND sb.tranche_id = query_a.tranche_id;

select logg('resolving supplier code ids');

UPDATE
    query_a
SET
    cat_content_id = cc.cat_content_id
FROM
    catalog_content cc
WHERE
    cc.supplier_code = query_a.supplier_code;

/*
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
        query_a q
    INNER JOIN catalog_substance cs on cs.cat_content_fk = q.cat_content_id
    INNER JOIN substance sb on sb.sub_id = cs.sub_id_fk);

DROP TABLE query_a;
*/
select logg('cloning catalog_substance and correcting');

drop table if exists catalog_substance_t cascade;
CREATE TABLE catalog_substance_t (
    LIKE catalog_substance INCLUDING defaults
);

ALTER TABLE catalog_substance_t
    ADD CONSTRAINT "catalog_substance_cat_itm_fk_fkey_t" FOREIGN KEY (cat_content_fk, tranche_id) REFERENCES catalog_content (cat_content_id, tranche_id) ON DELETE CASCADE;

ALTER TABLE catalog_substance_t
    ADD CONSTRAINT "catalog_substance_sub_id_fk_fkey_t" FOREIGN KEY (sub_id_fk, tranche_id) REFERENCES substance (sub_id, tranche_id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

ALTER TABLE catalog_substance_t disable TRIGGER ALL;

INSERT INTO catalog_substance_t(sub_id_fk, cat_content_fk, tranche_id) (
    SELECT DISTINCT ON(sub_id, cat_content_id)
        sub_id,
        cat_content_id,
        tranche_id
    FROM
        query_a
    WHERE
        sub_id is not null
        AND cat_content_id is not null);

/*
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
            sub_id);*/

drop index if exists catalog_substance_sub_id_fk_idx_t;
CREATE INDEX catalog_substance_sub_id_fk_idx_t ON public.catalog_substance_t (sub_id_fk, tranche_id);

drop index if exists catalog_substance_cat_id_fk_idx_t;
CREATE INDEX catalog_substance_cat_id_fk_idx_t ON public.catalog_substance_t (cat_content_fk, tranche_id);

ALTER TABLE catalog_substance_t enable TRIGGER ALL;

ALTER TABLE catalog_substance rename to catalog_substance_trash;
drop table catalog_substance_trash cascade;

ALTER INDEX catalog_substance_sub_id_fk_idx_t RENAME TO catalog_substance_sub_id_fk_idx;

ALTER INDEX catalog_substance_cat_id_fk_idx_t RENAME TO catalog_substance_cat_id_fk_idx;

ALTER TABLE catalog_substance_t RENAME CONSTRAINT catalog_substance_cat_itm_fk_fkey_t TO catalog_substance_cat_itm_fk_fkey;

ALTER TABLE catalog_substance_t RENAME CONSTRAINT catalog_substance_sub_id_fk_fkey_t TO catalog_substance_sub_id_fk_fkey;

ALTER TABLE catalog_substance_t RENAME TO catalog_substance;

COMMIT;
