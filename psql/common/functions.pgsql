create or replace function logg(t text) returns integer as $$
begin
	        raise info '[%]: %', clock_timestamp(), t;
		        return 0;
end;
$$ language plpgsql;
