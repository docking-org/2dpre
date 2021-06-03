begin

	--- prepare temporary tables for loading in data
	create temporary table temp_load(smiles char(64), code char(64), id int, sub_fk int, code_fk int, cat_fk smallint);
	create temporary table temp_load_sb(smiles mol, id int);
	create temporary table temp_load_cc(code char(64), cat_fk smallint, id int);

	alter table temp_load alter column id set default null;
	alter table temp_load_sb alter column id set default null;
	alter table temp_load_cc alter column id set default null;

	--- create temp sequences for loading
	create temporary sequence t_seq_sb;
	select setval('t_seq_sb', currval('sub_id_seq');
	alter table temp_load_sb alter column id set default nextval('t_seq_sb');

	create temporary sequence t_seq_cs;
	select setval('t_seq_cs', currval('cat_sub_itm_id_seq'));
	alter table temp_load_cs alter column id set default nextval('t_seq_cs');

	create temporary sequence t_seq_cc;
	select setval('t_seq_cc', currval('cat_content_id_seq'));
	alter table temp_load_cc alter column id set default nextval('t_seq_cc');	

	create temporary sequence t_seq_load;
	alter table temp_load alter column id set default nextval('t_seq_load');

	--- source_f contains smiles:supplier:cat_id rows, with cat_id being the int describing the catalog the smiles:supplier pair comes from
	copy temp_load(smiles, code, cat_fk) from :'source_f';

	--- load substance data to temp table
	insert into
		temp_load_sb(smiles)
	select
		smiles
	from
		temp_load
	group by
		smiles; --- group by makes sure there are no duplicates in this table

	--- load cat_content data to temp table
	insert into
		temp_load_cc(code, cat_fk)
	select
		code, cat_fk
	from 
		temp_load
	group by
		code; --- make sure unique, same as before

	--- find existing sub_ids, update temp table with them
	update
		temp_load_sb
	set
		id = substance.sub_id
	from
		substance
	where
		substance.smiles = temp_load_sb.smiles;

	--- "create" new sub_ids for compounds not found
	update 
		temp_load_sb
	set
		id = nextval('t_seq_sb')
	where
		id = null;


	--- find existing cat_content_ids
	update
		temp_load_cc
	set
		id = catalog_content.cat_content_id
	from
		catalog_content
	where
		catalog_content.supplier_code = temp_load_cc.code;

	--- "create" ids for new supplier codes
	update
		temp_load_cc
	set
		id = nextval('t_seq_cc')
	where
		id = null;

	--- resolve smiles ids
	update
		temp_load
	set
		sub_fk = temp_load_sb.id
	from
		temp_load_sb
	where
		temp_load.smiles = temp_load_sb.smiles;

	--- resolve code ids
	update
		temp_load
	set
		cat_fk = temp_load_cc.id
	from
		temp_load_cc
	where
		temp_load.code = temp_load_cc.code;

	--- find existing cat_substance entries and resolve cat_sub_itm_id
	update
		temp_load
	set
		id = cs.cat_sub_itm_id
	from
		catalog_substance cs
	where
		temp_load.code_fk <= currval('cat_content_id_seq') and
		temp_load.sub_fk <= currval('sub_id_seq') and
		cs.cat_content_fk = temp_load.cat_fk and
		cs.sub_id_fk = temp_load.sub_fk;

	--- assign cat_sub_itm_id value to new entries
	update
		temp_load
	set
		id = nextval('t_seq_cs')
	where
		id = null;

	--- clone the current tables to create the new ones
	--- these names are appended with _t so they are not confused with the current version
	--- it is necessary to modify a cloned version so that any users of the current table are not locked out
	create table substance_t ( like substance including defaults including constraints including indexes );
	create table catalog_content_t ( like catalog_content including defaults including constraints including indexes );
	create table catalog_substance_t ( like catalog_substance including defaults including constraints including indexes );

	--- now that we've identified all new entries, we want to prepare the database for insertion
	--- with the large volumes of data that we work with, it is faster to disable indexes, insert the data, then rebuild the indexes
	--- we can do this using a little trick
        --- much less verbose than dropping each index then rebuilding individually
        update pg_index set indisvalid = false where indrelid = ( select oid from pg_class where relname = 'substance_t' );
        update pg_index set indisready = false where indrelid = ( select oid from pg_class where relname = 'substance_t' );
        update pg_index set indisvalid = false where indrelid = ( select oid from pg_class where relname = 'catalog_content_t' );
        update pg_index set indisready = false where indrelid = ( select oid from pg_class where relname = 'catalog_content_t' );
        update pg_index set indisvalid = false where indrelid = ( select oid from pg_class where relname = 'catalog_substance_t' );
        update pg_index set indisready = false where indrelid = ( select oid from pg_class where relname = 'catalog_substance_t' );

        --- disable any constraints/triggers to speed up loading - we know we will not violate any of them
        alter table substance_t disable trigger all;
        alter table catalog_content_t disable trigger all;
        alter table catalog_substance_t disable trigger all;

	--- load new substance data in
	insert into 
		substance_t(sub_id, smiles) 
	select 
		id, smiles 
	from 
		temp_load_sb 
	where 
		temp_load_sb.id > currval('sub_id_seq'); --- only insert entries that don't exist yet, i.e their id is > the current table id

	--- new cat_content data...
	insert into 
		catalog_content_t(cat_content_id, supplier_code, cat_id_fk) 
	select 
		id, code, cat_fk
	from 
		temp_load_cc 
	where 
		temp_load_cc.id > currval('cat_content_id_seq'); --- same idea as previous

	--- and finally, cat_substance data
	insert into 
		catalog_substance_t(cat_content_fk, sub_id_fk, cat_sub_itm_id) 
	select 
		code_fk, smiles_fk, id
	from 
		temp_load
	where 
		temp_load.id > currval('cat_sub_itm_id_seq'); --- again, same idea

	--- rebuild indices on the new tables
	reindex table substance_t;
	reindex table catalog_content_t;
	reindex table catalog_substance_t;

	--- re-enable constraints/triggers once we're done
	alter table substance_t enable trigger all;
	alter table catalog_content_t enable trigger all;
	alter table catalog_substance_t enable trigger all;

	--- swap the new table for the old
	alter table substance rename to substance_trash;
	alter table catalog_content rename to catalog_content_trash;
	alter table catalog_substance_t rename to catalog_substance_trash;

	alter table substance_t rename to substance;
	alter table catalog_content_t rename to catalog_content;
	alter table catalog_substance_t rename to catalog_substance;

	--- update sequences with new values
	select setval('sub_id_seq', currval('t_seq_sb'));
	select setval('cat_sub_itm_id_seq', currval('t_seq_cs'));
	select setval('cat_content_id_seq', currval('t_seq_cc'));	

	--- dispose of the old table
        drop table substance_trash;
        drop table catalog_content_trash;
        drop table catalog_substance_trash;
commit;
