begin;

insert into meta (values ('n_partitions', 'n_partitions', :n_partitions));

create table supplier_codes_t (like supplier_codes including defaults) partition by hash(supplier_code);

call create_table_partitions('supplier_codes_t', '');

insert into supplier_codes_t (select * from supplier_codes);

alter table supplier_codes_t add primary key (supplier_code);

create table supplier_map_t (like supplier_map including defaults) partition by hash(sup_id_fk);

call create_table_partitions('supplier_map_t', '');

insert into supplier_map_t (select * from supplier_map);

alter table supplier_map_t add primary key (sup_id_fk, machine_id_fk);

drop table supplier_map;

drop table supplier_codes;

alter table supplier_codes_t rename to supplier_codes;
alter table supplier_map_t rename to supplier_map;

create unique index supplier_code_uniq_idx on supplier_codes(supplier_code);

call rename_table_partitions('supplier_codes_t', 'supplier_codes');

call rename_table_partitions('supplier_map_t', 'supplier_map');

commit;

