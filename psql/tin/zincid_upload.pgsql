LOAD 'auto_explain';
LOAD 'pg_trgm';
SET auto_explain.log_nested_statements = ON;
SET auto_explain.log_min_duration = 250;
SET client_min_messages to log;
set enable_partitionwise_aggregate=on; -- doesn't seem to do much, but may help certain queries
set enable_partitionwise_join=on; -- why do they keep all these optimization features hidden behind options???
create extension if not exists pg_trgm;

/*
this may need some explaining
input is a list of zincid,smiles (sub_id,smiles,tranche_id)

*/
begin;

	/*
	-- created externally with partitions
	create temporary table temp_load (
		smiles varchar,
		sub_id bigint,
		tranche_id smallint
	) partition by smiles;
	*/

	-- copying over should also be done externally
	-- copy temp_load(sub_id, tranche_id, smiles) from :'source_f' delimiter ' ';
	-- analyze temp_load;

	/*
	-- again, created externally
	create temporary table temp_load_p2 (
		sub_id_orig bigint,
		sub_id_src bigint,
		min_sub_id_src bigint,
		smiles varchar,
		tranche_id smallint
	) partition by smiles;*/

	create temporary table temp_load (
		smiles varchar,
		sub_id bigint,
		tranche_id smallint
	) partition by hash(sub_id);

	call create_table_partitions('temp_load', 'temporary');
	copy temp_load(sub_id, tranche_id, smiles) from :'source_f' delimiter ' ';

	create temporary table temp_load_fnd (
		smiles varchar,
		sub_id bigint,
		tranche_id smallint
	) partition by hash(sub_id);

	call create_table_partitions('temp_load_fnd', 'temporary');

	call get_many_substances_by_id('temp_load', 'temp_load_fnd');

	-- entries inserted to this table *should* be fairly few and far-between
	-- mainly we are looking for a specific anomaly from substances that had backslashes accidentally removed
	create temporary table temp_load_mismatch_smi (
		smiles_in varchar,
		smiles_fnd varchar,
		sub_id bigint,
		sub_id_fnd bigint,
		tranche_id smallint
	) partition by hash(smiles_in);

	call create_table_partitions('temp_load_mismatch_smi', 'temporary');

	-- select distinct on sub_id, since I've noticed some odd cases where there are duplicate zinc ids in the source file
	-- this should fix those
	insert into temp_load_mismatch_smi(smiles_in, smiles_fnd, sub_id, tranche_id) (select distinct on (t.sub_id) t.smiles_in, t.smiles_fnd, t.sub_id, t.tranche_id from (select tl.smiles as smiles_in, tlf.smiles as smiles_fnd, tl.sub_id, tl.tranche_id from temp_load tl left join temp_load_fnd tlf on tl.sub_id = tlf.sub_id where tl.smiles != tlf.smiles) t);
        drop table temp_load;
        drop table temp_load_fnd;

	update temp_load_mismatch_smi tlmm set sub_id_fnd = sb.sub_id from substance sb where sb.smiles = tlmm.smiles_in;
	-- assume: smiles_fnd != smiles_in, sub_id != sub_id_fnd

	-- case 1
	-- sub_id_fnd not null, smiles_fnd not null wrong is smiles_in
	--	delete smiles_in, insert sub_id_fnd,sub_id into corrections

	-- case 2
	-- sub_id_fnd not null, smiles_fnd not null wrong is smiles_fnd
	-- 	delete smiles_fnd, insert sub_id,sub_id_fnd into corrections

	-- case 3
	-- sub_id_fnd not null, smiles_fnd null
	--	insert sub_id,sub_id_fnd into corrections

	-- case 4
	-- sub_id_fnd null smiles_fnd not null wrong is smiles_fnd
	--	delete smiles_fnd, insert smiles_in into substance

	-- case 5
	-- sub_id_fnd null smiles_fnd null
	--	insert smiles_in,sub_id into substance

	-- case 1- found different counterparts for smiles & sub_id on database, smiles input is incorrect compared to found smiles
	-- response: assume found smiles is correct, delete smiles input from database and remap found sub_id to sub_id
	create temporary table case1 (
		smiles_in varchar,
		smiles_fnd varchar,
		sub_id_fnd bigint,
		sub_id bigint,
		smisim real
	);

	-- case 2- found different counterparts for smiles & sub_id on database, smiles input is correct compared to found smiles
	-- response: assume input smiles is correct, delete found smiles from database and map sub_id to found sub_id
	create temporary table case2 (
		smiles_fnd varchar,
		smiles_in varchar,
		sub_id bigint,
		sub_id_fnd bigint,
		smisim real
	);

	-- case 3- found smiles on database (sub_id_fnd) but not sub_id, therefore map sub_id -> sub_id_fnd
	create temporary table case3 (
		sub_id bigint,
		sub_id_fnd bigint
	);

	-- case 4- found sub_id on database (smiles_fnd) but not smiles (sub_id_fnd) and smiles_fnd is wrong, therefore delete smiles_fnd and replace with smiles_in
	create temporary table case4 (
		smiles_fnd varchar,
		smiles_in varchar,
		sub_id bigint,
		tranche_id smallint,
		smisim real
	);

	-- case 5- found no counterparts on database, insert as a new molecule
	create temporary table case5 (
		smiles varchar,
		sub_id bigint,
		tranche_id smallint
	);

	create or replace function countchar(s text, c char) returns int as $$
		declare
			r int;
		begin
			select (CHAR_LENGTH(s) - CHAR_LENGTH(REPLACE(s, c, ''))) into r;
			return r;
		end;
	$$ language plpgsql;

	copy (insert into case1(smiles_in, smiles_fnd, sub_id_fnd, sub_id, smisim) (
		select smiles_in, smiles_fnd, sub_id_fnd, sub_id, similarity(smiles_in, smiles_fnd) from temp_load_mismatch_smi tlmm where not sub_id_fnd is null and not smiles_fnd is null and countchar(smiles_in, '\')<countchar(smiles_fnd, '\')
	) returning *) to :'case1';

	copy (insert into case2(smiles_fnd, smiles_in, sub_id, sub_id_fnd, smisim) (
		select smiles_fnd, smiles_in, sub_id, sub_id_fnd, similarity(smiles_in, smiles_fnd) from temp_load_mismatch_smi tlmm where not sub_id_fnd is null and not smiles_fnd is null and countchar(smiles_fnd, '\')<=countchar(smiles_in, '\') -- the final <= here means that on tie, we should trust the input as correct
	) returning *) to :'case2';
	
	copy (insert into case3(sub_id, sub_id_fnd) (
		select sub_id, sub_id_fnd from temp_load_mismatch_smi tlmm where not sub_id_fnd is null and smiles_fnd is null
	) returning *) to :'case3';

	copy (insert into case4(smiles_fnd, smiles_in, sub_id, tranche_id, smisim) (
		select smiles_fnd, smiles_in, sub_id, tranche_id, similarity(smiles_in, smiles_fnd) from temp_load_mismatch_smi tlmm where sub_id_fnd is null and not smiles_fnd is null and countchar(smiles_fnd, '\')<countchar(smiles_in, '\')
	) returning *) to :'case4';

	copy (insert into case5(smiles, sub_id, tranche_id) (
		select smiles_in, sub_id, tranche_id from temp_load_mismatch_smi tlmm where smiles_fnd is null and sub_id_fnd is null
	) returning *) to :'case5';

	-- case 6- found smiles_fnd but not sub_id_fnd and smiles_fnd is correct, therefore don't change anything
	-- won't change the database, but should be logged for posterity
	copy (select smiles_fnd, smiles_in, sub_id, tranche_id, similarity(smiles_in, smiles_fnd) from temp_load_mismatch_smi tlmm where sub_id_fnd is null and not smiles_fnd is null and countchar(smiles_fnd, '\')>countchar(smiles_in, '\')) to :'case6';

	
	copy (
		delete from substance sb using (select smiles_in as smi from case1 union all select smiles_fnd as smi from case2 union all select smiles_fnd as smi from case4) t where sb.smiles = t.smi returning *
	) to :'deleted_substances';

	copy (
		insert into sub_dups_corrections(sub_id_wrong, sub_id_right) (select sub_id_fnd sw, sub_id sr from case1 union all select sub_id sw, sub_id_fnd sr from case2 union all select sub_id sw, sub_id_fnd sr from case3) returning *
	) to :'substance_conflicts';
	update sub_dups_corrections set sub_id_right = t.sr from (select sub_id_fnd sw, sub_id sr from case1 union all select sub_id sw, sub_id_fnd sr from case2 union all select sub_id sw, sub_id_fnd sr from case3) t where sub_id_right = t.sw;

	copy (
		insert into substance(smiles, sub_id, tranche_id) (select smiles_in as smiles, sub_id, tranche_id from case4 union all select smiles, sub_id, tranche_id from case5) returning *
	) to :'new_substances';

	/* -- deletes inserts updates broken down between cases in this block
	-- more efficient to bundle together all the insert update etc. transactions, makes it convenient to write a backup diff in case things go wrong
	delete from substance sb using case1 where sb.smiles = case1.smiles_in;
	insert into sub_dups_corrections(sub_id_wrong, sub_id_right) (select sub_id_fnd, sub_id from case1);
	update sub_dups_corrections sdc set sub_id_right = sub_id using case1 where sub_id_right = sub_id_fnd; -- do this so that the corrections table does not reference itself

	delete from substance sb using case2 where sb.smiles = case2.smiles_fnd;
	insert into sub_dups_corrections(sub_id_wrong, sub_id_right) (select sub_id, sub_id_fnd from case2);
	update sub_dups_corrections sdc set sub_id_right = sub_id_fnd using case2 where sub_id_right = sub_id;

	insert into sub_dups_corrections(sub_id_wrong, sub_id_right) (select sub_id, sub_id_fnd from case3);
	update sub_dups_corrections sdc set sub_id_right = sub_id_fnd using case3 where sub_id_right = sub_id;

	delete from substance sb using case4 where sb.smiles = case4.smiles_fnd;
	insert into substance(smiles, sub_id, tranche_id) (select smiles_in, sub_id, tranche_id from case4);

	insert into substance(smiles, sub_id, tranche_id) (select smiles, sub_id, tranche_id from case5);
	*/	

	--copy (insert into substance(smiles, sub_id, tranche_id) (select smiles_in, sub_id, tranche_id from temp_load_mismatch_smi where sub_id_fnd is null) returning smiles, sub_id, tranche_id) to :'new_substances' with delimiter ' ';
	--copy (delete from substance sb using temp_load_mismatch_smi tlmm where not tlmm.smiles_fnd is null and sb.smiles = tlmm.smiles_fnd returning tlmm.smiles_in, sb.smiles, tlmm.sub_id, sb.sub_id, tlmm.tranche_id, similarity(tlmm.smiles_in, smiles)) to :'deleted_substances' with delimiter ' ';
	--copy (insert into sub_dups_corrections (sub_id_wrong, sub_id_right) (select sub_id, sub_id_fnd from temp_load_mismatch_smi where not sub_id_fnd is null and sub_id_fnd != sub_id) returning sub_id_wrong, sub_id_right) to :'substance_conflicts' with delimiter ' ';

	-- insert into temp_load_mismatch_smi where smiles_in != smiles_found left join substance on
	--



	/*
	do $$
		declare
			i int;
			n_partitions int;
		begin
			select ivalue from tin_meta where svalue = 'n_partitions' limit 1 into n_partitions;
			for i in (0..n_partitions) loop
				execute(format('insert into temp_load_p2(smiles_in, smiles_fnd, sub_id, tranche_id) (select tl.smiles, tlf.smiles, tl.sub_id, tl.tranche_id from temp_load_p%s tl left join temp_load_fnd_p%s tlf on tl.sub_id = tlf.sub_id)', i, i));
	*/
/*
	create or replace function process_zincids_bypart(part int) returns int as $$
		begin
			create temporary table temp_load_part_zincid (
				smiles text,
				sub_id_src bigint,
				sub_id_orig bigint,
				min_sub_id_src bigint,
				tranche smallint
			);

			
			execute(format('insert into temp_load_part_zincid (select sb.sub_id, tl.sub_id, min(tl.sub_id) over (partition by tl.smiles) as min_sub_id_src, tl.smiles, tl.tranche_id from temp_load_part_zincid tl left join substance_p%s sb on tl.smiles = sb.smiles)', part));

			




	insert into temp_load_p2 (select sb.sub_id, tl.sub_id, min(tl.sub_id) over (partition by tl.smiles) as min_sub_id_src, tl.smiles, tl.tranche_id from temp_load tl left join substance sb on tl.smiles = sb.smiles);
	drop table temp_load;
	create index tl_nomatch_smiles_idx on temp_load_p2(sub_id_src) where sub_id_orig is null and sub_id_src = min_sub_id_src;
	create index tl_match_smiles_idx on temp_load_p2(sub_id_src) where sub_id_orig != min_sub_id_src;
	analyze temp_load_p2;

	update sub_dups_corrections set sub_id_right = min_sub_id_src from (select * from temp_load_p2 where min_sub_id_src != sub_id_orig and min_sub_id_src = sub_id_src) t where sub_id_right = sub_id_orig;
	insert into sub_dups_corrections(sub_id_wrong, sub_id_right) (select case when sub_id_src = min_sub_id_src then sub_id_orig else sub_id_src end, min_sub_id_src from temp_load_p2 tl where min_sub_id_src != sub_id_orig);
	insert into sub_dups_corrections(sub_id_wrong, sub_id_right) (select sub_id_src, min_sub_id_src from (select * from temp_load_p2 where sub_id_src != min_sub_id_src) tl left join sub_dups_corrections sdc on tl.sub_id_src = sdc.sub_id_wrong and tl.min_sub_id_src = sdc.sub_id_right where sdc.sub_id_wrong is null);
	update substance set sub_id = min_sub_id_src from (select sub_id_orig, min_sub_id_src from temp_load_p2 tl where sub_id_src = min_sub_id_src and sub_id_orig != min_sub_id_src) t where sub_id = sub_id_orig;

	-- delete anything already existing in substance with sub id matching
	delete from substance sb using (select sub_id_src from temp_load_p2 where sub_id_orig is null and sub_id_src = min_sub_id_src) t where t.sub_id_src = sb.sub_id;
	insert into substance(smiles, sub_id, tranche_id) (select smiles, sub_id_src, tranche_id from temp_load_p2 where sub_id_orig is null and sub_id_src = min_sub_id_src);
*/
commit;

vacuum;
