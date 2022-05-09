-- offending code, thankfully we copied changes to external file so we can reverse them
--copy (insert into substance(smiles, sub_id, tranche_id) (select smiles_in, sub_id, tranche_id from temp_load_mismatch_smi where sub_id_fnd is null) returning smiles, sub_id, tranche_id) to :'new_substances' with delimiter ' ';
--copy (delete from substance sb using temp_load_mismatch_smi tlmm where not tlmm.smiles_fnd is null and sb.smiles = tlmm.smiles_fnd returning tlmm.smiles_in, sb.smiles, tlmm.sub_id, sb.sub_id, tlmm.tranche_id, similarity(tlmm.smiles_in, smiles)) to :'deleted_substances' with delimiter ' ';
--copy (insert into sub_dups_corrections (sub_id_wrong, sub_id_right) (select sub_id, sub_id_fnd from temp_load_mismatch_smi where not sub_id_fnd is null and sub_id_fnd != sub_id) returning sub_id_wrong, sub_id_right) to :'substance_conflicts' with delimiter ' ';

begin;
create temporary table new_substances (
	smiles varchar,
	sub_id bigint,
	tranche_id smallint
);

create temporary table deleted_substances (
	smiles_in varchar,
	smiles_sb varchar,
	sub_id_in bigint,
	sub_id_sb bigint,
	tranche_id smallint,
	subsim real
);

create temporary table substance_conflicts (
	sub_id_wrong bigint,
	sub_id_right bigint
);

copy new_substances from :'new_substances' delimiter ' ';
copy deleted_substances from :'deleted_substances' delimiter ' ';
copy substance_conflicts from :'substance_conflicts' delimiter ' ';

delete from substance sb using new_substances ns where sb.smiles = ns.smiles;
-- luckily, I accidentally saved correct tranche_id info to the substance_conflicts file under "sub_id_right"
-- except for some weird molecules that have spaces in them, which seem to have triggered "sub_id_right" to not be tranche_id, so just filter them out by checking that "sub_id_right" is in tranche_id range
insert into substance(smiles, sub_id, tranche_id) (select ds.smiles_sb, ds.sub_id_sb, sc.sub_id_right as tranche_id from deleted_substances ds left join substance_conflicts sc on sc.sub_id_wrong = ds.sub_id_sb where sc.sub_id_right < 1024);
delete from sub_dups_corrections sdc using substance_conflicts sc where sdc.sub_id_wrong = sc.sub_id_wrong and sdc.sub_id_right = sc.sub_id_right;
commit;
