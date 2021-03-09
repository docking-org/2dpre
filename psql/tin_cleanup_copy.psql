// enable multithreaded index creation
alter table substance_t set (parallel_workers = 4);
alter table catalog_content_t set (parallel_workers = 4);
alter table catalog_substance_t set (parallel_workers = 4);
set max_parallel_maintenance_workers to 4;

// substance indexes
alter table substance_t add primary key (sub_id);
create index "substance3_logp_idx" on substance_t (mol_logp(smiles));
create index "substance3_mwt_idx" on substance_t (mol_amw(smiles));

// supplier indexes
alter table catalog_content_t add primary key (cat_content_id);
create unique index "catalog_item_unique_idx on catalog_content_t" (cat_id_fk, supplier_code);
create index "catalog_content_cat_content_id_idx" (cat_content_id) on catalog_content_t;
create index "ix_catalog_contents_content_item_id" on catalog_content_t (cat_content_id, supplier_code) where not depleted;
create index "ix_catalog_contents_supplier_code_current" on catalog_content_t (supplier_code) where not depleted;
create index "ix_catalog_item_substance_cur" on catalog_content_t (cat_id_fk, cat_content_id) where not depleted;

// catalog indexes
alter table catalog_substance_t add primary key (cat_sub_itm_id)
create unique index "index catalog_substance_unique on catalog_substance_t" (cat_content_fk, sub_id_fk);
create index "catalog_substance_cat_content_fk_idx" on catalog_substance_t (cat_content_fk);
create index "catalog_substance_idx" on catalog_substance_t (sub_id_fk);

// catalog contents (supplier) foreign keys
alter table catalog_content_t add constraint "catalog_contents_cat_id_fk_fkey foreign key" (cat_id_fk) references catalog(cat_id) on delete cascade;
// catalog substance (catalog) foreign keys
alter table catalog_substance_t add constraint "catalog_substances_cat_itm_fk_fkey" FOREIGN KEY (cat_content_fk) REFERENCES catalog_content(cat_content_id) ON DELETE CASCADE;
alter table catalog_substance_t add constraint "catalog_substances_sub_id_fk_fkey" FOREIGN KEY (sub_id_fk) REFERENCES substance(sub_id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

// swap out the old table...
alter table substance rename to substance_trash;
alter table catalog_content rename to catalog_content_trash;
alter table catalog_substance rename to catalog_substance_trash;
// ...for the new one
alter table substance_t rename to substance;
alter table catalog_content_t rename to catalog_content;
alter talbe catalog_substance_t rename to catalog_substance;
// delete the old table
drop table substance_trash;
drop table catalog_content_trash;
drop table catalog_substance_trash;

vacuum;
analyze;
