SET default_transaction_read_only = off;

SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;

--
-- Roles
--

CREATE ROLE admin;
ALTER ROLE admin WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'md57037abb4885de0d3521db711dc634826';
CREATE ROLE adminprivate;
ALTER ROLE adminprivate WITH NOSUPERUSER INHERIT NOCREATEROLE CREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'md53daafadd61518998cfcfce69e1ae1267';
CREATE ROLE btzuser;
ALTER ROLE btzuser WITH NOSUPERUSER INHERIT NOCREATEROLE CREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'md5138ad172f74f342ffb524cdf491ec8af';
CREATE ROLE chembl;
ALTER ROLE chembl WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS;
CREATE ROLE postgres;
ALTER ROLE postgres WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN REPLICATION BYPASSRLS;
CREATE ROLE root;
ALTER ROLE root WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN NOREPLICATION NOBYPASSRLS;
CREATE ROLE test;
ALTER ROLE test WITH NOSUPERUSER INHERIT NOCREATEROLE CREATEDB LOGIN NOREPLICATION NOBYPASSRLS;
CREATE ROLE antimonyuser;
ALTER ROLE antimonyuser WITH SUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'md516a847029f27f45ebc318a781bc3df5a';
CREATE ROLE zinc21;
ALTER ROLE zinc21 WITH SUPERUSER INHERIT CREATEROLE CREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'md50893f3c540509e267e4b24cef189e262';
CREATE ROLE zincfree;
ALTER ROLE zincfree WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'md52a08c13b63d4e1257e7cea48d468a5de';
CREATE ROLE zincread;
ALTER ROLE zincread WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'md57d8bffd68d271c7d10510986e086ce65';
CREATE ROLE zincwrite;
ALTER ROLE zincwrite WITH NOSUPERUSER INHERIT NOCREATEROLE NOCREATEDB LOGIN NOREPLICATION NOBYPASSRLS PASSWORD 'md57c0a812310ac0a935e992599d5df7e0a';


-- re-using tin config here. not sure if necessary
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

-- set up tables etc here

create sequence public.sup_id_seq;
create sequence public.machine_id_seq;
create sequence public.map_id_seq;

create table public.supplier_codes (

	supplier_code varchar,
	last4hash char(4),
	sup_id int primary key default nextval('public.sup_id_seq')

);

create index supplier_code_idx on public.supplier_codes using hash (supplier_code);

create table public.tin_machines (

	hostname varchar,
	port int,
	machine_id int primary key default nextval('public.machine_id_seq')

);

create table public.supplier_map (

	sup_id_fk int,
	machine_id_fk smallint,
	cat_content_id int,
	map_id int primary key default nextval('public.map_id_seq'),

	constraint sup_id_fk_fkey
		foreign key (sup_id_fk)
		references public.supplier_codes (sup_id),

	constraint machine_id_fk_fkey
		foreign key (machine_id_fk)
		references public.tin_machines (machine_id)

);

-- add unique index for select perf + validation of new data
--alter table supplier_map add primary key (sup_id_fk, machine_id_fk);

-- create standard btree index (since we are dealing with integers)
create index sup_id_fk_idx on public.supplier_map (sup_id_fk);
create index machine_id_fk_idx on public.supplier_map (machine_id_fk);
