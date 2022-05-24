LOAD 'auto_explain';
SET auto_explain.log_nested_statements = ON;
SET auto_explain.log_min_duration = 1;
SET client_min_messages to log;
set enable_partitionwise_aggregate=on; -- doesn't seem to do much, but may help certain queries

create or replace function upload(stage int, part int, transid text, diff_file_dest text) returns int as $$
    declare
        nupload int;
        nnew int;
    begin
        case
            when stage = 1 then
                execute(format('select count(*) from temp_load_p1_p%s', part)) into nupload;
                nnew := upload_bypart(part, 'temp_load_p1', 'supplier_codes', 'temp_load_p2', '{{"supplier_code:text"}}', 'sup_id:bigint', 'sup_id_seq', format('%s/codes/%s', diff_file_dest, part));
                execute(format('insert into transaction_record_%s (stagei, parti, nnew, nupload) (values (1, %s, %s, %s))', transid, part, nnew, nupload));
                raise notice 'finished codes bypart';
            when stage = 2 then
                execute(format('select count(*) from temp_load_p2_p%s', part)) into nupload;
                nnew := upload_bypart(part, 'temp_load_p2', 'supplier_map', null, '{{"sup_id_fk:bigint"},{"machine_id_fk:smallint"}}', 'map_id:bigint', 'map_id_seq', format('%s/codesmap/%s', diff_file_dest, part));
                execute(format('insert into transaction_record_%s (stagei, parti, nnew, nupload) (values (2, %s, %s, %s))', transid, part, nnew, nupload));
                raise notice 'finished codesmap bypart';
            else
                raise EXCEPTION 'upload stage not defined! %', stage;
                return 1;
        end case;
        return 0;
    end;
$$ language plpgsql;

begin;
select upload(:stage, :part, :'transid', :'diff_file_dest');
commit;
