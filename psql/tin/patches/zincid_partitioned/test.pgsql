        
drop table if exists subid_t;
create temporary table subid_t (sub_id bigint);

insert into subid_t (select sub_id_fk from catalog_substance_cat limit 25);
insert into subid_t (values (999999999));

create temporary table substance_out(sub_id bigint, smiles varchar, tranche_id smallint);

call get_many_substances_by_id('subid_t', 'substance_out');

select * from substance_out;
