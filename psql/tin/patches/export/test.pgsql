LOAD 'auto_explain';
SET auto_explain.log_nested_statements = ON;
SET auto_explain.log_min_duration = 1;
SET client_min_messages to log;

call rename_table_partitions('catalog_substance_t', 'catalog_substance');

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
	select count(*) from catid_t2_out;

	select logg('-------------------------------');
	
	create temporary table catid_t3_out (supplier_code text, smiles text, cat_content_id bigint, sub_id bigint, tranche_id smallint, cat_id_fk smallint);

	call get_many_pairs_by_id('catid_t2', 'catid_t3_out');

	select * from catid_t3_out limit 25;
	select count(*) from catid_t3_out;

	select logg('--------------------------------');

	create temporary table catid_t4_out (like catid_t3_out);

	call get_some_pairs_by_sub_id('catid_t2', 'catid_t4_out');

	select * from catid_t4_out limit 25;
	select count(*) from catid_t4_out;

	select count(*) from (select * from catid_t3_out intersect select * from catid_t4_out) t;

	select logg('--------------------------------');

	drop table if exists subid_t;
	create temporary table subid_t (sub_id bigint);

	insert into subid_t (select sub_id_fk from catalog_substance_cat limit 25);
	insert into subid_t (values (999999999));

	create temporary table substance_out(sub_id bigint, smiles varchar, tranche_id smallint);

	call get_many_substances_by_id('subid_t', 'substance_out');

	select * from substance_out;

	create temporary sequence tq_id_seq;
	create temporary table testq (sub_id bigint, temp_id bigint default nextval('tq_id_seq'));
	insert into testq(sub_id) (select sub_id_fk from catalog_substance_cat_p0 limit 1000);
	create temporary table testout (smiles varchar, sub_id bigint, tranche_id smallint, temp_id bigint);

	call get_some_substances_by_id('testq', 'testout');

	select count(*) from testout;
	select * from testout limit 25;
commit;
