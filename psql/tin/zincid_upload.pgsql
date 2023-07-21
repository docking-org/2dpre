LOAD 'auto_explain';
LOAD 'pg_trgm';
SET auto_explain.log_nested_statements = ON;
SET auto_explain.log_min_duration = 250;
SET client_min_messages to log;
set enable_partitionwise_aggregate=on; -- doesn't seem to do much, but may help certain queries
set enable_partitionwise_join=on;
create extension if not exists pg_trgm;
/*
this may need some explaining
input is a list of zincid,smiles (sub_id,smiles,tranche_id)
*/
begin;
	create temporary table oid_to_pfk(toid int, pfk smallint);
        insert into oid_to_pfk(toid, pfk) (select inhrelid, replace(inhrelid::regclass::text, 'substance_p', '')::int from pg_catalog.pg_inherits where inhparent = 'public.substance'::regclass);
        insert into oid_to_pfk(toid, pfk) (select inhrelid, replace(inhrelid::regclass::text, 'catalog_content_p', '')::int from pg_catalog.pg_inherits where inhparent = 'public.catalog_content'::regclass);

	select logg('starting!');
	create temporary table case1_all (
		smiles_in varchar,
		smiles_fnd varchar,
		sub_id_fnd bigint,
		sub_id bigint,
		smisim real
	);
	-- case 2- found different counterparts for smiles & sub_id on database, smiles input is correct compared to found smiles
	-- response: assume input smiles is correct, delete found smiles from database and map sub_id to found sub_id
	create temporary table case2_all (
		smiles_fnd varchar,
		smiles_in varchar,
		sub_id bigint,
		sub_id_fnd bigint,
		smisim real
	);
	-- case 3- found smiles on database (sub_id_fnd) but not sub_id, therefore map sub_id -> sub_id_fnd
	create temporary table case3_all (
		sub_id bigint,
		sub_id_fnd bigint
	);
	-- case 4- found sub_id on database (smiles_fnd) but not smiles (sub_id_fnd) and smiles_fnd is wrong, therefore delete smiles_fnd and replace with smiles_in
	create temporary table case4_all (
		smiles_fnd varchar,
		smiles_in varchar,
		sub_id bigint,
		tranche_id smallint,
		smisim real
	);
	-- case 5- found no counterparts on database, insert as a new molecule
	create temporary table case5_all (
		smiles varchar,
		sub_id bigint,
		tranche_id smallint
	);
	create temporary table case6_all (like case4_all);
	create or replace function countchar(s text, c char) returns int as $$
		declare
			r int;
		begin
			select (CHAR_LENGTH(s) - CHAR_LENGTH(REPLACE(s, c, ''))) into r;
			return r;
		end;
	$$ language plpgsql;
	drop table if exists temp_load_fnd;
	create temporary table temp_load_fnd (
		smiles varchar,
		sub_id bigint,
		tranche_id smallint
	) partition by hash(sub_id);
	call create_table_partitions('temp_load_fnd', 'temporary');
	create temporary table temp_load_mismatch_smi (
		smiles_in varchar,
		smiles_fnd varchar,
		sub_id bigint,
		sub_id_fnd bigint,
		tranche_id smallint
	) partition by hash(smiles_in);
	call create_table_partitions('temp_load_mismatch_smi', 'temporary');
	-- define main procedure here- we will loop over it a number of times, with decreasing numbers of molecules (size of which depends on input)
	create or replace procedure process_zinc_id_upload() as $$
	declare
		n_partitions int;
		i int;
		j int;
		k int;
		n int;
		msg text;
	begin
		call get_many_substances_by_id('stage3', 'temp_load_fnd');
		-- entries inserted to this table *should* be fairly few and far-between
		-- mainly we are looking for a specific anomaly from substances that had backslashes accidentally removed - at one point, but we're also using this operation to merge missing & possibly conflicting ids from the 3D source files
		-- DONT select distinct, because it is always slow. i dont think postgres optimizes it for the partitions, unfortunately
		-- must guarantee distinct zinc ids beforehand (& distinct smiles!)
		insert into temp_load_mismatch_smi(smiles_in, smiles_fnd, sub_id, tranche_id) (select t.smiles_in, t.smiles_fnd, t.sub_id, t.tranche_id from (select tl.smiles as smiles_in, tlf.smiles as smiles_fnd, tl.sub_id, tl.tranche_id from stage3 tl left join temp_load_fnd tlf on tl.sub_id = tlf.sub_id where tl.smiles != tlf.smiles or tlf.smiles is NULL) t);
		-- postgres creates a very ugly plan for this update by default, so we "fix" it here and do it partitionwise
		select count(*) from stage3 into k;
		select count(*) from temp_load_fnd into j;
		select count(*) from temp_load_mismatch_smi into i;
		select smiles from temp_load_fnd into msg;
		select sub_id from temp_load_fnd into n;
		raise notice 'found % mismatched, % total fnd, % total; smiles samp=% sub_id=%', i, j, k, msg, n;
		select ivalue from meta where svalue = 'n_partitions' into n_partitions;
		for i in 0..n_partitions-1 loop
			execute('update temp_load_mismatch_smi_p' || i::text || ' tlmm set sub_id_fnd = sb.sub_id from substance_p' || i::text || ' sb where sb.smiles = tlmm.smiles_in');
			raise notice 'updating %', i;
		end loop;
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
		create temporary table case1 (like case1_all);
		-- case 2- found different counterparts for smiles & sub_id on database, smiles input is correct compared to found smiles
		-- response: assume input smiles is correct, delete found smiles from database and map sub_id to found sub_id
		create temporary table case2 (like case2_all);
		-- case 3- found smiles on database (sub_id_fnd) but not sub_id, therefore map sub_id -> sub_id_fnd
		create temporary table case3 (like case3_all);
		-- case 4- found sub_id on database (smiles_fnd) but not smiles (sub_id_fnd) and smiles_fnd is wrong, therefore delete smiles_fnd and replace with smiles_in
		create temporary table case4 (like case4_all);
		-- case 5- found no counterparts on database, insert as a new molecule
		create temporary table case5 (like case5_all);
		-- case 6- counterpart of case4
		create temporary table case6 (like case6_all);
		insert into case1(smiles_in, smiles_fnd, sub_id_fnd, sub_id, smisim) (
			select smiles_in, smiles_fnd, sub_id_fnd, sub_id, similarity(smiles_in, smiles_fnd) from temp_load_mismatch_smi tlmm where not sub_id_fnd is null and not smiles_fnd is null and countchar(smiles_in, '\')<=countchar(smiles_fnd, '\'));
		insert into case2(smiles_fnd, smiles_in, sub_id, sub_id_fnd, smisim) (
			select smiles_fnd, smiles_in, sub_id, sub_id_fnd, similarity(smiles_in, smiles_fnd) from temp_load_mismatch_smi tlmm where not sub_id_fnd is null and not smiles_fnd is null and countchar(smiles_fnd, '\')<countchar(smiles_in, '\')); -- the final <= here means that on tie, we should trust the input as correct
		
		insert into case3(sub_id, sub_id_fnd) (
			select sub_id, sub_id_fnd from temp_load_mismatch_smi tlmm where not sub_id_fnd is null and smiles_fnd is null);
		insert into case4(smiles_fnd, smiles_in, sub_id, tranche_id, smisim) (
			select smiles_fnd, smiles_in, sub_id, tranche_id, similarity(smiles_in, smiles_fnd) from temp_load_mismatch_smi tlmm where sub_id_fnd is null and not smiles_fnd is null and countchar(smiles_fnd, '\')<countchar(smiles_in, '\'));
		insert into case5(smiles, sub_id, tranche_id) (
			select smiles_in, sub_id, tranche_id from temp_load_mismatch_smi tlmm where smiles_fnd is null and sub_id_fnd is null);
		-- case 6- found smiles_fnd but not sub_id_fnd and smiles_fnd is correct, therefore don't change anything
		-- won't change the database, but should be logged for posterity
		insert into case6(smiles_fnd, smiles_in, sub_id, tranche_id, smisim) (
			select smiles_fnd, smiles_in, sub_id, tranche_id, similarity(smiles_in, smiles_fnd) from temp_load_mismatch_smi tlmm where sub_id_fnd is null and not smiles_fnd is null and countchar(smiles_fnd, '\')>=countchar(smiles_in, '\'));
		with substance_delete as (
			delete from substance sb using (select smiles_in as smi from case1 union all select smiles_fnd as smi from case2 union all select smiles_fnd as smi from case4) t where sb.smiles = t.smi returning sub_id
		)
		delete from substance_id si using substance_delete sd where si.sub_id = sd.sub_id;
		insert into sub_dups_corrections(sub_id_wrong, sub_id_right) (select sub_id_fnd sw, sub_id sr from case1 union all select sub_id sw, sub_id_fnd sr from case2 union all select sub_id sw, sub_id_fnd sr from case3);
		update sub_dups_corrections set sub_id_right = t.sr from (select sub_id_fnd sw, sub_id sr from case1 union all select sub_id sw, sub_id_fnd sr from case2 union all select sub_id sw, sub_id_fnd sr from case3) t where sub_id_right = t.sw;
		with substance_insert as (
			insert into substance(smiles, sub_id, tranche_id) (select smiles_in as smiles, sub_id, tranche_id from case4 union all select smiles, sub_id, tranche_id from case5) returning sub_id, tableoid
		)
		insert into substance_id(sub_id, sub_partition_fk) (select sub_id, pfk from substance_insert si join oid_to_pfk op on si.tableoid = op.toid);
		-- clean up temp tables & push results to case tables
		insert into case1_all (select * from case1);
		insert into case2_all (select * from case2);
		insert into case3_all (select * from case3);
		insert into case4_all (select * from case4);
		insert into case5_all (select * from case5);
		insert into case6_all (select * from case6);
		drop table case1;
		drop table case2;
		drop table case3;
		drop table case4;
		drop table case5;
		drop table case6;
		truncate table temp_load_fnd;
		truncate table temp_load_mismatch_smi;
		
	end $$ language plpgsql;
	select logg('initializing tables');
	create temporary table temp_load (
                smiles varchar,
                sub_id bigint,
                tranche_id smallint
        );
	-- staging tables
	create temporary table stage0 (
		smiles varchar,
		sub_id bigint,
		tranche_id smallint,
		sub_id_dupnum smallint
	);
	create temporary table stage1 (like temp_load) partition by hash(smiles);
	create temporary table stage2 (
		smiles varchar,
		sub_id bigint,
		tranche_id smallint,
		smiles_dupnum smallint
	);
	create temporary table stage3 (like temp_load) partition by hash(sub_id);
	call create_table_partitions('stage1', 'temporary');
	call create_table_partitions('stage3', 'temporary');
        copy temp_load(sub_id, tranche_id, smiles) from :'source_f' delimiter ' ';
	analyze temp_load;

	-- this might prevent locks accumulating automatically- i'm not sure why postgres bothers with locks on temporary tables anyhow
	LOCK table stage0;
	LOCK table stage1;
	LOCK table stage2;
	LOCK table stage3;
	LOCK table temp_load_mismatch_smi;
	LOCK table temp_load_fnd;

	-- this operation must be applied over successive stages if there are duplicates in the source file
	-- the zinc id upload operation must be run under the assumption that each column in the input data is unique across all rows
	-- this can be accomplished using some staging tables, the PARTITION OVER clause, and the ROW_NUMBER() function to determine the "duplication number" of each entry
	-- each subset of data we insert into stage3 will satisfy our initial assumption, and every row in the source file will have been processed through stage3 by the end of the operation
	select logg('beginning upload loop');
	do $$
	declare
		i int;
		j int;
		k int;
		n int;
		p int;
		msg text;
	begin
		select ivalue from meta where svalue = 'n_partitions' limit 1 into p;
		insert into stage0(sub_id, smiles, tranche_id, sub_id_dupnum) (select sub_id, smiles, tranche_id, ROW_NUMBER() over (partition by sub_id) as rn from temp_load);
		select sub_id_dupnum, smiles from stage0 limit 1 into n, msg;
		raise notice 'found: %', concat(msg, n::text);
		analyze stage0;
		drop table temp_load;
		i := 1;
		while true loop
			insert into stage1(sub_id, smiles, tranche_id) (select sub_id, smiles, tranche_id from stage0 where sub_id_dupnum = i);
			analyze stage1;
			select count(*) from stage1 into n;
			if n = 0 then
				exit;
			end if;
			j := 1;
			-- this one is problematic- postgres wants to turns this into an append+sort into window, when I would rather have the window function take advantage of the natural partitions of the table
			-- sooo we do it manually. yay postgres. JUST PROCESS MY BIG DATA PROPERLY ALREADY OK????
			for k in 0..p-1 loop
				execute('insert into stage2(sub_id, smiles, tranche_id, smiles_dupnum) (select sub_id, smiles, tranche_id, ROW_NUMBER() over (partition by smiles) as rn from stage1_p' || k || ')');
			end loop;
			analyze stage2;
			while true loop
				insert into stage3(sub_id, smiles, tranche_id) (select sub_id, smiles, tranche_id from stage2 where smiles_dupnum = j);
				analyze stage3;
				select count(*) from stage3 into n;
				if n = 0 then
					exit;
				end if;
				raise notice '[%,%]: processing % entries', i, j, n;
				call process_zinc_id_upload();
				truncate table stage3;
				j := j + 1;
			end loop;
			truncate table stage1;
			truncate table stage2;
			i := i + 1;
		end loop;
	end $$ language plpgsql;
	select logg('ended upload loop- copying out');
	-- case files should be enough to roll back if necessary
	copy case1_all to :'case1';
	copy case2_all to :'case2';
	copy case3_all to :'case3';
	copy case4_all to :'case4';
	copy case5_all to :'case5';
	copy case6_all to :'case6';
commit;
select logg('committed! time to vacuum...');
vacuum analyze;
