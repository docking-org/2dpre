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

SELECT
    logg ('cloning table schema');

--- made a little whoopsie in the configuration before, we don't really use inchikeys so make them nullable
ALTER TABLE substance ALTER COLUMN inchikey DROP NOT NULL;

DROP TABLE IF EXISTS substance_t CASCADE;

CREATE TABLE substance_t (
    LIKE substance INCLUDING defaults
);

ALTER TABLE substance_t ALTER COLUMN smiles TYPE varchar USING smiles::varchar;

DROP TABLE IF EXISTS catalog_content_t CASCADE;

CREATE TABLE catalog_content_t (
    LIKE catalog_content INCLUDING defaults
);

DROP TABLE IF EXISTS catalog_substance_t CASCADE;

CREATE TABLE catalog_substance_t (
    LIKE catalog_substance INCLUDING defaults
);

ALTER TABLE substance_t
    ADD PRIMARY KEY (sub_id, tranche_id);

ALTER TABLE catalog_content_t
    ADD PRIMARY KEY (cat_content_id);

--- we are quite sure that the foreign key constraints will stay valid after this update, so we don't need to do any validation
--- unfortunately creating the constraint anew requires validation of all data currently in the tables, so we do it before loading in data and simply disable triggers, stopping any validation during load time
--- you may also know that foreign keys require a unique index on the referenced column, which is awkward, since we do not want to create indexes before we load in data
--- so we use a sneaky trick to get around this- we create the unique indexes (primary keys), and alter the system tables to invalidate the index (see above)
--- this means that the index will not get updated when inserting/updating rows, which is what we want
--- for all the foreign key constraint cares, the unique index exists and is working. After loading in data we just perform a reindex operation, re-enable triggers, and everything is hunky-dory!
--- ... this may actually be a bad idea. It's possible that some important data is created during the validation step, but so far our databases are working just fine without doing validation

--- I think this is a bad idea. I'm removing this bit, but will keep it commented out here for posterity
/*
ALTER TABLE catalog_content_t
    ADD CONSTRAINT "catalog_content_cat_id_fk_fkey_t" FOREIGN KEY (cat_id_fk) REFERENCES catalog (cat_id) ON DELETE CASCADE;

ALTER TABLE catalog_substance_t
    ADD CONSTRAINT "catalog_substance_cat_itm_fk_fkey_t" FOREIGN KEY (cat_content_fk) REFERENCES catalog_content_t (cat_content_id) ON DELETE CASCADE;

ALTER TABLE catalog_substance_t
    ADD CONSTRAINT "catalog_substance_sub_id_fk_fkey_t" FOREIGN KEY (sub_id_fk, tranche_id) REFERENCES substance_t (sub_id, tranche_id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
*/

SELECT
    invalidate_index ('substance_t_pkey');

SELECT
    invalidate_index ('catalog_content_t_pkey');

/*
ALTER TABLE catalog_content_t DISABLE TRIGGER ALL;

ALTER TABLE catalog_substance_t DISABLE TRIGGER ALL;

ALTER TABLE substance_t DISABLE TRIGGER ALL;
*/

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
    smiles varchar,
    code varchar,
    sub_fk int DEFAULT NULL,
    code_fk int DEFAULT NULL,
    cat_itm_id int DEFAULT NULL,
    cat_fk smallint,
    tranche_id smallint
);

/*CREATE TEMPORARY TABLE temp_load_sb (
    smiles mol,
    id int,
    tranche_id smallint
);

CREATE TEMPORARY TABLE temp_load_cc (
    code varchar,
    cat_fk smallint,
    id int,
    tranche_id smallint
);

CREATE TEMPORARY TABLE temp_load_cs (
    id int,
    sub_fk int,
    code_fk int,
    tranche_id smallint
);

ALTER TABLE temp_load_sb
    ALTER COLUMN id SET DEFAULT NULL;

ALTER TABLE temp_load_cc
    ALTER COLUMN id SET DEFAULT NULL;

ALTER TABLE temp_load_cs
   ALTER COLUMN id SET DEFAULT NULL;*/

--- create temp sequences for loading
CREATE TEMPORARY SEQUENCE t_seq_sb;

CREATE TEMPORARY SEQUENCE t_seq_cs;

CREATE TEMPORARY SEQUENCE t_seq_cc;

SELECT
    setval('t_seq_sb', :sb_count);

---currval('sub_id_seq'); CREATE TEMPORARY SEQUENCE t_seq_cs;
SELECT
    setval('t_seq_cs', :cs_count);

---currval('cat_sub_itm_id_seq')); CREATE TEMPORARY SEQUENCE t_seq_cc;
SELECT
    setval('t_seq_cc', :cc_count);



SELECT
    logg ('copying in new data...');

COPY temp_load (smiles, code, cat_fk, tranche_id)
FROM
    :'source_f' DELIMITER ' ';

select logg('fixing supplier codes...');

UPDATE
    temp_load
SET
    code = replace(code, '____', '__')
WHERE
    code LIKE '%\_\_\_\_%';

select logg('resolving smiles...');
UPDATE
    temp_load
SET
    sub_fk = sb.sub_id
FROM
    substance sb
WHERE
    sb.smiles::varchar = temp_load.smiles and sb.tranche_id = temp_load.tranche_id;

select logg('resolving supplier codes...');
UPDATE
    temp_load
SET
    code_fk = cc.cat_content_id
FROM
    catalog_content cc
WHERE
    cc.supplier_code = temp_load.code;

select logg('identifying new smiles');
UPDATE
    temp_load
SET
    sub_fk = nextval('t_seq_sb')
WHERE
    sub_fk is NULL;

select logg('identifying new supplier codes');
UPDATE
    temp_load
SET
    code_fk = nextval('t_seq_cc')
WHERE
    code_fk is NULL;

select logg('resolving smiles:code pairs');
UPDATE
    temp_load
SET
    cat_itm_id = cs.cat_sub_itm_id
FROM
    catalog_substance cs
WHERE
    sub_fk = cs.sub_id_fk AND code_fk = cs.cat_content_fk;

select logg('identifying new smiles:code pairs');
UPDATE
    temp_load
SET
    cat_itm_id = nextval('t_seq_cs')
WHERE
    cat_itm_id is NULL;

select logg('inserting all distinct new smiles into final table');
INSERT INTO substance_t(smiles, sub_id, tranche_id) (
	SELECT DISTINCT ON(t.smiles)
		t.smiles, t.sub_fk, t.tranche_id
	FROM
		(SELECT smiles, sub_fk, tranche_id
		 FROM temp_load 
		 WHERE sub_fk > :sb_count) t);

select logg('inserting all distinct new codes into final table');
INSERT INTO catalog_content_t(supplier_code, cat_content_id, cat_id_fk, tranche_id) (
	SELECT DISTINCT ON(t.code)
		t.code, t.code_fk, t.cat_fk, t.tranche_id
	FROM
		(SELECT code, code_fk, cat_fk, tranche_id
		 FROM temp_load
		 WHERE code_fk > :cc_count) t);

select logg('inserting all distinct new smiles:code pairs into final table');
INSERT INTO catalog_substance_t(sub_id_fk, cat_content_fk, cat_sub_itm_id, tranche_id) (
	SELECT DISTINCT ON(t.sub_fk, t.code_fk)
		t.sub_fk, t.code_fk, t.cat_itm_id, t.tranche_id
	FROM
		(SELECT sub_fk, code_fk, cat_itm_id, tranche_id
		 FROM temp_load
		 WHERE cat_itm_id > :cs_count) t);

--- fix tranche_ids in catalog_substance if they exist (shouldn't happen, still unsure why there are a few entries like this)
UPDATE catalog_substance_t SET tranche_id = sb.sub_id FROM substance_t sb WHERE sb.sub_id = sub_id_fk AND sb.tranche_id != tranche_id;

/*
--- load substance data to temp table
INSERT INTO temp_load_sb (smiles, tranche_id)
SELECT DISTINCT ON (smiles)
    mol_from_smiles(smiles::cstring),
    tranche_id
FROM
    temp_load;

SELECT
    logg ('identifying unique supplier codes');

--- group by makes sure there are no duplicates in this table
--- load cat_content data to temp table
INSERT INTO temp_load_cc (code, cat_fk, tranche_id)
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
    id is NULL;

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
    id is NULL;

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
    AND temp_load.smiles = temp_load_sb.smiles::varchar;

SELECT
    logg ('resolving supplier codes back to catalog');

--- resolve code ids
UPDATE
    temp_load
SET
    code_fk = temp_load_cc.id
FROM
    temp_load_cc
WHERE
    temp_load.tranche_id = temp_load_cc.tranche_id
    AND temp_load.code = temp_load_cc.code;

SELECT
    logg ('identifying unique catalog entries');

--- get distinct catalog entries
INSERT INTO temp_load_cs (sub_fk, code_fk, tranche_id)
SELECT DISTINCT ON (sub_fk, code_fk)
    sub_fk,
    code_fk,
    tranche_id
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
    cs.cat_content_fk = temp_load_cs.code_fk
    AND cs.sub_id_fk = temp_load_cs.sub_fk;

--- assign cat_sub_itm_id value to new entries
UPDATE
    temp_load_cs
SET
    id = nextval('t_seq_cs')
WHERE
    id is NULL;

SELECT
    logg ('loading new substance data');
--- load new substance data in
INSERT INTO substance_t (sub_id, smiles, tranche_id)
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

SELECT
    logg ('loading new catalog_substance data');

--- and finally, cat_substance data
INSERT INTO catalog_substance_t (cat_content_fk, sub_id_fk, cat_sub_itm_id, tranche_id)
SELECT
    code_fk,
    sub_fk,
    id,
    tranche_id
FROM
    temp_load_cs
WHERE
    temp_load_cs.id > :cs_count;
*/

--- update sequences with new values
SELECT
    setval('sub_id_seq', currval('t_seq_sb'));

SELECT
    setval('cat_sub_itm_id_seq', currval('t_seq_cs'));

SELECT
    setval('cat_content_id_seq', currval('t_seq_cc'));

--- free up a lil bit of memory because we can
DROP TABLE temp_load;

/*DROP TABLE temp_load_sb;

DROP TABLE temp_load_cc;

DROP TABLE temp_load_cs;*/


/*
 *  BEGIN BOILERPLATE FINALIZATION
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

--- initialize record of constraints, just for renaming them after we're done
INSERT INTO constraint_save (tablename, constraintname) (
        VALUES ('catalog_content', 'catalog_content_cat_id_fk_fkey'), ('catalog_substance', 'catalog_substance_cat_itm_fk_fkey'), ('catalog_substance', 'catalog_substance_sub_id_fk_fkey'));

--- keep a record of the pkeys so that we can rename them afterwards
INSERT INTO pkey_save (tablename, columnname) (
        VALUES ('substance', 'sub_id'), ('catalog_content', 'cat_content_id'));

REINDEX table substance_t;
REINDEX table catalog_content_t;

--- initialize our record of indexes we need to rebuild
--- also used for renaming them afterwards
INSERT INTO index_save (tablename, indexname, indexdef)
SELECT
    tablename,
    indexname,
    indexdef
FROM
    pg_indexes
WHERE
    tablename IN ('substance', 'catalog_content', 'catalog_substance')
    AND indexname NOT LIKE '%_pkey';

DO $$
DECLARE
    idx index_save % rowtype;
    idxdef text;
BEGIN
    FOR idx IN
    SELECT
        *
    FROM
        index_save LOOP
            idxdef := REPLACE(idx.indexdef, idx.indexname, CONCAT(idx.indexname, '_t'));
            idxdef := REPLACE(idxdef, CONCAT('public.', idx.tablename), CONCAT('public.', idx.tablename, '_t'));
            EXECUTE '' || idxdef;
            RAISE info '[%]: finished building index: %', clock_timestamp(), idx.indexname;
        END LOOP;
END
$$
LANGUAGE plpgsql;

--- moved constraint creation to here
ALTER TABLE catalog_content_t
    ADD CONSTRAINT "catalog_content_cat_id_fk_fkey_t" FOREIGN KEY (cat_id_fk) REFERENCES catalog (cat_id) ON DELETE CASCADE;

ALTER TABLE catalog_substance_t
    ADD CONSTRAINT "catalog_substance_cat_itm_fk_fkey_t" FOREIGN KEY (cat_content_fk) REFERENCES catalog_content_t (cat_content_id) ON DELETE CASCADE;

ALTER TABLE catalog_substance_t
    ADD CONSTRAINT "catalog_substance_sub_id_fk_fkey_t" FOREIGN KEY (sub_id_fk, tranche_id) REFERENCES substance_t (sub_id, tranche_id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

--- re-enable triggers. We could have done this earlier if we wanted
ALTER TABLE substance_t ENABLE TRIGGER ALL;

ALTER TABLE catalog_content_t ENABLE TRIGGER ALL;

ALTER TABLE catalog_substance_t ENABLE TRIGGER ALL;

--- swap out old table for new table
ALTER TABLE substance RENAME TO substance_trash;

ALTER TABLE catalog_content RENAME TO catalog_content_trash;

ALTER TABLE catalog_substance RENAME TO catalog_substance_trash;

ALTER TABLE substance_t RENAME TO substance;

ALTER TABLE catalog_content_t RENAME TO catalog_content;

ALTER TABLE catalog_substance_t RENAME TO catalog_substance;

SELECT
    logg ('tables swapped out!');

--- dispose of old table
DROP TABLE substance_trash CASCADE;

DROP TABLE catalog_content_trash CASCADE;

DROP TABLE catalog_substance_trash CASCADE;

SELECT
    logg ('old tables disposed!');

--- rename indexes (so we don't get indexes like %_t_t_t_t or w.e)
DO $$
DECLARE
    idx index_save % rowtype;
    cns constraint_save % rowtype;
    pky pkey_save % rowtype;
BEGIN
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
            EXECUTE 'alter table ' || cns.tablename || ' rename constraint ' || cns.constraintname || '_t to ' || cns.constraintname;
        END LOOP;
    RAISE info '[%]: finished renaming constraints & indexes!', clock_timestamp();
END
$$
LANGUAGE plpgsql;

COMMIT;

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

