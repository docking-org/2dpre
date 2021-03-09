-- we used to perform the copy/index operation on the same table one would run a select query on
-- problem is that this locks the table indexes up for the duration of the copy
-- so this is the new approach

begin;

create or replace function logg(t text) returns integer as $$
begin
	raise info '[%]: %', now(), t;
	return 0;
end;
$$ language plpgsql;

drop table if exists constraint_names;
create table constraint_names(i int, name text, tname text, tabname text);
insert into constraint_names (name, tname, tabname) values
        ('catalog_contents_cat_id_fk_fkey', 'catalog_contents_cat_id_fk_fkey_t', 'catalog_content'),
        ('catalog_substances_cat_itm_fk_fkey', 'catalog_substances_cat_itm_fk_fkey_t', 'catalog_substance'),
        ('catalog_substances_sub_id_fk_fkey', 'catalog_substances_sub_id_fk_fkey_t', 'catalog_substance');

drop table if exists index_names;
create table index_names(i int, name text, tname text, origtable text);
insert into index_names (name, tname, origtable) values
        ('substance_pkey', 'substance_t_pkey', 'substance'),
        ('substance3_logp_idx', 'substance3_logp_idx_t', 'substance'),
        ('substance3_mwt_idx', 'substance3_mwt_idx_t', 'substance'),
        ('catalog_contents_pkey', 'catalog_content_t_pkey', 'catalog_content'),
        ('catalog_item_unique_idx', 'catalog_item_unique_idx_t', 'catalog_content'),
        ('catalog_content_cat_content_id_idx', 'catalog_content_cat_content_id_idx_t', 'catalog_content'),
        ('ix_catalog_contents_content_item_id', 'ix_catalog_contents_content_item_id_t', 'catalog_content'),
        ('ix_catalog_contents_supplier_code_current', 'ix_catalog_contents_supplier_code_current_t', 'catalog_content'),
        ('ix_catalog_item_substance_cur', 'ix_catalog_item_substance_cur_t', 'catalog_content'),
        ('catalog_substances_pkey', 'catalog_substance_t_pkey', 'catalog_substance'),
        ('catalog_substance_unique', 'catalog_substance_unique_t', 'catalog_substance'),
        ('catalog_substance_cat_content_fk_idx', 'catalog_substance_cat_content_fk_idx_t', 'catalog_substance'),
        ('catalog_substance_idx', 'catalog_substance_idx_t', 'catalog_substance_t');

drop table if exists substance_t cascade;
drop table if exists catalog_content_t cascade;
drop table if exists catalog_substance_t cascade;

create table substance_t as table substance;
create table catalog_content_t as table catalog_content;
create table catalog_substance_t as table catalog_substance;

drop table if exists to_copy_substance;
drop table if exists to_copy_supplier;
drop table if exists to_copy_catalog;
create table to_copy_substance(i int, filename text);
create table to_copy_supplier(i int, filename text);
create table to_copy_catalog(i int, filename text);
copy to_copy_substance(filename) from :'to_copy_sub';
copy to_copy_supplier(filename) from :'to_copy_sup';
copy to_copy_catalog(filename) from :'to_copy_cat';

do
$do$
declare
	f1 to_copy_substance%rowtype;
	f2 to_copy_supplier%rowtype;
	f3 to_copy_catalog%rowtype;

begin
	for f1 in select * from to_copy_substance loop
		execute 'copy substance_t (smiles, inchikey, sub_id) from ''' || f1.filename || ''' with (delimiter " ")';
		raise info '[%]: finished copying % to substance table', now(), f1.filename;
	end loop;
	raise info 'finished copying new substance data';

	for f2 in select * from to_copy_supplier loop
		execute 'copy catalog_content_t (supplier_code, cat_content_id, cat_id_fk) from ''' || f2.filename || ''' with (delimiter " ")';
		raise info '[%]: finished copying % to catalog_content table', now(), f2.filename;
	end loop;
	raise info 'finished copying new supplier data';

	for f3 in select * from to_copy_catalog loop
		execute 'copy catalog_substance_t (sub_id_fk, cat_content_fk, cat_sub_itm_id) from ''' || f3.filename || ''' with (delimiter " ")';
		raise info '[%]: finished copying % to catalog_substance table', now(), f3.filename;
	end loop;
	raise info 'finished copying new catalog data';
end;
$do$ language plpgsql;

drop table to_copy_substance;
drop table to_copy_supplier;
drop table to_copy_catalog;

-- due to a small blunder, there will occasionally be duplicate entries in the catalog_substance table
-- can phase this (somewhat expensive) code out once we patch the table, for now this ensures that the upload goes through successfully
do
$$
declare
	rec record;
	dupid int;
begin
	raise notice '[%]: looking for duplicate entries in catalog_substance table', now();
	for rec in select cat_content_fk, sub_id_fk from catalog_substance group by cat_content_fk, sub_id_fk having count(*) > 1 loop
		select cat_sub_itm_id into dupid from catalog_substance where (cat_content_fk = rec.cat_content_fk) and (sub_id_fk = rec.sub_id_fk) limit 1;
		delete from catalog_substance where (cat_sub_itm_id = dupid);
		raise notice '[%]: deleted %', now(), dupid;
	end loop;
end;
$$ language plpgsql;
		

-- enable multithreaded index creation
alter table substance_t set (parallel_workers = 4);
alter table catalog_content_t set (parallel_workers = 4);
alter table catalog_substance_t set (parallel_workers = 4);
set max_parallel_maintenance_workers to 4;

select logg('starting index building: substance');

-- substance indexes
alter table substance_t add primary key (sub_id);
create index "substance3_logp_idx_t" on substance_t (mol_logp(smiles));
create index "substance3_mwt_idx_t" on substance_t (mol_amw(smiles));

select logg('starting index building: catalog_content');

-- supplier indexes
alter table catalog_content_t add primary key (cat_content_id);
create unique index "catalog_item_unique_idx_t" on catalog_content_t (cat_id_fk, supplier_code);
create index "catalog_content_cat_content_id_idx_t" on catalog_content_t (cat_content_id);
create index "ix_catalog_contents_content_item_id_t" on catalog_content_t (cat_content_id, supplier_code) where not depleted;
create index "ix_catalog_contents_supplier_code_current_t" on catalog_content_t (supplier_code) where not depleted;
create index "ix_catalog_item_substance_cur_t" on catalog_content_t (cat_id_fk, cat_content_id) where not depleted;

select logg('starting index building: catalog_substance');

-- catalog indexes
alter table catalog_substance_t add primary key (cat_sub_itm_id);

do $$
declare 
	max_sub_id int;
	max_sup_id int;
begin
	select max(sub_id) into max_sub_id from substance_t;
	select max(cat_content_id) into max_sup_id from catalog_content_t;
	delete from catalog_substance_t where (cat_content_fk > max_sup_id);
	delete from catalog_substance_t where (sub_id_fk > max_sub_id);
	raise notice 'finished deleting invalid entries from catalog_substance';
end $$;

create unique index "catalog_substance_unique_t" on catalog_substance_t (cat_content_fk, sub_id_fk);
create index "catalog_substance_cat_content_fk_idx_t" on catalog_substance_t (cat_content_fk);
create index "catalog_substance_idx_t" on catalog_substance_t (sub_id_fk);

select logg('adding constraints');

-- catalog contents (supplier) foreign keys
alter table catalog_content_t add constraint "catalog_contents_cat_id_fk_fkey_t" foreign key (cat_id_fk) references catalog(cat_id) on delete cascade;
-- catalog substance (catalog) foreign keys
alter table catalog_substance_t add constraint "catalog_substances_cat_itm_fk_fkey_t" FOREIGN KEY (cat_content_fk) REFERENCES catalog_content_t(cat_content_id) ON DELETE CASCADE;
alter table catalog_substance_t add constraint "catalog_substances_sub_id_fk_fkey_t" FOREIGN KEY (sub_id_fk) REFERENCES substance_t(sub_id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;

commit;

select logg('done creating replacement table');

begin;

-- swap out the old table...
alter table substance rename to substance_trash;
alter table catalog_content rename to catalog_content_trash;
alter table catalog_substance rename to catalog_substance_trash;
-- ...for the new one
alter table substance_t rename to substance;
alter table catalog_content_t rename to catalog_content;
alter table catalog_substance_t rename to catalog_substance;

select logg('tables renamed');

/*
-- drop constraints from the old table, this needs to be done
-- just kidding, CASCADE takes care of this, but keeping the code around just in case 
do
$do$
declare
        f index_names%rowtype
        d constraint_names%rowtype
begin
        for f in select * from index_names where tname like '%_pkey%' or tname like '%unique%' loop
                execute 'alter table ' || f.origtable || ' drop constraint if exists ' || f.name;
        end loop;
        for d in select * from constraint_names loop
                execute 'alter table ' || d.tabname || ' drop constraint if exists ' || d.name;
        end loop;
end;
$do$ language plpgsql;
*/

-- delete the old table
drop table substance_trash cascade;
drop table catalog_content_trash cascade;
drop table catalog_substance_trash cascade;

select logg('old tables deleted! swapping out for new data...');

-- rename indexes once old table is dropped
do
$do$
declare
	f index_names%rowtype;
	c constraint_names%rowtype;
begin
	for f in select * from index_names loop
		execute 'alter index ' || f.tname || ' rename to ' || f.name;
	end loop;
	for c in select * from constraint_names loop
		execute 'alter table ' || c.tabname || ' rename constraint ' || c.tname || ' to ' || c.name;
	end loop;
end;
$do$ language plpgsql;

select logg('finished swapping out tables!');

commit;

drop table index_names;
drop table constraint_names;

analyze;
vacuum;
