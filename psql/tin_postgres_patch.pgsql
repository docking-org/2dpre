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
/*
 *  BEGIN MAIN PROCEDURE
 */
DROP SEQUENCE IF EXISTS sub_id_seq;

CREATE SEQUENCE sub_id_seq
    START :sub_tot;

DROP SEQUENCE IF EXISTS cat_content_id_seq;

CREATE SEQUENCE cat_content_id_seq
    START :sup_tot;

DROP SEQUENCE IF EXISTS cat_sub_itm_id_seq;

CREATE SEQUENCE cat_sub_itm_id_seq
    START :cat_tot;

--- update database with tranche information, since multiple tranches may share the same database
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

COPY temp_load_sub (sub_id, tranche_id)
FROM
    :'tranche_sub_id_f' (DELIMITER ' ');

SELECT
    logg ('loaded sub data');

COPY temp_load_cc (cc_id, tranche_id)
FROM
    :'tranche_cc_id_f' (DELIMITER ' ');

SELECT
    logg ('loaded cat content data');

--- tranche_sub_id_f contains the sub_id of every substance in database, along with tranche id
--- all files read in are created by the python script
ALTER TABLE substance_t
    ADD COLUMN tranche_id smallint;

ALTER TABLE catalog_content_t
    ADD COLUMN tranche_id smallint;

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

--- drop old function-based indexes on substance table mwt and logp
--- they are not used and take up precious space & time
DROP INDEX IF EXISTS substance3_logp_idx;

DROP INDEX IF EXISTS substance3_mwt_idx;

--- this will scan and make sure all tranche_ids are set
--- if a tranche_id was left as null it will pop up as an error here
ALTER TABLE substance_t
    ALTER COLUMN tranche_id SET NOT NULL;

ALTER TABLE catalog_content_t
    ALTER COLUMN tranche_id SET NOT NULL;


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


/* boilerplate exception */
--- these aren't actually indexes yet, but we want to build them in the patched database
--- also, this bit isn't boilerplate, but is special to this procedure
INSERT INTO index_save (
    tablename,
    indexname,
    indexdef) (
    VALUES (
            'substance', 'substance_tranche_id_idx', 'CREATE INDEX substance_tranche_id_idx ON public.substance (tranche_id);'),
        (
            'catalog_content', 'catalog_content_tranche_id_idx', 'CREATE INDEX catalog_content_tranche_id_idx ON public.catalog_content (tranche_id);'),
        (
            'catalog_substance', 'catalog_substance_tranche_id_idx', 'CREATE INDEX catalog_substance_tranche_id_idx ON public.catalog_substance (tranche_id);'));


/* end of boilerplate exception */
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
        logg ('building constraints...');
    --- create the foreign key constraints for this new table- we want to do these before indices etc. so that we can disable them before we load in data
    ALTER TABLE catalog_content_t
        ADD CONSTRAINT "catalog_content_cat_id_fk_fkey_t" FOREIGN KEY (cat_id_fk) REFERENCES catalog (cat_id) ON DELETE CASCADE;
    ALTER TABLE catalog_substance_t
        ADD CONSTRAINT "catalog_substances_cat_itm_fk_fkey_t" FOREIGN KEY (cat_content_fk) REFERENCES catalog_content_t (cat_content_id) ON DELETE CASCADE;
    ALTER TABLE catalog_substance_t
        ADD CONSTRAINT "catalog_substances_sub_id_fk_fkey_t" FOREIGN KEY (sub_id_fk) REFERENCES substance_t (sub_id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;
    ALTER TABLE substance ENABLE TRIGGER ALL;
    ALTER TABLE catalog_content ENABLE TRIGGER ALL;
    ALTER TABLE catalog_substance ENABLE TRIGGER ALL;
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

