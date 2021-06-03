begin
	--- making sure this init script can be re-used redundantly and not cause problems
	--- mostly for development & testing purposes
	alter table substance drop column if exists tranche_id_fk;
	drop table if exists tranches;
	drop sequence if exists sub_id_seq;
	drop sequence if exists cat_content_id_seq;
	drop sequence if exists cat_sub_itm_id_seq;

	--- update database with tranche information, since multiple tranches may share the same database
	create table tranches(tranche_id smallint, tranche_name varchar);
	copy tranches(tranche_name, tranche_id) from :'tranche_info_f'; --- tranceh_info_f contains the name of each tranche & their id

	create temporary table temp_load_sub(sub_id int, tranche_id smallint);
	copy temp_load_sub(sub_id, tranche_id) from :'tranche_sub_id_f'; --- tranche_sub_id_f contains the sub_id of every substance in database, along with tranche id
	--- tranche_info_f and tranche_sub_id_f are created externally in the 2dload python script

	alter table substance add column tranche_id_fk smallint;
	update substance set tranche_id_fk = temp_load_sub.tranche_id where substance.sub_id = temp_load_sub.sub_id;

	--- create sequences to keep track of sub_id etc. before this was done by the python script
	create sequence sub_id_seq;
	select setval('sub_id_seq', :sub_tot);
	alter table substance alter column sub_id set default nextval('sub_id_seq');

	create sequence cat_content_id_seq;
	select setval('cat_content_id_seq', :sup_tot);
	alter table catalog_content alter column cat_content_id set default nextval('cat_content_id_seq');

	create sequence cat_sub_itm_id_seq;
	select setval('cat_sub_itm_id_seq', :cat_tot);	
	alter table catalog_substance alter column cat_sub_itm_id set default nextval('cat_sub_itm_id_seq');

	--- drop old function-based indexes on substance table (which are inefficient & take forever to build) and replace with column based index
	--- we need to add the columns then update substance table with mol_logp and mol_amw values to make this work
	drop index if exists substance3_logp_idx;
        drop index if exists substance3_mwt_idx;
	alter table substance add column amw real;
        alter table substance add column logp real;
        update table substance set amw = mol_amw(smiles), logp = mol_logp(smiles);
	create index substance3_logp_idx on substance (logp);
	create index substance3_mwt_idx on substance (amw);
commit;
