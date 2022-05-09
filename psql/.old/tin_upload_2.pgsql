begin;
	CREATE TEMPORARY SEQUENCE t_seq_sb;
	CREATE TEMPORARY SEQUENCE t_seq_cs;
	CREATE TEMPORARY SEQUENCE t_seq_cc;

	select setval('t_seq_sb', :sb_count);
	select setval('t_seq_cs', :cs_count);
	select setval('t_seq_cc', :cc_count);

	create temporary sequence t_seq_tl start 1;

	create temporary table temp_load (
		smiles varchar, -- create index
		code varchar, -- create index
		tranche_id smallint,
		cat_id smallint,
		temp_id bigint default nextval('t_seq_tl')
	);

	copy temp_load(smiles, code, cat_id, tranche_id) from :'source_f' delimiter ' ';
	create index tl_smi_idx_t on temp_load using hash(smiles);
	create index tl_code_idx_t on temp_load using hash(code);
	analyze temp_load;

	create temporary table temp_load_ids (
		sub_id bigint,
		code_id bigint,
		tranche_id smallint,
		cat_id smallint,
		temp_id bigint
	);

	explain insert into temp_load_ids (select sb.sub_id, cc.cat_content_id, tl.tranche_id, tl.cat_id, tl.temp_id from temp_load tl left join substance sb on sb.smiles = tl.smiles left join catalog_content cc on cc.supplier_code = tl.code);
	insert into temp_load_ids (select sb.sub_id, cc.cat_content_id, tl.tranche_id, tl.cat_id, tl.temp_id from temp_load tl left join substance sb on sb.smiles = tl.smiles left join catalog_content cc on cc.supplier_code = tl.code);

	create temporary table temp_load_found_both (
		sub_id bigint, --index
		code_id bigint, --index
		tranche_id smallint
	);

	explain insert into temp_load_found_both (select tli.sub_id, tli.code_id, tli.tranche_id from temp_load_ids tli where not tli.sub_id is null and not tli.code_id is null);
	insert into temp_load_found_both (select tli.sub_id, tli.code_id, tli.tranche_id from temp_load_ids tli where not tli.sub_id is null and not tli.code_id is null);
	create index tlfb_sub_id_idx_t on temp_load_found_both(sub_id);
	create index tlfb_code_id_idx_t on temp_load_found_both(code_id);
	analyze temp_load_found_both;

	create temporary table temp_load_no_found_sub (
		smiles varchar, -- create index
		code_id bigint,
		tranche_id smallint,
		cat_id smallint
	);

	explain insert into temp_load_no_found_sub(select tl.smiles, tli.code_id, tli.tranche_id, tli.cat_id from temp_load_ids tli left join temp_load tl on tl.temp_id = tli.temp_id where tli.sub_id is null);
	insert into temp_load_no_found_sub(select tl.smiles, tli.code_id, tli.tranche_id, tli.cat_id from temp_load_ids tli left join temp_load tl on tl.temp_id = tli.temp_id where tli.sub_id is null);
	create index tlns_smi_idx_t on temp_load_no_found_sub using hash(smiles);
	analyze temp_load_no_found_sub;

	create temporary table temp_load_no_found_code (
		sub_id bigint,
		code varchar, -- create index
		tranche_id smallint,
		cat_id smallint
	);

	explain insert into temp_load_no_found_code(select tli.sub_id, tl.code, tli.tranche_id, tli.cat_id from temp_load_ids tli left join temp_load tl on tl.temp_id = tli.temp_id where tli.code_id is null);
	insert into temp_load_no_found_code(select tli.sub_id, tl.code, tli.tranche_id, tli.cat_id from temp_load_ids tli left join temp_load tl on tl.temp_id = tli.temp_id where tli.code_id is null);
	create index tlnc_code_idx_t on temp_load_no_found_code using hash(code);
	analyze temp_load_no_found_code;

	create temporary table temp_load_no_found_both (
		smiles varchar, --index
		code varchar, --index
		tranche_id smallint,
		cat_id smallint
	);

	explain insert into temp_load_no_found_both (select tl.smiles, tl.code, tli.tranche_id, tli.cat_id from temp_load_ids tli left join temp_load tl on tl.temp_id = tli.temp_id where tli.code_id is null and tli.sub_id is null);
	insert into temp_load_no_found_both (select tl.smiles, tl.code, tli.tranche_id, tli.cat_id from temp_load_ids tli left join temp_load tl on tl.temp_id = tli.temp_id where tli.code_id is null and tli.sub_id is null);
	create index tlnb_smi_idx_t on temp_load_no_found_both using hash(smiles);
	create index tlnb_code_idx_t on temp_load_no_found_both using hash(code);
	analyze temp_load_no_found_both;

	create temporary table temp_load_uniq_sub (
		smiles varchar, --index
		sub_id bigint
	);

	create temporary table temp_load_uniq_code (
		code varchar, --index
		code_id bigint
	);

	explain insert into temp_load_uniq_sub (select distinct on (smiles) smiles, nextval('t_seq_sb') sub_id from temp_load_no_found_sub);
	insert into temp_load_uniq_sub (select distinct on (smiles) smiles, nextval('t_seq_sb') sub_id from temp_load_no_found_sub);
	create index tlus_smi_idx_t on temp_load_uniq_sub using hash(smiles);
	analyze temp_load_uniq_sub;

	explain insert into temp_load_uniq_code (select distinct on (code) code, nextval('t_seq_cc') code_id from temp_load_no_found_code);
	insert into temp_load_uniq_code (select distinct on (code) code, nextval('t_seq_cc') code_id from temp_load_no_found_code);
	create index tluc_code_idx_t on temp_load_uniq_code using hash(code);
	analyze temp_load_uniq_code;

	-- now we can create catalog substance pairs
	create temporary table catalog_substance_t (
		sub_id_fk bigint,
		cat_content_fk bigint,
		tranche_id smallint
	);

	-- any sub,code pairs that have a new sub or code by definition must be new to the catalog substance table
	-- for simplicity's sake we are going to assume there are no duplicate pairs. If there are, duplicate pairs will end up in the table, but this is simple to clear up on the frontend of things
	explain insert into catalog_substance_t(sub_id, code_id, tranche_id) (select tlus.sub_id, tlns.code_id, tlns.tranche_id from temp_load_no_found_sub tlns left join temp_load_uniq_sub tlus on tlns.smiles = tlus.smiles where not tlns.code_id is null);
	insert into catalog_substance_t(sub_id, code_id, tranche_id) (select tlus.sub_id, tlns.code_id, tlns.tranche_id from temp_load_no_found_sub tlns left join temp_load_uniq_sub tlus on tlns.smiles = tlus.smiles where not tlns.code_id is null);
	explain insert into catalog_substance_t(sub_id, code_id, tranche_id) (select tlnc.sub_id, tluc.code_id, tlnc.tranche_id from temp_load_no_found_code tlnc left join temp_load_uniq_code tluc on tlnc.code = tluc.code where not tlnc.sub_id is null);
	insert into catalog_substance_t(sub_id, code_id, tranche_id) (select tlnc.sub_id, tluc.code_id, tlnc.tranche_id from temp_load_no_found_code tlnc left join temp_load_uniq_code tluc on tlnc.code = tluc.code where not tlnc.sub_id is null);
	explain insert into catalog_substance_t(sub_id, code_id, tranche_id) (select tlus.sub_id, tluc.code_id, tlnb.tranche_id from temp_load_no_found_both tlnb left join temp_load_uniq_code tluc on tlnb.code = tluc.code left join temp_load_uniq_sub tlus on tlnb.smiles = tlus.smiles);
	insert into catalog_substance_t(sub_id, code_id, tranche_id) (select tlus.sub_id, tluc.code_id, tlnb.tranche_id from temp_load_no_found_both tlnb left join temp_load_uniq_code tluc on tlnb.code = tluc.code left join temp_load_uniq_sub tlus on tlnb.smiles = tlus.smiles);

	-- here is where we join with catalog substance to check that pairs don't already exist (from the set of substance,codes that have counterparts in the database)
	insert into catalog_substance_t (select tli.sub_id, tli.code_id, tli.tranche_id from temp_found_both tlfb left join catalog_substance cs on cs.sub_id_fk = tlfb.sub_id and cs.cat_content_fk = tlfb.code_id where cs.sub_id_fk is null);

rollback;
