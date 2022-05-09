begin;

set work_mem = 1000000;

create table substance_t (
        sub_id int default nextval('sub_id_seq'),
        smiles varchar not null,
        purchasable smallint,
        date_updated date default now(),
        inchikey character(27),
        tranche_id smallint not null default 0
);

copy substance_t (smiles, sub_id, tranche_id) from :'source_f' delimiter ' ';

alter table substance_t add primary key (sub_id, tranche_id);
create index smiles_hash_idx_t on substance_t using hash(smiles);

--- same philosophy as substance opt patch. This mountain of code doesn't seem to work, so we just cut the table down and promise to rebuild it later
truncate table catalog_substance;

--- same thing but for substance table
alter table substance rename to substance_trash;
alter table substance_t rename to substance;
drop table substance_trash cascade;

alter index smiles_hash_idx_t rename to smiles_hash_idx;
alter table substance rename constraint substance_t_pkey to substance_pkey;

commit;
