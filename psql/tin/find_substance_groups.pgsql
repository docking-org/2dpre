/*
	find_substance_groups.pgsql - analyzes connections between entries in catalog_substance table, combining any associated entries into "groups"

	computationally, what we are doing is finding all 'groups' of connected entries from an enormous list
	the operation is similar to finding cycles in a graph
	in our case, we know our 'groups' are roughly size 2-16, which lets us avoid any worst case assumptions about the data distribution (no huge/mono-groups)
 */

LOAD 'auto_explain';
SET auto_explain.log_min_duration = 1;
SET client_min_messages to log;
set enable_partitionwise_aggregate=on;
set enable_partitionwise_join=on;

begin;

	drop table if exists catalog_substance_new;
	drop table if exists catalog_substance_cat_new;

	create table catalog_substance_new (sub_id_fk bigint, cat_content_fk bigint, grp_id bigint) partition by hash(sub_id_fk);
	create table catalog_substance_cat_new (sub_id_fk bigint, cat_content_fk bigint, grp_id bigint) partition by hash(cat_content_fk);
	call create_table_partitions('catalog_substance_new', '');
	call create_table_partitions('catalog_substance_cat_new', '');

	create table gfinal (sub_id bigint, cat_id bigint, grp_id bigint) partition by hash(grp_id);
	--create temporary table gCATfinal (cat_id bigint, grp_id bigint) partition by hash(grp_id);
	call create_table_partitions('gfinal', '');
	--call create_table_partitions('gCATfinal', 'temporary');
	lock table gfinal;
	--lock table gCATfinal;

	create temporary table gSUB (sub_id bigint, cat_id bigint, grp_id bigint) partition by hash(sub_id);
	create temporary table gCAT (sub_id bigint, cat_id bigint, grp_id bigint) partition by hash(cat_id);
	create temporary table gGRP (sub_id bigint, cat_id bigint, grp_id bigint) partition by hash(grp_id);
	call create_table_partitions('gSUB', 'temporary');
	call create_table_partitions('gCAT', 'temporary');
	call create_table_partitions('gGRP', 'temporary');
	lock table gSUB;
	lock table gCAT; -- according to StackOverflow this prevents locks from accumulating on temp tables
	lock table gGRP; -- it seems that truncating a temporary table & continuing to work on it may leave locks hanging around

	-- in most cases grp_cnt can be a smallint, however in one particular case this limit was exceeded
	-- specifically by n-5-15:5435 (H29P340) - did we stereoexpand without limits at some point?
	create temporary table gstats_t0 (grp_id bigint, grp_cnt int) partition by hash(grp_id);
	create temporary table gstats_t1 (grp_id bigint, grp_cnt int) partition by hash(grp_id);
	call create_table_partitions('gstats_t0', 'temporary');
	call create_table_partitions('gstats_t1', 'temporary');
	lock table gstats_t0;
	lock table gstats_t1;

	-- insert initial groups via sub_id into gCAT for further grouping along cat_content_id
	insert into gCAT(sub_id, cat_id, grp_id) (
		select sub_id_fk, cat_content_fk, sub_id_fk from catalog_substance
	);
	-- "group id" is just sub_id on first iteration, so we can calculate group stats cheaply here
	insert into gstats_t0(grp_id, grp_cnt) (
		select sub_id_fk, count(sub_id_fk) from catalog_substance group by sub_id_fk
	);

	create or replace function get_npartitions() returns int as $$
	begin
		return (select ivalue from meta where svalue = 'n_partitions' limit 1);
	end $$ language plpgsql;

	-- number of iterations is equal to the size of the largest group, G (i think?)
	-- however time complexity is /not/ O(N*G), where N is the size of the database
	-- we only operate on groups whose membership has not yet been fully explored, so small groups (which make up the majority of groups) will be excluded quickly
	-- thus by the second iteration the dataset will be much reduced
	-- worst-case performance would occur if the entire dataset were linked together (i think?)
	-- performance is a bit hard to quantify, but this is definitely an efficient way to do this for our case
	do $$
	declare
		i int;
		j int;
		n int;
	begin
		i := 0;
		while true loop
			i := i + 1;
			j := 0;

			for j in 0..get_npartitions()-1 loop
			-- collapse groups by cat_id, and then insert into partitions by grp_id
				execute(format('insert into gGRP (select sub_id, cat_id, min(grp_id) over (partition by cat_id) as grp_id from gCAT_p%1$s)', j));
			end loop;

			-- take advantage of grp_id partitions to quickly calculate group statistics
			insert into gstats_t1 (
				select grp_id, count(grp_id) from gGRP group by (grp_id)
			);

			with grpstats_all as (
				select sub_id, cat_id, g.grp_id as grp_id, t0.grp_cnt as cnt_t0, t1.grp_cnt as cnt_t1 from gGRP g
                                        join gstats_t0 t0 on t0.grp_id = g.grp_id
                                        join gstats_t1 t1 on t1.grp_id = g.grp_id
                        ),
			grp_next as (
				insert into gSUB(sub_id, cat_id, grp_id) (
					select sub_id, cat_id, grp_id from grpstats_all where cnt_t0 != cnt_t1
				) returning *
                        )
			insert into gfinal (sub_id, cat_id, grp_id) (
				select sub_id, cat_id, grp_id from grpstats_all where cnt_t0 = cnt_t1
			);
			/*
			grp_sub_final as (
				insert into gSUBfinal (sub_id, grp_id) (
					select sub_id, grp_id from grpstats_all where cnt_t0 = cnt_t1 group by (grp_id, sub_id)
				) returning *
			),
			grp_cat_final as (
				insert into gCATfinal (cat_id, grp_id) (
					select cat_id, grp_id from grpstats_all where cnt_t0 = cnt_t1 group by (grp_id, cat_id)
				) returning *
			)*/
			--select 1 into n; -- hilariously, we need to have this "into n", otherwise psql will complain about no destination

			select count(*) from gSUB into n;
			if n = 0 then
				exit;
			end if;
			raise notice 'loop: i=%, n=%', i, n;

			truncate table gCAT;
			for j in 0..get_npartitions()-1 loop
				execute(format('insert into gCAT (select sub_id, cat_id, min(grp_id) over (partition by sub_id) as grp_id from gSUB_p%1$s)', j));
			end loop;

			truncate table gGRP;
			truncate table gSUB;
			-- swap statistics tables- we only need to hold on to the previous timestep's statistics
			truncate table gstats_t0;
			alter table gstats_t0 rename to gstats_tx;
			alter table gstats_t1 rename to gstats_t0;
			alter table gstats_tx rename to gstats_t1;

		end loop;

	end $$ language plpgsql;

	insert into catalog_substance_new (sub_id_fk, cat_content_fk, grp_id) (
	--	select sub_id, cat_id, sb.grp_id from gfinal sb natural join gCATfinal ct
		select sub_id, cat_id, grp_id from gfinal
	);
	insert into catalog_substance_cat_new (sub_id_fk, cat_content_fk, grp_id) (select sub_id_fk, cat_content_fk, grp_id from catalog_substance_new);
	--alter table gfinal rename to catalog_substance_grp_new;
	alter table gfinal rename column sub_id to sub_id_fk;
	alter table gfinal rename column cat_id to cat_content_fk;
	alter table gfinal rename to catalog_substance_grp_new;
	--insert into catalog_substance_grp_new (sub_id_fk, cat_content_fk, grp_id) (select sub_id_fk, cat_content_fk, grp_id from catalog_substance_new);

	alter table catalog_substance_new add primary key (sub_id_fk, cat_content_fk);
	alter table catalog_substance_cat_new add primary key (cat_content_fk, sub_id_fk); -- do it in reverse here so the index will actually accelerate cat_content_id queries
	alter table catalog_substance_grp_new add primary key (grp_id, sub_id_fk, cat_content_fk);

-- swap out tables in second transaction- just in case some lock is acquired on main tables by virtue of their presence in the first commit block
	alter table catalog_substance rename to trash1;
	alter table catalog_substance_cat rename to trash2;
	alter table if exists catalog_substance_grp rename to trash3;
	drop table trash1 cascade;
	drop table trash2 cascade;
	drop table if exists trash3 cascade;

	call rename_table_partitions('catalog_substance_new', 'catalog_substance');
	call rename_table_partitions('catalog_substance_cat_new', 'catalog_substance_cat');
	call rename_table_partitions('gfinal', 'catalog_substance_grp');
	alter table catalog_substance_new rename to catalog_substance;
	alter table catalog_substance_cat_new rename to catalog_substance_cat;
	alter table catalog_substance_grp_new rename to catalog_substance_grp;
commit;
