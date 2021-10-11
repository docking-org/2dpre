create extension if not exists tsm_system_rows;
begin;

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

--create temporary table dupstats(cnt int);

select count(*) from substance, (select * from substance tablesample system_rows(100000)) t where substance.smiles = t.smiles and substance.sub_id != t.sub_id;

/*
do
$$
begin
for i in 0..100 loop
insert into dupstats(cnt) (select count(*) from substance, (select * from substance tablesample system_rows(1000)) t where substance.smiles = t.smiles and substance.sub_id != t.sub_id);
if mod(i, 10) = 0 then
raise notice 'i: %', i;
end if;
end loop;
end;
$$ language plpgsql;

select avg(cnt) from dupstats;
*/
rollback;
