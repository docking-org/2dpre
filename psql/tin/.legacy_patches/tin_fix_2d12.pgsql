drop table if exists catalog_substance_save;
/* context for this patch-
	some substances were mistakenly loaded in prior to canonicalization
	as a result, there were a bunch of smiles in the database that weren't canonical substances
	externally, I ran a program to identify all these substances from the 2d-12 diff
	this patch reads those externally identified substances and removes them
*/

begin;

create temporary table noncanonical (
	sub_id bigint,
	tranche_id smallint
);
copy noncanonical from :'noncanon_src_f' delimiter ' ';
create index nc_idx on noncanonical(tranche_id, sub_id);

create temporary table escaped (
	sub_id bigint,
	tranche_id smallint,
	escaped_smiles varchar
);
copy escaped from :'escaped_src_f' delimiter ' ';
create index es_idx on escaped(tranche_id, sub_id);

create table substance_t (like substance including defaults);
alter table substance_t alter column sub_id type bigint;

insert into substance_t(sub_id, tranche_id, smiles, date_updated) (
	select sb.sub_id, sb.tranche_id, sb.smiles, sb.date_updated from (
		select sb.sub_id, sb.tranche_id, sb.smiles, sb.date_updated from substance sb left join escaped es on sb.sub_id = es.sub_id and sb.tranche_id = es.tranche_id where es.sub_id is null
	) sb left join noncanonical nc on sb.sub_id = nc.sub_id and sb.tranche_id = nc.tranche_id where nc.sub_id is null
);

insert into substance_t(sub_id, tranche_id, smiles) (select sub_id, tranche_id, escaped_smiles from escaped);

create table catalog_substance_t (like catalog_substance including defaults);
alter table catalog_substance_t alter column sub_id_fk type bigint;
alter table catalog_substance_t alter column cat_sub_itm_id type bigint;
alter table catalog_substance_t alter column cat_content_fk type bigint;

insert into catalog_substance_t(sub_id_fk, cat_content_fk, tranche_id, cat_sub_itm_id) (
	select cs.sub_id_fk, cs.cat_content_fk, cs.tranche_id, cs.cat_sub_itm_id from catalog_substance cs left join noncanonical nc on cs.tranche_id = nc.tranche_id and cs.sub_id_fk = nc.sub_id where nc.sub_id is null
);
-- want to find anomalies
-- check that all "escaped" sub_ids exist already
-- also check that smiles minus \ are equal
create temporary table anomalies (
	sub_id bigint,
	tranche_id smallint,
	smiles_es varchar,
	smiles_sb varchar
);

insert into anomalies(sub_id, tranche_id, smiles_es, smiles_sb) (
	select 
		es.sub_id, 
		es.tranche_id, 
		es.escaped_smiles, 
		sb.smiles 
	from escaped es left join substance sb on es.tranche_id = sb.tranche_id and es.sub_id = sb.sub_id
);

copy (
	select sub_id, tranche_id, smiles_es 
	from anomalies where smiles_sb is null
) to :'missing_file';

copy (
	select sub_id, tranche_id, smiles_es, smiles_sb 
	from anomalies where not smiles_sb is null and replace(smiles_es, '\', '') != replace(smiles_sb, '\', '')
) to :'mismatch_file'; 

/* update 4/6/22: need to re-apply this patch so that escape characters actually make it in (i had one job...)
   this bit can be left out bc noncanon ids should have been deleted already */
-- find which noncanon ids weren't found
-- labeled mystery because it would be a mystery if there were any cases of this
--copy (
--        select nc.sub_id, nc.tranche_id from noncanonical nc left join substance sb on nc.tranche_id = sb.tranche_id and
--nc.sub_id = sb.sub_id where sb.sub_id is null
--) to :'mystery_file';

commit;
begin;

alter table substance_t add primary key (tranche_id, sub_id);
create index smiles_hash_idx_t on substance_t using hash(smiles);
create index sub_id_idx_t on substance_t(sub_id);

create index catalog_substance_sub_id_fk_idx_t on catalog_substance_t(sub_id_fk);
create index catalog_substance_sub_id_tranche_id_fk_idx_t on catalog_substance_t(tranche_id, sub_id_fk);
create index catalog_substance_cat_id_fk_idx_t on catalog_substance_t(cat_content_fk);

alter table catalog_substance_t add constraint catalog_substance_sub_id_fk_fkey_t foreign key (tranche_id, sub_id_fk) references substance_t(tranche_id, sub_id);
alter table catalog_substance_t add constraint catalog_substance_cat_itm_fk_fkey_t foreign key (cat_content_fk) references catalog_content(cat_content_id);

alter index smiles_hash_idx rename to smiles_hash_idx_save;
--alter table substance alter constraint smiles_hash_idx rename to smiles_hash_idx_save;
alter table substance rename constraint substance_pkey to substance_pkey_save;
alter table substance rename to substance_save;

alter index catalog_substance_cat_id_fk_idx rename to catalog_substance_cat_id_fk_idx_save;
alter index catalog_substance_sub_id_fk_idx rename to catalog_substance_sub_id_fk_idx_save;
alter table catalog_substance rename constraint catalog_substance_sub_id_fk_fkey to catalog_substance_sub_id_fk_fkey_save;
alter table catalog_substance rename constraint catalog_substance_cat_itm_fk_fkey to catalog_substance_cat_itm_fk_fkey_save;
alter table catalog_substance rename to catalog_substance_save;

alter table substance_t rename to substance;
alter table substance rename constraint substance_t_pkey to substance_pkey;
alter index smiles_hash_idx_t rename to smiles_hash_idx;
alter index sub_id_idx_t rename to sub_id_idx;

alter table catalog_substance_t rename to catalog_substance;
alter table catalog_substance rename constraint catalog_substance_cat_itm_fk_fkey_t to catalog_substance_cat_itm_fk_fkey;
alter table catalog_substance rename constraint catalog_substance_sub_id_fk_fkey_t to catalog_substance_sub_id_fk_fkey;
alter index catalog_substance_cat_id_fk_idx_t rename to catalog_substance_cat_id_fk_idx;
alter index catalog_substance_sub_id_fk_idx_t rename to catalog_substance_sub_id_fk_idx;
alter index catalog_substance_sub_id_tranche_id_fk_idx_t rename to catalog_substance_sub_id_tranche_id_fk_idx;

commit;

--drop table catalog_substance_trash;
--drop table substance_trash;
--alter index smiles_hash_idx_t rename to smiles_hash_idx;
--alter index catalog_substance_sub_id_fk_idx_t rename to catalog_substance_sub_id_fk_idx;
