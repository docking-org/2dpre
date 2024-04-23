--
-- PostgreSQL database dump
--

-- Dumped from database version 12.3
-- Dumped by pg_dump version 12.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

CREATE ROLE admin;
ALTER ROLE admin WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'md57037abb4885de0d3521db711dc634826';
CREATE ROLE adminprivate;
ALTER ROLE adminprivate WITH NOSUPERUSER INHERIT NOCREATEROLE CREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'md53daafadd61518998cfcfce69e1ae1267';
CREATE ROLE btzuser;
ALTER ROLE btzuser WITH NOSUPERUSER INHERIT NOCREATEROLE CREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'md5138ad172f74f342ffb524cdf491ec8af';
CREATE ROLE chembl;
ALTER ROLE chembl WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS;
-- CREATE ROLE postgres;
ALTER ROLE postgres WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS;
CREATE ROLE root;
ALTER ROLE root WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN NOREPLICATION NOBYPASSRLS;
CREATE ROLE test;
ALTER ROLE test WITH NOSUPERUSER INHERIT NOCREATEROLE CREATEDB LOGIN NOREPLICATION NOBYPASSRLS;
CREATE ROLE tinuser;
ALTER ROLE tinuser WITH SUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'md516a847029f27f45ebc318a781bc3df5a';
CREATE ROLE zinc21;
ALTER ROLE zinc21 WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'md50893f3c540509e267e4b24cef189e262';
CREATE ROLE zincfree;
ALTER ROLE zincfree WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'md52a08c13b63d4e1257e7cea48d468a5de';
CREATE ROLE zincread;
ALTER ROLE zincread WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'md57d8bffd68d271c7d10510986e086ce65';
CREATE ROLE zincwrite;
ALTER ROLE zincwrite WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'md57c0a812310ac0a935e992599d5df7e0a';

-- Name: intarray; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS intarray WITH SCHEMA public;


--
-- Name: EXTENSION intarray; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION intarray IS 'functions, operators, and index support for 1-D arrays of integers';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: rdkit; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS rdkit WITH SCHEMA public;


--
-- Name: EXTENSION rdkit; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION rdkit IS 'Cheminformatics functionality for PostgreSQL.';


--
-- Name: tsm_system_rows; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS tsm_system_rows WITH SCHEMA public;


--
-- Name: EXTENSION tsm_system_rows; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION tsm_system_rows IS 'TABLESAMPLE method which accepts number of rows as a limit';

create table public.meta (varname text, svalue text, ivalue bigint);
insert into public.meta (values ('n_partitions', 'n_partitions', 2048));
insert into public.meta(varname, ivalue) values ('version', 0);

--
-- Name: cb_get_some_pairs_by_sub_id(); Type: PROCEDURE; Schema: public; Owner: tinuser
--


CREATE PROCEDURE public.cb_get_some_pairs_by_sub_id()
    LANGUAGE plpgsql
    AS $$
begin
	create temporary table pairs_tempload_p1(smiles text, sub_id bigint, tranche_id smallint, tranche_id_orig smallint);
	create temporary table pairs_tempload_p2(smiles text, sub_id bigint, tranche_id smallint, cat_content_id bigint, tranche_id_orig smallint);

	call get_some_substances_by_id('cb_sub_id_input', 'pairs_tempload_p1');

	insert into pairs_tempload_p2 (select p1.smiles, p1.sub_id, p1.tranche_id, cs.cat_content_fk, p1.tranche_id_orig from pairs_tempload_p1 p1 left join catalog_substance cs on cs.sub_id_fk = p1.sub_id);

	call get_some_codes_by_id('pairs_tempload_p2', 'cb_pairs_output');

	drop table pairs_tempload_p1;
	drop table pairs_tempload_p2;
end;
$$;


ALTER PROCEDURE public.cb_get_some_pairs_by_sub_id() OWNER TO tinuser;

--
-- Name: cb_get_some_pairs_by_vendor(); Type: PROCEDURE; Schema: public; Owner: tinuser
--

CREATE or replace PROCEDURE public.cb_get_some_pairs_by_vendor()
    LANGUAGE plpgsql
    AS $$
begin
	create temporary table pairs_tempload_p1(supplier_code text, sub_id bigint, cat_id smallint);
	--create temporary table pairs_tempload_p2(smiles text, sub_id bigint, tranche_id smallint, supplier_code text, cat_id_fk smallint);

	insert into pairs_tempload_p1 (select i.supplier_code, cs.sub_id_fk, cc.cat_id_fk from cb_vendor_input i left join catalog_content cc on i.supplier_code = cc.supplier_code left join catalog_substance cs on cs.cat_content_fk = cc.cat_content_id);

	call get_some_substances_by_id('pairs_tempload_p1', 'cb_pairs_output');

	drop table pairs_tempload_p1;
end;
$$;


ALTER PROCEDURE public.cb_get_some_pairs_by_vendor() OWNER TO tinuser;

--
-- Name: cols_declare(text[], text); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.cols_declare(cols text[], tabprefix text) RETURNS text
    LANGUAGE plpgsql
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
$$;


ALTER FUNCTION public.cols_declare(cols text[], tabprefix text) OWNER TO tinuser;

--
-- Name: cols_declare_join(text[], text, text); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.cols_declare_join(cols text[], t1 text, t2 text) RETURNS text
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION public.cols_declare_join(cols text[], t1 text, t2 text) OWNER TO tinuser;

--
-- Name: cols_declare_type(text[]); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.cols_declare_type(cols text[]) RETURNS text
    LANGUAGE plpgsql
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
$$;


ALTER FUNCTION public.cols_declare_type(cols text[]) OWNER TO tinuser;

--
-- Name: copy_in(text); Type: PROCEDURE; Schema: public; Owner: tinuser
--

CREATE PROCEDURE public.copy_in(num_digits text)
    LANGUAGE plpgsql
    AS $$
declare n_partitions int;
begin 
	select ivalue from meta where svalue = 'n_partitions' limit 1 into n_partitions;
	for i in 0..n_partitions-1 loop
		execute(format('insert into for_hashvals (select left(right(sha256(catalog_content_p%s.supplier_code::bytea)::varchar, 4), %s) last2hash, catalog_content_p%s.supplier_code, catalog_content_p%s.cat_content_id from catalog_content_p%s)', i, num_digits, i, i, i));
	end loop;
end $$;


ALTER PROCEDURE public.copy_in(num_digits text) OWNER TO tinuser;

--
-- Name: copy_out(text); Type: PROCEDURE; Schema: public; Owner: tinuser
--

CREATE PROCEDURE public.copy_out(out_dest text)
    LANGUAGE plpgsql
    AS $_$
declare i text;
begin
	for i in select hashval from hashvals_list loop
		execute(format('copy (select supplier_code, (right(sha256(supplier_code::bytea)::varchar, 4)) last4hash, cat_content_id from for_hashvals_%1$s) to ''%2$s/%1$s''', i, out_dest));
	end loop;

end $_$;


ALTER PROCEDURE public.copy_out(out_dest text) OWNER TO tinuser;

--
-- Name: copy_out(text, text); Type: PROCEDURE; Schema: public; Owner: tinuser
--

CREATE PROCEDURE public.copy_out(out_dest text, machine_id text)
    LANGUAGE plpgsql
    AS $_$
declare i text;
begin
	for i in select hashval from hashvals_list loop
		execute(format('copy (select supplier_code, (right(sha256(supplier_code::bytea)::varchar, 4)) last4hash, cat_content_id, ''%2$s'' machine_id from for_hashvals_%1$s) to ''%2$s/%1$s''', i, out_dest));
	end loop;

end $_$;


ALTER PROCEDURE public.copy_out(out_dest text, machine_id text) OWNER TO tinuser;

--
-- Name: copy_tables(integer); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.copy_tables(upload_full integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
begin
if upload_full = 1 then
	create table substance_t as select * from substance where 1=2;
	create table catalog_content_t as select * from catalog_content where 1=2;
	create table catalog_substance_t as select * from catalog_substance where 1=2;
else
	create table substance_t as table substance;
	create table catalog_content_t as table catalog_content;
	create table catalog_substance_t as table catalog_substance;
end if;
return 0;
end;
$$;


ALTER FUNCTION public.copy_tables(upload_full integer) OWNER TO tinuser;

--
-- Name: countchar(text, character); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.countchar(s text, c character) RETURNS integer
    LANGUAGE plpgsql
    AS $$
		declare
			r int;
		begin
			select (CHAR_LENGTH(s) - CHAR_LENGTH(REPLACE(s, c, ''))) into r;
			return r;
		end;
	$$;


ALTER FUNCTION public.countchar(s text, c character) OWNER TO tinuser;

--
-- Name: create_table_partitions(text, text); Type: PROCEDURE; Schema: public; Owner: tinuser
--

CREATE PROCEDURE public.create_table_partitions(tabname text, tmp text)
    LANGUAGE plpgsql
    AS $$

		declare
			n_partitions int;
			i int;
		begin
			select ivalue from public.meta where svalue = 'n_partitions' limit 1 into n_partitions;

			for i in 0..(n_partitions-1) loop

				execute(format('create %s table %s_p%s partition of %s for values with (modulus %s, remainder %s)', tmp, tabname, i, tabname, n_partitions, i));

			end loop;

		end;

	$$;


ALTER PROCEDURE public.create_table_partitions(tabname text, tmp text) OWNER TO tinuser;

--
-- Name: do_grouping(integer); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.do_grouping(i integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $_$
	declare
		--i int;
		j int;
		n int;
	begin
		--i := 0;
		while true loop
			--i := i + 1;
			j := 0;

			for j in 0..get_npartitions()-1 loop
			-- collapse groups by cat_id, and then insert into partitions by grp_id
				execute(format('insert into gGRP (select sub_id, cat_id, min(grp_id) over (partition by cat_id) as grp_id from gCAT_p%1$s)', j));
			end loop;

			-- take advantage of grp_id partitions to quickly calculate group statistics
			insert into gstats_t1 (
				select grp_id, count(grp_id) from gGRP group by (grp_id)
			);

			with grpstats_all as (
				select sub_id, cat_id, g.grp_id as grp_id, t0.grp_cnt as cnt_t0, t1.grp_cnt as cnt_t1 from gGRP g
                                        join gstats_t0 t0 on t0.grp_id = g.grp_id
                                        join gstats_t1 t1 on t1.grp_id = g.grp_id
                        ),
			grp_next as (
				insert into gSUB(sub_id, cat_id, grp_id) (
					select sub_id, cat_id, grp_id from grpstats_all where cnt_t0 != cnt_t1
				) returning *
                        )
			insert into gfinal (sub_id, cat_id, grp_id) (
				select sub_id, cat_id, grp_id from grpstats_all where cnt_t0 = cnt_t1
			);
			/*
			grp_sub_final as (
				insert into gSUBfinal (sub_id, grp_id) (
					select sub_id, grp_id from grpstats_all where cnt_t0 = cnt_t1 group by (grp_id, sub_id)
				) returning *
			),
			grp_cat_final as (
				insert into gCATfinal (cat_id, grp_id) (
					select cat_id, grp_id from grpstats_all where cnt_t0 = cnt_t1 group by (grp_id, cat_id)
				) returning *
			)*/
			--select 1 into n; -- hilariously, we need to have this "into n", otherwise psql will complain about no destination

			select count(*) from gSUB into n;
			if n = 0 then
				return true;
			end if;
			raise notice 'loop: i=%, n=%', i, n;

			truncate table gCAT;
			for j in 0..get_npartitions()-1 loop
				execute(format('insert into gCAT (select sub_id, cat_id, min(grp_id) over (partition by sub_id) as grp_id from gSUB_p%1$s)', j));
			end loop;

			truncate table gGRP;
			truncate table gSUB;
			-- swap statistics tables- we only need to hold on to the previous timestep's statistics
			truncate table gstats_t0;
			alter table gstats_t0 rename to gstats_tx;
			alter table gstats_t1 rename to gstats_t0;
			alter table gstats_tx rename to gstats_t1;

			return false;

		end loop;

	end $_$;


ALTER FUNCTION public.do_grouping(i integer) OWNER TO tinuser;

--
-- Name: do_grouping_iteration(text); Type: PROCEDURE; Schema: public; Owner: tinuser
--

CREATE PROCEDURE public.do_grouping_iteration(transaction_id text)
    LANGUAGE plpgsql
    AS $$
	declare
		success boolean;
		already_done boolean;
		iter int;
	begin
		already_done := false;
		select true from meta where varname = 'done_grouping' and svalue = transaction_id into already_done;
		if already_done then
			return;
		end if;
		select ivalue from meta where varname = 'grouping_iter' and svalue = transaction_id into iter;
		if iter is null then
			iter := 0;
		end if;
		if iter = 0 then
			call init_grouping();
			insert into meta(varname, svalue, ivalue) values ('grouping_iter', transaction_id, iter);
		end if;
		success := do_grouping(iter);
		update meta set ivalue = iter + 1 where varname = 'grouping_iter' and svalue = transaction_id;
		if success then
			call finalize_grouping();
			insert into meta(varname, svalue) values ('done_grouping', transaction_id);
		end if;
	end $$;


ALTER PROCEDURE public.do_grouping_iteration(transaction_id text) OWNER TO tinuser;

--
-- Name: do_update(text); Type: PROCEDURE; Schema: public; Owner: tinuser
--

CREATE PROCEDURE public.do_update(diff_destination text)
    LANGUAGE plpgsql
    AS $$
		declare
			i int;
			n_update int;
			n_partitions int;
			diff_fn text;
		begin
			select ivalue from meta where svalue = 'n_partitions' limit 1 into n_partitions;

			for i in 0..(n_partitions-1) loop
				raise info '||| % ||| % |||', i, clock_timestamp();

				select concat(diff_destination, '/sub_update_tranche_id/', format('%s', i)) into diff_fn;
				execute(format('copy (update substance_p%s sb set tranche_id = su.tranche_id from (select sb.smiles, su.tranche_id, sb.tranche_id as tranche_id_old from (select max(tranche_id) as tranche_id, smiles from smiles_update_src_p%s group by smiles) su left join (select tranche_id, smiles from substance_p%s) sb on su.smiles = sb.smiles where su.tranche_id != sb.tranche_id) su where sb.smiles = su.smiles returning sb.sub_id, sb.tranche_id, su.tranche_id_old) to ''%s'' delimiter '' ''', i, i, i, diff_fn));


				select concat(diff_destination, '/sup_update_cat_id/', format('%s', i)) into diff_fn;
				execute(format('copy (update catalog_content_p%s cc set cat_id_fk = cu.cat_id from (select cc.supplier_code, cu.cat_id, cc.cat_id_fk as cat_id_old from (select max(cat_id) as cat_id, supplier_code from supplier_update_src_p%s group by supplier_code) cu left join (select cat_id_fk, supplier_code from catalog_content_p%s) cc on cu.supplier_code = cc.supplier_code where cu.cat_id != cc.cat_id_fk) cu where cc.supplier_code = cu.supplier_code returning cc.cat_content_id, cc.cat_id_fk, cu.cat_id_old) to ''%s'' delimiter '' ''', i, i, i, diff_fn));

			end loop;
		end;
	$$;


ALTER PROCEDURE public.do_update(diff_destination text) OWNER TO tinuser;

--
-- Name: exec_diff3d(text); Type: PROCEDURE; Schema: public; Owner: tinuser
--

CREATE PROCEDURE public.exec_diff3d(diff_dest text)
    LANGUAGE plpgsql
    AS $_$
	declare 
		i int;
		tranche_id_ int;
		tranche_name_ text;
	begin
		for tranche_id_ in select tranche_id from tranches order by tranche_id asc loop
			execute(format('create temporary table not_built_out_p%1$s partition of not_built_out for values in (%2$s)', tranche_id_, tranche_id_));
		end loop;
		create temporary table not_built_out_pn partition of not_built_out for values in (null); -- catch any outliers here
		for i in 0..get_npartitions()-1 loop
			raise info 'resolving zinc ids for %', i;
			execute(format('insert into zinc_3d_map(sub_id, tranche_id, tarball_id) (select case when sub_id_wrong is null then sub_id else sub_id_right end, tranche_id, tarball_id from zinc_3d_mapt_p%1$s zm left join sub_dups_corrections sdc on zm.sub_id = sdc.sub_id_wrong)', i));
		end loop;
		for i in 0..get_npartitions()-1 loop
			raise info 'getting group info for %', i;
			--execute(format('update zinc_3d_map_p%1$s set sub_id = sdc.sub_id_right from sub_dups_corrections sdc where sub_id = sub_id_wrong', i));
			execute(format('update zinc_3d_map_p%1$s set grp_id = csb.grp_id from catalog_substance_p%2$s csb where sub_id = sub_id_fk', i, i));
			execute(format('insert into zinc_3d_map_grp(sub_id, tranche_id, tarball_id, grp_id) (select sub_id, tranche_id, tarball_id, grp_id from zinc_3d_map_p%1$s)', i));
			--execute(format('insert into not_built_sub_ids_p%(sub_id) (select sub_id_fk from catalog_substance_p% csb left join zinc_3d_map_p% zi on csb.grp_id = zi.grp_id where sub_id is null group by (sub_id_fk))', i, i, i));
		end loop;
		for i in 0..get_npartitions()-1 loop
			raise info 'getting not built for %', i;
			execute(format('insert into not_built_sub_id (sub_id) (select sub_id_fk from catalog_substance_grp_p%1$s csb left join zinc_3d_map_grp_p%2$s zm on csb.grp_id = zm.grp_id where zm.grp_id is null group by (sub_id_fk))', i, i));
		end loop;
		raise info 'fetching smiles for not built';
		call get_many_substances_by_id_('not_built_sub_id', 'not_built_out', true);

		for tranche_id_ in select tranche_id from tranches loop
			select tranche_name from tranches where tranche_id = tranche_id_ into tranche_name_;
			execute(format('copy (select * from not_built_out_p%1$s ) to ''%2$s/%3$s''', tranche_id_, diff_dest, tranche_name_));
		end loop;
		execute(format('copy (select * from not_built_out_pn) to ''%1$s/notfound''', diff_dest));
	end $_$;


ALTER PROCEDURE public.exec_diff3d(diff_dest text) OWNER TO tinuser;

--
-- Name: export_ids_from_catalog_content(); Type: PROCEDURE; Schema: public; Owner: tinuser
--

CREATE PROCEDURE public.export_ids_from_catalog_content()
    LANGUAGE plpgsql
    AS $$

		declare
			n_partitions int;
			i int;
		begin
			select ivalue from meta where svalue = 'n_partitions' limit 1 into n_partitions;

			for i in 0..(n_partitions-1) loop

				execute(format('insert into catalog_id (cat_content_id, cat_partition_fk) (select cat_content_id, %s from catalog_content_p%s)', i, i));

			end loop;

		end;

	$$;


ALTER PROCEDURE public.export_ids_from_catalog_content() OWNER TO tinuser;

--
-- Name: export_ids_from_substance(); Type: PROCEDURE; Schema: public; Owner: tinuser
--

CREATE PROCEDURE public.export_ids_from_substance()
    LANGUAGE plpgsql
    AS $$

		declare
			n_partitions int;
			i int;
		begin
			select ivalue from meta where svalue = 'n_partitions' limit 1 into n_partitions;

			for i in 0..(n_partitions-1) loop

				execute(format('insert into substance_id (sub_id, sub_partition_fk) (select sub_id, %s from substance_p%s)', i, i));

			end loop;

		end;

	$$;


ALTER PROCEDURE public.export_ids_from_substance() OWNER TO tinuser;

--
-- Name: finalize_grouping(); Type: PROCEDURE; Schema: public; Owner: tinuser
--

CREATE PROCEDURE public.finalize_grouping()
    LANGUAGE plpgsql
    AS $$
	begin
		drop table if exists catalog_substance_new;
		drop table if exists catalog_substance_cat_new;

		create table catalog_substance_new (sub_id_fk bigint, cat_content_fk bigint, grp_id bigint) partition by hash(sub_id_fk);
		create table catalog_substance_cat_new (sub_id_fk bigint, cat_content_fk bigint, grp_id bigint) partition by hash(cat_content_fk);
		call create_table_partitions('catalog_substance_new', '');
		call create_table_partitions('catalog_substance_cat_new', '');
		insert into catalog_substance_new (sub_id_fk, cat_content_fk, grp_id) (
		--	select sub_id, cat_id, sb.grp_id from gfinal sb natural join gCATfinal ct
			select sub_id, cat_id, grp_id from gfinal
		);
		insert into catalog_substance_cat_new (sub_id_fk, cat_content_fk, grp_id) (select sub_id_fk, cat_content_fk, grp_id from catalog_substance_new);
		--alter table gfinal rename to catalog_substance_grp_new;
		alter table gfinal rename column sub_id to sub_id_fk;
		alter table gfinal rename column cat_id to cat_content_fk;
		alter table gfinal rename to catalog_substance_grp_new;
		--insert into catalog_substance_grp_new (sub_id_fk, cat_content_fk, grp_id) (select sub_id_fk, cat_content_fk, grp_id from catalog_substance_new);

		alter table catalog_substance_new add primary key (sub_id_fk, cat_content_fk);
		alter table catalog_substance_cat_new add primary key (cat_content_fk, sub_id_fk); -- do it in reverse here so the index will actually accelerate cat_content_id queries
		alter table catalog_substance_grp_new add primary key (grp_id, sub_id_fk, cat_content_fk);

	-- swap out tables in second transaction- just in case some lock is acquired on main tables by virtue of their presence in the first commit block
		alter table catalog_substance rename to trash1;
		alter table catalog_substance_cat rename to trash2;
		alter table if exists catalog_substance_grp rename to trash3;
		drop table trash1 cascade;
		drop table trash2 cascade;
		drop table if exists trash3 cascade;

		call rename_table_partitions('catalog_substance_new', 'catalog_substance');
		call rename_table_partitions('catalog_substance_cat_new', 'catalog_substance_cat');
		call rename_table_partitions('gfinal', 'catalog_substance_grp');
		alter table catalog_substance_new rename to catalog_substance;
		alter table catalog_substance_cat_new rename to catalog_substance_cat;
		alter table catalog_substance_grp_new rename to catalog_substance_grp;

		drop table gSUB;
		drop table gCAT;
		drop table gGRP;
		drop table gstats_t0;
		drop table gstats_t1;

	end $$;


ALTER PROCEDURE public.finalize_grouping() OWNER TO tinuser;

--
-- Name: find_duplicate_rows_catcontent(); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.find_duplicate_rows_catcontent() RETURNS integer
    LANGUAGE plpgsql
    AS $_$
declare
	partition text;
	query text;
begin
	create temporary table cat_dups_corrections_t (
		like cat_dups_corrections
	);
	for partition in
	select
		*
	from
		get_table_partitions ('catalog_content_t') loop
			query := format('insert into cat_dups_corrections_t (select t.code_id, t.code_id_min from (select cat_content_id as code_id, min(cat_content_id) over (partition by supplier_code) as code_id_min from %1$s) t where t.code_id != t.code_id_min)', partition);
			execute (query);
			query := format('delete from %1$s cc using cat_dups_corrections_t cdc where cc.cat_content_id = cdc.code_id_wrong', partition);
			execute (query);
			insert into cat_dups_corrections (
				select
					*
				from
					cat_dups_corrections_t);
			truncate table cat_dups_corrections_t;
			raise notice '%', partition;
		end loop;
	drop table cat_dups_corrections_t;
	return 0;
end;
$_$;


ALTER FUNCTION public.find_duplicate_rows_catcontent() OWNER TO tinuser;

--
-- Name: find_duplicate_rows_catsubstance(); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.find_duplicate_rows_catsubstance() RETURNS integer
    LANGUAGE plpgsql
    AS $_$
declare
	partition text;
	query text;
begin
	create temporary table catsub_dups_corrections_t (
		cat_sub_itm_id bigint
	);
	for partition in
	select
		*
	from
		get_table_partitions ('catalog_substance_t') loop
			query := format('insert into catsub_dups_corrections_t (select t.cat_sub_itm_id from (select cat_sub_itm_id, min(cat_sub_itm_id) over (partition by sub_id_fk, cat_content_fk) as cat_sub_itm_id_min from %1$s) t where t.cat_sub_itm_id != t.cat_sub_itm_id_min)', partition);
			execute (query);
			query := format('delete from %1$s cs using catsub_dups_corrections_t csdc where cs.cat_sub_itm_id = csdc.cat_sub_itm_id', partition);
			execute (query);
			insert into catsub_dups_corrections (
				select
					*
				from
					catsub_dups_corrections_t);
			truncate table catsub_dups_corrections_t;
			raise notice '%', partition;
		end loop;
	drop table catsub_dups_corrections_t;
	return 0;
end;
$_$;


ALTER FUNCTION public.find_duplicate_rows_catsubstance() OWNER TO tinuser;

--
-- Name: find_duplicate_rows_substance(); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.find_duplicate_rows_substance() RETURNS integer
    LANGUAGE plpgsql
    AS $_$
declare
	partition text;
	query text;
begin
	create temporary table tranche_id_corrections_t (
		sub_id bigint,
		tranche_id_max smallint
	);
	create temporary table sub_dups_corrections_t (
		like sub_dups_corrections
	);
	for partition in
	select
		*
	from
		get_table_partitions ('substance_t') loop
			query := format('insert into sub_dups_corrections_t (select t.sub_id, t.sub_id_min from (select sub_id, min(sub_id) over (partition by smiles) as sub_id_min from %1$s) t where t.sub_id != t.sub_id_min)', partition);
			execute (query);
			query := format('delete from %1$s sb using sub_dups_corrections_t sdc where sb.sub_id = sdc.sub_id_wrong', partition);
			execute (query);
			-- needs some explanation
			-- sometimes there are duplicates of both sub_id and smiles in the table, with tranche_id being the only distinguishing field e.g (123, CCC, 1) & (123, CCC, 2)
			-- this is a rare occurence, but does seem to happen on occasion, so we deal with it here, only keeping the maximum tranche_id value
			-- we keep the max because sometimes tranche_id = 0 manages to be set, and we don't want to have any substances with tranche_id = 0
			-- make sure to keep record of anything deleted here, such that we can verify that a mismatched tranche_id for a zinc id lookup is valid
			query := format('insert into tranche_id_corrections_t(tranche_id_max, sub_id) (select max(tranche_id) as max_tranche_id, sub_id from %1$s group by sub_id having count(*) > 1)', partition);
			execute (query);
			-- performing this in a drawn out manner because apparently we can't "insert into X (delete from Y returning *)"
			query := format('insert into tranche_id_corrections(sub_id, tranche_id_wrong) (select sb.sub_id, sb.tranche_id from %1$s sb, tranche_id_corrections_t t where sb.sub_id = t.sub_id and sb.tranche_id <> t.tranche_id_max)', partition);
			execute (query);
			query := format('delete from %1$s sb using tranche_id_corrections_t t where sb.sub_id = t.sub_id and sb.tranche_id <> t.tranche_id_max', partition);
			execute (query);
			insert into sub_dups_corrections (
				select
					*
				from
					sub_dups_corrections_t);
			truncate sub_dups_corrections_t;
			truncate tranche_id_corrections_t;
			raise notice '%', partition;
		end loop;
	drop table sub_dups_corrections_t;
	drop table tranche_id_corrections_t;
	return 0;
end;
$_$;


ALTER FUNCTION public.find_duplicate_rows_substance() OWNER TO tinuser;

--
-- Name: get_cat_id_by_id_pfk(bigint, integer); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.get_cat_id_by_id_pfk(cc_id_q bigint, cat_partition_fk integer) RETURNS smallint
    LANGUAGE plpgsql
    AS $$
declare
	cat_id smallint;
begin
	if cat_partition_fk is null then
		return null;
	end if;
	execute(format('select cat_id_fk from catalog_content_p%s where cat_content_id = %s', cat_partition_fk, cc_id_q)) into cat_id;
	return cat_id;
end;
$$;


ALTER FUNCTION public.get_cat_id_by_id_pfk(cc_id_q bigint, cat_partition_fk integer) OWNER TO tinuser;

--
-- Name: get_code_by_id(bigint); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.get_code_by_id(cc_id_q bigint) RETURNS text
    LANGUAGE plpgsql
    AS $$

declare
	part_id int;
	code text;
begin
	if cc_id_q is null then
		return null;
	end if;
	select cat_partition_fk from catalog_id ccid where ccid.cat_content_id = cc_id_q into part_id;
	execute(format('select supplier_code from catalog_content_p%s where cat_content_id = %s', part_id, cc_id_q)) into code;
	return code;
end;

$$;


ALTER FUNCTION public.get_code_by_id(cc_id_q bigint) OWNER TO tinuser;

--
-- Name: get_code_by_id_pfk(bigint, integer); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.get_code_by_id_pfk(cc_id_q bigint, cat_partition_fk integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
declare
	code text;
begin
	if cat_partition_fk is null then
		return null;
	end if;
	execute(format('select supplier_code from catalog_content_p%s where cat_content_id = %s', cat_partition_fk, cc_id_q)) into code;
	return code;
end;
$$;


ALTER FUNCTION public.get_code_by_id_pfk(cc_id_q bigint, cat_partition_fk integer) OWNER TO tinuser;

--
-- Name: get_many_codes_by_id(text, text); Type: PROCEDURE; Schema: public; Owner: tinuser
--

CREATE PROCEDURE public.get_many_codes_by_id(code_id_input_tabname text, code_output_tabname text)
    LANGUAGE plpgsql
    AS $$
		begin
			call get_many_codes_by_id_(code_id_input_tabname, code_output_tabname, false);
		end;
	$$;


ALTER PROCEDURE public.get_many_codes_by_id(code_id_input_tabname text, code_output_tabname text) OWNER TO tinuser;

--
-- Name: get_many_codes_by_id(text, text, boolean); Type: PROCEDURE; Schema: public; Owner: tinuser
--

CREATE PROCEDURE public.get_many_codes_by_id(code_id_input_tabname text, code_output_tabname text, outputnull boolean)
    LANGUAGE plpgsql
    AS $$

		declare 
			retval text[];
			n_partitions int;
			i int;
			t_start timestamptz;
		begin
			t_start := clock_timestamp();
			create temporary table catids_by_catid (
				cat_content_id bigint
			) partition by hash(cat_content_id);

			call create_table_partitions('catids_by_catid'::text, 'temporary'::text);

			create temporary table catids_by_pfk (
				cat_content_id bigint,
				cat_partition_fk smallint
			) partition by list(cat_partition_fk);

			select ivalue from meta where svalue = 'n_partitions' limit 1 into n_partitions;
			for i in 0..(n_partitions-1) loop
				execute(format('create temporary table catids_by_pfk_p%s partition of catids_by_pfk for values in (%s)', i, i));
			end loop;

			create temporary table catids_by_pfk_pn partition of catids_by_pfk for values in (null);

			execute(format('insert into catids_by_catid (select cat_content_id from %s)', code_id_input_tabname));

			for i in 0..(n_partitions-1) loop
				execute(format('insert into catids_by_pfk (select cc.cat_content_id, ccid.cat_partition_fk from catids_by_catid_p%s cc left join catalog_id_p%s ccid on cc.cat_content_id = ccid.cat_content_id)', i, i));
			end loop;

			for i in 0..(n_partitions-1) loop
				execute(format('insert into %s (cat_content_id, supplier_code, cat_id_fk) (select cp.cat_content_id, cc.supplier_code, cc.cat_id_fk from catids_by_pfk_p%s cp left join catalog_content_p%s cc on cp.cat_content_id = cc.cat_content_id)', code_output_tabname, i, i));
			end loop;

			if outputnull then
				execute(format('insert into %s (cat_content_id) (select cat_content_id from catids_by_pfk_pn)', code_output_tabname));
			end if;

			drop table catids_by_catid;
			drop table catids_by_pfk;

			raise notice 'time spent=%s', clock_timestamp() - t_start;
		end;

	$$;


ALTER PROCEDURE public.get_many_codes_by_id(code_id_input_tabname text, code_output_tabname text, outputnull boolean) OWNER TO tinuser;

--
-- Name: get_many_codes_by_id_(text, text, boolean); Type: PROCEDURE; Schema: public; Owner: tinuser
--

CREATE PROCEDURE public.get_many_codes_by_id_(code_id_input_tabname text, code_output_tabname text, input_pre_partitioned boolean)
    LANGUAGE plpgsql
    AS $_$

                declare
                        retval text[];
                        n_partitions int;
                        i int;
                        t_start timestamptz;
			extra_columns text[];
			extra_cols_decl_type text;
			extra_cols_decl text;
			extra_cols_decl_cc text;
			extra_cols_decl_cp text;
                begin
			set enable_partitionwise_join = ON;

			extra_columns := get_shared_columns(code_id_input_tabname, code_output_tabname, 'cat_content_id', '{}');

			if array_length(extra_columns, 1) > 0 then
				extra_cols_decl_type := ',' || cols_declare_type(extra_columns);
				extra_cols_decl := ',' || cols_declare(extra_columns, '');
				extra_cols_decl_cc := ',' || cols_declare(extra_columns, 'cc.');
				extra_cols_decl_cp := ',' || cols_declare(extra_columns, 'cp.');
			else
				extra_cols_decl := '';
				extra_cols_decl_cc := '';
				extra_cols_decl_cp := '';
			end if;

                        t_start := clock_timestamp();
			if input_pre_partitioned then
				execute(format('alter table %s rename to catids_by_catid', code_id_input_tabname));
				call rename_table_partitions(code_id_input_tabname, 'catids_by_catid');
			else
				execute(format('create temporary table catids_by_catid (cat_content_id bigint %1$s) partition by hash(cat_content_id)', extra_cols_decl_type));
/*                      create temporary table catids_by_catid (
                                cat_content_id bigint
                        ) partition by hash(cat_content_id);*/

	                        call create_table_partitions('catids_by_catid'::text, 'temporary'::text);
				execute(format('insert into catids_by_catid (select cat_content_id %s from %s)', extra_cols_decl, code_id_input_tabname));
			end if;

			execute(format('create temporary table catids_by_pfk (cat_content_id bigint, cat_partition_fk smallint %1$s) partition by list(cat_partition_fk)', extra_cols_decl_type));
/*                      create temporary table catids_by_pfk (
                                cat_content_id bigint,
                                cat_partition_fk smallint
                        ) partition by list(cat_partition_fk);*/

                        select ivalue from meta where svalue = 'n_partitions' limit 1 into n_partitions;
                        for i in 0..(n_partitions-1) loop
                                execute(format('create temporary table catids_by_pfk_p%s partition of catids_by_pfk for values in (%s)', i, i));
                        end loop;

                        create temporary table catids_by_pfk_pn partition of catids_by_pfk for values in (null);

                        for i in 0..(n_partitions-1) loop
                                execute(format('insert into catids_by_pfk(cat_content_id, cat_partition_fk %3$s) (select cc.cat_content_id, ccid.cat_partition_fk %4$s from catids_by_catid_p%1$s cc left join catalog_id_p%1$s ccid on cc.cat_content_id = ccid.cat_content_id)', i, i, extra_cols_decl, extra_cols_decl_cc));
                        end loop;

                        for i in REVERSE (n_partitions-1)..0 loop
                                execute(format('insert into %1$s (cat_content_id, supplier_code, cat_id_fk %4$s) (select cp.cat_content_id, cc.supplier_code, cc.cat_id_fk %5$s from catids_by_pfk_p%2$s cp left join catalog_content_p%2$s cc on cp.cat_content_id = cc.cat_content_id)', code_output_tabname, i, i, extra_cols_decl, extra_cols_decl_cp));
                        end loop;

                        execute(format('insert into %1$s (cat_content_id %2$s) (select cat_content_id %2$s from catids_by_pfk_pn)', code_output_tabname, extra_cols_decl));

			if input_pre_partitioned then
				execute(format('alter table catids_by_catid rename to %s', code_id_input_tabname));
				call rename_table_partitions('catids_by_catid', code_id_input_tabname);
			else
                        	drop table catids_by_catid;
			end if;
                        drop table catids_by_pfk;

                        raise notice 'time spent=%s', clock_timestamp() - t_start;
                end;

        $_$;


ALTER PROCEDURE public.get_many_codes_by_id_(code_id_input_tabname text, code_output_tabname text, input_pre_partitioned boolean) OWNER TO tinuser;

--
-- Name: get_many_pairs_by_id(text, text); Type: PROCEDURE; Schema: public; Owner: tinuser
--

CREATE PROCEDURE public.get_many_pairs_by_id(pair_ids_input_tabname text, pairs_output_tabname text)
    LANGUAGE plpgsql
    AS $$
	begin
		call get_many_pairs_by_id_(pair_ids_input_tabname, pairs_output_tabname, false);
	end;
	$$;


ALTER PROCEDURE public.get_many_pairs_by_id(pair_ids_input_tabname text, pairs_output_tabname text) OWNER TO tinuser;

--
-- Name: get_many_pairs_by_id_(text, text, boolean); Type: PROCEDURE; Schema: public; Owner: tinuser
--

CREATE PROCEDURE public.get_many_pairs_by_id_(pair_ids_input_tabname text, pairs_output_tabname text, input_pre_partitioned boolean)
    LANGUAGE plpgsql
    AS $$
	declare msg text;
	begin
		/* (sub_id bigint, cat_content_id bigint) -> (smiles text, code text, sub_id bigint, tranche_id smallint, cat_id_fk smallint) */
		create temporary table pairs_tempload (smiles text, sub_id bigint, cat_content_id bigint, tranche_id smallint) partition by hash(cat_content_id);
		call create_table_partitions('pairs_tempload', 'temporary');

		call get_many_substances_by_id_(pair_ids_input_tabname, 'pairs_tempload', input_pre_partitioned);

		call get_many_codes_by_id_('pairs_tempload', pairs_output_tabname, true);

		drop table pairs_tempload;

	end;
	$$;


ALTER PROCEDURE public.get_many_pairs_by_id_(pair_ids_input_tabname text, pairs_output_tabname text, input_pre_partitioned boolean) OWNER TO tinuser;

--
-- Name: get_many_substances_by_id(text, text); Type: PROCEDURE; Schema: public; Owner: tinuser
--

CREATE PROCEDURE public.get_many_substances_by_id(sub_id_input_tabname text, substance_output_tabname text)
    LANGUAGE plpgsql
    AS $$
	begin
		call get_many_substances_by_id_(sub_id_input_tabname, substance_output_tabname, false);
	end;
	$$;


ALTER PROCEDURE public.get_many_substances_by_id(sub_id_input_tabname text, substance_output_tabname text) OWNER TO tinuser;

--
-- Name: get_many_substances_by_id(text, text, text); Type: PROCEDURE; Schema: public; Owner: tinuser
--

CREATE PROCEDURE public.get_many_substances_by_id(sub_id_input_tabname text, substance_output_tabname text, extra_field text)
    LANGUAGE plpgsql
    AS $$

		declare 
			retval text[];
			n_partitions int;
			i int;
			t_start timestamptz;
		begin
			t_start := clock_timestamp();

			if not extra_field is null then
				execute(format('create temporary table subids_by_subid (sub_id bigint, %s %s) partition by hash(sub_id)', sc_colname(extra_field), sc_coltype(extra_field)));
			else
				create temporary table subids_by_subid (
					sub_id bigint
				) partition by hash(sub_id);
			end if;

			call create_table_partitions('subids_by_subid'::text, 'temporary'::text);

			if not extra_field is null then
				execute(format('create temporary table subids_by_pfk (sub_id bigint, sub_partition_fk smallint, %s %s) partition by list(sub_partition_fk)', sc_colname(extra_field), sc_coltype(extra_field)));
			else
				create temporary table subids_by_pfk (
					sub_id bigint,
					sub_partition_fk smallint
				) partition by list(sub_partition_fk);
			end if;

			select ivalue from meta where svalue = 'n_partitions' limit 1 into n_partitions;
			for i in 0..(n_partitions-1) loop
				execute(format('create temporary table subids_by_pfk_p%s partition of subids_by_pfk for values in (%s)', i, i));
			end loop;

			create temporary table subids_by_pfk_pn partition of subids_by_pfk for values in (null);

			execute(format('insert into subids_by_subid (select sub_id%s from %s)', sub_id_input_tabname));

			for i in 0..(n_partitions-1) loop
				execute(format('insert into subids_by_pfk (select ss.sub_id, sbid.sub_partition_fk from subids_by_subid_p%s ss left join substance_id_p%s sbid on ss.sub_id = sbid.sub_id)', i, i));
			end loop;

			for i in 0..(n_partitions-1) loop
				execute(format('insert into %s (sub_id, smiles, tranche_id) (select sp.sub_id, sb.smiles, sb.tranche_id from subids_by_pfk_p%s sp left join substance_p%s sb on sp.sub_id = sb.sub_id)', substance_output_tabname, i, i));
			end loop;

			execute(format('insert into %s (sub_id) (select sub_id from subids_by_pfk_pn)', substance_output_tabname));

			drop table subids_by_subid;
			drop table subids_by_pfk;

			raise notice 'time spent=%s', clock_timestamp() - t_start;
		end;

	$$;


ALTER PROCEDURE public.get_many_substances_by_id(sub_id_input_tabname text, substance_output_tabname text, extra_field text) OWNER TO tinuser;

--
-- Name: get_many_substances_by_id_(text, text, boolean); Type: PROCEDURE; Schema: public; Owner: tinuser
--

CREATE PROCEDURE public.get_many_substances_by_id_(sub_id_input_tabname text, substance_output_tabname text, input_pre_partitioned boolean)
    LANGUAGE plpgsql
    AS $_$

                declare
                        retval text[];
                        n_partitions int;
                        i int;
                        t_start timestamptz;
			extra_cols text[];
			extra_cols_decl text;
			extra_cols_decl_type text;
			extra_cols_decl_ss text;
			extra_cols_decl_sp text;
                begin
                        t_start := clock_timestamp();

			extra_cols := get_shared_columns(sub_id_input_tabname, substance_output_tabname, '', '{{"tranche_id"},{"smiles"},{"sub_id"}}');

			if array_length(extra_cols, 1) > 0 then
				extra_cols_decl_type := ',' || cols_declare_type(extra_cols);
				extra_cols_decl := ',' || cols_declare(extra_cols, '');
				extra_cols_decl_ss := ',' || cols_declare(extra_cols, 'ss.');
				extra_cols_decl_sp := ',' || cols_declare(extra_cols, 'sp.');
			else
				extra_cols_decl := '';
				extra_cols_decl_type := '';
				extra_cols_decl_ss := '';
				extra_cols_decl_sp := '';
			end if;

			if input_pre_partitioned then
				execute(format('alter table %s rename to subids_by_subid', sub_id_input_tabname));
				call rename_table_partitions(sub_id_input_tabname, 'subids_by_subid');
			else
				execute(format('create temporary table subids_by_subid (sub_id bigint %1$s) partition by hash(sub_id)', extra_cols_decl_type));
/*			create temporary table subids_by_subid (
				sub_id bigint
			) partition by hash(sub_id);*/

	                        call create_table_partitions('subids_by_subid'::text, 'temporary'::text);
				execute(format('insert into subids_by_subid (select sub_id %s from %s)', extra_cols_decl, sub_id_input_tabname));
			end if;

			execute(format('create temporary table subids_by_pfk (sub_id bigint, sub_partition_fk smallint %1$s) partition by list(sub_partition_fk)', extra_cols_decl_type));
/*			create temporary table subids_by_pfk (
				sub_id bigint,
				sub_partition_fk smallint
			) partition by list(sub_partition_fk);*/

                        select ivalue from meta where svalue = 'n_partitions' limit 1 into n_partitions;
                        for i in 0..(n_partitions-1) loop
                                execute(format('create temporary table subids_by_pfk_p%s partition of subids_by_pfk for values in (%s)', i, i));
                        end loop;

                        create temporary table subids_by_pfk_pn partition of subids_by_pfk for values in (null);

                        for i in 0..(n_partitions-1) loop
                                execute(format('insert into subids_by_pfk (select ss.sub_id, sbid.sub_partition_fk %3$s from subids_by_subid_p%1$s ss left join substance_id_p%1$s sbid on ss.sub_id = sbid.sub_id)', i, i, extra_cols_decl_ss));
				if not input_pre_partitioned then
					execute(format('drop table subids_by_subid_p%s', i));
				end if;
                        end loop;


			-- I theorize that going in reverse on the next iteration will improve cache access
			-- partition populated more recently == more likely in cache
                        for i in REVERSE (n_partitions-1)..0 loop
                                execute(format('insert into %1$s (sub_id, smiles, tranche_id %5$s) (select sp.sub_id, sb.smiles, sb.tranche_id %4$s from subids_by_pfk_p%2$s sp left join substance_p%2$s sb on sp.sub_id = sb.sub_id)', substance_output_tabname, i, i, extra_cols_decl_sp, extra_cols_decl));
				execute(format('drop table subids_by_pfk_p%s', i));
                        end loop;

                        execute(format('insert into %1$s (sub_id %2$s) (select sub_id %2$s from subids_by_pfk_pn)', substance_output_tabname, extra_cols_decl));

			if input_pre_partitioned then
				execute(format('alter table subids_by_subid rename to %s', sub_id_input_tabname));
				call rename_table_partitions('subids_by_subid', sub_id_input_tabname);
			else
                        	drop table subids_by_subid;
			end if;
                        drop table subids_by_pfk;

                        raise notice 'time spent=%s', clock_timestamp() - t_start;
                end;

        $_$;


ALTER PROCEDURE public.get_many_substances_by_id_(sub_id_input_tabname text, substance_output_tabname text, input_pre_partitioned boolean) OWNER TO tinuser;

--
-- Name: get_npartitions(); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.get_npartitions() RETURNS integer
    LANGUAGE plpgsql
    AS $$
	begin
		return (select ivalue from meta where svalue = 'n_partitions' limit 1);
	end $$;


ALTER FUNCTION public.get_npartitions() OWNER TO tinuser;

--
-- Name: get_shared_columns(text, text, text, text[]); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.get_shared_columns(tab1 text, tab2 text, excl1 text, excl2 text[]) RETURNS text[]
    LANGUAGE plpgsql
    AS $$
DECLARE
	shared_cols text[];
BEGIN
	RAISE info '%', excl2;
	RAISE info '%', 'a' = ANY (excl2);
	SELECT
		INTO shared_cols array_agg(concat(t1.col, ':', t1.dtype))
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
			AND attnum > 0) t2 ON t1.col = t2.col
WHERE
	t1.col != excl1
		AND NOT t1.col = ANY (excl2);
	RETURN shared_cols;
END;
$$;


ALTER FUNCTION public.get_shared_columns(tab1 text, tab2 text, excl1 text, excl2 text[]) OWNER TO tinuser;

--
-- Name: get_some_codes_by_id(text, text); Type: PROCEDURE; Schema: public; Owner: tinuser
--

CREATE PROCEDURE public.get_some_codes_by_id(code_id_input_tabname text, code_output_tabname text)
    LANGUAGE plpgsql
    AS $_$
declare
	extrafields text[];
	extrafields_decl_it text;
	extrafields_decl text;
	subquery_1 text;
	subquery_2 text;
	query text;
begin
	extrafields := get_shared_columns(code_id_input_tabname, code_output_tabname, 'cat_content_id', '{}');

	if array_length(extrafields, 1) > 0 then
		extrafields_decl_it := ',' || cols_declare(extrafields, 'it.');
		extrafields_decl := ',' || cols_declare(extrafields, '');
	else
		extrafields_decl := '';
		extrafields_decl_it := '';
	end if;

	subquery_1 := format('select cid.cat_content_id, cid.cat_partition_fk %1$s from %2$s it left join catalog_id cid on it.cat_content_id = cid.cat_content_id order by cat_partition_fk', extrafields_decl_it, code_id_input_tabname);

	subquery_2 := format('select get_code_by_id_pfk(cat_content_id, cat_partition_fk) supplier_code, cat_content_id, get_cat_id_by_id_pfk(cat_content_id, cat_partition_fk) cat_id %1$s from (%2$s) t', extrafields_decl, subquery_1);

	query := format('insert into %3$s (supplier_code, cat_content_id, cat_id_fk %1$s) (%2$s)', extrafields_decl, subquery_2, code_output_tabname);

	execute(query);
end;
$_$;


ALTER PROCEDURE public.get_some_codes_by_id(code_id_input_tabname text, code_output_tabname text) OWNER TO tinuser;

--
-- Name: get_some_pairs_by_code_id(text, text); Type: PROCEDURE; Schema: public; Owner: tinuser
--

CREATE PROCEDURE public.get_some_pairs_by_code_id(code_ids_input_tabname text, pairs_output_tabname text)
    LANGUAGE plpgsql
    AS $$
declare cols text[];
begin
	create temporary table pairs_tempload_p1 (sub_id bigint, cat_content_id bigint, tranche_id smallint);
	create temporary table pairs_tempload_p2 (smiles text, sub_id bigint, tranche_id smallint, cat_content_id bigint);

	execute(format('insert into pairs_tempload_p1(sub_id, cat_content_id, tranche_id) (select sub_id_fk, cat_content_fk, tranche_id from %s i left join catalog_substance_cat cs on i.cat_content_id = cs.cat_content_fk)', code_ids_input_tabname));

	call get_some_substances_by_id('pairs_tempload_p1', 'pairs_tempload_p2');

	call get_some_codes_by_id('pairs_tempload_p2', pairs_output_tabname);
end;
$$;


ALTER PROCEDURE public.get_some_pairs_by_code_id(code_ids_input_tabname text, pairs_output_tabname text) OWNER TO tinuser;

--
-- Name: get_some_pairs_by_sub_id(text, text); Type: PROCEDURE; Schema: public; Owner: tinuser
--

CREATE PROCEDURE public.get_some_pairs_by_sub_id(sub_ids_input_tabname text, pairs_output_tabname text)
    LANGUAGE plpgsql
    AS $$
declare cols text[];
begin
	create temporary table pairs_tempload_p1 (sub_id bigint, cat_content_id bigint);
	create temporary table pairs_tempload_p2 (smiles text, sub_id bigint, tranche_id smallint, cat_content_id bigint);

	execute(format('insert into pairs_tempload_p1(sub_id, cat_content_id) (select i.sub_id, cat_content_fk from %s i left join catalog_substance cs on i.sub_id = cs.sub_id_fk)', sub_ids_input_tabname));

	call get_some_substances_by_id('pairs_tempload_p1', 'pairs_tempload_p2');

	call get_some_codes_by_id('pairs_tempload_p2', pairs_output_tabname);
end;
$$;


ALTER PROCEDURE public.get_some_pairs_by_sub_id(sub_ids_input_tabname text, pairs_output_tabname text) OWNER TO tinuser;

--
-- Name: get_some_substances_by_id(text, text); Type: PROCEDURE; Schema: public; Owner: tinuser
--

CREATE PROCEDURE public.get_some_substances_by_id(sub_id_input_tabname text, substance_output_tabname text)
    LANGUAGE plpgsql
    AS $_$
declare
	extrafields text[];
	extrafields_decl_it text;
	extrafields_decl text;
	subquery_1 text;
	subquery_2 text;
	query text;
begin
	extrafields := get_shared_columns(sub_id_input_tabname, substance_output_tabname, 'sub_id', '{{"tranche_id:smallint"}}');

	if array_length(extrafields, 1) > 0 then
		extrafields_decl_it := ',' || cols_declare(extrafields, 'it.');
		extrafields_decl := ',' || cols_declare(extrafields, '');
	else
		extrafields_decl := '';
		extrafields_decl_it := '';
	end if;

	subquery_1 := format('select it.sub_id, sid.sub_partition_fk %1$s from %2$s it left join substance_id sid on it.sub_id = sid.sub_id order by sub_partition_fk', extrafields_decl_it, sub_id_input_tabname);

	subquery_2 := format('select get_substance_by_id_pfk(sub_id, sub_partition_fk) as smiles, get_tranche_by_id_pfk(sub_id, sub_partition_fk) tranche_id, sub_id %1$s from (%2$s) t', extrafields_decl, subquery_1);

	query := format('insert into %3$s (smiles, tranche_id, sub_id %1$s) (%2$s)', extrafields_decl, subquery_2, substance_output_tabname);
	execute(query);
end;
$_$;


ALTER PROCEDURE public.get_some_substances_by_id(sub_id_input_tabname text, substance_output_tabname text) OWNER TO tinuser;

--
-- Name: get_substance_by_id(bigint); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.get_substance_by_id(sub_id_q bigint) RETURNS text
    LANGUAGE plpgsql
    AS $$
declare
	part_id int;
	sub text;
begin
	select sub_partition_fk from substance_id sbid where sbid.sub_id = sub_id_q into part_id;
	if part_id is null then
		select sub_id_right from sub_dups_corrections where sub_id_wrong = sub_id_q into sub_id_q;
		if sub_id_q is null then
			return null;
		end if;
		select sub_partition_fk from substance_id sbid where sbid.sub_id = sub_id_q into part_id;
	end if;
	if part_id is null then
		return null;
	end if;
	execute(format('select smiles::varchar from substance_p%s where sub_id = %s', part_id, sub_id_q)) into sub;
	return sub;
end;

$$;


ALTER FUNCTION public.get_substance_by_id(sub_id_q bigint) OWNER TO tinuser;

--
-- Name: get_substance_by_id_pfk(bigint, smallint); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.get_substance_by_id_pfk(sub_id_q bigint, part_id smallint) RETURNS text
    LANGUAGE plpgsql
    AS $$
declare
	sub text;
begin
	if part_id is null then
		return get_substance_by_id(sub_id_q);
	end if;
	execute(format('select smiles::varchar from substance_p%s where sub_id = %s', part_id, sub_id_q)) into sub;
	return sub;
end;

$$;


ALTER FUNCTION public.get_substance_by_id_pfk(sub_id_q bigint, part_id smallint) OWNER TO tinuser;

--
-- Name: get_table_partitions(character varying); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.get_table_partitions(parent_table character varying) RETURNS TABLE(partition_name text)
    LANGUAGE plpgsql
    AS $$
begin
	return query execute ('select inhrelid::regclass::text as child from pg_catalog.pg_inherits where inhparent = ''' || parent_table || '''::regclass');
end;
$$;


ALTER FUNCTION public.get_table_partitions(parent_table character varying) OWNER TO tinuser;

--
-- Name: get_tranche_by_id(bigint); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.get_tranche_by_id(sub_id_q bigint) RETURNS smallint
    LANGUAGE plpgsql
    AS $$
declare
	tranche_id smallint;
	part_id smallint;
begin
	select sub_partition_fk from substance_id sbid where sbid.sub_id = sub_id_q into part_id;
	if part_id is null then
		select sub_id_right from sub_dups_corrections where sub_id_wrong = sub_id_q into sub_id_q;
		if sub_id_q is null then
			return null;
		end if;
		select sub_partition_fk from substance_id sbid where sbid.sub_id = sub_id_q into part_id;
	end if;
	if part_id is null then
		return null;
	end if;
	execute(format('select tranche_id::smallint from substance_p%s where sub_id = %s', part_id, sub_id_q)) into tranche_id;
	return tranche_id;
end;
$$;


ALTER FUNCTION public.get_tranche_by_id(sub_id_q bigint) OWNER TO tinuser;

--
-- Name: get_tranche_by_id_pfk(bigint, smallint); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.get_tranche_by_id_pfk(sub_id_q bigint, part_id smallint) RETURNS smallint
    LANGUAGE plpgsql
    AS $$
declare
	tranche_id smallint;
begin
	if part_id is null then
		return get_tranche_by_id(sub_id_q);
	end if;
	execute(format('select tranche_id::smallint from substance_p%s where sub_id = %s', part_id, sub_id_q)) into tranche_id;
	return tranche_id;
end;
$$;


ALTER FUNCTION public.get_tranche_by_id_pfk(sub_id_q bigint, part_id smallint) OWNER TO tinuser;

--
-- Name: init_grouping(); Type: PROCEDURE; Schema: public; Owner: tinuser
--

CREATE PROCEDURE public.init_grouping()
    LANGUAGE plpgsql
    AS $$
	begin
		create table gfinal (sub_id bigint, cat_id bigint, grp_id bigint) partition by hash(grp_id);
		--create temporary table gCATfinal (cat_id bigint, grp_id bigint) partition by hash(grp_id);
		call create_table_partitions('gfinal', '');
		--call create_table_partitions('gCATfinal', 'temporary');
		lock table gfinal;
		--lock table gCATfinal;

		create table gSUB (sub_id bigint, cat_id bigint, grp_id bigint) partition by hash(sub_id);
		create table gCAT (sub_id bigint, cat_id bigint, grp_id bigint) partition by hash(cat_id);
		create table gGRP (sub_id bigint, cat_id bigint, grp_id bigint) partition by hash(grp_id);
		call create_table_partitions('gSUB', '');
		call create_table_partitions('gCAT', '');
		call create_table_partitions('gGRP', '');
		--lock table gSUB;
		--lock table gCAT; -- according to StackOverflow this prevents locks from accumulating on temp tables
		--lock table gGRP; -- it seems that truncating a temporary table & continuing to work on it may leave locks hanging around

		-- in most cases grp_cnt can be a smallint, however in one particular case this limit was exceeded
		-- specifically by n-5-15:5435 (H29P340) - did we stereoexpand without limits at some point?
		create table gstats_t0 (grp_id bigint, grp_cnt int) partition by hash(grp_id);
		create table gstats_t1 (grp_id bigint, grp_cnt int) partition by hash(grp_id);
		call create_table_partitions('gstats_t0', '');
		call create_table_partitions('gstats_t1', '');
		--lock table gstats_t0;
		--lock table gstats_t1;

		-- insert initial groups via sub_id into gCAT for further grouping along cat_content_id
		insert into gCAT(sub_id, cat_id, grp_id) (
			select sub_id_fk, cat_content_fk, sub_id_fk from catalog_substance
		);
		-- "group id" is just sub_id on first iteration, so we can calculate group stats cheaply here
		insert into gstats_t0(grp_id, grp_cnt) (
			select sub_id_fk, count(sub_id_fk) from catalog_substance group by sub_id_fk
		);
	end $$;


ALTER PROCEDURE public.init_grouping() OWNER TO tinuser;

--
-- Name: invalidate_index(text); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.invalidate_index(indname text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE
        pg_index
    SET
        indisvalid = FALSE,
        indisready = FALSE
    WHERE
        indexrelid = (
            SELECT
                oid
            FROM
                pg_class
            WHERE
                relname = indname);
    RETURN 0;
END;
$$;


ALTER FUNCTION public.invalidate_index(indname text) OWNER TO tinuser;

--
-- Name: logg(text); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.logg(t text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE info '[%]: %', clock_timestamp(), t;
    RETURN 0;
END;
$$;


ALTER FUNCTION public.logg(t text) OWNER TO tinuser;

--
-- Name: process_zinc_id_upload(); Type: PROCEDURE; Schema: public; Owner: tinuser
--

CREATE PROCEDURE public.process_zinc_id_upload()
    LANGUAGE plpgsql
    AS $$
	declare
		n_partitions int;
		i int;
		j int;
		k int;
		n int;
		msg text;
	begin
		call get_many_substances_by_id('stage3', 'temp_load_fnd');
		-- entries inserted to this table *should* be fairly few and far-between
		-- mainly we are looking for a specific anomaly from substances that had backslashes accidentally removed - at one point, but we're also using this operation to merge missing & possibly conflicting ids from the 3D source files
		-- DONT select distinct, because it is always slow. i dont think postgres optimizes it for the partitions, unfortunately
		-- must guarantee distinct zinc ids beforehand (& distinct smiles!)
		insert into temp_load_mismatch_smi(smiles_in, smiles_fnd, sub_id, tranche_id) (select t.smiles_in, t.smiles_fnd, t.sub_id, t.tranche_id from (select tl.smiles as smiles_in, tlf.smiles as smiles_fnd, tl.sub_id, tl.tranche_id from stage3 tl left join temp_load_fnd tlf on tl.sub_id = tlf.sub_id where tl.smiles != tlf.smiles or tlf.smiles is NULL) t);
		-- postgres creates a very ugly plan for this update by default, so we "fix" it here and do it partitionwise
		select count(*) from stage3 into k;
		select count(*) from temp_load_fnd into j;
		select count(*) from temp_load_mismatch_smi into i;
		select smiles from temp_load_fnd into msg;
		select sub_id from temp_load_fnd into n;
		raise notice 'found % mismatched, % total fnd, % total; smiles samp=% sub_id=%', i, j, k, msg, n;
		select ivalue from meta where svalue = 'n_partitions' into n_partitions;
		for i in 0..n_partitions-1 loop
			execute('update temp_load_mismatch_smi_p' || i::text || ' tlmm set sub_id_fnd = sb.sub_id from substance_p' || i::text || ' sb where sb.smiles = tlmm.smiles_in');
			raise notice 'updating %', i;
		end loop;
		-- assume: smiles_fnd != smiles_in, sub_id != sub_id_fnd
		-- case 1
		-- sub_id_fnd not null, smiles_fnd not null wrong is smiles_in
		--	delete smiles_in, insert sub_id_fnd,sub_id into corrections
		-- case 2
		-- sub_id_fnd not null, smiles_fnd not null wrong is smiles_fnd
		-- 	delete smiles_fnd, insert sub_id,sub_id_fnd into corrections
		-- case 3
		-- sub_id_fnd not null, smiles_fnd null
		--	insert sub_id,sub_id_fnd into corrections
		-- case 4
		-- sub_id_fnd null smiles_fnd not null wrong is smiles_fnd
		--	delete smiles_fnd, insert smiles_in into substance
		-- case 5
		-- sub_id_fnd null smiles_fnd null
		--	insert smiles_in,sub_id into substance
		-- case 1- found different counterparts for smiles & sub_id on database, smiles input is incorrect compared to found smiles
		-- response: assume found smiles is correct, delete smiles input from database and remap found sub_id to sub_id
		create temporary table case1 (like case1_all);
		-- case 2- found different counterparts for smiles & sub_id on database, smiles input is correct compared to found smiles
		-- response: assume input smiles is correct, delete found smiles from database and map sub_id to found sub_id
		create temporary table case2 (like case2_all);
		-- case 3- found smiles on database (sub_id_fnd) but not sub_id, therefore map sub_id -> sub_id_fnd
		create temporary table case3 (like case3_all);
		-- case 4- found sub_id on database (smiles_fnd) but not smiles (sub_id_fnd) and smiles_fnd is wrong, therefore delete smiles_fnd and replace with smiles_in
		create temporary table case4 (like case4_all);
		-- case 5- found no counterparts on database, insert as a new molecule
		create temporary table case5 (like case5_all);
		-- case 6- counterpart of case4
		create temporary table case6 (like case6_all);
		insert into case1(smiles_in, smiles_fnd, sub_id_fnd, sub_id, smisim) (
			select smiles_in, smiles_fnd, sub_id_fnd, sub_id, similarity(smiles_in, smiles_fnd) from temp_load_mismatch_smi tlmm where not sub_id_fnd is null and not smiles_fnd is null and countchar(smiles_in, '\')<=countchar(smiles_fnd, '\'));
		insert into case2(smiles_fnd, smiles_in, sub_id, sub_id_fnd, smisim) (
			select smiles_fnd, smiles_in, sub_id, sub_id_fnd, similarity(smiles_in, smiles_fnd) from temp_load_mismatch_smi tlmm where not sub_id_fnd is null and not smiles_fnd is null and countchar(smiles_fnd, '\')<countchar(smiles_in, '\')); -- the final <= here means that on tie, we should trust the input as correct
		
		insert into case3(sub_id, sub_id_fnd) (
			select sub_id, sub_id_fnd from temp_load_mismatch_smi tlmm where not sub_id_fnd is null and smiles_fnd is null);
		insert into case4(smiles_fnd, smiles_in, sub_id, tranche_id, smisim) (
			select smiles_fnd, smiles_in, sub_id, tranche_id, similarity(smiles_in, smiles_fnd) from temp_load_mismatch_smi tlmm where sub_id_fnd is null and not smiles_fnd is null and countchar(smiles_fnd, '\')<countchar(smiles_in, '\'));
		insert into case5(smiles, sub_id, tranche_id) (
			select smiles_in, sub_id, tranche_id from temp_load_mismatch_smi tlmm where smiles_fnd is null and sub_id_fnd is null);
		-- case 6- found smiles_fnd but not sub_id_fnd and smiles_fnd is correct, therefore don't change anything
		-- won't change the database, but should be logged for posterity
		insert into case6(smiles_fnd, smiles_in, sub_id, tranche_id, smisim) (
			select smiles_fnd, smiles_in, sub_id, tranche_id, similarity(smiles_in, smiles_fnd) from temp_load_mismatch_smi tlmm where sub_id_fnd is null and not smiles_fnd is null and countchar(smiles_fnd, '\')>=countchar(smiles_in, '\'));
		with substance_delete as (
			delete from substance sb using (select smiles_in as smi from case1 union all select smiles_fnd as smi from case2 union all select smiles_fnd as smi from case4) t where sb.smiles = t.smi returning sub_id
		)
		delete from substance_id si using substance_delete sd where si.sub_id = sd.sub_id;
		insert into sub_dups_corrections(sub_id_wrong, sub_id_right) (select sub_id_fnd sw, sub_id sr from case1 union all select sub_id sw, sub_id_fnd sr from case2 union all select sub_id sw, sub_id_fnd sr from case3);
		update sub_dups_corrections set sub_id_right = t.sr from (select sub_id_fnd sw, sub_id sr from case1 union all select sub_id sw, sub_id_fnd sr from case2 union all select sub_id sw, sub_id_fnd sr from case3) t where sub_id_right = t.sw;
		with substance_insert as (
			insert into substance(smiles, sub_id, tranche_id) (select smiles_in as smiles, sub_id, tranche_id from case4 union all select smiles, sub_id, tranche_id from case5) returning sub_id, tableoid
		)
		insert into substance_id(sub_id, sub_partition_fk) (select sub_id, pfk from substance_insert si join oid_to_pfk op on si.tableoid = op.toid);
		-- clean up temp tables & push results to case tables
		insert into case1_all (select * from case1);
		insert into case2_all (select * from case2);
		insert into case3_all (select * from case3);
		insert into case4_all (select * from case4);
		insert into case5_all (select * from case5);
		insert into case6_all (select * from case6);
		drop table case1;
		drop table case2;
		drop table case3;
		drop table case4;
		drop table case5;
		drop table case6;
		truncate table temp_load_fnd;
		truncate table temp_load_mismatch_smi;
		
	end $$;


ALTER PROCEDURE public.process_zinc_id_upload() OWNER TO tinuser;

--
-- Name: rename_table_partitions(text, text); Type: PROCEDURE; Schema: public; Owner: tinuser
--

CREATE PROCEDURE public.rename_table_partitions(tabname text, desiredname text)
    LANGUAGE plpgsql
    AS $_$
declare
        n_partitions int;
        i int;
begin
        select
                ivalue
        from
                meta
        where
                svalue = 'n_partitions'
        limit 1 into n_partitions;
        for i in 0.. (n_partitions - 1)
        loop
                execute (format('alter table if exists %s_p%s rename to %s_p%s', tabname, i, desiredname, i));
		execute (format('alter table if exists %1$sp%2$s rename to %s_p%s', tabname, i, desiredname, i));
        end loop;
end;
$_$;


ALTER PROCEDURE public.rename_table_partitions(tabname text, desiredname text) OWNER TO tinuser;

--
-- Name: sc_colname(text); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.sc_colname(scol text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN SPLIT_PART(scol, ':', 1);
END;
$$;


ALTER FUNCTION public.sc_colname(scol text) OWNER TO tinuser;

--
-- Name: sc_coltype(text); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.sc_coltype(scol text) RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
	RETURN SPLIT_PART(scol, ':', 2);
END;
$$;


ALTER FUNCTION public.sc_coltype(scol text) OWNER TO tinuser;

--
-- Name: smash_duplicates(text); Type: PROCEDURE; Schema: public; Owner: tinuser
--

CREATE PROCEDURE public.smash_duplicates(diff_destination text)
    LANGUAGE plpgsql
    AS $_$
	declare
		i int;
		n int;
	begin
		select ivalue from meta where svalue = 'n_partitions' into n;
		for i in 0..n-1 loop
			execute(format('with sub_to_del as (delete from substance_id_new_p%1$s si using (select ctid as si_ctid, ROW_NUMBER() over (partition by sub_id) as rn from substance_id_new_p%1$s si) t where t.rn > 1 and si.ctid = t.si_ctid returning *) insert into substance_to_delete(sub_id, sub_partition_fk, sb_ctid) (select sub_id, sub_partition_fk, substance_ctid from sub_to_del)', i::text));
		end loop;
		for i in 0..n-1 loop
			-- ctid should remain stable so long as all updates on the table using ctid are constrained to a single transaction
			-- we use multiple transactions, but only one per partition, meaning recorded row physical location (ctid) should not change over the course of the operation
			-- we shall see if this is the case...
			execute(format('copy (delete from substance_p%1$s sb using substance_to_delete_p%1$s sd where sd.sb_ctid = sb.ctid returning *) to ''%2$s/delsub/%1$s''', i::text, diff_destination));
		end loop;
	end $_$;


ALTER PROCEDURE public.smash_duplicates(diff_destination text) OWNER TO tinuser;

--
-- Name: upload(integer, integer, text); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.upload(stage integer, part integer, transid text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
		begin
			case
				when stage = 1 then
					perform upload_substance_bypart(part, transid);
					raise notice 'finished substance bypart';
				when stage = 2 then
					perform upload_catcontent_bypart(part, transid);
				when stage = 3 then
					perform upload_catsub_bypart(part, transid);
				else
					raise EXCEPTION 'upload stage not defined! %', stage;
					return 1;
			end case;
			return 0;
		end;
	$$;


ALTER FUNCTION public.upload(stage integer, part integer, transid text) OWNER TO tinuser;

--
-- Name: upload(integer, integer, text, text); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.upload(stage integer, part integer, transid text, diff_file_dest text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
		begin
			case
				when stage = 1 then
					perform upload_substance_bypart(part, transid, diff_file_dest);
					raise notice 'finished substance bypart';
				when stage = 2 then
					perform upload_catcontent_bypart(part, transid, diff_file_dest);
				when stage = 3 then
					perform upload_catsub_bypart(part, transid, diff_file_dest);
				else
					raise EXCEPTION 'upload stage not defined! %', stage;
					return 1;
			end case;
			return 0;
		end;
	$$;


ALTER FUNCTION public.upload(stage integer, part integer, transid text, diff_file_dest text) OWNER TO tinuser;

--
-- Name: upload_bypart(integer, text, text, text, text[], text, text, text); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.upload_bypart(partition integer, loadtable text, desttable text, nexttable text, keyfields text[], idfield text, destseq text, filediff text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
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
$_$;


ALTER FUNCTION public.upload_bypart(partition integer, loadtable text, desttable text, nexttable text, keyfields text[], idfield text, destseq text, filediff text) OWNER TO tinuser;

--
-- Name: upload_catcontent_bypart(integer, text); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.upload_catcontent_bypart(part integer, transid text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
		declare
			tempvar int;
			cntnew int;
			cntupload int;

		begin
			create temporary sequence tl_temp_id_seq;

			create temporary table temp_load_part_cat (
				sub_id bigint,
				code varchar,
				code_id bigint,
				tranche_id smallint,
				cat_id smallint,
				temp_id int default nextval('tl_temp_id_seq')
			);

			-- dynamic execution
			/*
			insert into temp_load_part_cat(sub_id, code, code_id, tranche_id, cat_id) (
				select 
					tl.sub_id, tl.code, cc.cat_content_id, tl.tranche_id, tl.cat_id
				from
					temp_load_p2_pXX tl
				left join
					catalog_content_pXX cc
				on
					tl.code = cc.code
			);*/
			execute(format('insert into temp_load_part_cat(sub_id, code, code_id, tranche_id, cat_id) (select tl.sub_id, tl.code, cc.cat_content_id, tl.tranche_id, tl.cat_id from temp_load_p2_p%s tl left join catalog_content_p%s cc on tl.code = cc.supplier_code)', part, part));

			alter table temp_load_part_cat add primary key(temp_id);

			select count(*) from temp_load_part_cat into cntupload;

			create temporary table new_codes (
				code varchar,
				code_id bigint,
				cat_id smallint,
				rn int,
				temp_id int
			);

			alter table new_codes add constraint temp_id_fk foreign key (temp_id) references temp_load_part_cat(temp_id);

			insert into new_codes (
				select
					t.code,
					min(t.code_id) over w as code_id,
					t.cat_id,
					ROW_NUMBER() over w as rn,
					t.temp_id
				from
					(
						select
							tl.code,
							case when ROW_NUMBER() over w = 1 then nextval('cat_content_id_seq') else null end as code_id,
							tl.cat_id,
							tl.temp_id
						from
							temp_load_part_cat tl
						where
							tl.code_id is null
						window w as
					       		(partition by code)
					) t
				window w as
					(partition by code)
			);

			analyze new_codes;

			select count(*) from new_codes where rn = 1 into cntnew;

			raise notice '# new codes: %', cntnew;

			-- dynamic execution
			/*
			insert into catalog_content_pXX(supplier_code, cat_content_id, cat_id_fk) (
				select
					nc.code,
					nc.code_id,
					nc.cat_id
				from
					new_codes nc
				where
					nc.rn = 1
			);*/
			execute(format('insert into catalog_content_p%s (supplier_code, cat_content_id, cat_id_fk) (select nc.code, nc.code_id, nc.cat_id from new_codes nc where nc.rn = 1)', part));

			insert into temp_load_p3 (
				select 
					tl.sub_id,
					case when tl.code_id is null then nc.code_id else tl.code_id end,
					tl.tranche_id
				from
					temp_load_part_cat tl
				left join
					new_codes nc
				on
					tl.temp_id = nc.temp_id
			);

			execute(format('insert into transaction_record_%s (stagei, parti, nnew, nupload) (values (2, %s, %s, %s))', transid, part, cntnew, cntupload));

			-- cleanup
			execute(format('drop table temp_load_p2_p%s', part));
			drop table new_codes;
			drop table temp_load_part_cat;

			return 0;
		end;

	$$;


ALTER FUNCTION public.upload_catcontent_bypart(part integer, transid text) OWNER TO tinuser;

--
-- Name: upload_catcontent_bypart(integer, text, text); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.upload_catcontent_bypart(part integer, transid text, diff_file_dest text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
		declare
			tempvar int;
			cntnew int;
			cntupload int;

		begin
			create temporary sequence tl_temp_id_seq;

			create temporary table temp_load_part_cat (
				sub_id bigint,
				code varchar,
				code_id bigint,
				tranche_id smallint,
				cat_id smallint,
				temp_id int default nextval('tl_temp_id_seq')
			);

			-- dynamic execution
			/*
			insert into temp_load_part_cat(sub_id, code, code_id, tranche_id, cat_id) (
				select 
					tl.sub_id, tl.code, cc.cat_content_id, tl.tranche_id, tl.cat_id
				from
					temp_load_p2_pXX tl
				left join
					catalog_content_pXX cc
				on
					tl.code = cc.code
			);*/
			execute(format('insert into temp_load_part_cat(sub_id, code, code_id, tranche_id, cat_id) (select tl.sub_id, tl.code, cc.cat_content_id, tl.tranche_id, tl.cat_id from temp_load_p2_p%s tl left join catalog_content_p%s cc on tl.code = cc.supplier_code)', part, part));

			alter table temp_load_part_cat add primary key(temp_id);

			select count(*) from temp_load_part_cat into cntupload;

			create temporary table new_codes (
				code varchar,
				code_id bigint,
				cat_id smallint,
				rn int,
				temp_id int
			);

			alter table new_codes add constraint temp_id_fk foreign key (temp_id) references temp_load_part_cat(temp_id);

			insert into new_codes(code, code_id, cat_id, rn, temp_id) (
				select
					t.code,
					min(t.code_id) over w as code_id,
					t.cat_id,
					ROW_NUMBER() over w as rn,
					t.temp_id
				from
					(
						select
							tl.code,
							case when ROW_NUMBER() over w = 1 then nextval('cat_content_id_seq') else null end as code_id,
							tl.cat_id,
							tl.temp_id
						from
							temp_load_part_cat tl
						where
							tl.code_id is null
						window w as
					       		(partition by code)
					) t
				window w as
					(partition by code)
			);

			analyze new_codes;

			select count(*) from new_codes where rn = 1 into cntnew;

			raise notice '# new codes: %', cntnew;

			-- dynamic execution
			/*
			insert into catalog_content_pXX(supplier_code, cat_content_id, cat_id_fk) (
				select
					nc.code,
					nc.code_id,
					nc.cat_id
				from
					new_codes nc
				where
					nc.rn = 1
			);*/
			execute(format('copy (insert into catalog_content_p%s (supplier_code, cat_content_id, cat_id_fk) (select nc.code, nc.code_id, nc.cat_id from new_codes nc where nc.rn = 1) returning *) to ''%s/cat/%s''', part, diff_file_dest, part));
			execute(format('insert into catalog_id (cat_content_id, cat_partition_fk) (select code_id, %s from new_codes nc where nc.rn = 1)', part));

			insert into temp_load_p3(sub_id, code_id, tranche_id) (
				select 
					tl.sub_id,
					case when tl.code_id is null then nc.code_id else tl.code_id end,
					tl.tranche_id
				from
					temp_load_part_cat tl
				left join
					new_codes nc
				on
					tl.temp_id = nc.temp_id
			);

			execute(format('insert into transaction_record_%s (stagei, parti, nnew, nupload) (values (2, %s, %s, %s))', transid, part, cntnew, cntupload));

			-- cleanup
			execute(format('drop table temp_load_p2_p%s', part));
			drop table new_codes;
			drop table temp_load_part_cat;

			return 0;
		end;

	$$;


ALTER FUNCTION public.upload_catcontent_bypart(part integer, transid text, diff_file_dest text) OWNER TO tinuser;

--
-- Name: upload_catsub_bypart(integer, text); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.upload_catsub_bypart(part integer, transid text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
		declare
			tempvar int;
			cntnew int;
			cntupload int;
		begin
			create temporary sequence tl_temp_id_seq;
			create temporary table temp_load_part_catsub (
				sub_id bigint,
				code_id bigint,
				cat_sub_itm_id bigint,
				tranche_id smallint,
				temp_id int default nextval('tl_temp_id_seq')
			);

			execute(format('insert into temp_load_part_catsub(sub_id, code_id, cat_sub_itm_id, tranche_id) (select tl.sub_id, tl.code_id, cs.cat_sub_itm_id, tl.tranche_id from temp_load_p3_p%s tl left join catalog_substance_p%s cs on tl.sub_id = cs.sub_id_fk and tl.code_id = cs.cat_content_fk)', part, part));
			alter table temp_load_part_catsub add primary key (temp_id);

			select count(*) from temp_load_part_catsub into cntupload;

			create temporary table new_entries (
				sub_id bigint,
				code_id bigint,
				cat_sub_itm_id bigint,
				tranche_id smallint,
				rn int,
				temp_id int
			);

			alter table new_entries add constraint temp_id_fk foreign key (temp_id) references temp_load_part_catsub(temp_id);

			insert into new_entries (
				select
					t.sub_id,
					t.code_id,
					min(t.cat_sub_itm_id) over w as cat_sub_itm_id,
					t.tranche_id,
					ROW_NUMBER() over w as rn,
					t.temp_id
				from
				(
					select
						tl.sub_id,
						tl.code_id,
						case when ROW_NUMBER() over w = 1 then nextval('cat_sub_itm_id_seq') else null end as cat_sub_itm_id,
						tl.tranche_id,
						tl.temp_id
					from
						temp_load_part_catsub tl
					where
						tl.cat_sub_itm_id is null
					window w as
						(partition by sub_id, code_id)
				) t
				window w as
					(partition by sub_id, code_id)
			);

			select count(*) from new_entries where rn = 1 into cntnew;

			-- dynamic execution
			/*
			insert into catalog_substance_pXX(sub_id_fk, cat_content_fk, tranche_id, cat_sub_itm_id) (
				select
					sub_id,
					code_id,
					tranche_id,
					cat_sub_itm_id
				from
					new_entries
				where
					rn = 1
			);
			*/

			execute(format('insert into catalog_substance_p%s (sub_id_fk, cat_content_fk, tranche_id, cat_sub_itm_id) (select sub_id, code_id, tranche_id, cat_sub_itm_id from new_entries where rn = 1)', part));

			execute(format('insert into transaction_record_%s (stagei, parti, nnew, nupload) (values (3, %s, %s, %s))', transid, part, cntnew, cntupload));

			execute(format('drop table temp_load_p3_p%s', part));
			drop table new_entries;
			drop table temp_load_part_catsub;

			return 0;

		end;
	$$;


ALTER FUNCTION public.upload_catsub_bypart(part integer, transid text) OWNER TO tinuser;

--
-- Name: upload_catsub_bypart(integer, text, text); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.upload_catsub_bypart(part integer, transid text, diff_file_dest text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
		declare
			tempvar int;
			cntnew int;
			cntupload int;
		begin
			create temporary sequence tl_temp_id_seq;
			create temporary table temp_load_part_catsub (
				sub_id bigint,
				code_id bigint,
				present bool
			);

			execute(format('insert into temp_load_part_catsub(sub_id, code_id, present) (select tl.sub_id, tl.code_id, not cs.sub_id_fk is null from temp_load_p3_p%s tl left join catalog_substance_p%s cs on tl.sub_id = cs.sub_id_fk and tl.code_id = cs.cat_content_fk)', part, part));
			--alter table temp_load_part_catsub add primary key (temp_id);

			select count(*) from temp_load_part_catsub into cntupload;

			create temporary table new_entries (
				sub_id bigint,
				code_id bigint,
				rn int
			);

			--alter table new_entries add constraint temp_id_fk foreign key (temp_id) references temp_load_part_catsub(temp_id);

			insert into new_entries(sub_id, code_id, rn) (
				select
					t.sub_id,
					t.code_id,
					ROW_NUMBER() over (partition by sub_id, code_id) as rn
				from
					temp_load_part_catsub t
				where
					not t.present
			);

			select count(*) from new_entries where rn = 1 into cntnew;

			-- dynamic execution
			/*
			insert into catalog_substance_pXX(sub_id_fk, cat_content_fk, tranche_id, cat_sub_itm_id) (
				select
					sub_id,
					code_id,
					tranche_id,
					cat_sub_itm_id
				from
					new_entries
				where
					rn = 1
			);
			*/

			execute(format('copy (insert into catalog_substance_p%s (sub_id_fk, cat_content_fk) (select sub_id, code_id from new_entries where rn = 1) returning *) to ''%s/catsub/%s''', part, diff_file_dest, part));

			execute(format('insert into transaction_record_%s (stagei, parti, nnew, nupload) (values (3, %s, %s, %s))', transid, part, cntnew, cntupload));

			execute(format('drop table temp_load_p3_p%s', part));
			drop table new_entries;
			drop table temp_load_part_catsub;

			return 0;

		end;
	$$;


ALTER FUNCTION public.upload_catsub_bypart(part integer, transid text, diff_file_dest text) OWNER TO tinuser;

--
-- Name: upload_substance_bypart(integer, text); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.upload_substance_bypart(part integer, transid text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
		declare
			tempvar int;
			cntupload int;
			cntnew int;

		begin
			-- temporary objects are unique to each session, so no need to worry about name overlap when we're executing this in parallel
			create temporary sequence tl_temp_id_seq;

			create temporary table temp_load_part_sub (

				smiles varchar,
				code varchar,
				sub_id bigint,
				tranche_id smallint,
				cat_id smallint,
				temp_id int default nextval('tl_temp_id_seq')
			);

			-- dynamic execution
			/*insert into temp_load_part_sub(smiles, code, sub_id, tranche_id, cat_id) (

				select 
					tl.smiles, tl.code, sb.sub_id, tl.tranche_id
				from
					temp_load_p1_pXX tl
				left join
					substance_pXX sb
				on tl.smiles = sb.smiles
			);*/
			execute(format('insert into temp_load_part_sub(smiles, code, sub_id, tranche_id, cat_id) (select tl.smiles, tl.code, sb.sub_id, tl.tranche_id, tl.cat_id from temp_load_p1_p%s tl left join substance_p%s sb on tl.smiles = sb.smiles)', part, part));
			select count(*) from temp_load_part_sub into cntupload;

			alter table temp_load_part_sub add primary key (temp_id);

			create temporary table new_substances (

                                smiles varchar,
                                sub_id bigint,
				rn int, -- used to track unique substances. rn = 1 means this is a unique instance of a substance
                                tranche_id smallint,
                                temp_id int
                        );

			alter table new_substances add constraint temp_id_fk foreign key (temp_id) references temp_load_part_sub(temp_id);

			insert into new_substances (

				select 
					t.smiles, 
					min(sub_id) over w as sub_id,
					ROW_NUMBER() over w as rn,
					t.tranche_id, 
					t.temp_id 
				from
				(
					select
						tl.smiles,
						-- **technically** we could use currval when ROW_NUMBER != 1, however this is not the least bit thread safe
						-- this procedure is designed to support loading many partitions in parallel
						case when ROW_NUMBER() over w = 1 then nextval('sub_id_seq') else null end as sub_id, 
						tl.tranche_id,
						tl.temp_id
					from
						temp_load_part_sub tl
					where
						tl.sub_id is null
					window w as
						(partition by smiles)
				) t
				-- even though we need to apply the same window function twice, it seems postgres is smart enough to sort just once
				-- so this extra window operation doesn't incur a significant extra cost (except maybe some processing/planning overhead)
				window w as
					(partition by t.smiles)

			);

			select count(*) from new_substances where rn = 1 into cntnew;
			raise notice '# new substances: %', cntnew;

			-- dynamic execution
			-- once we've identified new substances, insert them to the table (only unique instances with rn = 1)
			/*insert into substance_pXX(smiles, sub_id, tranche_id) (

				select
					smiles, sub_id, tranche_id
				from
					new_substances ns
				where
					ns.rn = 1
			);*/
			execute(format('insert into substance_p%s (smiles, sub_id, tranche_id) (select smiles, sub_id, tranche_id from new_substances ns where ns.rn = 1)', part));
					
			-- now we move the processed data to the next stage
			insert into temp_load_p2 (

				select
					case when tl.sub_id is null then ns.sub_id else tl.sub_id end,
					tl.code,
					tl.tranche_id,
					tl.cat_id
				from
					temp_load_part_sub tl
				left join
					new_substances ns
				on
					tl.temp_id = ns.temp_id

			);

			execute(format('insert into transaction_record_%s (stagei, parti, nnew, nupload) (values (1, %s, %s, %s))', transid, part, cntnew, cntupload));

			-- clean up our data
			--drop table temp_load_p1_pXX; -- dynamic execution
			execute(format('drop table temp_load_p1_p%s', part));
			drop table new_substances;
			drop table temp_load_part_sub;

			return 0;

		end;

	$$;


ALTER FUNCTION public.upload_substance_bypart(part integer, transid text) OWNER TO tinuser;

--
-- Name: upload_substance_bypart(integer, text, text); Type: FUNCTION; Schema: public; Owner: tinuser
--

CREATE FUNCTION public.upload_substance_bypart(part integer, transid text, diff_file_dest text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
		declare
			tempvar int;
			cntupload int;
			cntnew int;

		begin
			-- temporary objects are unique to each session, so no need to worry about name overlap when we're executing this in parallel
			create temporary sequence tl_temp_id_seq;

			create temporary table temp_load_part_sub (

				smiles varchar,
				code varchar,
				sub_id bigint,
				tranche_id smallint,
				cat_id smallint,
				temp_id int default nextval('tl_temp_id_seq')
			);

			-- dynamic execution
			/*insert into temp_load_part_sub(smiles, code, sub_id, tranche_id, cat_id) (

				select 
					tl.smiles, tl.code, sb.sub_id, tl.tranche_id
				from
					temp_load_p1_pXX tl
				left join
					substance_pXX sb
				on tl.smiles = sb.smiles
			);*/
			execute(format('insert into temp_load_part_sub(smiles, code, sub_id, tranche_id, cat_id) (select tl.smiles, tl.code, sb.sub_id, tl.tranche_id, tl.cat_id from temp_load_p1_p%s tl left join substance_p%s sb on tl.smiles = sb.smiles)', part, part));
			select count(*) from temp_load_part_sub into cntupload;

			alter table temp_load_part_sub add primary key (temp_id);

			create temporary table new_substances (

                                smiles varchar,
                                sub_id bigint,
				rn int, -- used to track unique substances. rn = 1 means this is a unique instance of a substance
                                tranche_id smallint,
                                temp_id int
                        );

			alter table new_substances add constraint temp_id_fk foreign key (temp_id) references temp_load_part_sub(temp_id);

			insert into new_substances (

				select 
					t.smiles, 
					min(sub_id) over w as sub_id,
					ROW_NUMBER() over w as rn,
					t.tranche_id, 
					t.temp_id 
				from
				(
					select
						tl.smiles,
						-- **technically** we could use currval when ROW_NUMBER != 1, however this is not the least bit thread safe
						-- this procedure is designed to support loading many partitions in parallel
						case when ROW_NUMBER() over w = 1 then nextval('sub_id_seq') else null end as sub_id, 
						tl.tranche_id,
						tl.temp_id
					from
						temp_load_part_sub tl
					where
						tl.sub_id is null
					window w as
						(partition by smiles)
				) t
				-- even though we need to apply the same window function twice, it seems postgres is smart enough to sort just once
				-- so this extra window operation doesn't incur a significant extra cost (except maybe some processing/planning overhead)
				window w as
					(partition by t.smiles)

			);

			select count(*) from new_substances where rn = 1 into cntnew;
			raise notice '# new substances: %', cntnew;

			-- dynamic execution
			-- once we've identified new substances, insert them to the table (only unique instances with rn = 1)
			/*insert into substance_pXX(smiles, sub_id, tranche_id) (

				select
					smiles, sub_id, tranche_id
				from
					new_substances ns
				where
					ns.rn = 1
			);*/
			execute(format('insert into substance_p%s (smiles, sub_id, tranche_id) (select smiles, sub_id, tranche_id from new_substances ns where ns.rn = 1)', part));
			-- do the substance diff a little differently- we want to export old as well as new, and include tranche name for convenience
			execute(format('copy (select smiles, sub_id, tr.tranche_name, tr.tranche_id from new_substances ns join tranches tr on tr.tranche_id = ns.tranche_id where ns.rn = 1) to ''%1$s/sub/%2$s.new''', diff_file_dest, part));
			execute(format('copy (select smiles, sub_id, tr.tranche_name, tr.tranche_id from temp_load_part_sub ts join tranches tr on tr.tranche_id = ts.tranche_id where not sub_id is null) to ''%1$s/sub/%2$s.old''', diff_file_dest, part));

			execute(format('insert into substance_id (sub_id, sub_partition_fk) (select sub_id, %s from new_substances ns where ns.rn = 1)', part));
					
			-- now we move the processed data to the next stage
			insert into temp_load_p2(sub_id, code, tranche_id, cat_id) (

				select
					case when tl.sub_id is null then ns.sub_id else tl.sub_id end,
					tl.code,
					tl.tranche_id,
					tl.cat_id
				from
					temp_load_part_sub tl
				left join
					new_substances ns
				on
					tl.temp_id = ns.temp_id

			);

			execute(format('insert into transaction_record_%s (stagei, parti, nnew, nupload) (values (1, %s, %s, %s))', transid, part, cntnew, cntupload));

			-- clean up our data
			--drop table temp_load_p1_pXX; -- dynamic execution
			execute(format('drop table temp_load_p1_p%s', part));
			drop table new_substances;
			drop table temp_load_part_sub;

			return 0;

		end;

	$_$;


ALTER FUNCTION public.upload_substance_bypart(part integer, transid text, diff_file_dest text) OWNER TO tinuser;

--
-- Name: cat_content_id_seq; Type: SEQUENCE; Schema: public; Owner: tinuser
--

CREATE SEQUENCE public.cat_content_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cat_content_id_seq OWNER TO tinuser;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: cat_dups_corrections; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.cat_dups_corrections (
    code_id_wrong bigint,
    code_id_right bigint
);


ALTER TABLE public.cat_dups_corrections OWNER TO tinuser;

--
-- Name: cat_s_codes; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.cat_s_codes (
    sub_id_fk bigint,
    cat_content_fk bigint,
    cat_id_fk integer
);


ALTER TABLE public.cat_s_codes OWNER TO tinuser;

--
-- Name: cat_sub_itm_id_seq; Type: SEQUENCE; Schema: public; Owner: tinuser
--

CREATE SEQUENCE public.cat_sub_itm_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cat_sub_itm_id_seq OWNER TO tinuser;

--
-- Name: catalog; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.catalog (
    cat_id integer NOT NULL,
    name character varying NOT NULL,
    version character varying,
    short_name character varying NOT NULL,
    free boolean DEFAULT true NOT NULL,
    purchasable integer DEFAULT 0 NOT NULL,
    updated date NOT NULL,
    website character varying,
    email character varying,
    phone character varying,
    fax character varying,
    item_template character varying,
    pubchem boolean DEFAULT true NOT NULL,
    integration integer DEFAULT 0 NOT NULL,
    bb boolean DEFAULT false NOT NULL,
    np integer DEFAULT 0 NOT NULL,
    drug integer DEFAULT 0 NOT NULL,
    original_size integer DEFAULT 0,
    num_filtered integer DEFAULT 0,
    num_unique integer DEFAULT 0,
    num_substances integer DEFAULT 0,
    num_items integer DEFAULT 0,
    num_biogenic integer,
    num_endogenous integer,
    num_inman integer,
    num_world integer
);


ALTER TABLE public.catalog OWNER TO root;

--
-- Name: catalog_cat_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.catalog_cat_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.catalog_cat_id_seq OWNER TO root;

--
-- Name: catalog_cat_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.catalog_cat_id_seq OWNED BY public.catalog.cat_id;


--
-- Name: catalog_content; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.catalog_content (
    cat_content_id bigint DEFAULT nextval('public.cat_content_id_seq'::regclass) NOT NULL,
    cat_id_fk integer,
    supplier_code character varying,
    depleted boolean,
    tranche_id smallint DEFAULT 0 NOT NULL
)
PARTITION BY HASH (supplier_code);


ALTER TABLE public.catalog_content OWNER TO tinuser;

--
-- Name: catalog_s_codes; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.catalog_s_codes (
    cat_id_fk integer
);


ALTER TABLE public.catalog_s_codes OWNER TO tinuser;

--
-- Name: catalog_substance; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.catalog_substance (
    sub_id_fk bigint NOT NULL,
    cat_content_fk bigint NOT NULL,
    grp_id bigint
)
PARTITION BY HASH (sub_id_fk);


ALTER TABLE public.catalog_substance OWNER TO tinuser;

--
-- Name: catalog_substance_cat; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.catalog_substance_cat (
    sub_id_fk bigint NOT NULL,
    cat_content_fk bigint NOT NULL,
    grp_id bigint
)
PARTITION BY HASH (cat_content_fk);


ALTER TABLE public.catalog_substance_cat OWNER TO tinuser;

--
-- Name: catalog_substance_grp; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.catalog_substance_grp (
    sub_id_fk bigint NOT NULL,
    cat_content_fk bigint NOT NULL,
    grp_id bigint NOT NULL
)
PARTITION BY HASH (grp_id);


ALTER TABLE public.catalog_substance_grp OWNER TO tinuser;

--
-- Name: catalog_substance_save; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.catalog_substance_save (
    sub_id_fk integer,
    cat_content_fk integer,
    tranche_id smallint,
    cat_sub_itm_id integer DEFAULT nextval('public.cat_sub_itm_id_seq'::regclass)
);


ALTER TABLE public.catalog_substance_save OWNER TO tinuser;

--
-- Name: catalog_substance_save_t; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.catalog_substance_save_t (
    sub_id_fk bigint,
    cat_content_fk bigint,
    tranche_id smallint,
    cat_sub_itm_id bigint
);


ALTER TABLE public.catalog_substance_save_t OWNER TO tinuser;

--
-- Name: catsub_dups_corrections; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.catsub_dups_corrections (
    cat_sub_itm_id bigint
);


ALTER TABLE public.catsub_dups_corrections OWNER TO tinuser;

--
-- Name: meta; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.meta (
    varname character varying,
    svalue character varying,
    ivalue integer,
    updated date DEFAULT now()
);


ALTER TABLE public.meta OWNER TO tinuser;

--
-- Name: meta_save; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.meta_save (
    svalue text,
    ivalue integer
);


ALTER TABLE public.meta_save OWNER TO tinuser;

--
-- Name: patches; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.patches (
    patchname character varying,
    patched boolean
);


ALTER TABLE public.patches OWNER TO tinuser;

--
-- Name: pattern; Type: TABLE; Schema: public; Owner: test
--

CREATE TABLE public.pattern (
    pattern_id integer NOT NULL,
    smarts public.qmol,
    origin_fk integer,
    description character varying,
    pat_type_fk integer,
    max_sub_id integer DEFAULT 0,
    readable_smarts character varying DEFAULT ''::character varying,
    name character varying DEFAULT ''::character varying,
    n_purchasable integer DEFAULT 0 NOT NULL,
    n_biogenic integer DEFAULT 0 NOT NULL,
    n_endometab integer DEFAULT 0 NOT NULL,
    n_inman integer DEFAULT 0 NOT NULL,
    n_world integer DEFAULT 0 NOT NULL,
    n_total integer DEFAULT 0 NOT NULL,
    reactive integer,
    n_bbnow integer
);


ALTER TABLE public.pattern OWNER TO test;

--
-- Name: pattern_pattern_id_seq; Type: SEQUENCE; Schema: public; Owner: test
--

CREATE SEQUENCE public.pattern_pattern_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.pattern_pattern_id_seq OWNER TO test;

--
-- Name: pattern_pattern_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: test
--

ALTER SEQUENCE public.pattern_pattern_id_seq OWNED BY public.pattern.pattern_id;


--
-- Name: pattern_type; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.pattern_type (
    pattern_type_id integer NOT NULL,
    description character varying,
    name character varying DEFAULT ''::character varying NOT NULL
);


ALTER TABLE public.pattern_type OWNER TO tinuser;

--
-- Name: s_codes; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.s_codes (
    cat_content_id bigint
);


ALTER TABLE public.s_codes OWNER TO tinuser;

--
-- Name: sub_dups_corrections; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.sub_dups_corrections (
    sub_id_wrong bigint,
    sub_id_right bigint
);


ALTER TABLE public.sub_dups_corrections OWNER TO tinuser;

--
-- Name: sub_id_seq; Type: SEQUENCE; Schema: public; Owner: tinuser
--

CREATE SEQUENCE public.sub_id_seq
    AS bigint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sub_id_seq OWNER TO tinuser;

CREATE TABLE public.catalog_id (
	cat_content_id bigint NOT NULL,
	cat_partition_fk smallint 
) partition by hash(cat_content_id);


--
-- Name: substance; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.substance (
    sub_id bigint DEFAULT nextval('public.sub_id_seq'::regclass) NOT NULL,
    smiles character varying NOT NULL,
    purchasable smallint,
    date_updated date DEFAULT now(),
    inchikey character(27),
    tranche_id smallint DEFAULT 0 NOT NULL
)
PARTITION BY HASH (smiles);


ALTER TABLE public.substance OWNER TO tinuser;

--
-- Name: substance_id; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.substance_id (
    sub_id bigint NOT NULL,
    sub_partition_fk smallint
)
PARTITION BY HASH (sub_id);


ALTER TABLE public.substance_id OWNER TO tinuser;

--
-- Name: substance_orphans; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.substance_orphans (
    sub_id bigint NOT NULL,
    still_orphaned boolean DEFAULT true,
    updated date DEFAULT now()
);


ALTER TABLE public.substance_orphans OWNER TO tinuser;

--
-- Name: substance_save; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.substance_save (
    sub_id integer DEFAULT nextval('public.sub_id_seq'::regclass) NOT NULL,
    smiles character varying NOT NULL,
    purchasable smallint,
    date_updated date DEFAULT now(),
    inchikey character(27),
    tranche_id smallint DEFAULT 0 NOT NULL
);


ALTER TABLE public.substance_save OWNER TO tinuser;

--
-- Name: substance_save_prepartition; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.substance_save_prepartition (
    sub_id bigint DEFAULT nextval('public.sub_id_seq'::regclass) NOT NULL,
    smiles character varying NOT NULL,
    purchasable smallint,
    date_updated date DEFAULT now(),
    inchikey character(27),
    tranche_id smallint DEFAULT 0 NOT NULL
);


ALTER TABLE public.substance_save_prepartition OWNER TO tinuser;

--
-- Name: substance_save_t; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.substance_save_t (
    sub_id bigint,
    smiles character varying,
    purchasable smallint,
    date_updated date,
    inchikey character(27),
    tranche_id smallint
);


ALTER TABLE public.substance_save_t OWNER TO tinuser;



CREATE TABLE public.temp_load_super_ids (
    name text,
    cat_id integer
);


ALTER TABLE public.temp_load_super_ids OWNER TO tinuser;


create SEQUENCE public.tranche_id 
    START WITH 1
    INCREMENT BY 1 
    NO MINVALUE 
    NO MAXVALUE 
    CACHE 1;

--
-- Name: tranches; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.tranches (
    tranche_id smallint default nextval('public.tranche_id'::regclass) NOT NULL,
    tranche_name varchar
);



ALTER TABLE public.tranches OWNER TO tinuser;

--
-- Name: transaction_record_chbr; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.transaction_record_chbr (
    stagei integer,
    parti integer,
    nupload integer,
    nnew integer
);


ALTER TABLE public.transaction_record_chbr OWNER TO tinuser;

--
-- Name: transaction_record_enamine_macrocycles; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.transaction_record_enamine_macrocycles (
    stagei integer,
    parti integer,
    nupload integer,
    nnew integer
);


ALTER TABLE public.transaction_record_enamine_macrocycles OWNER TO tinuser;

--
-- Name: transaction_record_freedom; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.transaction_record_freedom (
    stagei integer,
    parti integer,
    nupload integer,
    nnew integer
);


ALTER TABLE public.transaction_record_freedom OWNER TO tinuser;

--
-- Name: transaction_record_informer; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.transaction_record_informer (
    stagei integer,
    parti integer,
    nupload integer,
    nnew integer
);


ALTER TABLE public.transaction_record_informer OWNER TO tinuser;

--
-- Name: transaction_record_informer2; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.transaction_record_informer2 (
    stagei integer,
    parti integer,
    nupload integer,
    nnew integer
);


ALTER TABLE public.transaction_record_informer2 OWNER TO tinuser;

--
-- Name: transaction_record_md; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.transaction_record_md (
    stagei integer,
    parti integer,
    nupload integer,
    nnew integer
);


ALTER TABLE public.transaction_record_md OWNER TO tinuser;

--
-- Name: transaction_record_mq; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.transaction_record_mq (
    stagei integer,
    parti integer,
    nupload integer,
    nnew integer
);


ALTER TABLE public.transaction_record_mq OWNER TO tinuser;

--
-- Name: transaction_record_mv; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.transaction_record_mv (
    stagei integer,
    parti integer,
    nupload integer,
    nnew integer
);


ALTER TABLE public.transaction_record_mv OWNER TO tinuser;

--
-- Name: transaction_record_q1_en_screening_selected; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.transaction_record_q1_en_screening_selected (
    stagei integer,
    parti integer,
    nupload integer,
    nnew integer
);


ALTER TABLE public.transaction_record_q1_en_screening_selected OWNER TO tinuser;

--
-- Name: transaction_record_real; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.transaction_record_real (
    stagei integer,
    parti integer,
    nupload integer,
    nnew integer
);


ALTER TABLE public.transaction_record_real OWNER TO tinuser;

--
-- Name: transaction_record_sd; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.transaction_record_sd (
    stagei integer,
    parti integer,
    nupload integer,
    nnew integer
);


ALTER TABLE public.transaction_record_sd OWNER TO tinuser;

--
-- Name: transaction_record_sq; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.transaction_record_sq (
    stagei integer,
    parti integer,
    nupload integer,
    nnew integer
);


ALTER TABLE public.transaction_record_sq OWNER TO tinuser;

--
-- Name: transaction_record_sv; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.transaction_record_sv (
    stagei integer,
    parti integer,
    nupload integer,
    nnew integer
);


ALTER TABLE public.transaction_record_sv OWNER TO tinuser;

--
-- Name: transaction_record_sz; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.transaction_record_sz (
    stagei integer,
    parti integer,
    nupload integer,
    nnew integer
);


ALTER TABLE public.transaction_record_sz OWNER TO tinuser;

--
-- Name: transaction_record_wuxi2; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.transaction_record_wuxi2 (
    stagei integer,
    parti integer,
    nupload integer,
    nnew integer
);


ALTER TABLE public.transaction_record_wuxi2 OWNER TO tinuser;

--
-- Name: transaction_record_wuxi3; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.transaction_record_wuxi3 (
    stagei integer,
    parti integer,
    nupload integer,
    nnew integer
);


ALTER TABLE public.transaction_record_wuxi3 OWNER TO tinuser;

--
-- Name: weirdmols; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.weirdmols (
    sub_id bigint NOT NULL,
    smiles character varying NOT NULL,
    purchasable smallint,
    date_updated date,
    inchikey character(27),
    tranche_id smallint NOT NULL
);


ALTER TABLE public.weirdmols OWNER TO tinuser;

--
-- Name: weirdmols_catsub; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.weirdmols_catsub (
    sub_id_fk bigint,
    cat_content_fk bigint,
    tranche_id smallint,
    cat_sub_itm_id bigint
);


ALTER TABLE public.weirdmols_catsub OWNER TO tinuser;

--
-- Name: zinc_3d_map; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.zinc_3d_map (
    sub_id bigint,
    tranche_id smallint,
    tarball_id integer,
    grp_id integer
)
PARTITION BY HASH (sub_id);


ALTER TABLE public.zinc_3d_map OWNER TO tinuser;

--
-- Name: zinc_tarballs; Type: TABLE; Schema: public; Owner: tinuser
--

CREATE TABLE public.zinc_tarballs (
    tarball_path text,
    tarball_id integer
);


ALTER TABLE public.zinc_tarballs OWNER TO tinuser;

--
-- Name: catalog cat_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.catalog ALTER COLUMN cat_id SET DEFAULT nextval('public.catalog_cat_id_seq'::regclass);


--
-- Name: pattern pattern_id; Type: DEFAULT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.pattern ALTER COLUMN pattern_id SET DEFAULT nextval('public.pattern_pattern_id_seq'::regclass);


--
-- Name: catalog_content catalog_content_uniq_code; Type: CONSTRAINT; Schema: public; Owner: tinuser
--

ALTER TABLE ONLY public.catalog_content
    ADD CONSTRAINT catalog_content_uniq_code UNIQUE (supplier_code);


--
-- Name: catalog_id catalog_id_new_pkey; Type: CONSTRAINT; Schema: public; Owner: tinuser
--

ALTER TABLE ONLY public.catalog_id
    ADD CONSTRAINT catalog_id_new_pkey PRIMARY KEY (cat_content_id);


--

--
-- Name: catalog catalog_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.catalog
    ADD CONSTRAINT catalog_pkey PRIMARY KEY (cat_id);


--
-- Name: catalog_substance_cat catalog_substance_cat_new_pkey; Type: CONSTRAINT; Schema: public; Owner: tinuser
--

ALTER TABLE ONLY public.catalog_substance_cat
    ADD CONSTRAINT catalog_substance_cat_new_pkey PRIMARY KEY (cat_content_fk, sub_id_fk);

--
-- Name: catalog_substance_grp catalog_substance_grp_new_pkey1; Type: CONSTRAINT; Schema: public; Owner: tinuser
--

ALTER TABLE ONLY public.catalog_substance_grp
    ADD CONSTRAINT catalog_substance_grp_new_pkey1 PRIMARY KEY (grp_id, sub_id_fk, cat_content_fk);


--
-- Name: catalog_substance catalog_substance_new_pkey; Type: CONSTRAINT; Schema: public; Owner: tinuser
--

ALTER TABLE ONLY public.catalog_substance
    ADD CONSTRAINT catalog_substance_new_pkey PRIMARY KEY (sub_id_fk, cat_content_fk);


--
-- Name: pattern pattern_pkey; Type: CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.pattern
    ADD CONSTRAINT pattern_pkey PRIMARY KEY (pattern_id);


--
-- Name: pattern_type pattern_type_id_pkey; Type: CONSTRAINT; Schema: public; Owner: tinuser
--

ALTER TABLE ONLY public.pattern_type
    ADD CONSTRAINT pattern_type_id_pkey PRIMARY KEY (pattern_type_id);


--
-- Name: pattern_type pattern_type_name_uniq; Type: CONSTRAINT; Schema: public; Owner: tinuser
--

ALTER TABLE ONLY public.pattern_type
    ADD CONSTRAINT pattern_type_name_uniq UNIQUE (name);


--
-- Name: substance_id substance_id_new_pkey; Type: CONSTRAINT; Schema: public; Owner: tinuser
--

ALTER TABLE ONLY public.substance_id
    ADD CONSTRAINT substance_id_new_pkey PRIMARY KEY (sub_id);

--
-- Name: substance_orphans substance_orphans_pkey; Type: CONSTRAINT; Schema: public; Owner: tinuser
--

ALTER TABLE ONLY public.substance_orphans
    ADD CONSTRAINT substance_orphans_pkey PRIMARY KEY (sub_id);


--
-- Name: substance substance_uniq_smiles; Type: CONSTRAINT; Schema: public; Owner: tinuser
--

ALTER TABLE ONLY public.substance
    ADD CONSTRAINT substance_uniq_smiles UNIQUE (smiles);

ALTER TABLE ONLY public.substance
    ADD CONSTRAINT substance_uniq_sub_id UNIQUE (sub_id);

--
-- Name: substance_save_prepartition substance_pkey; Type: CONSTRAINT; Schema: public; Owner: tinuser
--

ALTER TABLE ONLY public.substance_save_prepartition
    ADD CONSTRAINT substance_pkey PRIMARY KEY (tranche_id, sub_id);


--
-- Name: substance_save substance_pkey_save; Type: CONSTRAINT; Schema: public; Owner: tinuser
--

ALTER TABLE ONLY public.substance_save
    ADD CONSTRAINT substance_pkey_save PRIMARY KEY (sub_id, tranche_id);


--
-- Name: catalog_content_t_cat_content_id_idx; Type: INDEX; Schema: public; Owner: tinuser
--

CREATE INDEX catalog_content_t_cat_content_id_idx ON ONLY public.catalog_content USING btree (cat_content_id);


--
-- Name: catalog_substance_cat_id_fk_idx_save; Type: INDEX; Schema: public; Owner: tinuser
--

CREATE INDEX catalog_substance_cat_id_fk_idx_save ON public.catalog_substance_save USING btree (cat_content_fk);


--
-- Name: catalog_substance_sub_id_fk_idx_save; Type: INDEX; Schema: public; Owner: tinuser
--

CREATE INDEX catalog_substance_sub_id_fk_idx_save ON public.catalog_substance_save USING btree (sub_id_fk, tranche_id);


--
-- Name: cdc_code_id_idx_t; Type: INDEX; Schema: public; Owner: tinuser
--

CREATE INDEX cdc_code_id_idx_t ON public.cat_dups_corrections USING btree (code_id_wrong);


--
-- Name: ix_catalog_free; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_catalog_free ON public.catalog USING btree (free);


--
-- Name: ix_catalog_purchasable; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_catalog_purchasable ON public.catalog USING btree (purchasable);


--
-- Name: ix_catalog_short_name; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_catalog_short_name ON public.catalog USING btree (short_name);


--
-- Name: ix_catalog_text_ts; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_catalog_text_ts ON public.catalog USING gist (to_tsvector('english'::regconfig, (((name)::text || ' '::text) || (short_name)::text)));


--
-- Name: ix_pattern_id; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX ix_pattern_id ON public.pattern USING btree (pattern_id);


--
-- Name: ix_pattern_n_biogenic; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX ix_pattern_n_biogenic ON public.pattern USING btree (n_biogenic);


--
-- Name: ix_pattern_n_endometab; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX ix_pattern_n_endometab ON public.pattern USING btree (n_endometab);


--
-- Name: ix_pattern_n_inman; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX ix_pattern_n_inman ON public.pattern USING btree (n_inman);


--
-- Name: ix_pattern_n_purch; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX ix_pattern_n_purch ON public.pattern USING btree (n_purchasable);


--
-- Name: ix_pattern_n_total; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX ix_pattern_n_total ON public.pattern USING btree (n_total);


--
-- Name: ix_pattern_n_total_name; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX ix_pattern_n_total_name ON public.pattern USING btree (n_total, name);


--
-- Name: ix_pattern_n_world; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX ix_pattern_n_world ON public.pattern USING btree (n_world);


--
-- Name: ix_pattern_name; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX ix_pattern_name ON public.pattern USING btree (name);


--
-- Name: ix_pattern_origin_fk; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX ix_pattern_origin_fk ON public.pattern USING btree (origin_fk);


--
-- Name: ix_pattern_pattern_id_origin_fk; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX ix_pattern_pattern_id_origin_fk ON public.pattern USING btree (pattern_id, origin_fk);


--
-- Name: ix_pattern_reactive; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX ix_pattern_reactive ON public.pattern USING btree (reactive);


--
-- Name: ix_pattern_reactive_reversed; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX ix_pattern_reactive_reversed ON public.pattern USING btree (reactive DESC);


--
-- Name: ix_pattern_reactive_reversed_notanodyne; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX ix_pattern_reactive_reversed_notanodyne ON public.pattern USING btree (reactive DESC) WHERE (reactive > 0);


--
-- Name: ix_pattern_smarts_string; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX ix_pattern_smarts_string ON public.pattern USING btree (((public.mol_to_smarts(smarts))::text));


--
-- Name: ix_pattern_text_ts; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX ix_pattern_text_ts ON public.pattern USING gist (to_tsvector('english'::regconfig, (((name)::text || ' '::text) || (description)::text)));


--
-- Name: ix_pattern_type_fk; Type: INDEX; Schema: public; Owner: test
--

CREATE INDEX ix_pattern_type_fk ON public.pattern USING btree (pat_type_fk);


--
-- Name: sdc_sub_id_idx_t; Type: INDEX; Schema: public; Owner: tinuser
--

CREATE INDEX sdc_sub_id_idx_t ON public.sub_dups_corrections USING btree (sub_id_wrong);


--
-- Name: smiles_hash_idx; Type: INDEX; Schema: public; Owner: tinuser
--

CREATE INDEX smiles_hash_idx ON public.substance_save_prepartition USING hash (smiles);


--
-- Name: smiles_hash_idx_save; Type: INDEX; Schema: public; Owner: tinuser
--

CREATE INDEX smiles_hash_idx_save ON public.substance_save USING hash (smiles);


--
-- Name: sub_id_idx; Type: INDEX; Schema: public; Owner: tinuser
--

CREATE INDEX sub_id_idx ON public.substance_save_prepartition USING btree (sub_id);


--
-- Name: substance_t_sub_id_idx; Type: INDEX; Schema: public; Owner: tinuser
--

CREATE INDEX substance_t_sub_id_idx ON ONLY public.substance USING btree (sub_id);


--
-- Name: catalog_substance_save catalog_substance_sub_id_fk_fkey_save; Type: FK CONSTRAINT; Schema: public; Owner: tinuser
--

ALTER TABLE ONLY public.catalog_substance_save
    ADD CONSTRAINT catalog_substance_sub_id_fk_fkey_save FOREIGN KEY (sub_id_fk, tranche_id) REFERENCES public.substance_save(sub_id, tranche_id);


--
-- Name: pattern pattern_type_fk; Type: FK CONSTRAINT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.pattern
    ADD CONSTRAINT pattern_type_fk FOREIGN KEY (pat_type_fk) REFERENCES public.pattern_type(pattern_type_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: TABLE catalog; Type: ACL; Schema: public; Owner: root
--

GRANT ALL ON TABLE public.catalog TO test;
GRANT SELECT ON TABLE public.catalog TO zincread;
GRANT SELECT ON TABLE public.catalog TO zincfree;
GRANT ALL ON TABLE public.catalog TO adminprivate;
GRANT ALL ON TABLE public.catalog TO admin;


--
-- Name: SEQUENCE catalog_cat_id_seq; Type: ACL; Schema: public; Owner: root
--

GRANT SELECT,USAGE ON SEQUENCE public.catalog_cat_id_seq TO zincread;
GRANT SELECT,USAGE ON SEQUENCE public.catalog_cat_id_seq TO zincfree;
GRANT SELECT,USAGE ON SEQUENCE public.catalog_cat_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.catalog_cat_id_seq TO adminprivate;



--
-- Name: TABLE pattern; Type: ACL; Schema: public; Owner: test
--

GRANT SELECT ON TABLE public.pattern TO zincfree;
GRANT SELECT ON TABLE public.pattern TO admin;
GRANT SELECT ON TABLE public.pattern TO adminprivate;


--
-- Name: SEQUENCE pattern_pattern_id_seq; Type: ACL; Schema: public; Owner: test
--

GRANT SELECT,USAGE ON SEQUENCE public.pattern_pattern_id_seq TO zincread;
GRANT SELECT,USAGE ON SEQUENCE public.pattern_pattern_id_seq TO zincfree;
GRANT SELECT,USAGE ON SEQUENCE public.pattern_pattern_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.pattern_pattern_id_seq TO adminprivate;


--
-- Name: TABLE pattern_type; Type: ACL; Schema: public; Owner: tinuser
--

GRANT SELECT ON TABLE public.pattern_type TO zincfree;
GRANT SELECT ON TABLE public.pattern_type TO zincread;
GRANT SELECT ON TABLE public.pattern_type TO admin;
GRANT SELECT ON TABLE public.pattern_type TO adminprivate;


--
-- PostgreSQL database dump complete
--

call public.create_table_partitions('public.catalog_content', '');
call public.create_table_partitions('public.catalog_id', '');
call public.create_table_partitions('public.catalog_substance', '');
call public.create_table_partitions('public.catalog_substance_cat', '');
call public.create_table_partitions('public.catalog_substance_grp', '');
call public.create_table_partitions('public.substance', '');
call public.create_table_partitions('public.zinc_3d_map', '');
call public.create_table_partitions('public.substance_id', '');