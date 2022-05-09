begin;

create temporary table temp_load (smiles varchar, sub_id int, tranche_id smallint);

copy temp_load from :'source_f' delimiter ' ';

create table legacy_substance (sub_id_legacy int, tranche_id_legacy smallint, sub_id_fk int, tranche_id smallint);

insert into legacy_substance (select tl.sub_id, tl.tranche_id, sb.sub_id, sb.tranche_id from substance sb, temp_load tl where sb.smiles = tl.smiles);

create index legacy_substance_sub_id_idx on legacy_substance (sub_id_legacy, tranche_id_legacy);
--alter table legacy_substance add primary key (sub_id_legacy, tranche_id_legacy);

alter table legacy_substance add foreign key (sub_id_fk, tranche_id) references substance(sub_id, tranche_id);

commit;
