BEGIN;

--- prepare temporary tables for loading in data
CREATE TEMPORARY TABLE temp_load (
    smiles char(64),
    code char(64),
    id int,
    sub_fk int,
    code_fk int,
    cat_fk smallint,
    tranche_id smallint
);

CREATE TEMPORARY TABLE temp_load_sb (
    smiles mol,
    id int,
    tranche_id smallint
);

CREATE TEMPORARY TABLE temp_load_cc (
    code char(64),
    cat_fk smallint,
    id int,
    tranche_id smallint
);

ALTER TABLE temp_load
    ALTER COLUMN id SET DEFAULT NULL;

ALTER TABLE temp_load_sb
    ALTER COLUMN id SET DEFAULT NULL;

ALTER TABLE temp_load_cc
    ALTER COLUMN id SET DEFAULT NULL;

--- create temp sequences for loading
CREATE TEMPORARY SEQUENCE t_seq_sb;

SELECT
    setval('t_seq_sb', :sb_count);

---currval('sub_id_seq'); CREATE TEMPORARY SEQUENCE t_seq_cs;
SELECT
    setval('t_seq_cs', :cs_count);

---currval('cat_sub_itm_id_seq')); CREATE TEMPORARY SEQUENCE t_seq_cc;
SELECT
    setval('t_seq_cc', :cc_count);

---currval('cat_content_id_seq'));
--- source_f contains smiles:supplier:cat_id rows, with cat_id being the int describing the catalog the smiles:supplier pair comes from
COPY temp_load (smiles, code, cat_fk, tranche_id)
FROM
    :'source_f';

--- load substance data to temp table
INSERT INTO temp_load_sb (smiles, tranche_id)
SELECT
    smiles,
    tranche_id
FROM
    temp_load
GROUP BY
    smiles;

--- group by makes sure there are no duplicates in this table
--- load cat_content data to temp table
INSERT INTO temp_load_cc (code, cat_fk)
SELECT
    code,
    cat_fk,
    tranche_id
FROM
    temp_load
GROUP BY
    code;

--- make sure unique, same as before
--- find existing sub_ids, update temp table with them
UPDATE
    temp_load_sb
SET
    id = substance.sub_id
FROM
    substance
WHERE
    --- this should speed up this query, making sure we only compare smiles with matching tranche ids
    substance.tranche_id = temp_load_sb.tranche_id
    AND substance.smiles = temp_load_sb.smiles;

--- "create" new sub_ids for compounds not found
UPDATE
    temp_load_sb
SET
    id = nextval('t_seq_sb')
WHERE
    id = NULL;

--- find existing cat_content_ids
UPDATE
    temp_load_cc
SET
    id = catalog_content.cat_content_id
FROM
    catalog_content
WHERE
    catalog_content.tranche_id = temp_load_cc.tranche_id
    AND catalog_content.supplier_code = temp_load_cc.code;

--- "create" ids for new supplier codes
UPDATE
    temp_load_cc
SET
    id = nextval('t_seq_cc')
WHERE
    id = NULL;

--- resolve smiles ids
UPDATE
    temp_load
SET
    sub_fk = temp_load_sb.id
FROM
    temp_load_sb
WHERE
    temp_load.tranche_id = temp_load_sb.tranche_id
    AND temp_load.smiles = temp_load_sb.smiles;

--- resolve code ids
UPDATE
    temp_load
SET
    cat_fk = temp_load_cc.id
FROM
    temp_load_cc
WHERE
    temp_load.tranche_id = temp_load_cc.tranche_id
    AND temp_load.code = temp_load_cc.code;

--- find existing cat_substance entries and resolve cat_sub_itm_id
UPDATE
    temp_load
SET
    id = cs.cat_sub_itm_id
FROM
    catalog_substance cs
WHERE
    cs.tranche_id = temp_load.tranche_id
    AND cs.cat_content_fk = temp_load.cat_fk
    AND cs.sub_id_fk = temp_load.sub_fk;

--- assign cat_sub_itm_id value to new entries
UPDATE
    temp_load
SET
    id = nextval('t_seq_cs')
WHERE
    id = NULL;

--- clone the current tables to create the new ones
--- these names are appended with _t so they are not confused with the current version
--- it is necessary to modify a cloned version so that any users of the current table are not locked out
CREATE TABLE substance_t (
    LIKE substance INCLUDING defaults INCLUDING constraints INCLUDING indexes
);

CREATE TABLE catalog_content_t (
    LIKE catalog_content INCLUDING defaults INCLUDING constraints INCLUDING indexes
);

CREATE TABLE catalog_substance_t (
    LIKE catalog_substance INCLUDING defaults INCLUDING constraints INCLUDING indexes
);

--- now that we've identified all new entries, we want to prepare the database for insertion
--- with the large volumes of data that we work with, it is faster to disable indexes, insert the data, then rebuild the indexes
--- we can disable indexes in postgres using a little trick
--- much less verbose than dropping each index then rebuilding individually
UPDATE
    pg_index
SET
    indisvalid = FALSE
WHERE
    indrelid = (
        SELECT
            oid
        FROM
            pg_class
        WHERE
            relname = 'substance_t');

UPDATE
    pg_index
SET
    indisready = FALSE
WHERE
    indrelid = (
        SELECT
            oid
        FROM
            pg_class
        WHERE
            relname = 'substance_t');

UPDATE
    pg_index
SET
    indisvalid = FALSE
WHERE
    indrelid = (
        SELECT
            oid
        FROM
            pg_class
        WHERE
            relname = 'catalog_content_t');

UPDATE
    pg_index
SET
    indisready = FALSE
WHERE
    indrelid = (
        SELECT
            oid
        FROM
            pg_class
        WHERE
            relname = 'catalog_content_t');

UPDATE
    pg_index
SET
    indisvalid = FALSE
WHERE
    indrelid = (
        SELECT
            oid
        FROM
            pg_class
        WHERE
            relname = 'catalog_substance_t');

UPDATE
    pg_index
SET
    indisready = FALSE
WHERE
    indrelid = (
        SELECT
            oid
        FROM
            pg_class
        WHERE
            relname = 'catalog_substance_t');

--- disable any constraints/triggers to speed up loading - we know we will not violate any of them
ALTER TABLE substance_t DISABLE TRIGGER ALL;

ALTER TABLE catalog_content_t DISABLE TRIGGER ALL;

ALTER TABLE catalog_substance_t DISABLE TRIGGER ALL;

--- load new substance data in
INSERT INTO substance_t (sub_id, smiles, tranche_id, amw, logp)
SELECT
    id,
    smiles,
    tranche_id,
    mol_amw(smiles),
    mol_logp(smiles)
FROM
    temp_load_sb
WHERE
    --- we must provide the current count on each table as a variable to the script
    --- currval is a volatile function, which means that any queries using it will not be optimized
    --- quite annoying
    temp_load_sb.id > :sb_count;

---currval('sub_id_seq');
--- only insert entries that don't exist yet, i.e their id is > the current table id
--- new cat_content data...
INSERT INTO catalog_content_t (cat_content_id, supplier_code, cat_id_fk, tranche_id)
SELECT
    id,
    code,
    cat_fk,
    tranche_id
FROM
    temp_load_cc
WHERE
    temp_load_cc.id > :cc_count;

---currval('cat_content_id_seq');
--- same idea as previous
--- and finally, cat_substance data
INSERT INTO catalog_substance_t (cat_content_fk, sub_id_fk, cat_sub_itm_id, tranche_id)
SELECT
    code_fk,
    smiles_fk,
    id,
    tranche_id
FROM
    temp_load
WHERE
    temp_load.id > :cs_count;

---currval('cat_sub_itm_id_seq');
--- again, same idea
--- rebuild indices on the new tables
REINDEX TABLE substance_t;

REINDEX TABLE catalog_content_t;

REINDEX TABLE catalog_substance_t;

--- re-enable constraints/triggers once we're done
ALTER TABLE substance_t ENABLE TRIGGER ALL;

ALTER TABLE catalog_content_t ENABLE TRIGGER ALL;

ALTER TABLE catalog_substance_t ENABLE TRIGGER ALL;

--- swap the new table for the old
ALTER TABLE substance RENAME TO substance_trash;

ALTER TABLE catalog_content RENAME TO catalog_content_trash;

ALTER TABLE catalog_substance_t RENAME TO catalog_substance_trash;

ALTER TABLE substance_t RENAME TO substance;

ALTER TABLE catalog_content_t RENAME TO catalog_content;

ALTER TABLE catalog_substance_t RENAME TO catalog_substance;

--- update sequences with new values
SELECT
    setval('sub_id_seq', currval('t_seq_sb'));

SELECT
    setval('cat_sub_itm_id_seq', currval('t_seq_cs'));

SELECT
    setval('cat_content_id_seq', currval('t_seq_cc'));

--- dispose of the old table
DROP TABLE substance_trash CASCADE;

DROP TABLE catalog_content_trash CASCADE;

DROP TABLE catalog_substance_trash CASCADE;

COMMIT;

ANALYZE;

VACUUM;

