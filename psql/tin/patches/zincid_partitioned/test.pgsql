LOAD 'auto_explain';
SET auto_explain.log_nested_statements = ON;
SET auto_explain.log_min_duration = 0;
SET client_min_messages to log;

drop table if exists subid_t;
create temporary table subid_t (sub_id bigint);

insert into subid_t (select sub_id_fk from catalog_substance_cat limit 25);
insert into subid_t (values (999999999));

create temporary table substance_out(sub_id bigint, smiles varchar, tranche_id smallint);

call get_many_substances_by_id('subid_t', 'substance_out');

select * from substance_out;

create temporary sequence tq_id_seq;
create temporary table testq (sub_id bigint, temp_id bigint default nextval('tq_id_seq'));
insert into testq(sub_id) (select sub_id_fk from catalog_substance_cat_p27 limit 1000);
create temporary table testout (smiles varchar, sub_id bigint, tranche_id smallint, temp_id bigint);

call get_some_substances_by_id('testq', 'testout');

select count(*) from testout;
select * from testout limit 25;
