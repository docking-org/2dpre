BEGIN;


/*
 *  BEGIN BOILERPLATE INITIALIZATION
 *  initialization code for any large-scale update to TIN
 */
CREATE OR REPLACE FUNCTION logg (t text)
    RETURNS integer
    AS $$
BEGIN
    RAISE info '[%]: %', clock_timestamp(), t;
    RETURN 0;
END;
$$
LANGUAGE plpgsql;

SELECT
    logg ('cloning table schema');

CREATE TABLE substance_t (
    LIKE substance INCLUDING defaults
);

CREATE TABLE catalog_content_t (
    LIKE catalog_content INCLUDING defaults
);

CREATE TABLE catalog_substance_t (
    LIKE catalog_substance INCLUDING defaults
);

--- disable triggers to speed up loading performance, as we are sure we will not violate any of the constraints
ALTER TABLE catalog_content_t DISABLE TRIGGER ALL;

ALTER TABLE catalog_substance_t DISABLE TRIGGER ALL;

ALTER TABLE substance_t DISABLE TRIGGER ALL;

SELECT
    logg ('copying substance data to clone table...');
INSERT INTO substance_t
SELECT
    *
FROM
    substance;

SELECT
    logg ('copying catalog_content data to clone table...');
INSERT INTO catalog_content_t
SELECT
    *
FROM
    catalog_content;

SELECT
    logg ('copying catalog_substance data to clone table');
INSERT INTO catalog_substance_t
SELECT
    *
FROM
    catalog_substance;


/*
 *  END BOLIERPLATE INITIALIZATION
 */
--- prepare temporary tables for loading in data
CREATE TEMPORARY TABLE temp_load (
    smiles char(64),
    code char(64),
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

CREATE TEMPORARY TABLE temp_load_cs (
    id int,
    sub_fk int,
    code_fk int
);

ALTER TABLE temp_load_sb
    ALTER COLUMN id SET DEFAULT NULL;

ALTER TABLE temp_load_cc
    ALTER COLUMN id SET DEFAULT NULL;

ALTER TABLE temp_load_cs
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

SELECT
    logg ('copying in new data...')
    ---currval('cat_content_id_seq'));
    --- source_f contains smiles:supplier:cat_id rows, with cat_id being the int describing the catalog the smiles:supplier pair comes from
    COPY temp_load (smiles, code, cat_fk, tranche_id)
FROM
    :'source_f';

SELECT
    logg ('identifying all unique smiles');

--- load substance data to temp table
INSERT INTO temp_load_sb (
    smiles,
    tranche_id)
SELECT DISTINCT ON (smiles)
    smiles,
    tranche_id
FROM
    temp_load;

SELECT
    logg ('identifying unique supplier codes');

--- group by makes sure there are no duplicates in this table
--- load cat_content data to temp table
INSERT INTO temp_load_cc (
    code,
    cat_fk)
SELECT DISTINCT ON (code)
    code,
    cat_fk,
    tranche_id
FROM
    temp_load;

SELECT
    logg ('resolving smiles ids');

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

SELECT
    logg ('resolving supplier code ids');

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

SELECT
    logg ('resolving smiles back to catalog');

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

SELECT
    logg ('resolving supplier codes back to catalog');

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

SELECT
    logg ('identifying unique catalog entries');

--- get distinct catalog entries
INSERT INTO temp_load_cs (
    sub_fk,
    code_fk)
SELECT DISTINCT ON (sub_fk, code_fk)
    sub_fk,
    code_fk
FROM
    temp_load;

SELECT
    logg ('resolving catalog entries');

--- find existing cat_substance entries and resolve cat_sub_itm_id
UPDATE
    temp_load_cs
SET
    id = cs.cat_sub_itm_id
FROM
    catalog_substance cs
WHERE
    cs.cat_content_fk = temp_load_cs.cat_fk
    AND cs.sub_id_fk = temp_load_cs.sub_fk;

--- assign cat_sub_itm_id value to new entries
UPDATE
    temp_load_cs
SET
    id = nextval('t_seq_cs')
WHERE
    id = NULL;

SELECT
    logg ('loading new substance data')
    --- load new substance data in
    INSERT INTO substance_t (
        sub_id,
        smiles,
        tranche_id)
    SELECT
        id,
        smiles,
        tranche_id
    FROM
        temp_load_sb
    WHERE
    --- we must provide the current count on each table as a variable to the script, as opposed to using something like currval('sub_id_seq')
    --- currval is a volatile function, so it does not get optimized in large queries like this
    temp_load_sb.id > :sb_count;

SELECT
    logg ('loading new catalog_content data');

--- new cat_content data...
INSERT INTO catalog_content_t (
    cat_content_id,
    supplier_code,
    cat_id_fk,
    tranche_id)
SELECT
    id,
    code,
    cat_fk,
    tranche_id
FROM
    temp_load_cc
WHERE
    temp_load_cc.id > :cc_count;

SELECT
    logg ('loading new catalog_substance data');

--- and finally, cat_substance data
INSERT INTO catalog_substance_t (
    cat_content_fk,
    sub_id_fk,
    cat_sub_itm_id)
SELECT
    code_fk,
    smiles_fk,
    id
FROM
    temp_load
WHERE
    temp_load.id > :cs_count;

--- update sequences with new values
SELECT
    setval('sub_id_seq', currval('t_seq_sb'));

SELECT
    setval('cat_sub_itm_id_seq', currval('t_seq_cs'));

SELECT
    setval('cat_content_id_seq', currval('t_seq_cc'));

--- free up a lil bit of memory because we can
DROP TABLE temp_load;

DROP TABLE temp_load_sb;

DROP TABLE temp_load_cc;

DROP TABLE temp_load_cs;


/*
 *  BEGIN BOILERPLATE FINALIZATION
 *  finalization code used for any large-scale update
 */
CREATE TEMPORARY TABLE index_save (
    tablename text,
    indexname text,
    indexdef text
);

CREATE TEMPORARY TABLE constraint_save (
    tablename text,
    constraintname text
);

CREATE TEMPORARY TABLE pkey_save (
    tablename text,
    columnname text
);

--- initialize record of constraints to be rebuilt
INSERT INTO constraint_save (
    tablename,
    constraintname) (
    VALUES (
            'catalog_content', 'catalog_content_cat_id_fk_fkey'),
        (
            'catalog_substance', 'catalog_substance_cat_itm_fk_fkey'),
        (
            'catalog_substance', 'catalog_substance_sub_id_fk_fkey'));

--- pkeys are both an index and a constraint, so we deal with them separately. initialize record of pkeys here
INSERT INTO pkey_save (
    tablename,
    columnname) (
    VALUES (
            'substance', 'sub_id'),
        (
            'catalog_content', 'cat_content_id'),
        (
            'catalog_substance', 'cat_sub_itm_id'));

--- initialize our record of indexes we need to rebuild
INSERT INTO index_save
SELECT
    (tablename,
        indexname,
        indexdef)
FROM
    pg_indexes
WHERE
    tablename IN ('substance', 'catalog_content', 'catalog_substance')
    AND indexname NOT LIKE '%_pkey';

--- don't build pkey indexes from their indexdef, that will not create (exactly) a pkey
DO $$
DECLARE
    idx index_save % rowtype;
    cns constraint_save % rowtype;
    pky pkey_save % rowtype;
    idxdef text;
BEGIN
    --- first generate normal indexes
    FOR idx IN
    SELECT
        *
    FROM
        index_save LOOP
            idxdef := REPLACE(idx.indexdef, idx.indexname, CONCAT(idx.indexname, '_t'));
            idxdef := REPLACE(idxdef, CONCAT('public.', idx.tablename), CONCAT('public.', idx.tablename, '_t'));
            EXECUTE idxdef;
            RAISE info '[%]: finished building index: %', clock_timestamp(), idx.indexname;
        END LOOP;
    --- then generate pkey indexes
    FOR pky IN
    SELECT
        *
    FROM
        pkey_save LOOP
            EXECUTE 'alter table ' || pky.tablename || '_t add primary key (' || pky.columnname || ')';
            RAISE info '[%]: finished building pkey: %_pkey', clock_timestamp(), pky.tablename;
        END LOOP;
    SELECT
        logg ('adding constraints');
    ALTER TABLE catalog_content_t
        ADD CONSTRAINT "catalog_content_cat_id_fk_fkey_t" FOREIGN KEY (cat_id_fk) REFERENCES catalog (cat_id) ON DELETE CASCADE;
    ALTER TABLE catalog_substance_t
        ADD CONSTRAINT "catalog_substances_cat_itm_fk_fkey_t" FOREIGN KEY (cat_content_fk) REFERENCES catalog_content_t (cat_content_id) ON DELETE CASCADE;
    ALTER TABLE catalog_substance_t
        ADD CONSTRAINT "catalog_substances_sub_id_fk_fkey_t" FOREIGN KEY (sub_id_fk) REFERENCES substance_t (sub_id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
    --- swap out old table for new table
    ALTER TABLE substance RENAME TO substance_trash;
    ALTER TABLE catalog_content RENAME TO catalog_content_trash;
    ALTER TABLE catalog_substance RENAME TO catalog_substance_trash;
    ALTER TABLE substance_t RENAME TO substance;
    ALTER TABLE catalog_content_t RENAME TO catalog_content;
    ALTER TABLE catalog_substance_t RENAME TO catalog_substance;
    RAISE info '[%]: tables swapped out!', clock_timestamp();
    --- dispose of old table
    DROP TABLE substance_trash CASCADE;
    DROP TABLE catalog_content_trash CASCADE;
    DROP TABLE catalog_substance_trash CASCADE;
    RAISE info '[%]: old table disposed!', clock_timestamp();
    --- rename indexes (so we don't get indexes like %_t_t_t_t or w.e)
    FOR idx IN
    SELECT
        *
    FROM
        index_save LOOP
            EXECUTE 'alter index ' || idx.indexname || '_t rename to ' || idx.indexname;
        END LOOP;
    --- rename pkeys
    FOR pky IN
    SELECT
        *
    FROM
        pkey_save LOOP
            EXECUTE 'alter table ' || pky.tablename || ' rename constraint ' || pky.tablename || '_t_pkey to ' || pky.tablename || '_pkey';
        END LOOP;
    --- rename constraints
    FOR cns IN
    SELECT
        *
    FROM
        constraint_save LOOP
            EXECUTE 'alter table ' || cns.tablename || 'rename constraint ' || cns.constraintname || '_t to ' || cns.constraintname;
        END LOOP;
    RAISE info '[%]: finished renaming constraints & indexes!', clock_timestamp();
END
$$
LANGUAGE plpgsql;

ALTER TABLE substance ENABLE TRIGGER ALL;

ALTER TABLE catalog_content ENABLE TRIGGER ALL;

ALTER TABLE catalog_substance ENABLE TRIGGER ALL;

SELECT
    logg ('cleaning up...');

--- finish up with vacuum & analysis to optimize performance
VACUUM;

ANALYZE;

SELECT
    logg ('done with everything!');


/*
 *  END BOILERPLATE FINALIZATION
 */
COMMIT;

