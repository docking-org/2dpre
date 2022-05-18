CREATE OR REPLACE FUNCTION get_shared_columns (tab1 text, tab2 text, excl1 text, excl2 text[])
	RETURNS text[]
	AS $$
DECLARE
	shared_cols text[];
BEGIN
	RAISE info '%', excl2;
	RAISE info '%', 'a' = ANY (excl2);
	SELECT INTO shared_cols 
		array_agg(concat(t1.col, ':', t1.dtype))
	FROM (
		SELECT
			attname::text AS col,
			atttypid::regtype AS dtype
		FROM
			pg_attribute
		WHERE
			attrelid = tab1::regclass
			AND attnum > 0) t1
	INNER JOIN (
		SELECT
			attname::text AS col,
			atttypid::regtype AS dtype
		FROM
			pg_attribute
		WHERE
			attrelid = tab2::regclass
			AND attnum > 0) t2 
	ON t1.col = t2.col
	WHERE
		t1.col != sc_colname(excl1)
		AND NOT t1.col = ANY (excl2);
	RAISE info '%', shared_cols;
	RAISE info '%', excl1;

	RETURN shared_cols;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sc_colname (scol text)
	RETURNS text
	AS $$
BEGIN
	RETURN SPLIT_PART(scol, ':', 1);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION sc_coltype (scol text)
	RETURNS text
	AS $$
BEGIN
	RETURN SPLIT_PART(scol, ':', 2);
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cols_declare (cols text[], tabprefix text)
	RETURNS text
	AS $$
DECLARE
	colnames text[];
BEGIN
	SELECT
		INTO colnames array_agg(sc_colname (t.col))
	FROM
		unnest(cols) AS t (col);
	IF NOT tabprefix IS NULL THEN
		RETURN tabprefix || array_to_string(colnames, ', ' || tabprefix);
	ELSE
		RETURN array_to_string(colnames, ', ');
	END IF;
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION cols_declare_type (cols text[])
	RETURNS text
	AS $$
DECLARE
	coldecl text[];
BEGIN
	SELECT
		INTO coldecl array_agg(replace(t.col, ':', ' '))
	FROM
		unnest(cols) as t (col);
	RETURN array_to_string(coldecl, ', ');
END;
$$
LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION cols_declare_join (cols text[], t1 text, t2 text)
	RETURNS text
	AS $$
DECLARE
	colnames text[];
	equ_stmts text[];
BEGIN
	SELECT
		INTO colnames array_agg(sc_colname (t.col))
	FROM
		unnest(cols) AS t (col);
	SELECT
		array_agg(format('%2$s.%1$s = %3$s.%1$s', col, t1, t2))
	FROM
		unnest(colnames) AS t (col) INTO equ_stmts;
	RETURN array_to_string(equ_stmts, ' and ');
END;
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION upload_bypart (PARTITION int, loadtable text, desttable text, nexttable text, keyfields text[], idfield text, destseq text, filediff text)
	RETURNS int
	AS $$
DECLARE
	destcolumns text[];
	loadcolumns text[];
	nextcolumns text[];
	keyfield_colnames text[];
	desttable_p text;
	loadtable_p text;
	query text;
	col text;
BEGIN
	IF PARTITION <> - 1 THEN
		desttable_p := format('%s_p%s', desttable, PARTITION);
		loadtable_p := format('%s_p%s', loadtable, PARTITION);
	ELSE
		desttable_p := desttable;
		loadtable_p := loadtable;
	END IF;
	SELECT
		array_agg(sc_colname (t.col))
	FROM
		unnest(keyfields) AS t (col) INTO keyfield_colnames;
	-- columns shared between load table and dest table, keyfields are assumed to be shared (thus will not be included in list of shared columns)
	destcolumns := get_shared_columns (loadtable_p, desttable_p, idfield, keyfield_colnames);
	-- columns of the load table (minus keyfields + idfield)
	loadcolumns := get_shared_columns (loadtable_p, loadtable_p, idfield, keyfield_colnames);
	-- columns shared between the load table and the next stage table (what data do we pass on to the next stage, idfield is assumed to be passed, but not keyfields)
	nextcolumns := get_shared_columns (loadtable_p, nexttable, idfield, '{}');
	RAISE info '%', format('shared cols : dest <> load : %s', array_to_string(destcolumns, ','));
	RAISE info '%', format('shared cols : load <> load : %s', array_to_string(loadcolumns, ','));
	RAISE info '%', format('shared cols : load <> next : %s', array_to_string(nextcolumns, ','));
	-- allocate temporary table for calculations
	CREATE TEMPORARY SEQUENCE temp_seq;
	CREATE TEMPORARY TABLE temp_table_load (
		temp_id int DEFAULT nextval('temp_seq' )
	);
	EXECUTE (format('alter table temp_table_load add column %s %s', sc_colname (idfield), sc_coltype (idfield)));
	foreach col IN ARRAY keyfields LOOP
		EXECUTE (format('alter table temp_table_load add column %s %s', sc_colname (col), sc_coltype (col)));
	END LOOP;
	foreach col IN ARRAY loadcolumns LOOP
		EXECUTE (format('alter table temp_table_load add column %s %s', sc_colname (col), sc_coltype (col)));
	END LOOP;
	-- join input table to destination table on keyfields and store result in temporary table
	EXECUTE (format('insert into temp_table_load(%1$s, %2$s, %3$s) (select s.%1$s, %4$s, %5$s from %6$s t left join %7$s s on %8$s)', sc_colname (idfield), cols_declare (keyfield_colnames, ''), cols_declare(loadcolumns, ''), cols_declare (keyfield_colnames, 't.'), cols_declare (loadcolumns, 't.'), loadtable_p, desttable_p, cols_declare_join (keyfields, 't', 's')));
	-- create second temporary table to store just entries new to the destination table
	EXECUTE (format('create temporary table new_entries (%1$s %2$s, temp_id int, rn int)', sc_colname (idfield), sc_coltype (idfield)));
	foreach col IN ARRAY keyfields LOOP
		EXECUTE (format('alter table new_entries add column %s %s', sc_colname (col), sc_coltype (col)));
	END LOOP;
	-- locate all entries new to destination table and assign them a new sequential ID, storing in the temporary table we just created
	EXECUTE (format('insert into new_entries(%1$s, %2$s, rn, temp_id) (select %1$s, min(%2$s) over w as %2$s, ROW_NUMBER() over w as rn, temp_id from (select %3$s, case when ROW_NUMBER() over w = 1 then nextval(''%4$s'') else null end as %2$s, t.temp_id from temp_table_load t where t.%2$s is null window w as (partition by %3$s)) t window w as (partition by %3$s))', cols_declare (keyfields, ''), sc_colname (idfield), cols_declare (keyfields, 't.'), destseq));
	-- finally, insert new entries to destination table
	query := format('insert into %1$s (%2$s, %3$s, %4$s) (select %5$s, n.%3$s, %6$s from new_entries n left join temp_table_load t on n.temp_id = t.temp_id where n.rn = 1)', desttable_p, cols_declare (keyfields, ''), sc_colname(idfield), cols_declare(destcolumns, ''), cols_declare (keyfields, 'n.'), cols_declare (destcolumns, 't.'));
	-- save the diff to an external file (if specified)
	IF NOT filediff IS NULL THEN
		query := 'copy (' || query || ' returning *) to ''' || filediff || '''';
	END IF;
	EXECUTE (query);
	-- move data to next stage (if applicable)
	IF NOT nexttable IS NULL THEN
		query := format('insert into %1$s (%2$s, %3$s) (select %2$s, case when t.%3$s is null then n.%3$s else t.%3$s end from temp_table_load t left join new_entries n on t.temp_id = n.temp_id)', nexttable, cols_declare (nextcolumns, ''), sc_colname (idfield));
		EXECUTE (query);
	END IF;
	-- clean up!
	DROP TABLE temp_table_load;
	DROP SEQUENCE temp_seq;
	DROP TABLE new_entries;
	RETURN 0;

	/* END GENERALIZATION REWRITE */
END
$$
LANGUAGE plpgsql;
