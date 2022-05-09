
	create or replace function get_shared_columns (tab1 text, tab2 text, excl1 text, excl2 text[]) returns text[] as $$
		declare
			shared_cols text[];
		begin
			raise info '%', excl2;
			raise info '%', 'a' = ANY(excl2);
			select into shared_cols array_agg(concat(t1.col, ':', t1.dtype)) from (select attname::text as col, atttypid::regtype as dtype from pg_attribute where attrelid = tab1::regclass and attnum > 0) t1 inner join (select attname::text as col, atttypid::regtype as dtype from pg_attribute where attrelid = tab2::regclass and attnum > 0) t2 on t1.col = t2.col where t1.col != excl1 and not t1.col = ANY(excl2);
			return shared_cols;
		end;
	$$ language plpgsql;

	create or replace function sc_colname(scol text) returns text as $$
		begin
			return SPLIT_PART(scol, ':', 1);
		end;
	$$ language plpgsql;

	create or replace function sc_coltype(scol text) returns text as $$
		begin
			return SPLIT_PART(scol, ':', 2);
		end;
	$$ language plpgsql;

	create or replace function cols_declare(cols text[], tabprefix text) returns text as $$
		declare
			colnames text[];
		begin
			select into colnames array_agg(sc_colname(t.col)) from unnest(cols) as t(col);
			if not tabprefix is null then
				return tabprefix || array_to_string(colnames, ', ' || tabprefix);
			else
				return array_to_string(colnames, ', ');
			end if;
		end;
	$$ language plpgsql;

	create or replace function cols_declare_join(cols text[], t1 text, t2 text) returns text as $$
		declare
			colnames text[];
			equ_stmts text[];
		begin
			select into colnames array_agg(sc_colname(t.col)) from unnest(cols) as t(col);
			select array_agg(format('%2$s.%1$s = %3$s.%1$s', col, t1, t2)) from unnest(colnames) as t(col) into equ_stmts;
			return array_to_string(equ_stmts, ' and ');
		end;
	$$ language plpgsql;

	create or replace function upload_bypart(partition int, loadtable text, desttable text, nexttable text, keyfields text[], idfield text, destseq text, filediff text) returns int as $$

		declare

                        destcolumns text[];
                        loadcolumns text[];
                        nextcolumns text[];
			keyfield_colnames text[];
			desttable_p text;
			loadtable_p text;
			query text;
			col text;
		begin
			if partition <> -1 then
				desttable_p := format('%s_p%s', desttable, partition);
				loadtable_p := format('%s_p%s', loadtable, partition);
			else
				desttable_p := desttable;
				loadtable_p := loadtable;
			end if;

			select array_agg(sc_colname(t.col)) from unnest(keyfields) as t(col) into keyfield_colnames;
			-- columns shared between load table and dest table, keyfields are assumed to be shared (thus will not be included in list of shared columns)
                        destcolumns := get_shared_columns(loadtable_p, desttable_p, idfield, keyfield_colnames);
			-- columns of the load table (minus keyfields + idfield)
                        loadcolumns := get_shared_columns(loadtable_p, loadtable_p, idfield, keyfield_colnames);
			-- columns shared between the load table and the next stage table (what data do we pass on to the next stage, idfield is assumed to be passed, but not keyfields)
                        nextcolumns := get_shared_columns(loadtable_p, nexttable, idfield, '{}');

			raise info '%', format('shared cols : dest <> load : %s', array_to_string(destcolumns, ','));
			raise info '%', format('shared cols : load <> load : %s', array_to_string(loadcolumns, ','));
			raise info '%', format('shared cols : load <> next : %s', array_to_string(nextcolumns, ','));

			-- allocate temporary table for calculations
			create temporary sequence temp_seq;
			create temporary table temp_table_load (temp_id int default nextval('temp_seq'));
			execute(format('alter table temp_table_load add column %s %s', sc_colname(idfield), sc_coltype(idfield)));
			foreach col in array keyfields loop
				execute(format('alter table temp_table_load add column %s %s', sc_colname(col), sc_coltype(col)));
			end loop;
                        foreach col in array loadcolumns loop
                                execute(format('alter table temp_table_load add column %s %s', sc_colname(col), sc_coltype(col)));
                        end loop;

			-- join input table to destination table on keyfields and store result in temporary table
                        execute(format('insert into temp_table_load(%1$s, %2$s, %3$s) (select s.%1$s, %4$s, %5$s from %6$s t left join %7$s s on %8$s)', sc_colname(idfield), cols_declare(keyfield_colnames, ''), cols_declare(loadcolumns, ''), cols_declare(keyfield_colnames, 't.'), cols_declare(loadcolumns, 't.'), loadtable_p, desttable_p, cols_declare_join(keyfields, 't', 's')));

			-- create second temporary table to store just entries new to the destination table
                        execute(format('create temporary table new_entries (%1$s %2$s, temp_id int, rn int)', sc_colname(idfield), sc_coltype(idfield)));
			foreach col in array keyfields loop
				execute(format('alter table new_entries add column %s %s', sc_colname(col), sc_coltype(col)));
			end loop;

			-- locate all entries new to destination table and assign them a new sequential ID, storing in the temporary table we just created
                        execute(format('insert into new_entries(%1$s, %2$s, rn, temp_id) (select %1$s, min(%2$s) over w as %2$s, ROW_NUMBER() over w as rn, temp_id from (select %3$s, case when ROW_NUMBER() over w = 1 then nextval(''%4$s'') else null end as %2$s, t.temp_id from temp_table_load t where t.%2$s is null window w as (partition by %3$s)) t window w as (partition by %3$s))', cols_declare(keyfields, ''), sc_colname(idfield), cols_declare(keyfields, 't.'), destseq));

			-- finally, insert new entries to destination table
			query := format('insert into %1$s (%2$s, %3$s, %4$s) (select %5$s, n.%3$s, %6$s from new_entries n left join temp_table_load t on n.temp_id = t.temp_id where n.rn = 1)', desttable_p, cols_declare(keyfields, ''), sc_colname(idfield), cols_declare(destcolumns, ''), cols_declare(keyfields, 'n.'), cols_declare(destcolumns, 't.'));

			-- save the diff to an external file (if specified)
			if not filediff is null then
				query := 'copy (' || query || ' returning *) to ''' || filediff || '''';
			end if;

			execute(query);

			-- move data to next stage (if applicable)
			if not nexttable is null then
				query := format('insert into %1$s (%2$s, %3$s) (select %2$s, case when t.%3$s is null then n.%3$s else t.%3$s end from temp_table_load t left join new_entries n on t.temp_id = n.temp_id)', nexttable, cols_declare(nextcolumns, ''), sc_colname(idfield));
				execute(query);
			end if;

			-- clean up!
			drop table temp_table_load;
			drop sequence temp_seq;
			drop table new_entries;

			return 0;

                        /* END GENERALIZATION REWRITE */
		end
	$$ language plpgsql;
