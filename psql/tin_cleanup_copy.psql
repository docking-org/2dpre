/*
alter table substance add primary key (sub_id);
create index substance3_logp_idx on substance (mol_logp(smiles));
create index substance3_mwt_idx on substance (mol_amw(smiles));
create index substance_sub_id_idx on substance (sub_id);
*/

reindex table substance;
reindex table catalog_content;
reindex table catalog_substance; 
reindex table catalog;

alter table catalog_substance enable trigger all;
alter table substance enable trigger all;
alter table catalog_content enable trigger all;
alter table catalog enable trigger all;
vacuum;
analyze;
