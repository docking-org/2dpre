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

--create temporary table raw_copy(smiles varchar, sub_id int, tranche_id smallint);
--copy raw_copy(smiles, sub_id, tranche_id) from :'source_f' delimiter ' ';

--insert into substance_t(smiles, sub_id, tranche_id) (select mol_from_smiles(smiles::cstring), sub_id, tranche_id from raw_copy);

-- we apply the substance optimization patch here to make things faster. The substance opt patch should only be applied standalone if the database received this patch before the substanceopt patch was made

copy substance_t (smiles, sub_id, tranche_id) from :'source_f' delimiter ' ';

alter table substance_t add primary key (sub_id, tranche_id);
create index smiles_hash_idx_t on substance_t using hash(smiles);

--- same philosophy as substance opt patch. This mountain of code doesn't seem to work, so we just cut the table down and promise to rebuild it later
truncate table catalog_substance;
--create table catalog_substance_t (like catalog_substance including defaults);

--insert into catalog_substance_t (select * from catalog_substance);

-- correct any incorrect tranche_ids in catalog_substance to be canonical with substance table
--update catalog_substance_t cs set tranche_id = sb.tranche_id from substance_t sb where sb.sub_id = cs.sub_id_fk and sb.tranche_id != cs.tranche_id;

/*
--- adding in this huge chunk of code to make sure we don't get an "invalid_foreign_key" exception
	do
        $$
        declare
                succeeded_sub boolean;
                msg_text text;
                exception_detail text;
                exception_hint text;
        begin
                raise notice 'adding foreign keys to catalog_substance';
                alter table catalog_substance add constraint catalog_substance_sub_id_fk_fkey_t foreign key (sub_id_fk, tranche_id) references substance_t (sub_id, tranche_id);
                succeeded_sub := true;
                alter table catalog_substance add constraint catalog_substance_cat_itm_fk_fkey_t foreign key (cat_content_fk) references catalog_content (cat_content_id);

                alter table catalog_substance drop constraint catalog_substance_sub_id_fk_fkey;
                alter table catalog_substance drop constraint catalog_substance_cat_itm_fk_fkey;

                alter table catalog_substance rename constraint catalog_substance_sub_id_fk_fkey_t to catalog_substance_sub_id_fk_fkey;
                alter table catalog_substance rename constraint catalog_substance_cat_itm_fk_fkey_t to catalog_substance_cat_itm_fk_fkey;
                raise notice 'finished adding foreign keys to catalog_substance';
        exception
                when invalid_foreign_key or foreign_key_violation then
                        raise notice 'failed to add foreign key- rebuilding catalog_substance to correct this';
                        create table catalog_substance_t (like catalog_substance including defaults);
                        if succeeded_sub then
                                insert into catalog_substance_t (select cs.sub_id_fk, cs.cat_content_fk, cs.cat_sub_itm_id, cs.tranche_id from catalog_substance left join catalog_content on cat_content_fk = cat_content_id where cat_content_id is not null);
				update catalog_substance_t cs set tranche_id = sb.tranche_id from substance_t sb where sb.sub_id = cs.sub_id_fk and sb.tranche_id != cs.tranche_id;
				alter table catalog_substance drop constraint catalog_substance_sub_id_fk_fkey;
                                alter table catalog_substance drop constraint catalog_substance_cat_itm_fk_fkey;
                        else
                                insert into catalog_substance_t (select t.sub_id_fk, t.cat_content_fk, t.cat_sub_itm_id, t.tranche_id from (select sub_id_fk, cat_content_fk, cat_sub_itm_id, sb.tranche_id from catalog_substance cs left join substance_t sb on sub_id_fk = sub_id where sub_id is not null) t left join catalog_content on t.cat_content_fk = cat_content_id where cat_content_id is not null);
				alter table catalog_substance drop constraint catalog_substance_sub_id_fk_fkey;
                                alter table catalog_substance drop constraint catalog_substance_cat_itm_fk_fkey;
                        end if;
                        raise notice 'finished dropping bogus entries, rebuilding table indexes and constraints';
                        create index catalog_substance_cat_id_fk_idx_t on catalog_substance_t (cat_content_fk);
                        create index catalog_substance_sub_id_fk_idx_t on catalog_substance_t (sub_id_fk, tranche_id);
                        alter table catalog_substance_t add constraint catalog_substance_sub_id_fk_fkey foreign key (sub_id_fk, tranche_id) references substance_t (sub_id, tranche_id);
                        alter table catalog_substance_t add constraint catalog_substance_cat_itm_fk_fkey foreign key (cat_content_fk) references catalog_content (cat_content_id);

                        alter table catalog_substance rename to catalog_substance_trash;
                        alter table catalog_substance_t rename to catalog_substance;
                        drop table catalog_substance_trash cascade;
                        alter index catalog_substance_cat_id_fk_idx_t rename to catalog_substance_cat_id_fk_idx;
                        alter index catalog_substance_sub_id_fk_idx_t rename to catalog_substance_sub_id_fk_idx;
                        raise notice 'done rebuilding catalog_substance';
                when others then
                        get stacked diagnostics msg_text = MESSAGE_TEXT, exception_detail = PG_EXCEPTION_DETAIL, exception_hint = PG_EXCEPTION_HINT;
                        raise notice '%\n%\n%\n', msg_text, exception_detail, exception_hint;
                        raise exception 'something unexpected has happened!! PANIC!!!!!!!!!!!!!!!!!!!!!';
        end $$ language plpgsql;
*/

--- there may be some downtime after the tables are swapped when these changes are being committed, but other than that the amount of exclusive locks should be minimum
        /*alter table substance rename to substance_trash;
        alter table substance_t rename to substance;
        drop table substance_trash cascade;
        alter table substance rename constraint substance_t_pkey to substance_pkey;
        alter index smiles_hash_idx_t rename to smiles_hash_idx;*/




-- we want to wipe out entries that reference zinc20-stock, but sometimes these entries don't show up in catalog_substance because of the catsub patch
-- as a backup, we want to remove any entries that reference now non-existent substances (e.g ones that were added in zinc20-stock)
-- we will be applying the catsub patch after this to fix anything else that may be broken, but while that is in progress this will give us a reasonably correct catalog_substance table that doesn't have broken foreign keys
/*do
$$
declare
	maxid int;
begin
	select max(sub_id) from substance_t into maxid;
	delete from catalog_substance_t where sub_id_fk > maxid;
end $$;*/

-- wipe out any catalog_substance entries that reference zinc20-stock, since we are wiping out those substances (the catalog_content entries can stay where they are)
/*
delete from catalog_substance_t where cat_content_fk in (select cat_content_id from catalog_content where cat_id_fk in (select cat_id from catalog where name like '%zinc20%'));

create index catalog_substance_sub_id_fk_idx_t on catalog_substance_t (sub_id_fk, tranche_id);
create index catalog_substance_cat_id_fk_idx_t on catalog_substance_t (cat_content_fk);

alter table catalog_substance_t add constraint catalog_substance_cat_itm_fk_fkey_t foreign key (cat_content_fk) references catalog_content (cat_content_id);
alter table catalog_substance_t add constraint catalog_substance_sub_id_fk_fkey_t foreign key (sub_id_fk, tranche_id) references substance_t (sub_id, tranche_id);

-- swap out catalog_substance tables and rename constraints
alter table catalog_substance rename to catalog_substance_trash;
alter table catalog_substance_t rename to catalog_substance;
alter table catalog_substance_trash drop constraint if exists catalog_substance_cat_itm_fk_fkey;
alter table catalog_substance_trash drop constraint if exists catalog_substance_sub_id_fk_fkey;
drop table catalog_substance_trash cascade;

alter table catalog_substance rename constraint catalog_substance_cat_itm_fk_fkey_t to catalog_substance_cat_itm_fk_fkey;
alter table catalog_substance rename constraint catalog_substance_sub_id_fk_fkey_t to catalog_substance_sub_id_fk_fkey;
alter index catalog_substance_sub_id_fk_idx_t rename to catalog_substance_sub_id_fk_idx;
alter index catalog_substance_cat_id_fk_idx_t rename to catalog_substance_cat_id_fk_idx;
*/
--- same thing but for substance table
alter table substance rename to substance_trash;
alter table substance_t rename to substance;
drop table substance_trash cascade;

alter index smiles_hash_idx_t rename to smiles_hash_idx;
alter table substance rename constraint substance_t_pkey to substance_pkey;
--alter table catalog_substance add constraint catalog_substance_sub_id_fk_fkey foreign key (sub_id_fk, tranche_id) references substance(sub_id, tranche_id);

commit;
