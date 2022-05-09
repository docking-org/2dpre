set work_mem = 2000000;
LOAD 'auto_explain';
SET auto_explain.log_nested_statements = ON;
SET auto_explain.log_min_duration = 0;
SET client_min_messages to log;
set enable_partitionwise_aggregate=on; -- doesn't seem to do much, but may help certain queries

begin;

	create temporary sequence temp_seq;
	create temporary table source_t (

		supplier_code varchar,
		last4hash char(4),
		machine_id smallint,
		cat_content_id int,
		temp_id int default nextval('temp_seq')

	);

	create temporary table source_t_ids (
		machine_id smallint,
		sup_id int,
		map_id int,
		temp_id int
	);

	copy source_t(supplier_code, last4hash, cat_content_id, machine_id) from :'source_f' delimiter ' ';

	alter table source_t add primary key (temp_id);
	analyze source_t;

	insert into source_t_ids (select st.machine_id, sc.sup_id, st.temp_id from source_t st left join supplier_codes sc on st.supplier_code = sc.supplier_code);

	update source_t set sup_id = sc.sup_id from supplier_codes sc where sc.supplier_code = source_t.supplier_code;

	create temporary table new_codes (

		supplier_code varchar,
		last4hash char(4),
		sup_id int,
		temp_id int

	);

	alter table new_codes add constraint temp_id_fk foreign key (temp_id) references source_t(temp_id);

	create index new_codes_idx_t on new_codes using hash(supplier_code);

	insert into new_codes (select distinct on (supplier_code) supplier_code, last4hash, nextval('sup_id_seq') sup_id from source_t where sup_id is null);

	update source_t st set sup_id = nc.sup_id from new_codes nc where st.supplier_code = nc.supplier_code;
	update source_t st set map_id = sm.map_id from supplier_map sm where sm.sup_id_fk = st.sup_id and sm.machine_id_fk = st.machine_id;

	create temporary table new_maps (

		sup_id_fk int,
		machine_id_fk smallint,
		cat_content_id int,
		map_id int
	);

	insert into new_maps (select distinct on (sup_id, machine_id) sup_id, machine_id, cat_content_id, nextval('map_id_seq') map_id from source_t where map_id is null);

	create table supplier_codes_t (like supplier_codes including defaults);
	create table supplier_map_t (like supplier_map including defaults);

	insert into supplier_codes_t (select * from new_codes);
	insert into supplier_codes_t (select * from supplier_codes);

	insert into supplier_map_t (select * from new_maps);
	insert into supplier_map_t (select * from supplier_map);

	alter table supplier_codes_t add primary key (sup_id);
	create index supplier_code_idx_t on supplier_codes_t using hash (supplier_code);

	--create index sup_id_fk_idx_t on supplier_map (sup_id_fk);
	--create index machine_id_fk_idx_t on supplier_map (machine_id_fk);
	alter table supplier_map_t add primary key (sup_id_fk, machine_id_fk);
	alter table supplier_map_t add constraint sup_id_fk_fkey_t foreign key (sup_id_fk) references supplier_codes_t (sup_id);
	--alter table supplier_map_t add constraint machine_id_fk_fkey_t foreign key (machine_id_fk) references tin_machines (machine_id);

	alter table supplier_map rename to supplier_map_trash;
	alter table supplier_codes rename to supplier_codes_trash;

	alter table supplier_map_t rename to supplier_map;
	alter table supplier_codes_t rename to supplier_codes;

	drop table supplier_map_trash cascade;
	drop table supplier_codes_trash cascade;

	alter table supplier_codes rename constraint supplier_codes_t_pkey to supplier_codes_pkey;
	alter index supplier_code_idx_t rename to supplier_code_idx;

	--alter index sup_id_fk_idx_t rename to sup_id_fk_idx;
	--alter index machine_id_fk_idx_t rename to machine_id_fk_idx;
	alter table supplier_map rename constraint supplier_map_t_pkey to supplier_map_pkey;
	alter table supplier_map rename constraint sup_id_fk_fkey_t to sup_id_fk_fkey;
	--alter table supplier_map rename constraint machine_id_fk_fkey_t to machine_id_fk_fkey;

commit;

vacuum;
analyze;
