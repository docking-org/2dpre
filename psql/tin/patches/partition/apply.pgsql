LOAD 'auto_explain';
SET auto_explain.log_nested_statements = ON;
SET auto_explain.log_min_duration = 0;
SET client_min_messages to LOG;

begin;

	-- this bit used to be done in python, moving it to postgres
	-- delete from meta where svalue = 'n_partitions' or varname = 'n_partitions';
	-- insert into meta (values ('n_partitions', 'n_partitions', :n_partitions));

	-- create table substance_t (like substance including defaults) partition by hash(smiles);
	-- create table catalog_content_t (like catalog_content including defaults) partition by hash(supplier_code);
	-- create table catalog_substance_t (like catalog_substance including defaults) partition by hash(sub_id_fk);
	-- create table catalog_substance_cat_t (like catalog_substance including defaults) partition by hash(cat_content_fk);

	-- call create_table_partitions('substance_t', '');
	-- call create_table_partitions('catalog_content_t', '');
	-- call create_table_partitions('catalog_substance_t', '');
	-- call create_table_partitions('catalog_substance_cat_t', '');
	-- end bit that used to be done in python

	--explain insert into substance_t(smiles, sub_id, tranche_id, date_updated) (select smiles, sub_id, tranche_id, date_updated from substance);
	-- insert into substance_t(smiles, sub_id, tranche_id, date_updated) (select smiles, sub_id, tranche_id, date_updated from substance);
	-- create index substance_t_smiles_idx on substance_t(smiles); -- indexes will be useful for identifying duplicates & removing them
	-- create index on substance_t(sub_id); -- will see if rebuilding them after the delete is worth or not, but with limited partition size it should be fine
	-- analyze substance_t;

	--explain insert into catalog_content_t(supplier_code, cat_content_id, cat_id_fk) (select supplier_code, cat_content_id, cat_id_fk from catalog_content);
	-- insert into catalog_content_t(supplier_code, cat_content_id, cat_id_fk) (select supplier_code, cat_content_id, cat_id_fk from catalog_content);
	-- create index catcontent_t_code_idx on catalog_content_t(supplier_code);
	-- create index on catalog_content_t(cat_content_id);
	-- analyze catalog_content_t;

	-- drop table if exists sub_dups_corrections;
	-- drop table if exists cat_dups_corrections;

	-- don't insert into catalog_substance_t just yet, we want to identify duplicates first
	-- keep these tables around, they may become useful
	create table sub_dups_corrections (
		sub_id_wrong bigint,
		sub_id_right bigint
	);

	create table tranche_id_corrections (
		sub_id bigint,
		tranche_id_wrong smallint
	);

	create table cat_dups_corrections (
		code_id_wrong bigint,
		code_id_right bigint
	);

	create table catsub_dups_corrections (
		cat_sub_itm_id bigint
	);

	-- select logg('starting sub dup correction');
	-- select find_duplicate_rows_substance();
	-- drop index substance_t_smiles_idx;
	-- alter table substance_t add constraint substance_uniq_smiles unique(smiles);
	-- select logg('starting cat dup correction');
	-- select find_duplicate_rows_catcontent();
	-- drop index catcontent_t_code_idx;
	-- alter table catalog_content_t add constraint catalog_content_uniq_code unique(supplier_code);
	-- select logg('finished cat dup correction');
	-- select logg('creating indexes on dup data');
	-- create index sdc_sub_id_idx_t on sub_dups_corrections(sub_id_wrong);
	-- create index cdc_code_id_idx_t on cat_dups_corrections(code_id_wrong);

	-- select logg('creating catsub tables');
	-- insert into catalog_substance_t(sub_id_fk, cat_content_fk, tranche_id) (
		--select 
		--	case when not sub_id_wrong is null then sub_id_right else sub_id_fk end, 
		--	case when not code_id_wrong is null then code_id_right else cat_content_fk end,
		--	tranche_id 
	--	from catalog_substance cs 
	--		left join sub_dups_corrections sdc on cs.sub_id_fk = sdc.sub_id_wrong 
	--		left join cat_dups_corrections cdc on cs.cat_content_fk = cdc.code_id_wrong
	-- );
	--create index cat_sub_code_idx on catalog_substance_t(cat_content_fk);
	--create index cat_sub_sub_idx on catalog_substance_t(sub_id_fk);
	-- select find_duplicate_rows_catsubstance();

	-- select count(*) from sub_dups_corrections;
	-- select count(*) from cat_dups_corrections;
	-- select count(*) from catsub_dups_corrections;
	
	--insert into catalog_substance_cat_t (select * from catalog_substance_t);
	--create index cat_sub_cat_code_idx on catalog_substance_cat_t(cat_content_fk);
	--create index cat_sub_cat_sub_idx on catalog_substance_cat_t(sub_id_fk);
	--select logg('finished! finalizing...');

	--drop table substance cascade;
	--drop table catalog_content cascade;
	--drop table catalog_substance cascade;

	--alter table substance_t rename to substance;
	--alter table catalog_content_t rename to catalog_content;
	--alter table catalog_substance_t rename to catalog_substance;
	--alter table catalog_substance_cat_t rename to catalog_substance_cat;

	--create sequence sub_id_seq owned by substance.sub_id;

	-- this bit also used to be done in python
	--call rename_table_partitions('substance_t', 'substance');
	--call rename_table_partitions('catalog_content_t', 'catalog_content');
	--call rename_table_partitions('catalog_substance_t', 'catalog_substance');
	--call rename_table_partitions('catalog_substance_cat_t', 'catalog_substance_cat');

commit;

-- analyze substance;
-- analyze catalog_content;
-- analyze catalog_substance;
-- analyze catalog_substance_cat;

-- vacuum;
