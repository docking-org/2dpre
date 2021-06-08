BEGIN;

--- making sure this init script can be re-used redundantly and not cause problems
--- mostly for development & testing purposes
ALTER TABLE substance
    DROP COLUMN IF EXISTS tranche_id;

ALTER TABLE substance
    DROP COLUMN IF EXISTS amw;

ALTER TABLE substance
    DROP COLUMN IF EXISTS logp;

ALTER TABLE catalog_content
    DROP COLUMN IF EXISTS tranche_id;

ALTER TABLE catalog_substance
    DROP COLUMN IF EXISTS tranche_id;

DROP TABLE IF EXISTS tranches;

DROP SEQUENCE IF EXISTS sub_id_seq;

DROP SEQUENCE IF EXISTS cat_content_id_seq;

DROP SEQUENCE IF EXISTS cat_sub_itm_id_seq;

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

CREATE TEMPORARY TABLE temp_load_cs (
    cs_id int,
    tranche_id smallint
);

COPY temp_load_sub (sub_id, tranche_id)
FROM
    :'tranche_sub_id_f' (DELIMITER ' ');

COPY temp_load_cc (cc_id, tranche_id)
FROM
    :'tranche_cc_id_f' (DELIMITER ' ');

COPY temp_load_cs (cs_id, tranche_id)
FROM
    :'tranche_cs_id_f' (DELIMITER ' ');

--- tranche_sub_id_f contains the sub_id of every substance in database, along with tranche id
--- all files read in are created by the python script
ALTER TABLE substance
    ADD COLUMN tranche_id smallint;

ALTER TABLE catalog_content
    ADD COLUMN tranche_id smallint;

ALTER TABLE catalog_substance
    ADD COLUMN tranche_id smallint;

UPDATE
    substance
SET
    tranche_id = temp_load_sub.tranche_id
FROM
    temp_load_sub
WHERE
    substance.sub_id = temp_load_sub.sub_id;

UPDATE
    catalog_content
SET
    tranche_id = temp_load_cc.tranche_id
FROM
    temp_load_cc
WHERE
    catalog_content.cat_content_id = temp_load_cc.cc_id;

UPDATE
    catalog_substance
SET
    tranche_id = temp_load_cs.tranche_id
FROM
    temp_load_cs
WHERE
    catalog_substance.cat_sub_itm_id = temp_load_cs.cs_id;

--- create sequences to keep track of sub_id etc. before this was done by the python script
CREATE SEQUENCE sub_id_seq START :sub_tot;

ALTER TABLE substance
    ALTER COLUMN sub_id SET DEFAULT nextval('sub_id_seq');

CREATE SEQUENCE cat_content_id_seq START :sup_tot;

ALTER TABLE catalog_content
    ALTER COLUMN cat_content_id SET DEFAULT nextval('cat_content_id_seq');

CREATE SEQUENCE cat_sub_itm_id_seq START :cat_tot;

ALTER TABLE catalog_substance
    ALTER COLUMN cat_sub_itm_id SET DEFAULT nextval('cat_sub_itm_id_seq');

--- drop old function-based indexes on substance table (which are inefficient & take forever to build) and replace with column based index
--- we need to add the columns then update substance table with mol_logp and mol_amw values to make this work
DROP INDEX IF EXISTS substance3_logp_idx;

DROP INDEX IF EXISTS substance3_mwt_idx;

DROP INDEX IF EXISTS substance_tranche_id_idx;

DROP INDEX IF EXISTS catalog_content_tranche_id_idx;

DROP INDEX IF EXISTS catalog_substance_tranche_id_idx;

ALTER TABLE substance
    ADD COLUMN amw real;

ALTER TABLE substance
    ADD COLUMN logp real;

UPDATE
    TABLE substance
SET
    amw = mol_amw(smiles),
    logp = mol_logp(smiles);

CREATE INDEX substance3_logp_idx ON substance (logp);

CREATE INDEX substance3_mwt_idx ON substance (amw);

CREATE INDEX substance_tranche_id_idx ON substance (tranche_id);

CREATE INDEX catalog_content_tranche_id_idx ON catalog_content (tranche_id);

CREATE INDEX catalog_substance_tranche_id_idx ON catalog_substance (tranche_id);

COMMIT;

