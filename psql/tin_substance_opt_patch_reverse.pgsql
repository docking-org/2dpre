begin;

create table substance_t (
	sub_id int default nextval('sub_id_seq'),
	smiles mol not null,
	purchasable smallint,
	date_updated date default now(),
	inchikey character(27),
	tranche_id smallint not null default 0
);

insert into substance_t (sub_id, smiles, purchasable, date_updated, tranche_id) (
	select sub_id, mol_from_smiles(smiles::cstring), purchasable, date_updated, tranche_id from substance);

alter table substance_t add primary key (sub_id, tranche_id);
-- new hash index, testing it out. Might considerably increase load performance!
-- create index smiles_hash_idx_t on substance_t using hash(smiles);

alter table catalog_substance add constraint catalog_substance_sub_id_fk_fkey_t foreign key (sub_id_fk, tranche_id) references substance_t(sub_id, tranche_id);

alter table substance rename to substance_trash;
alter table substance_t rename to substance;

alter table catalog_substance drop constraint catalog_substance_sub_id_fk_fkey;
drop table substance_trash cascade;
alter table substance rename constraint substance_t_pkey to substance_pkey;
-- alter index smiles_hash_idx_t rename to smiles_hash_idx;
alter table catalog_substance rename constraint catalog_substance_sub_id_fk_fkey_t to catalog_substance_sub_id_fk_fkey;

commit;

-- vacuum analyze;
