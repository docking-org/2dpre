begin;

	create temporary sequence tl_seq_t start 1;

	create temporary table temp_load (
		smiles varchar,
		code varchar,
		tranche_id smallint,
		cat_id smallint,
		temp_id bigint default nextval('tl_seq_t')
	);

	create temporary table temp_load_ids (
		sub_id bigint,
		code_id bigint,
		tranche_id smallint,
		temp_id bigint
	);

	copy temp_load(smiles, code, tranche_id, cat_id) from :'source_f';
	create index tl_smi_hash_idx_t on temp_load using hash(smiles);
	create index tl_cod_hash_idx_t on temp_load using hash(code);
	alter table temp_load add primary key (temp_id);
	analyze temp_load;

	explain insert into temp_load_ids (select sb.sub_id, cc.cat_content_id, sb.tranche_id, tl.temp_id from temp_load tl left join catalog_content cc on cc.supplier_code = t.code left join substance sb on sb.smiles = tl.smiles);
	insert into temp_load_ids (select t.sub_id, cc.cat_content_id, t.tranche_id, t.temp_id from (select sb.sub_id, sb.tranche_id, tl.code, tl.temp_id from temp_load tl left join substance sb on tl.smiles = sb.smiles) t left join catalog_content cc on cc.supplier_code = t.code);
	alter table temp_load_ids add primary key (temp_id);
	alter table temp_load_ids add constraint fk_temp_id foreign key (temp_id) references temp_load(temp_id);
	create index tli_sub_id_idx_t on temp_load_ids(sub_id);
	create index tli_code_id_idx_t on temp_load_ids(code_id);
	analyze temp_load_ids;

	create temporary table tl_new_smiles (
		smiles varchar,
		sub_id bigint,
		tranche_id smallint
	);

	explain insert into tl_new_smiles (select distinct on (t.smiles) t.smiles, nextval('t_seq_sub_id') sub_id, t.tranche_id from (select tl.smiles, tl.tranche_id from temp_load_ids tli left join temp_load tl on temp_id where tli.sub_id is null) t);
	insert into tl_new_smiles (select distinct on (t.smiles) t.smiles, nextval('t_seq_sub_id') sub_id, t.tranche_id from (select tl.smiles, tl.tranche_id from temp_load_ids tli left join temp_load tl on temp_id where tli.sub_id is null) t);
	create index tl_new_smiles_hash_idx_t on tl_new_smiles using hash(smiles);
	analyze tl_new_smiles;

	create temporary table tl_new_codes (
		code varchar,
		code_id bigint,
		cat_id smallint
	);

	explain insert into tl_new_codes (select distinct on (t.code) t.code, nextval('t_seq_code_id') code_id, t.cat_id from (select tl.code, tl.cat_id from temp_load_ids tli left join temp_load tl on temp_id where tli.code_id is null) t);
	insert into tl_new_codes (select distinct on (t.code) t.code, nextval('t_seq_code_id') code_id, t.cat_id from (select tl.code, tl.cat_id from temp_load_ids tli left join temp_load tl on temp_id where tli.code_id is null) t);
	create index tl_new_codes_hash_idx_t on tl_new_codes using hash(code);
	analyze tl_new_codes;


	create temporary table tl_ids_no_sub (
		sub_id bigint,
		code_id bigint,
		tranche_id smallint
	);

	insert into tl_ids_no_sub (select tlns.sub_id, 

	create temporary table tl_ids_no_code (
		sub_id bigint,
		code_id bigint,
		tranche_id smallint
	);

	create temporary table tl_ids_neither (
		sub_id bigint,
		code_id bigint,
		tranche_id smallint
	);

	create temporary table tl_new_ids (
		sub_id bigint,
		code_id bigint,
		tranche_id smallint
	);

	-- first deal with sub,code pairs that have been resolved
	insert into tl_new_ids (select t.sub_id, t.code_id from (select * from temp_load_ids where not sub_id is null and not code_id is null) t left join catalog_substance cs on t.sub_id = cs.sub_id_fk and t.code_id = cs.cat_content_fk);

	insert into tl_new_ids (select tlns.sub_id, tlnc.code_id, tlns.tranche_id from tl_new_smiles tlns, tl_new_codes tlnc, temp_load tl where tlns.smiles = tl.smiles or tlnc.code = tl.code);
	-- now with sub,code pairs that aren't resolved yet
	-- insert into tl_new_ids (select t.smiles, t.code, t.tranche_id, t.cat_id from (select tlns.sub_id, tl.code, tl.tranche_id from tl_new_smiles tlns, temp_load tl where tlns.smiles = tl.smiles) t, tl_new_codes tlnc where t.code = tlnc.code);

commit;
