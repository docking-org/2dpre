begin;

        create table substance_id (

                sub_id bigint,
                sub_partition_fk smallint

        ) partition by hash (sub_id);

        call create_table_partitions('substance_id', '');

        call export_ids_from_substance();

        alter table substance_id add primary key (sub_id);
        create index substance_id_partition_fk_idx on substance_id (sub_partition_fk);

commit;
