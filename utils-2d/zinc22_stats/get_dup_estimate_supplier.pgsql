
/*
do
$$
declare
patchexists boolean;
begin
patchexists := (select patched from patches where patchname = 'substanceopt');
if patchexists = false or patchexists is null then
raise exception 'has not received substance opt patch yet! exiting...';
end if;
end;
$$ language plpgsql;
*/

create extension if not exists tsm_system_rows;

select count(*) from catalog_content, (select * from catalog_content tablesample system_rows(100000) where supplier_code like '%\_\_\_\_%') t where catalog_content.supplier_code = replace(t.supplier_code, '____', '__');

--create temporary table dupstats(cnt int);

/*
do
$$
begin
insert into dupstats(cnt) (select count(*) from substance, (select * from substance tablesample system_rows(1000)) t where substance.smiles = t.smiles and substance.sub_id != t.sub_id);
end;
$$ language plpgsql;

select avg(cnt) from dupstats;
*/
