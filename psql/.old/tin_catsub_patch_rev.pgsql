BEGIN;

CREATE OR REPLACE FUNCTION logg (t text)
    RETURNS integer
    AS $$
BEGIN
	    RAISE info '[%]: %', clock_timestamp(), t;
	    RETURN 0;
END;
$$
LANGUAGE plpgsql;

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

select logg('number of supplier codes not found on database:');
select count(*) from query_a where cat_content_id is NULL;

select logg('number of smiles not found on database:');
select count(*) from query_a where sub_id is NULL;

select logg('total number of catalog_substance entries not found on database:');
select count(*) from query_a where sub_id is NULL or cat_content_id is NULL;

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

do
$$
declare a varchar;
begin
	select indexdef from pg_indexes into a where indexname = 'catalog_content_pkey' and indexdef like '%tranche_id%';
	if found then
		raise notice 'catalog_content unique index with tranche_id found, creating a new one without it';
		create unique index catalog_content_pkey_t on catalog_content (cat_content_id);
		--alter table catalog_content drop constraint catalog_content_pkey;
		--alter table catalog_content add primary key catalog_content_pkey using index catalog_content_pkey_t;
	end if;
end $$;

/*
ALTER TABLE catalog_substance_t
    ADD CONSTRAINT "catalog_substance_cat_itm_fk_fkey_t" FOREIGN KEY (cat_content_fk) REFERENCES catalog_content (cat_content_id) ON DELETE CASCADE;

ALTER TABLE catalog_substance_t
    ADD CONSTRAINT "catalog_substance_sub_id_fk_fkey_t" FOREIGN KEY (sub_id_fk, tranche_id) REFERENCES substance (sub_id, tranche_id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
*/

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

--- fix tranche_ids to be canonical with substance table where they are not
UPDATE catalog_substance_t SET tranche_id = sb.tranche_id FROM substance sb WHERE sb.sub_id = sub_id_fk AND catalog_substance_t.tranche_id != sb.tranche_id;

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

ALTER TABLE catalog_substance_t
    ADD CONSTRAINT "catalog_substance_cat_itm_fk_fkey_t" FOREIGN KEY (cat_content_fk) REFERENCES catalog_content (cat_content_id) ON DELETE CASCADE;

ALTER TABLE catalog_substance_t
    ADD CONSTRAINT "catalog_substance_sub_id_fk_fkey_t" FOREIGN KEY (sub_id_fk, tranche_id) REFERENCES substance (sub_id, tranche_id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

drop index if exists catalog_substance_sub_id_fk_idx_t;
CREATE INDEX catalog_substance_sub_id_fk_idx_t ON public.catalog_substance_t (sub_id_fk, tranche_id);

drop index if exists catalog_substance_cat_id_fk_idx_t;
CREATE INDEX catalog_substance_cat_id_fk_idx_t ON public.catalog_substance_t (cat_content_fk);

ALTER TABLE catalog_substance_t enable TRIGGER ALL;

ALTER TABLE catalog_substance rename to catalog_substance_trash;
drop table catalog_substance_trash cascade;

ALTER INDEX catalog_substance_sub_id_fk_idx_t RENAME TO catalog_substance_sub_id_fk_idx;

ALTER INDEX catalog_substance_cat_id_fk_idx_t RENAME TO catalog_substance_cat_id_fk_idx;

ALTER TABLE catalog_substance_t RENAME CONSTRAINT catalog_substance_cat_itm_fk_fkey_t TO catalog_substance_cat_itm_fk_fkey;

ALTER TABLE catalog_substance_t RENAME CONSTRAINT catalog_substance_sub_id_fk_fkey_t TO catalog_substance_sub_id_fk_fkey;

ALTER TABLE catalog_substance_t RENAME TO catalog_substance;

do
$$
declare a varchar;
begin
        select indexdef from pg_indexes into a where indexname = 'catalog_content_pkey' and indexdef like '%tranche_id%';
        if found then
		ALTER TABLE catalog_content DROP CONSTRAINT catalog_content_pkey;
		ALTER TABLE catalog_content ADD CONSTRAINT catalog_content_pkey PRIMARY KEY USING INDEX catalog_content_pkey_t;
        end if;
end $$;

COMMIT;
