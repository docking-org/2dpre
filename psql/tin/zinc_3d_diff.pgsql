load 'auto_explain';
set auto_explain.log_min_duration = 50;
set enable_partitionwise_join = on;
set enable_partitionwise_aggregate = on;

begin;
	drop table if exists zinc_tarballs;
	create table zinc_tarballs (tarball_path text, tarball_id int); 
	copy zinc_tarballs from :'tarball_f';

	drop table if exists zinc_3d_map;
	create table zinc_3d_map (sub_id bigint, tranche_id smallint, tarball_id int, grp_id int) partition by hash(sub_id);
	call create_table_partitions('zinc_3d_map', '');

	create temporary table zinc_3d_mapt (sub_id bigint, tranche_id smallint, tarball_id int, grp_id int) partition by hash(sub_id);
	call create_table_partitions('zinc_3d_mapt', 'temporary');
	copy zinc_3d_mapt(sub_id, tranche_id, tarball_id) from :'source_f' delimiter ' ';

	create temporary table zinc_3d_map_grp (sub_id bigint, tranche_id smallint, tarball_id int, grp_id int) partition by hash(grp_id);
	call create_table_partitions('zinc_3d_map_grp', 'temporary');

	create temporary table not_built_sub_id (sub_id bigint) partition by hash(sub_id);
	call create_table_partitions('not_built_sub_id', 'temporary');

	create temporary table not_built_out (sub_id bigint, tranche_id smallint, smiles text) partition by list(tranche_id);
	--call create_table_partitions('not_built_out', 'temporary');

	create or replace procedure exec_diff3d(diff_dest text) as $$
	declare 
		i int;
		tranche_id_ int;
		tranche_name_ text;
	begin
		for tranche_id_ in select tranche_id from tranches order by tranche_id asc loop
			execute(format('create temporary table not_built_out_p%1$s partition of not_built_out for values in (%2$s)', tranche_id_, tranche_id_));
		end loop;
		create temporary table not_built_out_pn partition of not_built_out for values in (null); -- catch any outliers here
		for i in 0..get_npartitions()-1 loop
			raise info 'resolving zinc ids for %', i;
			execute(format('insert into zinc_3d_map(sub_id, tranche_id, tarball_id) (select case when sub_id_wrong is null then sub_id else sub_id_right end, tranche_id, tarball_id from zinc_3d_mapt_p%1$s zm left join sub_dups_corrections sdc on zm.sub_id = sdc.sub_id_wrong)', i));
		end loop;
		for i in 0..get_npartitions()-1 loop
			raise info 'getting group info for %', i;
			--execute(format('update zinc_3d_map_p%1$s set sub_id = sdc.sub_id_right from sub_dups_corrections sdc where sub_id = sub_id_wrong', i));
			execute(format('update zinc_3d_map_p%1$s set grp_id = csb.grp_id from catalog_substance_p%2$s csb where sub_id = sub_id_fk', i, i));
			execute(format('insert into zinc_3d_map_grp(sub_id, tranche_id, tarball_id, grp_id) (select sub_id, tranche_id, tarball_id, grp_id from zinc_3d_map_p%1$s)', i));
			--execute(format('insert into not_built_sub_ids_p%(sub_id) (select sub_id_fk from catalog_substance_p% csb left join zinc_3d_map_p% zi on csb.grp_id = zi.grp_id where sub_id is null group by (sub_id_fk))', i, i, i));
		end loop;
		for i in 0..get_npartitions()-1 loop
			raise info 'getting not built for %', i;
			execute(format('insert into not_built_sub_id (sub_id) (select sub_id_fk from catalog_substance_grp_p%1$s csb left join zinc_3d_map_grp_p%2$s zm on csb.grp_id = zm.grp_id where zm.grp_id is null group by (sub_id_fk))', i, i));
		end loop;
		raise info 'fetching smiles for not built';
		call get_many_substances_by_id_('not_built_sub_id', 'not_built_out', true);

		for tranche_id_ in select tranche_id from tranches loop
			select tranche_name from tranches where tranche_id = tranche_id_ into tranche_name_;
			execute(format('copy (select * from not_built_out_p%1$s ) to ''%2$s/%3$s''', tranche_id_, diff_dest, tranche_name_));
		end loop;
		execute(format('copy (select * from not_built_out_pn) to ''%1$s/notfound''', diff_dest));
	end $$ language plpgsql;

	call exec_diff3d(:'diff_dest');

commit;
