-- test code
begin;
        drop table if exists catid_t;
        create temporary table catid_t (cat_content_id bigint);

        insert into catid_t (select cat_content_fk from catalog_substance limit 1000);
        insert into catid_t (values (999999999));

        create temporary table catalog_content_out(cat_content_id bigint, supplier_code varchar, cat_id_fk smallint);

        call get_many_codes_by_id('catid_t', 'catalog_content_out', true);

        select * from catalog_content_out limit 25;

	create temporary table catid_t2 (cat_content_id bigint, sub_id bigint);
	create temporary table catid_t2_out (supplier_code varchar, cat_content_id bigint, cat_id_fk smallint, sub_id bigint);

	insert into catid_t2 (select cat_content_fk, sub_id_fk from catalog_substance_p0 limit 1000);

	call get_some_codes_by_id('catid_t2', 'catid_t2_out');

	select * from catid_t2_out limit 25;

commit;
