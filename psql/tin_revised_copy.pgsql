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
		t.smiles, nextval('t_seq_sb'), t.tranche_id
	FROM
		(SELECT smiles, sub_fk, tranche_id
		 FROM temp_load 
		 WHERE sub_fk > :cc_count) t);

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

--- update sequences with new values
SELECT
    setval('sub_id_seq', currval('t_seq_sb'));

SELECT
    setval('cat_sub_itm_id_seq', currval('t_seq_cs'));

SELECT
    setval('cat_content_id_seq', currval('t_seq_cc'));

--- free up a lil bit of memory because we can
DROP TABLE temp_load;

/*
 *  BEGIN BOILERPLATE FINALIZATION
 */
select logg('creating constraints and indexes for new substance table');
--- now we have to re-initialize allllll of the indexes, constraints, etc. on the tables
alter table substance_t add primary key (sub_id, tranche_id);
create index smiles_hash_idx_t on substance_t using hash(smiles);
select logg('done');

select logg('creating constraints and indexes for new catalog_content table');
alter table catalog_content_t add primary key (cat_content_id);
alter table catalog_content_t add constraint catalog_content_cat_id_fk_fkey_t foreign key (cat_id_fk) references catalog(cat_id);
create index catalog_content_supplier_code_idx_t on catalog_content_t using hash(supplier_code);
select logg('done');

select logg('creating constraints and indexes for new catalog_substance table');
alter table catalog_substance_t add constraint catalog_substance_cat_itm_fk_fkey_t foreign key (cat_content_fk) references catalog_content_t(cat_content_id);
alter table catalog_substance_t add constraint catalog_substance_sub_id_fk_fkey_t foreign key (sub_id_fk, tranche_id) references substance_t(sub_id, tranche_id);
create index catalog_substance_cat_id_fk_idx_t on catalog_substance_t(cat_content_fk);
create index catalog_substance_sub_id_fk_idx_t on catalog_substance_t(sub_id_fk, tranche_id);
select logg('done');

--- drop old tables
select logg('dropping old tables and replacing with new ones');
drop table substance cascade;
drop table catalog_content cascade;
drop table catalog_substance cascade;

--- rename new tables & constraints
alter table substance_t rename to substance;
alter table substance rename constraint substance_t_pkey to substance_pkey;
alter index smiles_hash_idx_t rename to smiles_hash_idx;

alter table catalog_content_t rename to catalog_content;
alter table catalog_content rename constraint catalog_content_t_pkey to catalog_content_pkey;
alter table catalog_content rename constraint catalog_content_cat_id_fk_fkey_t to catalog_content_cat_id_fk_fkey;
alter index catalog_content_supplier_code_idx_t rename to catalog_content_supplier_code_idx;

alter table catalog_substance_t rename to catalog_substance;
alter table catalog_substance rename constraint catalog_substance_cat_itm_fk_fkey_t to catalog_substance_cat_itm_fk_fkey;
alter table catalog_substance rename constraint catalog_substance_sub_id_fk_fkey_t to catalog_substance_sub_id_fk_fkey;
alter index catalog_substance_cat_id_fk_idx_t rename to catalog_substance_cat_id_fk_idx;
alter index catalog_substance_sub_id_fk_idx_t rename to catalog_substance_sub_id_fk_idx;
select logg('done. All done!');

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

