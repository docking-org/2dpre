begin;

create table substance_t (
	sub_id int default nextval('sub_id_seq'),
	smiles varchar not null,
	purchasable smallint,
	date_updated date default now(),
	inchikey character(27),
	tranche_id smallint not null default 0
);

insert into substance_t (sub_id, smiles, purchasable, date_updated, tranche_id) (
	select sub_id, smiles::varchar, purchasable, date_updated, tranche_id from substance);

alter table substance_t add primary key (sub_id, tranche_id);
-- new hash index, testing it out. Might considerably increase load performance!
create index smiles_hash_idx_t on substance_t using hash(smiles);

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
                                insert into catalog_substance_t (select * from catalog_substance where cat_content_fk in (select cat_content_id from catalog_content));
                                alter table catalog_substance drop constraint catalog_substance_sub_id_fk_fkey;
                        else
                                insert into catalog_substance_t (select * from catalog_substance where sub_id_fk in (select sub_id from substance_t) and cat_content_id in (select cat_content_id from catalog_content));
                        end if;
                        raise notice 'finished dropping bogus entries, rebuilding table indexes and constraints';
                        create index catalog_substance_cat_id_fk_idx_t on catalog_substance (cat_content_fk);
                        create index catalog_substance_sub_id_fk_idx_t on catalog_substance (sub_id_fk, tranche_id);
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

--- there may be some downtime after the tables are swapped when these changes are being committed, but other than that the amount of exclusive locks should be minimum
        alter table substance rename to substance_trash;
        alter table substance_t rename to substance;
        drop table substance_trash cascade;
        alter table substance rename constraint substance_t_pkey to substance_pkey;
        alter index smiles_hash_idx_t rename to smiles_hash_idx;

commit;

vacuum analyze;
