set work_mem = 2000000;

CREATE OR REPLACE FUNCTION logg (t text)
    RETURNS integer
    AS $$
BEGIN
	    RAISE info '[%]: %', clock_timestamp(), t;
	    RETURN 0;
END;
$$
LANGUAGE plpgsql;

--- if these tables exist (second transaction failed)
--- we want to delete them for maximum memory available
drop table if exists substance_t cascade;
drop table if exists catalog_content_t cascade;
drop table if exists catalog_substance_t cascade;

begin;

create temporary sequence t_seq_temp_id start 1;
create temporary sequence t_seq_sup_id start 1;
create temporary sequence t_seq_cat_itm_id start 1;
create temporary sequence t_seq_sub_id;

select nextval('t_seq_sub_id');
select setval('t_seq_sub_id', (select max(sub_id) from substance));

create temporary table source_t (
	smiles varchar,
	supplier varchar,
	tranche_id smallint,
	temp_id int default nextval('t_seq_temp_id'),
	sup_id int,
	cat_id smallint
);

--- we will log all of the meaty operations so we can get a sense of how long they take
select logg('step 00: copying in source data');
copy source_t(smiles, supplier, tranche_id, cat_id) from :'source_f';
select logg('done with step 00');

select logg('step 01: identifying distinct supplier codes from source');
--- assign ids to all distinct supplier codes- we are not concerned with preserving these from the current database iteration
create temporary table dist_supplier (
	supplier varchar,
	sup_id int
);
insert into dist_supplier (select t.supplier supplier, nextval('t_seq_sup_id') sup_id from (select distinct supplier from source_t) t);

create index sup_hash_idx_t on dist_supplier using hash(supplier);
update source_t set sup_id = dist_supplier.sup_id from dist_supplier where dist_supplier.supplier = source_t.supplier;
--update source_t set sup_id = tt.sup_id from (
--	select t.supplier supplier, nextval('t_seq_sup_id') sup_id from (
--		select distinct supplier from source_t) t) tt where source_t.supplier = tt.supplier;
select logg('done with step 01');

--- create the new catalog_substance table, with an extra column that will hold the provisional id of each new entry (we will delete the column later)
create table catalog_substance_t (
	sub_id_fk int,
	cat_content_fk int,
	temp_id int,
	tranche_id smallint,
	cat_sub_itm_id int default nextval('t_seq_cat_itm_id')
);
create table substance_t (like substance including defaults);
create table catalog_content_t (like catalog_content including defaults);

select logg('step 02: creating catalog_substance mappings from found substances');
--- resolve source smiles to table smiles, create new catalog_substance mappings
insert into catalog_substance_t (
	select sb.sub_id, src.sup_id, src.temp_id, sb.tranche_id from substance sb, source_t src where sb.smiles = src.smiles);
select logg('done with step 02');

create temporary table new_substances (
	smiles varchar,
	sub_id int,
	tranche_id smallint,
	sup_id int
);

select logg('step 03: identifying missing substances');
insert into new_substances (smiles, tranche_id, sup_id) (
	select src.smiles, src.tranche_id, src.sup_id from source_t src left join catalog_substance_t cs on src.temp_id = cs.temp_id where cs.temp_id is null);
select logg('done with step 03');

select logg('step 04: identifying distinct substances from missing substances');
create temporary table dist_substances (
	smiles varchar,
	sub_id int
);
insert into dist_substances (select t.smiles, nextval('t_seq_sub_id') sub_id from (select distinct smiles from new_substances) t);
create index dist_substances_idx_t on dist_substances using hash(smiles);
update new_substances set sub_id = dist_substances.sub_id from dist_substances where new_substances.smiles = dist_substances.smiles;
--update new_substances set sub_id = tt.sub_id from (
--	select t.smiles smiles, nextval('t_seq_sub_id') sub_id from (
--		select distinct smiles from new_substances) t) tt where new_substances.smiles = tt.smiles;
select logg('done with step 04');

select logg('step 05: copying new substance entries to replacement table');
--- insert new smiles to new substance table
insert into substance_t(smiles, sub_id, tranche_id) (
	select distinct on (sub_id, tranche_id) smiles, sub_id, tranche_id from new_substances);
select logg('done with step 05');

select logg('step 06: copying old substances to replacement table');
--- isnert old smiles to new substance table
insert into substance_t (select * from substance);
select logg('done with step 06');

select logg('step 07: creating catalog_substance entries from missing substances');
--- insert new mappings to new catalog_substance table
insert into catalog_substance_t (sub_id_fk, cat_content_fk, tranche_id) (
	select sub_id, sup_id, tranche_id from new_substances);
select logg('done with step 07');

--- get rid of the temp info we had in catalog_substance_t
alter table catalog_substance_t drop column temp_id;

select logg('step 08: creating catalog_content entries');
--- select distinct on sup_id is faster than distinct on supplier and accomplishes the same task (int vs varchar)
insert into catalog_content_t (supplier_code, cat_content_id, cat_id_fk) (
	select distinct on (sup_id) supplier, sup_id, cat_id from source_t);
select logg('done with step 08');

drop table source_t;
drop table new_substances;

--- finalize new sequence values
select setval('sub_id_seq', currval('t_seq_sub_id'));
select setval('cat_content_id_seq', currval('t_seq_sup_id'));
select setval('cat_sub_itm_id_seq', currval('t_seq_cat_itm_id'));
alter table catalog_substance_t alter column cat_sub_itm_id set default nextval('cat_sub_itm_id_seq');
--- commit changes so that the disk space is freed from source_t and new_substances
--- if the next transaction fails we will have substance_t etc tables floating around
--- but we can deal with that
commit;

begin;

select logg('step 09: creating constraints and indexes for new substance table');
--- now we have to re-initialize allllll of the indexes, constraints, etc. on the tables
alter table substance_t add primary key (sub_id, tranche_id);
create index smiles_hash_idx_t on substance_t using hash(smiles);
select logg('done with step 09');

select logg('step 10: creating constraints and indexes for new catalog_content table');
alter table catalog_content_t add primary key (cat_content_id);
alter table catalog_content_t add constraint catalog_content_cat_id_fk_fkey_t foreign key (cat_id_fk) references catalog(cat_id);
create index catalog_content_supplier_code_idx_t on catalog_content_t using hash(supplier_code);
select logg('done with step 10');

select logg('step 11: creating constraints and indexes for new catalog_substance table');
alter table catalog_substance_t add constraint catalog_substance_cat_itm_fk_fkey_t foreign key (cat_content_fk) references catalog_content_t(cat_content_id);
alter table catalog_substance_t add constraint catalog_substance_sub_id_fk_fkey_t foreign key (sub_id_fk, tranche_id) references substance_t(sub_id, tranche_id);
create index catalog_substance_cat_id_fk_idx_t on catalog_substance_t(cat_content_fk);
create index catalog_substance_sub_id_fk_idx_t on catalog_substance_t(sub_id_fk, tranche_id);
select logg('done with step 11');

--- drop old tables
select logg('step 12: dropping old tables and replacing with new ones');
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
select logg('done with step 12. All done!');

commit;

--- finish up with good ol' vacuum analyze. Unsure if this accomplishes anything, but it gives me some peace of mind
vacuum analyze;

