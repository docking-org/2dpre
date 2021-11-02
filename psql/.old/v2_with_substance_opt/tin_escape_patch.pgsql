begin;

create table substance_t (like substance including defaults);

alter table substance_t alter column smiles type varchar using smiles::varchar;

--create temporary table raw_copy(smiles varchar, sub_id int, tranche_id smallint);
--copy raw_copy(smiles, sub_id, tranche_id) from :'source_f' delimiter ' ';

--insert into substance_t(smiles, sub_id, tranche_id) (select mol_from_smiles(smiles::cstring), sub_id, tranche_id from raw_copy);

-- we apply the substance optimization patch here to make things faster. The substance opt patch should only be applied standalone if the database received this patch before the substanceopt patch was made

copy substance_t (smiles, sub_id, tranche_id) from :'source_f' delimiter ' ';

alter table substance_t add primary key (sub_id, tranche_id);
create index smiles_hash_idx_t on substance_t using hash(smiles);

create table catalog_substance_t (like catalog_substance including defaults);

insert into catalog_substance_t (select * from catalog_substance);

-- correct any incorrect tranche_ids in catalog_substance to be canonical with substance table
update catalog_substance_t cs set tranche_id = sb.tranche_id from substance_t sb where sb.sub_id = cs.sub_id_fk and sb.tranche_id != cs.tranche_id;

-- we want to wipe out entries that reference zinc20-stock, but sometimes these entries don't show up in catalog_substance because of the catsub patch
-- as a backup, we want to remove any entries that reference now non-existent substances (e.g ones that were added in zinc20-stock)
-- we will be applying the catsub patch after this to fix anything else that may be broken, but while that is in progress this will give us a reasonably correct catalog_substance table that doesn't have broken foreign keys
do
$$
declare
	maxid int;
begin
	select max(sub_id) from substance_t into maxid;
	delete from catalog_substance_t where sub_id_fk > maxid;
end $$;

-- wipe out any catalog_substance entries that reference zinc20-stock, since we are wiping out those substances (the catalog_content entries can stay where they are)
delete from catalog_substance_t where cat_content_fk in (select cat_content_id from catalog_content where cat_id_fk in (select cat_id from catalog where name like '%zinc20%'));

create index catalog_substance_sub_id_fk_idx_t on catalog_substance_t (sub_id_fk, tranche_id);
create index catalog_substance_cat_id_fk_idx_t on catalog_substance_t (cat_content_fk);

alter table catalog_substance_t add constraint catalog_substance_cat_itm_fk_fkey_t foreign key (cat_content_fk) references catalog_content (cat_content_id);
alter table catalog_substance_t add constraint catalog_substance_sub_id_fk_fkey_t foreign key (sub_id_fk, tranche_id) references substance_t (sub_id, tranche_id);

-- swap out catalog_substance tables and rename constraints
alter table catalog_substance rename to catalog_substance_trash;
alter table catalog_substance_t rename to catalog_substance;
alter table catalog_substance_trash drop constraint catalog_substance_cat_itm_fk_fkey;
alter table catalog_substance_trash drop constraint catalog_substance_sub_id_fk_fkey;
drop table catalog_substance_trash cascade;

alter table catalog_substance rename constraint catalog_substance_cat_itm_fk_fkey_t to catalog_substance_cat_itm_fk_fkey;
alter table catalog_substance rename constraint catalog_substance_sub_id_fk_fkey_t to catalog_substance_sub_id_fk_fkey;
alter index catalog_substance_sub_id_fk_idx_t rename to catalog_substance_sub_id_fk_idx;
alter index catalog_substance_cat_id_fk_idx_t rename to catalog_substance_cat_id_fk_idx;

--- same thing but for substance table
alter table substance rename to substance_trash;
alter table substance_t rename to substance;
drop table substance_trash cascade;

alter index smiles_hash_idx_t rename to smiles_hash_idx;
alter table substance rename constraint substance_t_pkey to substance_pkey;
--alter table catalog_substance add constraint catalog_substance_sub_id_fk_fkey foreign key (sub_id_fk, tranche_id) references substance(sub_id, tranche_id);

commit;
