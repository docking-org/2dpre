BEGIN;

set work_mem = 1000000;

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

DROP TABLE IF EXISTS substance_t CASCADE;
CREATE TABLE substance_t (
    LIKE substance INCLUDING defaults
);

ALTER TABLE substance_t alter column smiles type varchar using smiles::varchar;

DROP TABLE IF EXISTS catalog_content_t CASCADE;
CREATE TABLE catalog_content_t (
    LIKE catalog_content INCLUDING defaults
);

DROP TABLE IF EXISTS catalog_substance_t CASCADE;
CREATE TABLE catalog_substance_t (
    LIKE catalog_substance INCLUDING defaults
);

alter table substance_t alter column inchikey drop not null;

/* this bit is not boilerplate */
alter table substance_t drop column if exists tranche_id;
ALTER TABLE substance_t
    ADD COLUMN IF NOT EXISTS tranche_id smallint DEFAULT 0;

alter table catalog_content_t drop column if exists tranche_id;
ALTER TABLE catalog_content_t
    ADD COLUMN IF NOT EXISTS tranche_id smallint DEFAULT 0;

alter table catalog_substance_t drop column if exists tranche_id;
ALTER TABLE catalog_substance_t
    ADD COLUMN IF NOT EXISTS tranche_id smallint DEFAULT 0;


/* end not boilerplate bit */
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
ALTER TABLE catalog_content_t
    ADD CONSTRAINT "catalog_content_cat_id_fk_fkey_t" FOREIGN KEY (cat_id_fk) REFERENCES catalog (cat_id) ON DELETE CASCADE;

ALTER TABLE catalog_substance_t
    ADD CONSTRAINT "catalog_substance_cat_itm_fk_fkey_t" FOREIGN KEY (cat_content_fk) REFERENCES catalog_content_t (cat_content_id) ON DELETE CASCADE;

ALTER TABLE catalog_substance_t
    ADD CONSTRAINT "catalog_substance_sub_id_fk_fkey_t" FOREIGN KEY (sub_id_fk, tranche_id) REFERENCES substance_t (sub_id, tranche_id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

SELECT
    invalidate_index ('substance_t_pkey');

SELECT
    invalidate_index ('catalog_content_t_pkey');

ALTER TABLE catalog_content_t DISABLE TRIGGER ALL;

ALTER TABLE catalog_substance_t DISABLE TRIGGER ALL;

ALTER TABLE substance_t DISABLE TRIGGER ALL;

SELECT
    logg ('copying substance data to clone table...');

INSERT INTO substance_t (sub_id, smiles, purchasable, date_updated)
SELECT
    sub_id, smiles::varchar, purchasable, date_updated
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
/*
 *  BEGIN MAIN PROCEDURE
 */
DROP SEQUENCE IF EXISTS sub_id_seq;

CREATE SEQUENCE IF NOT EXISTS sub_id_seq
    START :sub_tot;

DROP SEQUENCE IF EXISTS cat_content_id_seq;

CREATE SEQUENCE cat_content_id_seq
    START :sup_tot;

DROP SEQUENCE IF EXISTS cat_sub_itm_id_seq;

CREATE SEQUENCE cat_sub_itm_id_seq
    START :cat_tot;

--- update database with tranche information, since multiple tranches may share the same database
DROP TABLE IF EXISTS tranches;
CREATE TABLE tranches (
    tranche_id smallint,
    tranche_name varchar
);

COPY tranches (tranche_name, tranche_id)
FROM
    :'tranche_info_f' (DELIMITER ' ');

--- tranceh_info_f contains the name of each tranche & their id
CREATE TEMPORARY TABLE temp_load_sub (
    sub_id int,
    tranche_id smallint
);

CREATE TEMPORARY TABLE temp_load_cc (
    cc_id int,
    tranche_id smallint
);

CREATE TEMPORARY TABLE temp_load_cs (
    cs_id int,
    tranche_id smallint
);

COPY temp_load_sub (sub_id, tranche_id)
FROM
    :'tranche_sub_id_f' (DELIMITER ' ');
ALTER TABLE temp_load_sub ADD PRIMARY KEY (sub_id);

SELECT
    logg ('loaded sub data');

COPY temp_load_cc (cc_id, tranche_id)
FROM
    :'tranche_cc_id_f' (DELIMITER ' ');
ALTER TABLE temp_load_cc ADD PRIMARY KEY (cc_id);

SELECT
    logg ('loaded cat content data');

COPY temp_load_cs (cs_id, tranche_id)
FROM
    :'tranche_cs_id_f' (DELIMITER ' ');
ALTER TABLE temp_load_cs ADD PRIMARY KEY (cs_id);

--- tranche_sub_id_f contains the sub_id of every substance in database, along with tranche id
--- all files read in are created by the python script
--- set default values for table ids to the sequences we created
ALTER TABLE substance_t
    ALTER COLUMN sub_id SET DEFAULT nextval('sub_id_seq');

ALTER TABLE catalog_content_t
    ALTER COLUMN cat_content_id SET DEFAULT nextval('cat_content_id_seq');

ALTER TABLE catalog_substance_t
    ALTER COLUMN cat_sub_itm_id SET DEFAULT nextval('cat_sub_itm_id_seq');

SELECT
    logg ('starting update on substance table');

UPDATE
    substance_t sb
SET
    tranche_id = temp_load_sub.tranche_id
FROM
    temp_load_sub
WHERE
    sb.sub_id = temp_load_sub.sub_id;

SELECT
    logg ('finished update on substance table');

SELECT
    logg ('starting update on cat content table');

UPDATE
    catalog_content_t cc
SET
    tranche_id = temp_load_cc.tranche_id
FROM
    temp_load_cc
WHERE
    cc.cat_content_id = temp_load_cc.cc_id;

SELECT
    logg ('finished update on cat content table');

UPDATE
    catalog_substance_t cs
SET
    tranche_id = temp_load_cs.tranche_id
FROM
    temp_load_cs
WHERE
    cs.cat_sub_itm_id = temp_load_cs.cs_id;

SELECT
    logg ('finished update on cat substance table');


/*
 *  END MAIN PROCEDURE
 */
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
    columnnames text
);

--- initialize record of constraints, just for renaming them after we're done
INSERT INTO constraint_save (
    tablename,
    constraintname) (
    VALUES (
            'catalog_content', 'catalog_content_cat_id_fk_fkey'),
        (
            'catalog_substance', 'catalog_substance_cat_itm_fk_fkey'),
        (
            'catalog_substance', 'catalog_substance_sub_id_fk_fkey'));

--- keep a record of the pkeys so that we can rename them afterwards
INSERT INTO pkey_save (
    tablename,
    columnnames) (
    VALUES (
            'substance', 'sub_id, tranche_id'),
        (
            'catalog_content', 'cat_content_id, tranche_id'));

--- initialize our record of indexes we need to rebuild
--- also used for renaming them afterwards
--- in this case we are actually wiping out most existing indexes and replacing them with different ones
--- so we don't want to save the previous indexes
/*INSERT INTO index_save (
 tablename,
 indexname,
 indexdef)
SELECT
 tablename,
 indexname,
 indexdef
FROM
 pg_indexes
WHERE
 tablename IN ('substance', 'catalog_content', 'catalog_substance')
 AND indexname NOT LIKE '%_pkey';*/
/* boilerplate exception */
--- these aren't actually indexes yet, but we want to build them in the patched database
INSERT INTO index_save (
    tablename,
    indexname,
    indexdef) (
    VALUES 
	(
	    'substance', 'smiles_hash_idx', 'CREATE INDEX smiles_hash_idx ON public.substance using hash(smiles)'),
	(
            'catalog_content', 'catalog_content_supplier_code_idx', 'CREATE INDEX catalog_content_supplier_code_idx ON public.catalog_content (supplier_code)'),
        (
            'catalog_substance', 'catalog_substance_sub_id_fk_idx', 'CREATE INDEX catalog_substance_sub_id_fk_idx ON public.catalog_substance (sub_id_fk, tranche_id)'),
        (
            'catalog_substance', 'catalog_substance_cat_id_fk_idx', 'CREATE INDEX catalog_substance_cat_id_fk_idx ON public.catalog_substance (cat_content_fk)'));

SELECT
    logg ('building primary key indexes...');

REINDEX TABLE substance_t;

REINDEX TABLE catalog_content_t;


/* end of boilerplate exception */
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

SELECT
    logg ('cleaning up...');

SELECT
    logg ('done with everything!');


/*
 *  END BOILERPLATE FINALIZATION
 */
COMMIT;

