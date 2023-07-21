load 'auto_explain';
set auto_explain.log_min_duration = 250;
set enable_partitionwise_join = on;
set enable_partitionwise_aggregate = on;

begin;
	create table if not exists substance_orphans (sub_id bigint primary key, still_orphaned bool default true, updated date default now());
	update substance_orphans set still_orphaned = false;

	insert into substance_orphans(sub_id) (
		select sub_id from substance_id left join catalog_substance on sub_id = sub_id_fk where sub_id_fk is null
	) on conflict (sub_id) do update set updated = now();

	alter table meta add column if not exists updated date default now();
	insert into meta (varname, ivalue) (select 'orphan_cnt', t.c from (select count(*) as c from substance_orphans) t);
	insert into meta (varname, ivalue) (select 'total_cnt', t.c from (select count(*) as c from substance) t);

commit;
