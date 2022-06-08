analyze substance;
analyze catalog_content;

begin;
	create index tranche_id_brin on substance using brin(tranche_id);
	create index cat_id_brin on catalog_content using brin(cat_id_fk);
commit;
