LOAD 'auto_explain';
SET auto_explain.log_nested_statements = ON;
SET auto_explain.log_min_duration = 0;
SET client_min_messages to log;
alter table if exists substance rename to substance_t;
alter table if exists catalog_content rename to catalog_content_t;
alter table if exists catalog_substance rename to catalog_substance_t;
alter table if exists catalog_substance_cat rename to catalog_substance_cat_t;

/*begin;

	select logg('starting sub dup correction');
        select find_duplicate_rows_substance();
commit;*/

begin;
        drop index if exists substance_t_smiles_idx;
        alter table substance_t add constraint substance_uniq_smiles unique(smiles);

	alter table substance_t rename to substance;
	alter table catalog_content_t rename to catalog_content;
	alter table catalog_substance_t rename to catalog_substance;
	alter table if exists catalog_substance_cat_t rename to catalog_substance_cat;

	 -- this bit also used to be done in python
        call rename_table_partitions('substance_t', 'substance');
        call rename_table_partitions('catalog_content_t', 'catalog_content');
        call rename_table_partitions('catalog_substance_t', 'catalog_substance');
        call rename_table_partitions('catalog_substance_cat_t', 'catalog_substance_cat');

commit;
