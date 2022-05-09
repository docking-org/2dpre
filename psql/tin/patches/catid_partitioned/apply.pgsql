begin;
        create table catalog_id (

                cat_content_id bigint,
                cat_partition_fk smallint

        ) partition by hash (cat_content_id);

        call create_table_partitions('catalog_id', '');

        call export_ids_from_catalog_content();

        alter table catalog_id add primary key (cat_content_id);

commit;
