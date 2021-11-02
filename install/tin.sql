--
-- PostgreSQL database cluster dump
--

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






--
-- PostgreSQL database cluster dump complete
--

--
-- PostgreSQL database dump
--

-- Dumped from database version 12.1
-- Dumped by pg_dump version 12.1

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

--
-- Name: intarray; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS intarray WITH SCHEMA public;


--
-- Name: EXTENSION intarray; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION intarray IS 'functions, operators, and index support for 1-D arrays of integers';


--
-- Name: rdkit; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS rdkit WITH SCHEMA public;


--
-- Name: EXTENSION rdkit; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION rdkit IS 'Cheminformatics functionality for PostgreSQL.';


SET default_tablespace = '';

SET default_table_access_method = heap;

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
-- Name: cat_content_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.cat_content_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cat_content_id_seq OWNER TO root;

--
-- Name: catalog_content; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.catalog_content (
    cat_content_id bigint DEFAULT nextval('public.cat_content_id_seq'::regclass) NOT NULL,
    cat_id_fk integer NOT NULL,
    supplier_code character varying NOT NULL,
    depleted boolean,
    tranche_id smallint default 0 not null
);


ALTER TABLE public.catalog_content OWNER TO root;

--
-- Name: catalog_content_cat_content_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

/*CREATE SEQUENCE public.cat_content_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE public.cat_content_id_seq OWNER TO root;

--
-- Name: catalog_content_cat_content_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.cat_content_id_seq OWNED BY public.catalog_content.cat_content_id;
*/

--
-- Name: catalog_substance; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.catalog_substance (
    cat_content_fk bigint NOT NULL,
    sub_id_fk bigint NOT NULL,
    cat_sub_itm_id bigint NOT NULL,
    tranche_id smallint default 0 not null
);


ALTER TABLE public.catalog_substance OWNER TO root;

--
-- Name: catalog_item; Type: VIEW; Schema: public; Owner: root
--

CREATE VIEW public.catalog_item AS
 SELECT catalog_substance.cat_sub_itm_id AS cat_itm_id,
    catalog_substance.sub_id_fk,
    catalog_content.cat_id_fk,
    catalog_content.supplier_code,
    catalog_content.depleted,
    catalog_content.cat_content_id AS cat_content_fk
   FROM (public.catalog_content
     JOIN public.catalog_substance ON ((catalog_content.cat_content_id = catalog_substance.cat_content_fk)));


ALTER TABLE public.catalog_item OWNER TO root;

--
-- Name: cat_sub_itm_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.cat_sub_itm_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.cat_sub_itm_id_seq OWNER TO root;

--
-- Name: cat_sub_itm_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.cat_sub_itm_id_seq OWNED BY public.catalog_substance.cat_sub_itm_id;


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
-- Name: substance; Type: TABLE; Schema: public; Owner: root
--

CREATE TABLE public.substance (
    sub_id bigint NOT NULL,
    smiles public.mol,
    purchasable integer,
    date_updated date DEFAULT now() NOT NULL,
    inchikey character(27) NOT NULL COLLATE pg_catalog."C",
    tranche_id smallint default 0 not null
);


ALTER TABLE public.substance OWNER TO root;

--
-- Name: sub_id_seq; Type: SEQUENCE; Schema: public; Owner: root
--

CREATE SEQUENCE public.sub_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.sub_id_seq OWNER TO root;

--
-- Name: sub_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: root
--

ALTER SEQUENCE public.sub_id_seq OWNED BY public.substance.sub_id;


--
-- Name: catalog cat_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.catalog ALTER COLUMN cat_id SET DEFAULT nextval('public.catalog_cat_id_seq'::regclass);


--
-- Name: catalog_substance cat_sub_itm_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.catalog_substance ALTER COLUMN cat_sub_itm_id SET DEFAULT nextval('public.cat_sub_itm_id_seq'::regclass);


--
-- Name: pattern pattern_id; Type: DEFAULT; Schema: public; Owner: test
--

ALTER TABLE ONLY public.pattern ALTER COLUMN pattern_id SET DEFAULT nextval('public.pattern_pattern_id_seq'::regclass);


--
-- Name: substance sub_id; Type: DEFAULT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.substance ALTER COLUMN sub_id SET DEFAULT nextval('public.sub_id_seq'::regclass);


CREATE TABLE patches (
	patched boolean,
	patchname varchar
)

INSERT INTO patches VALUES (true, 'postgres'), (true, 'escape'), (true, 'substanceopt'), (true, 'normalize_p1'), (true, 'normalize_p2');

--
-- Data for Name: pattern; Type: TABLE DATA; Schema: public; Owner: test
--

COPY public.pattern (pattern_id, smarts, origin_fk, description, pat_type_fk, max_sub_id, readable_smarts, name, n_purchasable, n_biogenic, n_endometab, n_inman, n_world, n_total, reactive, n_bbnow) FROM stdin;
1001	[#1,#6,#7,#8:6]-[#6:3](-[#1,#6,#7,#8:7])=[O:4]	6	Reaction pattern	9	0	[#1,#6,#7,#8:6]-[#6:3](-[#1,#6,#7,#8:7])=[O:4]	1001	0	0	0	0	0	0	0	\N
1002	[F,Cl,Br,I:3]-[#6:2]=[#6:1]	7	Reaction pattern	9	0	[F,Cl,Br,I:3]-[#6:2]=[#6:1]	1002	0	0	0	0	0	0	0	\N
1003	[#6:8]-[#6:6](-[#8,#17:9])=[O:7]	6	Reaction pattern	9	0	[#6:8]-[#6:6](-[#8,#17:9])=[O:7]	1003	0	0	0	0	0	0	0	\N
1004	[N:3]#[C:4]-,:[C:5]-,:[C:6](=[O:7])-,:[N&D1:8]	6	Reaction pattern	9	0	[N:3]#[C:4]-,:[C:5]-,:[C:6](=[O:7])-,:[N&D1:8]	1004	0	0	0	0	0	0	0	\N
1005	[#17,#35:7]-[#6:2]-[#6:1](-[#1,#6:9])=[O:8]	6	Reaction pattern	9	0	[#17,#35:7]-[#6:2]-[#6:1](-[#1,#6:9])=[O:8]	1005	0	0	0	0	0	0	0	\N
1007	[#8:5]-[#6:2](-[#1,#6:6])-[#6:1](-[#8:3])-[#1,#6:4]	6	Reaction pattern	9	0	[#8:5]-[#6:2](-[#1,#6:6])-[#6:1](-[#8:3])-[#1,#6:4]	1007	0	0	0	0	0	0	0	\N
1011	[#8&-:4]-[#7&+:3]=[O:5]	6	Reaction pattern	9	0	[#8&-:4]-[#7&+:3]=[O:5]	1011	0	0	0	0	0	0	0	\N
1013	[#1:6]-,:[#8:2]-[#6:1]-[#6:3]	7	Reaction pattern	9	0	[#1:6]-,:[#8:2]-[#6:1]-[#6:3]	1013	0	0	0	0	0	0	0	\N
1014	[#1:7]-,:[#8:6]-[#6:8]	6	Reaction pattern	9	0	[#1:7]-,:[#8:6]-[#6:8]	1014	0	0	0	0	0	0	0	\N
1015	[N&D1]-[#6]	7	Reaction pattern	9	0	[N&D1]-[#6]	primary-amine	0	0	0	0	0	0	0	\N
1016	[O:8]=[#6:7]-[c:6]1:,-[c:1]:,-[c:2]:,-[c:9](-[#6:10]=[O:11]):,-[s:5]:,-1	7	Reaction pattern	9	0	[O:8]=[#6:7]-[c:6]1:,-[c:1]:,-[c:2]:,-[c:9](-[#6:10]=[O:11]):,-[s:5]:,-1	1016	0	0	0	0	0	0	0	\N
1017	[#6,#8:1]-[c:2]1:,-[c:3]:,-[c:4]:,-[c:5](-[#6,#8:6]):,-[s:7]:,-1	7	Reaction pattern	9	0	[#6,#8:1]-[c:2]1:,-[c:3]:,-[c:4]:,-[c:5](-[#6,#8:6]):,-[s:7]:,-1	1017	0	0	0	0	0	0	0	\N
1018	[#1:4]-,:[#8:3]-[c:2]:[c:1]	6	Reaction pattern	9	0	[#1:4]-,:[#8:3]-[c:2]:[c:1]	1018	0	0	0	0	0	0	0	\N
1033	[#1:7]-,:[#8:6]-[#6:5]	6	Reaction pattern	9	0	[#1:7]-,:[#8:6]-[#6:5]	1033	0	0	0	0	0	0	0	\N
1019	[#1,#6]-,:[C:1]#[C:2]-,:[#1,#6]	6	Reaction pattern	9	0	[#1,#6]-,:[C:1]#[C:2]-,:[#1,#6]	1019	0	0	0	0	0	0	0	\N
1020	[#6:3]-[#8,#9,#17,#35,#53:4]	6	Reaction pattern	9	0	[#6:3]-[#8,#9,#17,#35,#53:4]	1020	0	0	0	0	0	0	0	\N
1021	[#6:9]-,:[#7:4](-,:[#6,#7:5])-,:[#1:6]	6	Reaction pattern	9	0	[#6:9]-,:[#7:4](-,:[#6,#7:5])-,:[#1:6]	1021	0	0	0	0	0	0	0	\N
1023	[#1:6]-,:[#8:5]-,:[#7:4]=[#6:2](-,:[#6,#7:1])-[#7:3](-,:[#1:8])-,:[#1:7]	6	Reaction pattern	9	0	[#1:6]-,:[#8:5]-,:[#7:4]=[#6:2](-,:[#6,#7:1])-[#7:3](-,:[#1:8])-,:[#1:7]	1023	0	0	0	0	0	0	0	\N
1024	[#1:3]-,:[#8:2]-[#6:1](-,:[#1:4])-,:[#1:5]	6	Reaction pattern	9	0	[#1:3]-,:[#8:2]-[#6:1](-,:[#1:4])-,:[#1:5]	1024	0	0	0	0	0	0	0	\N
1025	[O:2]=[#6:1]1-[#6:3]-[#6:4]-,:[#6:5]-[#6:6]-1	7	Reaction pattern	9	0	[O:2]=[#6:1]1-[#6:3]-[#6:4]-,:[#6:5]-[#6:6]-1	1025	0	0	0	0	0	0	0	\N
1026	[#1:12]-,:[#7:8](-,:[#1:13])-[#6:9]=[O:10]	6	Reaction pattern	9	0	[#1:12]-,:[#7:8](-,:[#1:13])-[#6:9]=[O:10]	1026	0	0	0	0	0	0	0	\N
1027	[c:2]-[#7&X3:1]	7	Reaction pattern	9	0	[c:2]-[#7&X3:1]	1027	0	0	0	0	0	0	0	\N
1028	[#1:2]-,:[#8:1]-[c:3]	6	Reaction pattern	9	0	[#1:2]-,:[#8:1]-[c:3]	1028	0	0	0	0	0	0	0	\N
1029	[$(*)]-[#7:3]=[C:2]=[#7:1]-[$(*)]	6	Reaction pattern	9	0	[$([#1,*])]-[#7:3]=[C:2]=[#7:1]-[$([#1,*])]	1029	0	0	0	0	0	0	0	\N
1030	[C:1]-,:[#8:2]-,:[N:4](=[O:5])=[O:6]	7	Reaction pattern	9	0	[C:1]-,:[#8:2]-,:[N:4](=[O:5])=[O:6]	1030	0	0	0	0	0	0	0	\N
1031	[#6:4]-[#6:2](-[#8,#16,#17,#35,#53:6])=[O:3]	6	Reaction pattern	9	0	[#6:4]-[#6:2](-[#8,#16,#17,#35,#53:6])=[O:3]	1031	0	0	0	0	0	0	0	\N
1032	[#1:8]-,:[#8:7]-[c:1]1:,-[c:2]:,-[c:3]:,-[c:4]:,-[c:5]:,-[c:6]:,-1	6	Reaction pattern	9	0	[#1:8]-,:[#8:7]-[c:1]1:,-[c:2]:,-[c:3]:,-[c:4]:,-[c:5]:,-[c:6]:,-1	1032	0	0	0	0	0	0	0	\N
1034	[c:1]-[#7&+:3](-[#8&-:4])=[O:5]	7	Reaction pattern	9	0	[c:1]-[#7&+:3](-[#8&-:4])=[O:5]	1034	0	0	0	0	0	0	0	\N
1035	[#1:10]-,:[#7:1](-,:[#1:11])-[#6:2](-,:[#1:13])-[#6:3]=[O:12]	6	Reaction pattern	9	0	[#1:10]-,:[#7:1](-,:[#1:11])-[#6:2](-,:[#1:13])-[#6:3]=[O:12]	1035	0	0	0	0	0	0	0	\N
1036	[#6:1]-[#6:2](-,:[Cl:7])=[O:3]	6	Reaction pattern	9	0	[#6:1]-[#6:2](-,:[Cl:7])=[O:3]	1036	0	0	0	0	0	0	0	\N
1038	[#1:7]-,:[#8:6]-[#6:4](-[c:1])=[O:5]	6	Reaction pattern	9	0	[#1:7]-,:[#8:6]-[#6:4](-[c:1])=[O:5]	1038	0	0	0	0	0	0	0	\N
1040	[#1:17]-,:[C:3](-,:[#1:18])(-,:[#1,#6:9])-,:[#6:2](-[#1,#6:10])=[O:5]	6	Reaction pattern	9	0	[#1:17]-,:[C:3](-,:[#1:18])(-,:[#1,#6:9])-,:[#6:2](-[#1,#6:10])=[O:5]	1040	0	0	0	0	0	0	0	\N
1042	[#6:5]-,:[N&+:1]#[C:2]	7	Reaction pattern	9	0	[#6:5]-,:[N&+:1]#[C:2]	1042	0	0	0	0	0	0	0	\N
1044	[#1,#6:14]-[c:2]1:,-[c:3]:,-[c:4](-[#1,#6:13]):,-[c:11]2:,-c:,-c:,-c:,-c:,-[c:12]:,-2:,-[n:1]:,-1	7	Reaction pattern	9	0	[#1,#6:14]-[c:2]2:,-[c:3]:,-[c:4](-[#1,#6:13]):,-[c:11]1:,-c:,-c:,-c:,-c:,-[c:12]:,-1:,-[n:1]:,-2	1044	0	0	0	0	0	0	0	\N
1045	[#1]-,:[#8]-[#6](=O)-[#6:1]=[#6:2]	7	Reaction pattern	9	0	[#1]-,:[#8]-[#6](=O)-[#6:1]=[#6:2]	1045	0	0	0	0	0	0	0	\N
1046	[#1,#6:10]-[c:8]1:,-[n:4]:,-[c:3]2:,-[c:12]:,-[c:13]:,-[c:14]:,-[c:15]:,-[c:2]:,-2:,-[n:1]:,-1	7	Reaction pattern	9	0	[#1,#6:10]-[c:8]2:,-[n:4]:,-[c:3]1:,-[c:12]:,-[c:13]:,-[c:14]:,-[c:15]:,-[c:2]:,-1:,-[n:1]:,-2	1046	0	0	0	0	0	0	0	\N
1047	[#7&H1,#8&H1]-[#6]-[#6](-[#6,#7,#15,#16])=[#6]	7	Reaction pattern	9	0	[#7&H1,#8&H1]-[#6]-[#6](-[#6,#7,#15,#16])=[#6]	1047	0	0	0	0	0	0	0	\N
1048	[#6:2]=[#6:1]	6	Reaction pattern	9	0	[#6:2]=[#6:1]	1048	0	0	0	0	0	0	0	\N
1049	[#1:14]-,:[#7:12](-,:[#1:13])-[#1,#6:15]	6	Reaction pattern	9	0	[#1:14]-,:[#7:12](-,:[#1:13])-[#1,#6:15]	1049	0	0	0	0	0	0	0	\N
1050	[#1:12]-,:[C:7](-,:[#1:13])(-,:[#6:8](-[#6:14])=[O:9])-,:[#6:10](-[#6,#8:15])=[O:11]	6	Reaction pattern	9	0	[#1:12]-,:[C:7](-,:[#1:13])(-,:[#6:8](-[#6:14])=[O:9])-,:[#6:10](-[#6,#8:15])=[O:11]	1050	0	0	0	0	0	0	0	\N
1051	[#8,#17:6]-[#6:4]=[O:5]	6	Reaction pattern	9	0	[#8,#17:6]-[#6:4]=[O:5]	1051	0	0	0	0	0	0	0	\N
1052	[#7,#8:5]-[#6:3](=[O:4])-[c:2]1:,-[c:8]:,-[c:7](-[#1,#6:11]):,-[n:12](-[#1,#6:15]):,-[c:1]:,-1	7	Reaction pattern	9	0	[#7,#8:5]-[#6:3](=[O:4])-[c:2]1:,-[c:8]:,-[c:7](-[#1,#6:11]):,-[n:12](-[#1,#6:15]):,-[c:1]:,-1	1052	0	0	0	0	0	0	0	\N
1053	[#6:7]-[#7:1]-,:[#6:2](-[#8:4]-[#6:5])=[#7:3]-,:[#6:8]	7	Reaction pattern	9	0	[#6:7]-[#7:1]-,:[#6:2](-[#8:4]-[#6:5])=[#7:3]-,:[#6:8]	1053	0	0	0	0	0	0	0	\N
1054	[#6:2]-[#9,#17,#35,#53:3]	6	Reaction pattern	9	0	[#6:2]-[#9,#17,#35,#53:3]	1054	0	0	0	0	0	0	0	\N
1055	[#6:4]-[#7&X3:1]=[C:2]=[S:3]	7	Reaction pattern	9	0	[#6:4]-[#7&X3:1]=[C:2]=[S:3]	1055	0	0	0	0	0	0	0	\N
1056	[c:1]-,:[S:3](-,:[Cl:6])(=[O:5])=[O:4]	7	Reaction pattern	9	0	[c:1]-,:[S:3](-,:[Cl:6])(=[O:5])=[O:4]	1056	0	0	0	0	0	0	0	\N
1057	[#1:4]-,:[#8:3]-[#6:1]	6	Reaction pattern	9	0	[#1:4]-,:[#8:3]-[#6:1]	1057	0	0	0	0	0	0	0	\N
1058	[#1,#6:7]-[#8:4]-[#6:5]=[O:6]	6	Reaction pattern	9	0	[#1,#6:7]-[#8:4]-[#6:5]=[O:6]	1058	0	0	0	0	0	0	0	\N
1059	[#1:11]-,:[c:4]1:,-[c:6]:,-[c:7]:,-[c:8]:,-[c:9]:,-[c:10]:,-1-[#7,#8:1]-[#6:2]=[O:3]	6	Reaction pattern	9	0	[#1:11]-,:[c:4]1:,-[c:6]:,-[c:7]:,-[c:8]:,-[c:9]:,-[c:10]:,-1-[#7,#8:1]-[#6:2]=[O:3]	1059	0	0	0	0	0	0	0	\N
1060	[#8]-[#7:2]=[O:3]	6	Reaction pattern	9	0	[#8]-[#7:2]=[O:3]	1060	0	0	0	0	0	0	0	\N
1061	[c:1]1:,-[c:6]:,-[c:5]:,-[c:4]:,-[c:3]:,-[c:2]:,-1	6	Reaction pattern	9	0	[c:1]1:,-[c:6]:,-[c:5]:,-[c:4]:,-[c:3]:,-[c:2]:,-1	1061	0	0	0	0	0	0	0	\N
1062	[O:4]=[#6:3]-[#8:5]-[#6:6]=[O:7]	6	Reaction pattern	9	0	[O:4]=[#6:3]-[#8:5]-[#6:6]=[O:7]	1062	0	0	0	0	0	0	0	\N
1063	[#1,#6:3]-[#6:2](-[#1,#6:4])=[O:1]	6	Reaction pattern	9	0	[#1,#6:3]-[#6:2](-[#1,#6:4])=[O:1]	1063	0	0	0	0	0	0	0	\N
1064	[#7:4]-,:[#1:5]	6	Reaction pattern	9	0	[#7:4]-,:[#1:5]	1064	0	0	0	0	0	0	0	\N
1065	[C:1]-,:[#7&+](-[#8&-])=O	6	Reaction pattern	9	0	[C:1]-,:[#7&+](-[#8&-])=O	1065	0	0	0	0	0	0	0	\N
1067	[#1,#6:7]-[#6:4](-[#1,#6:8])=[O:5]	6	Reaction pattern	9	0	[#1,#6:7]-[#6:4](-[#1,#6:8])=[O:5]	1067	0	0	0	0	0	0	0	\N
1068	[c:1]-[#6,#7,#8,#16:3]	7	Reaction pattern	9	0	[c:1]-[#6,#7,#8,#16:3]	1068	0	0	0	0	0	0	0	\N
1069	[#1]-,:[#6:2](-[#1,#6:4])=[#6:1](-,:[#1])-[#1,#6:3]	6	Reaction pattern	9	0	[#1]-,:[#6:2](-[#1,#6:4])=[#6:1](-,:[#1])-[#1,#6:3]	1069	0	0	0	0	0	0	0	\N
1071	[#6&-:2]-,:[P&+:4](-,:[#6]1=[#6]-[#6]=[#6]-[#6]=[#6]-1)(-,:[#6]1=[#6]-[#6]=[#6]-[#6]=[#6]-1)-,:[#6]1=[#6]-[#6]=[#6]-[#6]=[#6]-1	6	Reaction pattern	9	0	[#6&-:2]-,:[P&+:4](-,:[#6]1=[#6]-[#6]=[#6]-[#6]=[#6]-1)(-,:[#6]2=[#6]-[#6]=[#6]-[#6]=[#6]-2)-,:[#6]3=[#6]-[#6]=[#6]-[#6]=[#6]-3	1071	0	0	0	0	0	0	0	\N
1072	[C:2]-,:[#9,#17,#35,#53:3]	7	Reaction pattern	9	0	[C:2]-,:[#9,#17,#35,#53:3]	1072	0	0	0	0	0	0	0	\N
1086	[C:2]-,:[Br:5]	7	Reaction pattern	9	0	[C:2]-,:[Br:5]	1086	0	0	0	0	0	0	0	\N
1087	[C:2]-,:[#9,#17,#35,#53:4]	6	Reaction pattern	9	0	[C:2]-,:[#9,#17,#35,#53:4]	1087	0	0	0	0	0	0	0	\N
1088	[#6:14]-[#6:10](=[O:15])-[#6:11]-[#6:12]=[O:13]	6	Reaction pattern	9	0	[#6:14]-[#6:10](=[O:15])-[#6:11]-[#6:12]=[O:13]	1088	0	0	0	0	0	0	0	\N
1073	[#1:5]-,:[n:1]1:,-[c:8](-[#6:14]):,-[c:7](-[#6:10](-[#6,#8:15])=[O:11]):,-[c:3](-[#6,#1:17]):,-[c:2]:,-1-[#6,#1:16]	7	Reaction pattern	9	0	[#1:5]-,:[n:1]1:,-[c:8](-[#6:14]):,-[c:7](-[#6:10](-[#6,#8:15])=[O:11]):,-[c:3](-[#6,#1:17]):,-[c:2]:,-1-[#6,#1:16]	1073	0	0	0	0	0	0	0	\N
1074	[#1:3]-,:[#6:2]=[#6:1]	6	Reaction pattern	9	0	[#1:3]-,:[#6:2]=[#6:1]	1074	0	0	0	0	0	0	0	\N
1075	[#1:9]-,:[#7:1](-,:[#1:8])-[c:12]1:,-c:,-c:,-c:,-c:,-[c:11]:,-1-[#6:4](-[#1,#6:13])=[O:10]	6	Reaction pattern	9	0	[#1:9]-,:[#7:1](-,:[#1:8])-[c:12]1:,-c:,-c:,-c:,-c:,-[c:11]:,-1-[#6:4](-[#1,#6:13])=[O:10]	1075	0	0	0	0	0	0	0	\N
1076	[#1:7]-,:[#7:6](-,:[#1:8])-[#7:1]-[c:15]1:,-[c:14]:,-[c:13]:,-[c:12]:,-[c:11]:,-[c:4]:,-1-,:[#1:16]	6	Reaction pattern	9	0	[#1:7]-,:[#7:6](-,:[#1:8])-[#7:1]-[c:15]1:,-[c:14]:,-[c:13]:,-[c:12]:,-[c:11]:,-[c:4]:,-1-,:[#1:16]	1076	0	0	0	0	0	0	0	\N
1077	[#1:4]-,:[#8:1]-,:[C:2](-,:[#1:3])(-,:[#1,#6])-,:[#1,#6]	6	Reaction pattern	9	0	[#1:4]-,:[#8:1]-,:[C:2](-,:[#1:3])(-,:[#1,#6])-,:[#1,#6]	1077	0	0	0	0	0	0	0	\N
1079	[#1:5]-,:[#7:1](-,:[#1:4])-[#6:2]	6	Reaction pattern	9	0	[#1:5]-,:[#7:1](-,:[#1:4])-[#6:2]	1079	0	0	0	0	0	0	0	\N
1080	[#6:8]-[#7:3]=[C:2]=[#7:1]-[#6:7]	6	Reaction pattern	9	0	[#6:8]-[#7:3]=[C:2]=[#7:1]-[#6:7]	1080	0	0	0	0	0	0	0	\N
1083	[#6:2]-[#7:1]	7	Reaction pattern	9	0	[#6:2]-[#7:1]	1083	0	0	0	0	0	0	0	\N
1084	[#1:4]-,:[#8:3]-[c:1]	7	Reaction pattern	9	0	[#1:4]-,:[#8:3]-[c:1]	1084	0	0	0	0	0	0	0	\N
1085	[#1:3]-,:[#6:1](=[O:5])-,:[C:2](-,:[#1:6])(-,:[#1:7])-,:[#1,#6:4]	7	Reaction pattern	9	0	[#1:3]-,:[#6:1](=[O:5])-,:[C:2](-,:[#1:6])(-,:[#1:7])-,:[#1,#6:4]	1085	0	0	0	0	0	0	0	\N
1089	[#1:10]-,:[c:5]1:,-[c:4]:,-[c:3]:,-[c:2]-,:[#7,#8,#16;a:1]-,:1	6	Reaction pattern	9	0	[#1:10]-,:[c:5]1:,-[c:4]:,-[c:3]:,-[c:2]-,:[#7,#8,#16;a:1]-,:1	1089	0	0	0	0	0	0	0	\N
1090	[C:1]#[C:2]	6	Reaction pattern	9	0	[C:1]#[C:2]	1090	0	0	0	0	0	0	0	\N
1091	[#1:5]-,:[#7:1]-[#6:2]-[#6:3]-[#9,#17,#35,#53:4]	6	Reaction pattern	9	0	[#1:5]-,:[#7:1]-[#6:2]-[#6:3]-[#9,#17,#35,#53:4]	1091	0	0	0	0	0	0	0	\N
1092	[#1:3]-,:[#6:1]-[#6:2]=O	7	Reaction pattern	9	0	[#1:3]-,:[#6:1]-[#6:2]=O	1092	0	0	0	0	0	0	0	\N
1093	[#1:5]-,:[#6:3](-,:[#1:6])-[#6:2](-[#1,#6:14])=[O:7]	6	Reaction pattern	9	0	[#1:5]-,:[#6:3](-,:[#1:6])-[#6:2](-[#1,#6:14])=[O:7]	1093	0	0	0	0	0	0	0	\N
1094	[#1:6]-,:[#8:2]-,:[C:1](-,:[#1:8])(-,:[#1:7])-,:[#6:5]	7	Reaction pattern	9	0	[#1:6]-,:[#8:2]-,:[C:1](-,:[#1:8])(-,:[#1:7])-,:[#6:5]	1094	0	0	0	0	0	0	0	\N
1095	[#6:10]-[#8:9]-[#6:7](=[O:8])-[#6:1]1-[#6:2]-[#6:3]-[#6:4]-[#6:5]-1=[O:6]	6	Reaction pattern	9	0	[#6:10]-[#8:9]-[#6:7](=[O:8])-[#6:1]1-[#6:2]-[#6:3]-[#6:4]-[#6:5]-1=[O:6]	1095	0	0	0	0	0	0	0	\N
1096	[#6:5]-[#6:6]=[O:7]	7	Reaction pattern	9	0	[#6:5]-[#6:6]=[O:7]	1096	0	0	0	0	0	0	0	\N
1097	[c:2]-[#9,#17,#35,#53:3]	6	Reaction pattern	9	0	[c:2]-[#9,#17,#35,#53:3]	1097	0	0	0	0	0	0	0	\N
1098	[#1:3]-,:[#7:2](-[#6:4])-[#1,#6:1]	6	Reaction pattern	9	0	[#1:3]-,:[#7:2](-[#6:4])-[#1,#6:1]	1098	0	0	0	0	0	0	0	\N
1099	[#7:1]-,:[#1:5]	6	Reaction pattern	9	0	[#7:1]-,:[#1:5]	1099	0	0	0	0	0	0	0	\N
1100	[c:2]-[#17,#35,#53:4]	6	Reaction pattern	9	0	[c:2]-[#17,#35,#53:4]	1100	0	0	0	0	0	0	0	\N
1101	[C:5]#[C:1]-,:[C:2]#[C:7]	6	Reaction pattern	9	0	[C:5]#[C:1]-,:[C:2]#[C:7]	1101	0	0	0	0	0	0	0	\N
1117	[#6:4]-[#7&X3:1]	6	Reaction pattern	9	0	[#6:4]-[#7&X3:1]	1117	0	0	0	0	0	0	0	\N
1118	[#7,#8,#16:5]-[#6:1]=[O:2]	7	Reaction pattern	9	0	[#7,#8,#16:5]-[#6:1]=[O:2]	1118	0	0	0	0	0	0	0	\N
1102	[c:3]1:,-[c:2]:,-[c:1]:,-[c:6]2:,-[c:7]:,-[c:8]:,-[c:9]:,-[c:10]:,-[c:5]:,-2:,-[c:4]:,-1	6	Reaction pattern	9	0	[c:3]2:,-[c:2]:,-[c:1]:,-[c:6]1:,-[c:7]:,-[c:8]:,-[c:9]:,-[c:10]:,-[c:5]:,-1:,-[c:4]:,-2	1102	0	0	0	0	0	0	0	\N
1103	[#1,#6]-[#6](=O)-[#8:3]-[#6:2]=[#6:1]	7	Reaction pattern	9	0	[#1,#6]-[#6](=O)-[#8:3]-[#6:2]=[#6:1]	1103	0	0	0	0	0	0	0	\N
1104	[#1:6]-,:[#8:4]-[#6:5]	6	Reaction pattern	9	0	[#1:6]-,:[#8:4]-[#6:5]	1104	0	0	0	0	0	0	0	\N
1105	[C:2]-,:[#1:1]	6	Reaction pattern	9	0	[C:2]-,:[#1:1]	1105	0	0	0	0	0	0	0	\N
1106	[#6:1]-[#7,#8,#16:2]-[#6:5]=[O:6]	7	Reaction pattern	9	0	[#6:1]-[#7,#8,#16:2]-[#6:5]=[O:6]	1106	0	0	0	0	0	0	0	\N
1107	[#6:2]-[#17,#35,#53:4]	6	Reaction pattern	9	0	[#6:2]-[#17,#35,#53:4]	1107	0	0	0	0	0	0	0	\N
1108	[#6:2]=[#6:1]	7	Reaction pattern	9	0	[#6:2]=[#6:1]	1108	0	0	0	0	0	0	0	\N
1109	[#1:8]-,:[#8:7]-[#6:5](=[O:6])-[#6:10]~[#6:9]-[#6:1](=[O:2])-[#8:3]-,:[#1:4]	6	Reaction pattern	9	0	[#1:8]-,:[#8:7]-[#6:5](=[O:6])-[#6:10]~[#6:9]-[#6:1](=[O:2])-[#8:3]-,:[#1:4]	1109	0	0	0	0	0	0	0	\N
1110	[#1:5]-,:[#7:4](-,:[#1:6])-[#6:1]	7	Reaction pattern	9	0	[#1:5]-,:[#7:4](-,:[#1:6])-[#6:1]	1110	0	0	0	0	0	0	0	\N
1112	[#6:3]-[c:2]1:,-[n:4]:,-[n:5]:,-[n:6](-[#6,#14:7]):,-[c:1]:,-1-[#1,#6,#7:8]	7	Reaction pattern	9	0	[#6:3]-[c:2]1:,-[n:4]:,-[n:5]:,-[n:6](-[#6,#14:7]):,-[c:1]:,-1-[#1,#6,#7:8]	1112	0	0	0	0	0	0	0	\N
1113	[#1:8]-,:[#8:7]-[#6:4]	7	Reaction pattern	9	0	[#1:8]-,:[#8:7]-[#6:4]	1113	0	0	0	0	0	0	0	\N
1114	[#6:3]-[#8:4]-[#6:2]=[#6:1]	6	Reaction pattern	9	0	[#6:3]-[#8:4]-[#6:2]=[#6:1]	1114	0	0	0	0	0	0	0	\N
1115	[#1,#6]-[#6:2]1-[#6:1]-[#8:3]-1	7	Reaction pattern	9	0	[#1,#6]-[#6:2]1-[#6:1]-[#8:3]-1	1115	0	0	0	0	0	0	0	\N
1116	[#6:6]-[#8:5]-[#6:1]=[O:2]	6	Reaction pattern	9	0	[#6:6]-[#8:5]-[#6:1]=[O:2]	1116	0	0	0	0	0	0	0	\N
1119	[#1:5]-,:[#6:2](-[#6:1])=[O:4]	7	Reaction pattern	9	0	[#1:5]-,:[#6:2](-[#6:1])=[O:4]	1119	0	0	0	0	0	0	0	\N
1120	[#6:8]-[c:5]1:,-[n:1]:,-[c:2]:,-[c:3]:,-[s:4]:,-1	7	Reaction pattern	9	0	[#6:8]-[c:5]1:,-[n:1]:,-[c:2]:,-[c:3]:,-[s:4]:,-1	1120	0	0	0	0	0	0	0	\N
1121	[#6:5]-[#6:1](-[#1,#6:4])=[O:2]	6	Reaction pattern	9	0	[#6:5]-[#6:1](-[#1,#6:4])=[O:2]	1121	0	0	0	0	0	0	0	\N
1123	[#1:4]-,:[#7:1](-,:[#1:3])-[#6:5]	6	Reaction pattern	9	0	[#1:4]-,:[#7:1](-,:[#1:3])-[#6:5]	1123	0	0	0	0	0	0	0	\N
1124	[#1:2]-,:[C:1](-,:[#1,#6:3])(-,:[#1,#6;A:4])-,:[#1,#6:5]	6	Reaction pattern	9	0	[#1:2]-,:[C:1](-,:[#1,#6:3])(-,:[#1,#6;A:4])-,:[#1,#6:5]	1124	0	0	0	0	0	0	0	\N
1125	[#1:5]-,:[#8:4]-[#6:1](-[#6:3])=[O:2]	6	Reaction pattern	9	0	[#1:5]-,:[#8:4]-[#6:1](-[#6:3])=[O:2]	1125	0	0	0	0	0	0	0	\N
1126	[#1:15]-,:[#7:1]1-[#6:6](-[#1,#6:7])=[#6:5]-[#6:4](-[#1,#6:10])=[#6:3](-,:[C:12]#[N:13])-[#6:2]-1=[O:14]	7	Reaction pattern	9	0	[#1:15]-,:[#7:1]1-[#6:6](-[#1,#6:7])=[#6:5]-[#6:4](-[#1,#6:10])=[#6:3](-,:[C:12]#[N:13])-[#6:2]-1=[O:14]	1126	0	0	0	0	0	0	0	\N
1127	[#1:16]-,:[n:4]1:,-[c:5](-[#6:15]):,-[n:3]:,-[c:2](-[#1,#6:9]):,-[c:1]:,-1-[#1,#6:8]	7	Reaction pattern	9	0	[#1:16]-,:[n:4]1:,-[c:5](-[#6:15]):,-[n:3]:,-[c:2](-[#1,#6:9]):,-[c:1]:,-1-[#1,#6:8]	1127	0	0	0	0	0	0	0	\N
1128	[#6:4]-[#7,#8,#16:5]-[#6:1]=[O:2]	7	Reaction pattern	9	0	[#6:4]-[#7,#8,#16:5]-[#6:1]=[O:2]	1128	0	0	0	0	0	0	0	\N
1130	[#6:1]-,:[#12:3]-,:[#17,#35,#53:2]	7	Reaction pattern	9	0	[#6:1]-,:[#12:3]-,:[#17,#35,#53:2]	1130	0	0	0	0	0	0	0	\N
1131	[#1]-,:[#7,#8,#16:5]-[#6:6]	6	Reaction pattern	9	0	[#1]-,:[#7,#8,#16:5]-[#6:6]	1131	0	0	0	0	0	0	0	\N
1142	[#1:6]-,:[#8:2]-[#6:1]-,:[C:3]#[N:4]	7	Reaction pattern	9	0	[#1:6]-,:[#8:2]-[#6:1]-,:[C:3]#[N:4]	1142	0	0	0	0	0	0	0	\N
1132	[#6:9](-[#8:1]-[c:2]1:,-[c:7]:,-[c:6]:,-[c:5]:,-[c:4]:,-[c:3]:,-1)-c1:,-c:,-c:,-c:,-c:,-c:,-1	7	Reaction pattern	9	0	[#6:9](-[#8:1]-[c:2]1:,-[c:7]:,-[c:6]:,-[c:5]:,-[c:4]:,-[c:3]:,-1)-c2:,-c:,-c:,-c:,-c:,-c:,-2	1132	0	0	0	0	0	0	0	\N
1133	[#1:3]-,:[#8:5]-,:[#1:6]	7	Reaction pattern	9	0	[#1:3]-,:[#8:5]-,:[#1:6]	1133	0	0	0	0	0	0	0	\N
1134	[#1:8]-,:[#7:7](-,:[#1:16])-[c:5]1:,-[n:4]:,-[c:3]:,-[c:2]:,-[c:1]:,-[n:6]:,-1	7	Reaction pattern	9	0	[#1:8]-,:[#7:7](-,:[#1:16])-[c:5]1:,-[n:4]:,-[c:3]:,-[c:2]:,-[c:1]:,-[n:6]:,-1	1134	0	0	0	0	0	0	0	\N
1135	[#1:5]-,:[#8:4]-,:[C:3](-,:[#1,#6,#7,#8:7])(-,:[#1,#6,#7,#8:6])-,:[C:1]#[C:2]	7	Reaction pattern	9	0	[#1:5]-,:[#8:4]-,:[C:3](-,:[#1,#6,#7,#8:7])(-,:[#1,#6,#7,#8:6])-,:[C:1]#[C:2]	1135	0	0	0	0	0	0	0	\N
1136	[#6:1]=,:[#6:2]-[#6:3]-[F,Cl,Br,I:5]	7	Reaction pattern	9	0	[#6:1]=,:[#6:2]-[#6:3]-[F,Cl,Br,I:5]	1136	0	0	0	0	0	0	0	\N
1137	[#1:3]-,:[#8:2]-[#6:1](-[#6:5])-[#1,#6:4]	7	Reaction pattern	9	0	[#1:3]-,:[#8:2]-[#6:1](-[#6:5])-[#1,#6:4]	1137	0	0	0	0	0	0	0	\N
1138	[C:6]#[C:3]-,:[C:4]#[C:8]	7	Reaction pattern	9	0	[C:6]#[C:3]-,:[C:4]#[C:8]	1138	0	0	0	0	0	0	0	\N
1139	[#6:1]=[#6:2]-,:[#6:3]=[#6:4]	6	Reaction pattern	9	0	[#6:1]=[#6:2]-,:[#6:3]=[#6:4]	1139	0	0	0	0	0	0	0	\N
1140	[c:3]1:,-[c:2]:,-[n:1]:,-[c:6]:,-[c:5]:,-[n:4]:,-1	7	Reaction pattern	9	0	[c:3]1:,-[c:2]:,-[n:1]:,-[c:6]:,-[c:5]:,-[n:4]:,-1	1140	0	0	0	0	0	0	0	\N
1141	[C:1]-,:[F,Cl,Br,I:3]	7	Reaction pattern	9	0	[C:1]-,:[F,Cl,Br,I:3]	1141	0	0	0	0	0	0	0	\N
1160	[Br:5]-,:[#6:3]-[#6:1]=[O:2]	7	Reaction pattern	9	0	[Br:5]-,:[#6:3]-[#6:1]=[O:2]	1160	0	0	0	0	0	0	0	\N
1144	[#1:6]-,:[#8:1]-,:[C:2](-,:[#1:5])(-,:[#1,#6:3])-,:[#1,#6:4]	7	Reaction pattern	9	0	[#1:6]-,:[#8:1]-,:[C:2](-,:[#1:5])(-,:[#1,#6:3])-,:[#1,#6:4]	1144	0	0	0	0	0	0	0	\N
1145	[#6:4]-[#6:2](-[#7&X3:1])=[O:3]	7	Reaction pattern	9	0	[#6:4]-[#6:2](-[#7&X3:1])=[O:3]	1145	0	0	0	0	0	0	0	\N
1146	[#1:6]-,:[#8:3]-[#6:4]	7	Reaction pattern	9	0	[#1:6]-,:[#8:3]-[#6:4]	1146	0	0	0	0	0	0	0	\N
1147	[#1,#6:3]-,:[C:1]#[C:2]-,:[#1,#6:4]	6	Reaction pattern	9	0	[#1,#6:3]-,:[C:1]#[C:2]-,:[#1,#6:4]	1147	0	0	0	0	0	0	0	\N
1148	[#6:4]-[#6:1](-[#6:3])=[O:2]	7	Reaction pattern	9	0	[#6:4]-[#6:1](-[#6:3])=[O:2]	1148	0	0	0	0	0	0	0	\N
1149	[#6:1]=,:[#6:2]-[#8,#16,#17,#35,#53:6]	6	Reaction pattern	9	0	[#6:1]=,:[#6:2]-[#8,#16,#17,#35,#53:6]	1149	0	0	0	0	0	0	0	\N
1150	[#1:9]-[#7:6](-,:[#1:11])-[#1,#6:7]	6	Reaction pattern	9	0	[#1:9]-[#7:6](-,:[#1:11])-[#1,#6:7]	1150	0	0	0	0	0	0	0	\N
1151	[#1,#6]-,:[#6:1](-[F,Cl,Br,I:3])=[#6:2](-,:[#1,#6])-[F,Cl,Br,I:4]	7	Reaction pattern	9	0	[#1,#6]-,:[#6:1](-[F,Cl,Br,I:3])=[#6:2](-,:[#1,#6])-[F,Cl,Br,I:4]	1151	0	0	0	0	0	0	0	\N
1152	[#6:3]-[#8,#17,#35,#53:4]	6	Reaction pattern	9	0	[#6:3]-[#8,#17,#35,#53:4]	1152	0	0	0	0	0	0	0	\N
1153	[#1:4]-,:[#8:3]-[#6:1](-[#6:5])=[O:2]	6	Reaction pattern	9	0	[#1:4]-,:[#8:3]-[#6:1](-[#6:5])=[O:2]	1153	0	0	0	0	0	0	0	\N
1154	[#6:2]-[#8,#17,#35,#53:4]	6	Reaction pattern	9	0	[#6:2]-[#8,#17,#35,#53:4]	1154	0	0	0	0	0	0	0	\N
1155	[#1,#14,#17,#35,#53:11]-,:[C:2]#[C:7]	6	Reaction pattern	9	0	[#1,#14,#17,#35,#53:11]-,:[C:2]#[C:7]	1155	0	0	0	0	0	0	0	\N
1156	[#6:1]=[O:2]	7	Reaction pattern	9	0	[#6:1]=[O:2]	1156	0	0	0	0	0	0	0	\N
1157	[#1:8]-,:[#8:7]-[#6:1]=[O:6]	7	Reaction pattern	9	0	[#1:8]-,:[#8:7]-[#6:1]=[O:6]	1157	0	0	0	0	0	0	0	\N
1159	[#1:4]-,:[#8:3]-[#6:2]-[#6:1]	7	Reaction pattern	9	0	[#1:4]-,:[#8:3]-[#6:2]-[#6:1]	1159	0	0	0	0	0	0	0	\N
1161	[#8,#9,#17,#35,#53:4]-,:[#1:2]	7	Reaction pattern	9	0	[#8,#9,#17,#35,#53:4]-,:[#1:2]	1161	0	0	0	0	0	0	0	\N
1162	[#7,#8,#16:1]-,:[#1:2]	6	Reaction pattern	9	0	[#7,#8,#16:1]-,:[#1:2]	1162	0	0	0	0	0	0	0	\N
1163	[#1:5]-,:[#6:1]=[O:2]	6	Reaction pattern	9	0	[#1:5]-,:[#6:1]=[O:2]	1163	0	0	0	0	0	0	0	\N
1164	[C:1]=O	6	Reaction pattern	9	0	[C:1]=O	1164	0	0	0	0	0	0	0	\N
1165	[#9,#17,#35,#53:4]-[#9,#17,#35,#53:3]	6	Reaction pattern	9	0	[#9,#17,#35,#53:4]-[#9,#17,#35,#53:3]	1165	0	0	0	0	0	0	0	\N
1166	[#1:10]-,:[#7:8](-,:[#1:11])-[#6:9]	6	Reaction pattern	9	0	[#1:10]-,:[#7:8](-,:[#1:11])-[#6:9]	1166	0	0	0	0	0	0	0	\N
1167	[C:3]-,:[#9,#17,#35,#53:4]	6	Reaction pattern	9	0	[C:3]-,:[#9,#17,#35,#53:4]	1167	0	0	0	0	0	0	0	\N
1168	[#1:6]-,:[#7:1]-[#6:7]	6	Reaction pattern	9	0	[#1:6]-,:[#7:1]-[#6:7]	1168	0	0	0	0	0	0	0	\N
1169	[#1:3]-,:[#7,#8,#16:2]-[#6:1]	6	Reaction pattern	9	0	[#1:3]-,:[#7,#8,#16:2]-[#6:1]	1169	0	0	0	0	0	0	0	\N
1170	[#1:7]-,:[#8:3]-[#6:4]-[#6:5]-[#8:6]-,:[#1:8]	6	Reaction pattern	9	0	[#1:7]-,:[#8:3]-[#6:4]-[#6:5]-[#8:6]-,:[#1:8]	1170	0	0	0	0	0	0	0	\N
1171	[#17,#35,#53:3]-[#6,#16:2]=[#8,#16]	6	Reaction pattern	9	0	[#17,#35,#53:3]-[#6,#16:2]=[#8,#16]	1171	0	0	0	0	0	0	0	\N
1172	[#1:6]-,:[#8:5]-[#6:3](-[#6:1])=[O:4]	7	Reaction pattern	9	0	[#1:6]-,:[#8:5]-[#6:3](-[#6:1])=[O:4]	1172	0	0	0	0	0	0	0	\N
1173	[#8&-]-,:[O&+]=O	6	Reaction pattern	9	0	[#8&-]-,:[O&+]=O	1173	0	0	0	0	0	0	0	\N
1174	[#1:5]-,:[#7:4]-[#6:1](-[#6:3])=[#7:2]	7	Reaction pattern	9	0	[#1:5]-,:[#7:4]-[#6:1](-[#6:3])=[#7:2]	1174	0	0	0	0	0	0	0	\N
1175	[#1:3]-,:[#6:1]=[#6:2]	6	Reaction pattern	9	0	[#1:3]-,:[#6:1]=[#6:2]	1175	0	0	0	0	0	0	0	\N
1176	[#1:8]-,:[#8:6]-[#6:7]	6	Reaction pattern	9	0	[#1:8]-,:[#8:6]-[#6:7]	1176	0	0	0	0	0	0	0	\N
1198	[Cl:3]-,:[#6:1]=[O:2]	6	Reaction pattern	9	0	[Cl:3]-,:[#6:1]=[O:2]	1198	0	0	0	0	0	0	0	\N
1177	[#6:5]-,:[S:1](=[O:3])(=[O:4])-,:[#7:2](-[#6,#1:9])-[#6,#1:8]	7	Reaction pattern	9	0	[#6:5]-,:[S:1](=[O:3])(=[O:4])-,:[#7:2](-[#6,#1:9])-[#6,#1:8]	1177	0	0	0	0	0	0	0	\N
1178	[c:1]-,:[#1:4]	6	Reaction pattern	9	0	[c:1]-,:[#1:4]	1178	0	0	0	0	0	0	0	\N
1179	[#1:4]-,:[C:3]-,:C-,:C-,:C-,:[#7&X3:1]-[#17,#35,#53:2]	6	Reaction pattern	9	0	[#1:4]-,:[C:3]-,:C-,:C-,:C-,:[#7&X3:1]-[#17,#35,#53:2]	1179	0	0	0	0	0	0	0	\N
1180	[#1:6]-,:[#8:4]-[#6:3]	6	Reaction pattern	9	0	[#1:6]-,:[#8:4]-[#6:3]	1180	0	0	0	0	0	0	0	\N
1181	[#1:6]-,:[#7:4]-[#6:5]	6	Reaction pattern	9	0	[#1:6]-,:[#7:4]-[#6:5]	1181	0	0	0	0	0	0	0	\N
1182	[#6:1]-[#6:2]=[O:3]	7	Reaction pattern	9	0	[#6:1]-[#6:2]=[O:3]	1182	0	0	0	0	0	0	0	\N
1183	[#1:6]-,:[#6:2]-[#6:1](=[O:5])-[#8:3]-,:[#1:4]	6	Reaction pattern	9	0	[#1:6]-,:[#6:2]-[#6:1](=[O:5])-[#8:3]-,:[#1:4]	1183	0	0	0	0	0	0	0	\N
1184	[O:7]=[#6:1]1-[#6:6]-[#6:5]-[#6:4]-[#6:3]-[#6:2]-1	7	Reaction pattern	9	0	[O:7]=[#6:1]1-[#6:6]-[#6:5]-[#6:4]-[#6:3]-[#6:2]-1	1184	0	0	0	0	0	0	0	\N
1186	[#6:1]-[#8:2]-[#6:4]	7	Reaction pattern	9	0	[#6:1]-[#8:2]-[#6:4]	1186	0	0	0	0	0	0	0	\N
1188	[#7&X3:1]-[#6:2]=[#6:3]	7	Reaction pattern	9	0	[#7&X3:1]-[#6:2]=[#6:3]	1188	0	0	0	0	0	0	0	\N
1190	[#7,#8,#16:2]-,:[#1:5]	6	Reaction pattern	9	0	[#7,#8,#16:2]-,:[#1:5]	1190	0	0	0	0	0	0	0	\N
1193	C-,:[#7&+:1]-[#8&-:2]	7	Reaction pattern	9	0	C-,:[#7&+:1]-[#8&-:2]	1193	0	0	0	0	0	0	0	\N
1194	[Br:5]-,:[C:6]#[N:7]	6	Reaction pattern	9	0	[Br:5]-,:[C:6]#[N:7]	1194	0	0	0	0	0	0	0	\N
1195	[Cl:6]-,:[S:3](=[O:5])=[O:4]	6	Reaction pattern	9	0	[Cl:6]-,:[S:3](=[O:5])=[O:4]	1195	0	0	0	0	0	0	0	\N
1196	[#6:8]=[N&+]=[#7&-]	6	Reaction pattern	9	0	[#6:8]=[N&+]=[#7&-]	1196	0	0	0	0	0	0	0	\N
1197	[#1:8]-,:[#7:6](-,:[#1:9])-[#7,#8:7]	6	Reaction pattern	9	0	[#1:8]-,:[#7:6](-,:[#1:9])-[#7,#8:7]	1197	0	0	0	0	0	0	0	\N
1199	[O&D1]-[C&D2]	7	Reaction pattern	9	0	[O&D1]-[C&D2]	primary-alcohol	0	0	0	0	0	0	0	\N
1200	[#6:1]=[#6:3]	6	Reaction pattern	9	0	[#6:1]=[#6:3]	1200	0	0	0	0	0	0	0	\N
1201	[O:3]=[#6:2]-[#6:1]=[O:4]	6	Reaction pattern	9	0	[O:3]=[#6:2]-[#6:1]=[O:4]	1201	0	0	0	0	0	0	0	\N
1202	[#1:4]-,:[#8:3]-[#6:1](=[O:2])-[#6:5]-[#9,#17,#35:6]	6	Reaction pattern	9	0	[#1:4]-,:[#8:3]-[#6:1](=[O:2])-[#6:5]-[#9,#17,#35:6]	1202	0	0	0	0	0	0	0	\N
1203	[#1,#6:4]-[#6:1]=[O:3]	6	Reaction pattern	9	0	[#1,#6:4]-[#6:1]=[O:3]	1203	0	0	0	0	0	0	0	\N
1204	[#1:4]-,:[#6:3]-[#6:2]-[#7&+:1]	6	Reaction pattern	9	0	[#1:4]-,:[#6:3]-[#6:2]-[#7&+:1]	1204	0	0	0	0	0	0	0	\N
1205	[#6:2]-[#8,#16,#17,#35,#53:4]	6	Reaction pattern	9	0	[#6:2]-[#8,#16,#17,#35,#53:4]	1205	0	0	0	0	0	0	0	\N
1206	[C:1]=[C:5](-,:[C:4]#[N:3])-,:[C:6](=[O:7])-,:[N:8]	7	Reaction pattern	9	0	[C:1]=[C:5](-,:[C:4]#[N:3])-,:[C:6](=[O:7])-,:[N:8]	1206	0	0	0	0	0	0	0	\N
1207	[#1:7]-,:[#7:1]-[c:2]1:,-[c:15]:,-[c:14]:,-[c:13]:,-[c:12]:,-[c:3]:,-1-[#7:4](-,:[#1:6])-,:[#1:5]	6	Reaction pattern	9	0	[#1:7]-,:[#7:1]-[c:2]1:,-[c:15]:,-[c:14]:,-[c:13]:,-[c:12]:,-[c:3]:,-1-[#7:4](-,:[#1:6])-,:[#1:5]	1207	0	0	0	0	0	0	0	\N
1208	[C:2]#[C:1]-,:[C:3]#[C:4]	7	Reaction pattern	9	0	[C:2]#[C:1]-,:[C:3]#[C:4]	1208	0	0	0	0	0	0	0	\N
1210	[#1:16]-,:[#7:6](-,:[#1])-[#6:5](-[#1,#6:15])=[O:14]	6	Reaction pattern	9	0	[#1:16]-,:[#7:6](-,:[#1])-[#6:5](-[#1,#6:15])=[O:14]	1210	0	0	0	0	0	0	0	\N
1211	[#6:5]-[#6:1](=[O:6])-[#6:2]-[#6:3]=[O:4]	6	Reaction pattern	9	0	[#6:5]-[#6:1](=[O:6])-[#6:2]-[#6:3]=[O:4]	1211	0	0	0	0	0	0	0	\N
1213	[#1,#14,#17,#35,#53:10]-,:[C:1]#[C:5]	6	Reaction pattern	9	0	[#1,#14,#17,#35,#53:10]-,:[C:1]#[C:5]	1213	0	0	0	0	0	0	0	\N
1214	[#1:3]-,:[C:1](-,:[#1:2])(-,:C)-,:C	6	Reaction pattern	9	0	[#1:3]-,:[C:1](-,:[#1:2])(-,:C)-,:C	1214	0	0	0	0	0	0	0	\N
1215	[#6:7]-[#8:6]-[#6:1]-[#8:3]-[#6:4]	7	Reaction pattern	9	0	[#6:7]-[#8:6]-[#6:1]-[#8:3]-[#6:4]	1215	0	0	0	0	0	0	0	\N
1216	[O:5]=[#6:1]!@&-[#6:2]-[#6:3]=[O:4]	6	Reaction pattern	9	0	[O:5]=[#6:1]!@&-[#6:2]-[#6:3]=[O:4]	1216	0	0	0	0	0	0	0	\N
1217	[#1]-,:[#7:4](-,:[#1])-[c:3]1:,-[c:11]:,-[c:10]:,-[c:9]:,-[c:8]:,-[c:2]:,-1-[#6:1](-[#7,#8:12])=[O:7]	6	Reaction pattern	9	0	[#1]-,:[#7:4](-,:[#1])-[c:3]1:,-[c:11]:,-[c:10]:,-[c:9]:,-[c:8]:,-[c:2]:,-1-[#6:1](-[#7,#8:12])=[O:7]	1217	0	0	0	0	0	0	0	\N
1218	[#6:1]=[#6:5]-[#6:6]=[O:7]	7	Reaction pattern	9	0	[#6:1]=[#6:5]-[#6:6]=[O:7]	1218	0	0	0	0	0	0	0	\N
1220	[#1:5]-,:[#8:2]-[#6:1]	6	Reaction pattern	9	0	[#1:5]-,:[#8:2]-[#6:1]	1220	0	0	0	0	0	0	0	\N
1221	[#6:1]-[#7&+:2](-[#8&-])=O	6	Reaction pattern	9	0	[#6:1]-[#7&+:2](-[#8&-])=O	1221	0	0	0	0	0	0	0	\N
1222	[C:1]-,:[#6,#7,#8,#9,#16,#17,#35,#53:3]	7	Reaction pattern	9	0	[C:1]-,:[#6,#7,#8,#9,#16,#17,#35,#53:3]	1222	0	0	0	0	0	0	0	\N
1223	[#1:8]-,:[#8:7]-[c:1]1:,-[c:6]:,-[c:5]:,-[c:4]:,-[c:3]:,-[c:2]:,-1-[#6:9](-[#8:11])=[O:10]	7	Reaction pattern	9	0	[#1:8]-,:[#8:7]-[c:1]1:,-[c:6]:,-[c:5]:,-[c:4]:,-[c:3]:,-[c:2]:,-1-[#6:9](-[#8:11])=[O:10]	1223	0	0	0	0	0	0	0	\N
1224	[#6:2]=[O:4]	7	Reaction pattern	9	0	[#6:2]=[O:4]	1224	0	0	0	0	0	0	0	\N
1225	[#6:2]-,:[N&+:1](-,:[#6:4])(-,:[#6:5])-,:[#6:3]	7	Reaction pattern	9	0	[#6:2]-,:[N&+:1](-,:[#6:4])(-,:[#6:5])-,:[#6:3]	1225	0	0	0	0	0	0	0	\N
1226	[#6:7]-[#7:1]-[#6:2](-[#6:3])-[#6]	7	Reaction pattern	9	0	[#6:7]-[#7:1]-[#6:2](-[#6:3])-[#6]	1226	0	0	0	0	0	0	0	\N
1227	[#1:8]-,:[#8:7]-[c:6]:[c:5]	6	Reaction pattern	9	0	[#1:8]-,:[#8:7]-[c:6]:[c:5]	1227	0	0	0	0	0	0	0	\N
1243	[#1:3]-,:[#8:4]-[#6:2](-[c:1])=[O:5]	7	Reaction pattern	9	0	[#1:3]-,:[#8:4]-[#6:2](-[c:1])=[O:5]	1243	0	0	0	0	0	0	0	\N
1228	[#1:10]-,:[#7:1]1-[c:8]2:,-[c:7]:,-[c:6]:,-[c:5]:,-[c:4]:,-[c:9]:,-2-[#7:3](-,:[#1:13])-,:[C:2]-,:1(-,:[#1,#6:16])-,:[#1,#6:15]	7	Reaction pattern	9	0	[#1:10]-,:[#7:1]2-[c:8]1:,-[c:7]:,-[c:6]:,-[c:5]:,-[c:4]:,-[c:9]:,-1-[#7:3](-,:[#1:13])-,:[C:2]-,:2(-,:[#1,#6:16])-,:[#1,#6:15]	1228	0	0	0	0	0	0	0	\N
1229	[#1:4]-,:[#6:1](-[#6:3])=[O:2]	6	Reaction pattern	9	0	[#1:4]-,:[#6:1](-[#6:3])=[O:2]	1229	0	0	0	0	0	0	0	\N
1230	[#6:1]-,:[#12:2]-,:[#17,#35,#53:3]	6	Reaction pattern	9	0	[#6:1]-,:[#12:2]-,:[#17,#35,#53:3]	1230	0	0	0	0	0	0	0	\N
1231	[c:3]1:,-[c:4]:,-[c:5]-,:[#7,#8,#16;a:1]-,:[c:2]:,-1	6	Reaction pattern	9	0	[c:3]1:,-[c:4]:,-[c:5]-,:[#7,#8,#16;a:1]-,:[c:2]:,-1	1231	0	0	0	0	0	0	0	\N
1232	[#7:1]-[#7:2]=[O:3]	7	Reaction pattern	9	0	[#7:1]-[#7:2]=[O:3]	1232	0	0	0	0	0	0	0	\N
1233	[#1:4]-,:[#8:3]-[#6:1](-[#6:5])=[O:2]	7	Reaction pattern	9	0	[#1:4]-,:[#8:3]-[#6:1](-[#6:5])=[O:2]	1233	0	0	0	0	0	0	0	\N
1234	[#7,#8,#17:9]-[#6:7]=[O:8]	6	Reaction pattern	9	0	[#7,#8,#17:9]-[#6:7]=[O:8]	1234	0	0	0	0	0	0	0	\N
1235	[#6:1]-,:[I:5]	7	Reaction pattern	9	0	[#6:1]-,:[I:5]	1235	0	0	0	0	0	0	0	\N
1236	[#6:1]=[#6:2]	6	Reaction pattern	9	0	[#6:1]=[#6:2]	1236	0	0	0	0	0	0	0	\N
1237	[#6:1]=[O:2]	6	Reaction pattern	9	0	[#6:1]=[O:2]	1237	0	0	0	0	0	0	0	\N
1238	[O:2]=[#6:1]-[#8:3]-[#6:5]=[O:6]	7	Reaction pattern	9	0	[O:2]=[#6:1]-[#8:3]-[#6:5]=[O:6]	1238	0	0	0	0	0	0	0	\N
1239	[#1:7]-,:[#7:2](-[#6,#1:8])-[#6,#1:9]	6	Reaction pattern	9	0	[#1:7]-,:[#7:2](-[#6,#1:8])-[#6,#1:9]	1239	0	0	0	0	0	0	0	\N
1240	[C:2]#[C:1]	6	Reaction pattern	9	0	[C:2]#[C:1]	1240	0	0	0	0	0	0	0	\N
1241	[#9,#17,#35,#53:4]-,:[#1:2]	7	Reaction pattern	9	0	[#9,#17,#35,#53:4]-,:[#1:2]	1241	0	0	0	0	0	0	0	\N
1242	*-,:[#6:2](-[*:4])=[#6:1](-,:[*:3])-*	7	Reaction pattern	9	0	[*,#1]-,:[#6:2](-[*,#1:4])=[#6:1](-,:[*,#1:3])-[*,#1]	1242	0	0	0	0	0	0	0	\N
1245	[#6:4]-[#8:3]-[#6:1](-[#6:7])=[O:2]	6	Reaction pattern	9	0	[#6:4]-[#8:3]-[#6:1](-[#6:7])=[O:2]	1245	0	0	0	0	0	0	0	\N
1246	Cl-,:[#6:9]-c1:,-c:,-c:,-c:,-c:,-c:,-1	6	Reaction pattern	9	0	[Cl]-,:[#6:9]-c1:,-c:,-c:,-c:,-c:,-c:,-1	1246	0	0	0	0	0	0	0	\N
1247	[#1:4]-,:[#6:3]-[#6:2]=[O:6]	6	Reaction pattern	9	0	[#1:4]-,:[#6:3]-[#6:2]=[O:6]	1247	0	0	0	0	0	0	0	\N
1248	[#1,#6]-[#6:1](-[#1,#6])=[#6,#7,#8,#16:2]	6	Reaction pattern	9	0	[#1,#6]-[#6:1](-[#1,#6])=[#6,#7,#8,#16:2]	1248	0	0	0	0	0	0	0	\N
1249	[#6:1]-[#6:2]=[O:3]	6	Reaction pattern	9	0	[#6:1]-[#6:2]=[O:3]	1249	0	0	0	0	0	0	0	\N
1250	[#8:5]-[#6:3](=[O:4])-[#6:2]-[#6:1]=[O:6]	6	Reaction pattern	9	0	[#8:5]-[#6:3](=[O:4])-[#6:2]-[#6:1]=[O:6]	1250	0	0	0	0	0	0	0	\N
1251	[#1:3]-,:[#8:2]-[#6:1]	6	Reaction pattern	9	0	[#1:3]-,:[#8:2]-[#6:1]	1251	0	0	0	0	0	0	0	\N
1252	[#1,#6:13]-[#6:2](=[O:11])-[#6:1](-[#1,#6:14])=[O:12]	6	Reaction pattern	9	0	[#1,#6:13]-[#6:2](=[O:11])-[#6:1](-[#1,#6:14])=[O:12]	1252	0	0	0	0	0	0	0	\N
1253	[#6:1]1-[#6:6]=[#6:5]-[#6:4]-[#6:3]=[#6:2]-1	7	Reaction pattern	9	0	[#6:1]1-[#6:6]=[#6:5]-[#6:4]-[#6:3]=[#6:2]-1	1253	0	0	0	0	0	0	0	\N
1254	[#6:1]=,:[#6:2]-[#6:3]-,:[#1:4]	6	Reaction pattern	9	0	[#6:1]=,:[#6:2]-[#6:3]-,:[#1:4]	1254	0	0	0	0	0	0	0	\N
1255	[#1:4]-,:[C:3]#N	6	Reaction pattern	9	0	[#1:4]-,:[C:3]#N	1255	0	0	0	0	0	0	0	\N
1256	[#1:5]-,:[#6:3](=[O:4])-[#6:2]-[#6:1]	7	Reaction pattern	9	0	[#1:5]-,:[#6:3](=[O:4])-[#6:2]-[#6:1]	1256	0	0	0	0	0	0	0	\N
1257	[#6:4]-[#7:1](-[#6:3])-,:[C:6]#[N:7]	6	Reaction pattern	9	0	[#6:4]-[#7:1](-[#6:3])-,:[C:6]#[N:7]	1257	0	0	0	0	0	0	0	\N
1259	[#1,#6:3]-,:[C:1]#[C:2]	6	Reaction pattern	9	0	[#1,#6:3]-,:[C:1]#[C:2]	1259	0	0	0	0	0	0	0	\N
1260	[#1:7]-,:[#7:4](-[#1,#6:5])-[#1,#6:6]	6	Reaction pattern	9	0	[#1:7]-,:[#7:4](-[#1,#6:5])-[#1,#6:6]	1260	0	0	0	0	0	0	0	\N
1261	[#1,#6:6]-[c:5]1:,-[c:4]:,-[c:3]:,-[c:2](-[#1,#6:1]):,-[n&v3:7]:,-1	7	Reaction pattern	9	0	[#1,#6:6]-[c:5]1:,-[c:4]:,-[c:3]:,-[c:2](-[#1,#6:1]):,-[n&v3:7]:,-1	1261	0	0	0	0	0	0	0	\N
1262	[#6:3]-,:[#12:4]-,:[#9,#17,#35,#53:5]	6	Reaction pattern	9	0	[#6:3]-,:[#12:4]-,:[#9,#17,#35,#53:5]	1262	0	0	0	0	0	0	0	\N
1264	[#6:2]1-[#6:1]-[#8]-1	6	Reaction pattern	9	0	[#6:2]1-[#6:1]-[#8]-1	1264	0	0	0	0	0	0	0	\N
1265	[Cl:14]-,:[c:1]1:,-[n:6]:,-[c:5](-[#1,#6:11]):,-[n:4]:,-[c:3]2:,-[c:10]:,-[c:9]:,-[c:8]:,-[c:7]:,-[c:2]:,-1:,-2	7	Reaction pattern	9	0	[Cl:14]-,:[c:1]1:,-[n:6]:,-[c:5](-[#1,#6:11]):,-[n:4]:,-[c:3]2:,-[c:10]:,-[c:9]:,-[c:8]:,-[c:7]:,-[c:2]:,-1:,-2	1265	0	0	0	0	0	0	0	\N
1267	[#6:4]-,:[C:2]#[C:1]-,:[#6:3]	6	Reaction pattern	9	0	[#6:4]-,:[C:2]#[C:1]-,:[#6:3]	1267	0	0	0	0	0	0	0	\N
1268	[#9,#17,#35,#53:3]-[#6:1]-[#1,#6:2]	6	Reaction pattern	9	0	[#9,#17,#35,#53:3]-[#6:1]-[#1,#6:2]	1268	0	0	0	0	0	0	0	\N
1269	[#15:8]-[#6:5]-[#6:6]=[O:7]	6	Reaction pattern	9	0	[#15:8]-[#6:5]-[#6:6]=[O:7]	1269	0	0	0	0	0	0	0	\N
1270	[#1:8]-,:[#7:4](-[#1,#6:7])-[#1,#6:6]	7	Reaction pattern	9	0	[#1:8]-,:[#7:4](-[#1,#6:7])-[#1,#6:6]	1270	0	0	0	0	0	0	0	\N
1271	[#1:8]-,:[#7:7]=[#6:5](-,:[#7:4](-,:[#1:9])-,:[#1:10])-[#7:6](-,:[#1:12])-,:[#1:11]	6	Reaction pattern	9	0	[#1:8]-,:[#7:7]=[#6:5](-,:[#7:4](-,:[#1:9])-,:[#1:10])-[#7:6](-,:[#1:12])-,:[#1:11]	1271	0	0	0	0	0	0	0	\N
1272	[#1:8]-,:[#8:7]-[#6:5](-[#6:9])=[O:6]	6	Reaction pattern	9	0	[#1:8]-,:[#8:7]-[#6:5](-[#6:9])=[O:6]	1272	0	0	0	0	0	0	0	\N
1273	[#1:7]-,:[#6:1]-[#6:2]=[O:4]	7	Reaction pattern	9	0	[#1:7]-,:[#6:1]-[#6:2]=[O:4]	1273	0	0	0	0	0	0	0	\N
1507	[#1,#14:5]-,:[C:1]#[C:2]	6	Reaction pattern	9	0	[#1,#14:5]-,:[C:1]#[C:2]	1507	0	0	0	0	0	0	0	\N
1274	[#1,#6]-,:[C:1]1(-,:[#1,#6])-,:[#6]-[#6,#7,#8,#16:2]-,:1	7	Reaction pattern	9	0	[#1,#6]-,:[C:1]1(-,:[#1,#6])-,:[#6]-[#6,#7,#8,#16:2]-,:1	1274	0	0	0	0	0	0	0	\N
1276	[#6,#1:3]-[#7:1]=[C:4]=[O:5]	7	Reaction pattern	9	0	[#6,#1:3]-[#7:1]=[C:4]=[O:5]	1276	0	0	0	0	0	0	0	\N
1277	[#1:4]-,:[#6:2]-[#6:1]=[O:3]	7	Reaction pattern	9	0	[#1:4]-,:[#6:2]-[#6:1]=[O:3]	1277	0	0	0	0	0	0	0	\N
1278	[#1:5]-,:[#8:4]-[#6:1]=[O:2]	6	Reaction pattern	9	0	[#1:5]-,:[#8:4]-[#6:1]=[O:2]	1278	0	0	0	0	0	0	0	\N
1279	[#1:2]-,:[#7:1](-,:[#1:4])-[#1,#6:3]	6	Reaction pattern	9	0	[#1:2]-,:[#7:1](-,:[#1:4])-[#1,#6:3]	1279	0	0	0	0	0	0	0	\N
1280	[#1:4]-,:[#8:3]-[#6:2]	6	Reaction pattern	9	0	[#1:4]-,:[#8:3]-[#6:2]	1280	0	0	0	0	0	0	0	\N
1281	[#1:5]-,:[#8:4]-,:[C:3]-,:[#6:2]=[#6:1]-,:[#1,#6:4]	7	Reaction pattern	9	0	[#1:5]-,:[#8:4]-,:[C:3]-,:[#6:2]=[#6:1]-,:[#1,#6:4]	1281	0	0	0	0	0	0	0	\N
1282	[c:3]-,:[#7:4]=[#7:2]-,:[c:1]	7	Reaction pattern	9	0	[c:3]-,:[#7:4]=[#7:2]-,:[c:1]	1282	0	0	0	0	0	0	0	\N
1283	[#6:1]-[#8:2]-[#6:3]	6	Reaction pattern	9	0	[#6:1]-[#8:2]-[#6:3]	1283	0	0	0	0	0	0	0	\N
1284	[#1,#6:10]-[#6:8](!@&-[#1,#8:11])=[O:9]	6	Reaction pattern	9	0	[#1,#6:10]-[#6:8](!@&-[#1,#8:11])=[O:9]	1284	0	0	0	0	0	0	0	\N
1285	[#1:4]-,:[#7&X3:1]-,:[#1:5]	6	Reaction pattern	9	0	[#1:4]-,:[#7&X3:1]-,:[#1:5]	1285	0	0	0	0	0	0	0	\N
1286	[#1,#6:15]-[#6:5]1=[#7:4]-[c:3]2:,-[c:11]:,-[c:10]:,-[c:9]:,-[c:8]:,-[c:2]:,-2-[#6:1](=[O:7])-[#7:6]-1	7	Reaction pattern	9	0	[#1,#6:15]-[#6:5]2=[#7:4]-[c:3]1:,-[c:11]:,-[c:10]:,-[c:9]:,-[c:8]:,-[c:2]:,-1-[#6:1](=[O:7])-[#7:6]-2	1286	0	0	0	0	0	0	0	\N
1287	[#1:15]-,:[#6:2](-[#6:1]=[O:13])-[#6:3]=[O:14]	6	Reaction pattern	9	0	[#1:15]-,:[#6:2](-[#6:1]=[O:13])-[#6:3]=[O:14]	1287	0	0	0	0	0	0	0	\N
1288	[#1:7]-,:[#7:4](-,:[#1:8])-[#6:5](-,:[#1:14])-[#6:6]=[O:9]	6	Reaction pattern	9	0	[#1:7]-,:[#7:4](-,:[#1:8])-[#6:5](-,:[#1:14])-[#6:6]=[O:9]	1288	0	0	0	0	0	0	0	\N
1289	[#6:2]=[O:3]	6	Reaction pattern	9	0	[#6:2]=[O:3]	1289	0	0	0	0	0	0	0	\N
1292	[#1]-,:[#7:1](-[#6:4])-[#6:2](=[#8,#16:3])-[#7,#8,#16:5]-[#6:6]	7	Reaction pattern	9	0	[#1]-,:[#7:1](-[#6:4])-[#6:2](=[#8,#16:3])-[#7,#8,#16:5]-[#6:6]	1292	0	0	0	0	0	0	0	\N
1293	[#6,#7,#8,#16;-:3]	6	Reaction pattern	9	0	[#6,#7,#8,#16;-:3]	1293	0	0	0	0	0	0	0	\N
1294	[#1:8]-,:[#8:4]-[c:3]:[c:2]-[#7:1](-,:[#1:9])-,:[#1:10]	6	Reaction pattern	9	0	[#1:8]-,:[#8:4]-[c:3]:[c:2]-[#7:1](-,:[#1:9])-,:[#1:10]	1294	0	0	0	0	0	0	0	\N
1295	[#1]-,:[#6:2](-[#6])=[O:4]	6	Reaction pattern	9	0	[#1]-,:[#6:2](-[#6])=[O:4]	1295	0	0	0	0	0	0	0	\N
1296	[#9,#17,#35,#53:3]-[*:4]	6	Reaction pattern	9	0	[#9,#17,#35,#53:3]-[*,#1:4]	1296	0	0	0	0	0	0	0	\N
1297	[#7,#8,#16:1]-[#6:3]=[O:4]	7	Reaction pattern	9	0	[#7,#8,#16:1]-[#6:3]=[O:4]	1297	0	0	0	0	0	0	0	\N
1298	[#1,#14,#17,#35,#53:9]-,:[C:3]#[C:6]	6	Reaction pattern	9	0	[#1,#14,#17,#35,#53:9]-,:[C:3]#[C:6]	1298	0	0	0	0	0	0	0	\N
1299	[#1:6]-,:[#7,#8,#16:5]-[#6:4]	6	Reaction pattern	9	0	[#1:6]-,:[#7,#8,#16:5]-[#6:4]	1299	0	0	0	0	0	0	0	\N
1300	[#6:2]=[#6:3]	7	Reaction pattern	9	0	[#6:2]=[#6:3]	1300	0	0	0	0	0	0	0	\N
1301	[#1:6]-,:[#8:3]-[#6:1](-[#6:5])=[O:2]	6	Reaction pattern	9	0	[#1:6]-,:[#8:3]-[#6:1](-[#6:5])=[O:2]	1301	0	0	0	0	0	0	0	\N
1302	[#17,#35:9]-[#6:8]-[#6:7]=[O:9]	6	Reaction pattern	9	0	[#17,#35:9]-[#6:8]-[#6:7]=[O:9]	1302	0	0	0	0	0	0	0	\N
1303	[O:17]=[#6:12]1-[#6:16]-[#6:15]-[#6,#7:14]-[#6:13]-1	6	Reaction pattern	9	0	[O:17]=[#6:12]1-[#6:16]-[#6:15]-[#6,#7:14]-[#6:13]-1	1303	0	0	0	0	0	0	0	\N
1304	[#1:3]-,:[C:1]-,:[C:2]-,:[#9,#17,#35,#53]	6	Reaction pattern	9	0	[#1:3]-,:[C:1]-,:[C:2]-,:[#9,#17,#35,#53]	1304	0	0	0	0	0	0	0	\N
1305	[#1:8]-,:[#7:6](-,:[#1:7])-[#6:5]-,:[#6:4]-[#7:3](-,:[#1:10])-,:[#1:9]	6	Reaction pattern	9	0	[#1:8]-,:[#7:6](-,:[#1:7])-[#6:5]-,:[#6:4]-[#7:3](-,:[#1:10])-,:[#1:9]	1305	0	0	0	0	0	0	0	\N
1306	[#1,#14,#17,#35,#53:12]-,:[C:4]#[C:8]	6	Reaction pattern	9	0	[#1,#14,#17,#35,#53:12]-,:[C:4]#[C:8]	1306	0	0	0	0	0	0	0	\N
1307	[#1:4]-,:[#8:2]-[#6:3]	6	Reaction pattern	9	0	[#1:4]-,:[#8:2]-[#6:3]	1307	0	0	0	0	0	0	0	\N
1308	[#1,#6:6]-[#6:5](=[O:10])-[#6:4]~[#6:3]-[#6:2](!@&-[#1,#6:1])=[O:9]	6	Reaction pattern	9	0	[#1,#6:6]-[#6:5](=[O:10])-[#6:4]~[#6:3]-[#6:2](!@&-[#1,#6:1])=[O:9]	1308	0	0	0	0	0	0	0	\N
1309	[c:1]-[#17,#35,#53:3]	6	Reaction pattern	9	0	[c:1]-[#17,#35,#53:3]	1309	0	0	0	0	0	0	0	\N
1310	[#6:4]-,:[#12:5]-,:[#17,#35,#53:6]	6	Reaction pattern	9	0	[#6:4]-,:[#12:5]-,:[#17,#35,#53:6]	1310	0	0	0	0	0	0	0	\N
1311	[#1:4]-,:[#8:3]-[#6:1](-[#1,#6:8])=[O:2]	6	Reaction pattern	9	0	[#1:4]-,:[#8:3]-[#6:1](-[#1,#6:8])=[O:2]	1311	0	0	0	0	0	0	0	\N
1312	[#1:15]-,:[#7:1](-,:[#1:7])-[#6:2](=[O:14])-,:[C:3](-,:[#1:17])(-,:[#1:18])-,:[C:12]#[N:13]	6	Reaction pattern	9	0	[#1:15]-,:[#7:1](-,:[#1:7])-[#6:2](=[O:14])-,:[C:3](-,:[#1:17])(-,:[#1:18])-,:[C:12]#[N:13]	1312	0	0	0	0	0	0	0	\N
1313	[#1,#6]-[#6:2](-[#1,#6])=[O:1]	7	Reaction pattern	9	0	[#1,#6]-[#6:2](-[#1,#6])=[O:1]	1313	0	0	0	0	0	0	0	\N
1314	[#6:3]-[#6:1](-,:[Br:6])=[O:2]	7	Reaction pattern	9	0	[#6:3]-[#6:1](-,:[Br:6])=[O:2]	1314	0	0	0	0	0	0	0	\N
1315	[O&D1]-C=O	6	Reaction pattern	9	0	[O&D1]-C=O	carboxylic-acid	0	0	0	0	0	0	0	\N
1316	[#6:5]-[#9,#17,#35,#53:6]	6	Reaction pattern	9	0	[#6:5]-[#9,#17,#35,#53:6]	1316	0	0	0	0	0	0	0	\N
1317	[#1:4]-,:[#6:3]-[#6:1](-[#1,#6:7])=[O:2]	6	Reaction pattern	9	0	[#1:4]-,:[#6:3]-[#6:1](-[#1,#6:7])=[O:2]	1317	0	0	0	0	0	0	0	\N
1318	[#1:3]-,:[#8:2]-,:[#1:4]	7	Reaction pattern	9	0	[#1:3]-,:[#8:2]-,:[#1:4]	1318	0	0	0	0	0	0	0	\N
1319	[#1:9]-,:[#7:3](-,:[#1:8])-[#6:4]=[S:5]	6	Reaction pattern	9	0	[#1:9]-,:[#7:3](-,:[#1:8])-[#6:4]=[S:5]	1319	0	0	0	0	0	0	0	\N
1320	[#1:6]-,:[#6:2]=[#6:1](-[#1,#6:3])-[#8:4]-[#6:5]	7	Reaction pattern	9	0	[#1:6]-,:[#6:2]=[#6:1](-[#1,#6:3])-[#8:4]-[#6:5]	1320	0	0	0	0	0	0	0	\N
1321	[#8,#17,#35:7]-[#6:5]=[O:6]	6	Reaction pattern	9	0	[#8,#17,#35:7]-[#6:5]=[O:6]	1321	0	0	0	0	0	0	0	\N
1322	[C:1]-,:[C:3]	7	Reaction pattern	9	0	[C:1]-,:[C:3]	1322	0	0	0	0	0	0	0	\N
1324	[#6:1]=C=[#6:2]	7	Reaction pattern	9	0	[#6:1]=C=[#6:2]	1324	0	0	0	0	0	0	0	\N
1325	[#1:9]-,:[#8:8]-[#6:2](-[#6:1])=[O:3]	6	Reaction pattern	9	0	[#1:9]-,:[#8:8]-[#6:2](-[#6:1])=[O:3]	1325	0	0	0	0	0	0	0	\N
1326	[#1:4]-,:[#7:1](-,:[#1:5])-[c:2]	6	Reaction pattern	9	0	[#1:4]-,:[#7:1](-,:[#1:5])-[c:2]	1326	0	0	0	0	0	0	0	\N
1327	[#6,#7,#8,#9,#16,#17,#35,#53;-:3]	6	Reaction pattern	9	0	[#6,#7,#8,#9,#16,#17,#35,#53;-:3]	1327	0	0	0	0	0	0	0	\N
1328	[#1:6]-,:[#8:3]-[#6:2]	7	Reaction pattern	9	0	[#1:6]-,:[#8:3]-[#6:2]	1328	0	0	0	0	0	0	0	\N
1329	[c:1]-,:S(-,:[#8])(=O)=O	7	Reaction pattern	9	0	[c:1]-,:S(-,:[#8])(=O)=O	1329	0	0	0	0	0	0	0	\N
1330	[#6]-,:[C:1]#[C:2]-,:[#1,#6:3]	7	Reaction pattern	9	0	[#6]-,:[C:1]#[C:2]-,:[#1,#6:3]	1330	0	0	0	0	0	0	0	\N
1331	[#6:3]-[c:1]	6	Reaction pattern	9	0	[#6:3]-[c:1]	1331	0	0	0	0	0	0	0	\N
1333	[C:1]-,:[#1:2]	6	Reaction pattern	9	0	[C:1]-,:[#1:2]	1333	0	0	0	0	0	0	0	\N
1334	[#6:4]1-[#6:5]-[#8:6]-[#6:1]-[#8:3]-1	7	Reaction pattern	9	0	[#6:4]1-[#6:5]-[#8:6]-[#6:1]-[#8:3]-1	1334	0	0	0	0	0	0	0	\N
1335	[#1:3]-,:[#8]-[#6:1]-[#6:2]-[#8]-,:[#1:4]	7	Reaction pattern	9	0	[#1:3]-,:[#8]-[#6:1]-[#6:2]-[#8]-,:[#1:4]	1335	0	0	0	0	0	0	0	\N
1348	[#7,#8:5]-[#6:3](=[O:4])-[#6:2]-[#6:1]=[O:6]	6	Reaction pattern	9	0	[#7,#8:5]-[#6:3](=[O:4])-[#6:2]-[#6:1]=[O:6]	1348	0	0	0	0	0	0	0	\N
1336	[#1:3]-,:[#8:2]-[#6:1](-,:[C:4]#[C:5]-,:[#1,#6,#14:6])-[#6:7]1=[#6]-[#6]=[#6]-[#6]=[#6]-1	6	Reaction pattern	9	0	[#1:3]-,:[#8:2]-[#6:1](-,:[C:4]#[C:5]-,:[#1,#6,#14:6])-[#6:7]1=[#6]-[#6]=[#6]-[#6]=[#6]-1	1336	0	0	0	0	0	0	0	\N
1337	[#7,#9,#17,#35,#53]-[F,Cl,Br,I:5]	6	Reaction pattern	9	0	[#7,#9,#17,#35,#53]-[F,Cl,Br,I:5]	1337	0	0	0	0	0	0	0	\N
1338	[#6:2]1-[#6:3]-[#8:4]-1	6	Reaction pattern	9	0	[#6:2]1-[#6:3]-[#8:4]-1	1338	0	0	0	0	0	0	0	\N
1339	[#7:4]=[C:5]=[S:6]	6	Reaction pattern	9	0	[#7:4]=[C:5]=[S:6]	1339	0	0	0	0	0	0	0	\N
1341	[#6:8]-[#8:7]-[#6:5](=[O:6])-[#6:4](-,:[C:9])-[#6:2](-[#6:1])=[O:3]	7	Reaction pattern	9	0	[#6:8]-[#8:7]-[#6:5](=[O:6])-[#6:4](-,:[C:9])-[#6:2](-[#6:1])=[O:3]	1341	0	0	0	0	0	0	0	\N
1342	[#1:6]-,:[n:5]1:,-[c:4]:,-[n:3]:,-[c:2]:,-[c:1]:,-1-[#1,#6:9]	7	Reaction pattern	9	0	[#1:6]-,:[n:5]1:,-[c:4]:,-[n:3]:,-[c:2]:,-[c:1]:,-1-[#1,#6:9]	1342	0	0	0	0	0	0	0	\N
1343	[#1:5]-,:[#6:2]-[#6:1]-[#8:3]-,:[#1:4]	6	Reaction pattern	9	0	[#1:5]-,:[#6:2]-[#6:1]-[#8:3]-,:[#1:4]	1343	0	0	0	0	0	0	0	\N
1344	[#1:8]-,:[#7&v3:7]-,:[#1:9]	6	Reaction pattern	9	0	[#1:8]-,:[#7&v3:7]-,:[#1:9]	1344	0	0	0	0	0	0	0	\N
1345	[#1,#6:13]-[#6:12]=[O:14]	6	Reaction pattern	9	0	[#1,#6:13]-[#6:12]=[O:14]	1345	0	0	0	0	0	0	0	\N
1346	[#1:2]-,:[#7:1](-[#6,#1:3])-[#6:4](-,:[Cl:6])=[O:5]	6	Reaction pattern	9	0	[#1:2]-,:[#7:1](-[#6,#1:3])-[#6:4](-,:[Cl:6])=[O:5]	1346	0	0	0	0	0	0	0	\N
1347	[#1:11]-,:[#8:10]-[c:2]1:,-[c:3]:,-[c:4]:,-[c:5]:,-[c:6]:,-[c:1]:,-1-[#6:7](=[O:8])-,:[C:9](-,:[#1:18])(-,:[#1:19])-,:[#1:20]	6	Reaction pattern	9	0	[#1:11]-,:[#8:10]-[c:2]1:,-[c:3]:,-[c:4]:,-[c:5]:,-[c:6]:,-[c:1]:,-1-[#6:7](=[O:8])-,:[C:9](-,:[#1:18])(-,:[#1:19])-,:[#1:20]	1347	0	0	0	0	0	0	0	\N
1349	[#1,#6:10]-[c:2]1:,-[n:1]:,-[c:15]2:,-[c:14]:,-[c:13]:,-[c:12]:,-[c:11]:,-[c:4]:,-2:,-[c:3]:,-1-[#1,#6:9]	7	Reaction pattern	9	0	[#1,#6:10]-[c:2]2:,-[n:1]:,-[c:15]1:,-[c:14]:,-[c:13]:,-[c:12]:,-[c:11]:,-[c:4]:,-1:,-[c:3]:,-2-[#1,#6:9]	1349	0	0	0	0	0	0	0	\N
1351	[#1:2]-,:[c:1]1:,-[c:6](-[#1,#6:11]):,-[c:7](-[#1,#6:12]):,-[c:8](!@&-[#1,#6:13]):,-[c:9](-[#1,#6:14]):,-[c:10]:,-1-[#1,#6:15]	6	Reaction pattern	9	0	[#1:2]-,:[c:1]1:,-[c:6](-[#1,#6:11]):,-[c:7](-[#1,#6:12]):,-[c:8](!@&-[#1,#6:13]):,-[c:9](-[#1,#6:14]):,-[c:10]:,-1-[#1,#6:15]	1351	0	0	0	0	0	0	0	\N
1352	[#6:5]-[#8:6]-[#6:1](-[#1,#6:8])=[O:2]	7	Reaction pattern	9	0	[#6:5]-[#8:6]-[#6:1](-[#1,#6:8])=[O:2]	1352	0	0	0	0	0	0	0	\N
1353	[#1,#6:13]-[c:2]1:,-[n:3]:,-[c:4]:,-[c:5]:,-[n:6]:,-[c:1]:,-1-[#1,#6:14]	7	Reaction pattern	9	0	[#1,#6:13]-[c:2]1:,-[n:3]:,-[c:4]:,-[c:5]:,-[n:6]:,-[c:1]:,-1-[#1,#6:14]	1353	0	0	0	0	0	0	0	\N
1354	[#6:5]-[#6:1](-,:[Cl:6])=[O:2]	7	Reaction pattern	9	0	[#6:5]-[#6:1](-,:[Cl:6])=[O:2]	1354	0	0	0	0	0	0	0	\N
1355	[c:1]-,:[#1:2]	6	Reaction pattern	9	0	[c:1]-,:[#1:2]	1355	0	0	0	0	0	0	0	\N
1356	[O:6]=[#6:5]1-[#6:9]~[#6:10]-[#6:1](=[O:2])-[#8:3]-1	7	Reaction pattern	9	0	[O:6]=[#6:5]1-[#6:9]~[#6:10]-[#6:1](=[O:2])-[#8:3]-1	1356	0	0	0	0	0	0	0	\N
1357	[#1:3]-,:[C:2](-,:[c:1])(-,:[#1,#6])-,:[#1,#6]	6	Reaction pattern	9	0	[#1:3]-,:[C:2](-,:[c:1])(-,:[#1,#6])-,:[#1,#6]	1357	0	0	0	0	0	0	0	\N
1358	[#6,#8:1]!@&-[#6:2](=O)-[#6:3]~[#6:4]-[#6:5](-[#6,#8:6])=O	6	Reaction pattern	9	0	[#6,#8:1]!@&-[#6:2](=O)-[#6:3]~[#6:4]-[#6:5](-[#6,#8:6])=O	1358	0	0	0	0	0	0	0	\N
1359	[#6&h1](-[#6,#7,#15,#16])=[#6]	6	Reaction pattern	9	0	[#6&h1](-[#6,#7,#15,#16])=[#6]	1359	0	0	0	0	0	0	0	\N
1360	C-,:[O&D1]	7	Reaction pattern	9	0	C-,:[O&D1]	alcohol	0	0	0	0	0	0	0	\N
1361	[#1:11]-,:[#16:4]-[c:3]:[c:2]-[#7:1](-,:[#1:10])-,:[#1:9]	6	Reaction pattern	9	0	[#1:11]-,:[#16:4]-[c:3]:[c:2]-[#7:1](-,:[#1:10])-,:[#1:9]	1361	0	0	0	0	0	0	0	\N
1362	[#1:10]-,:[#8:9]-,:[S:4](=[O:8])(=[O:7])-,:[#8:2]-[#6:1]	6	Reaction pattern	9	0	[#1:10]-,:[#8:9]-,:[S:4](=[O:8])(=[O:7])-,:[#8:2]-[#6:1]	1362	0	0	0	0	0	0	0	\N
1363	[#6:5]-,:[#7:4]=[#6:2](-,:[#7:1]-[$(*)])-[#7:3]-[$(*)]	7	Reaction pattern	9	0	[#6:5]-,:[#7:4]=[#6:2](-,:[#7:1]-[$([#1,*])])-[#7:3]-[$([#1,*])]	1363	0	0	0	0	0	0	0	\N
1364	[#6:2]-[#6:1]=[#6:3]	7	Reaction pattern	9	0	[#6:2]-[#6:1]=[#6:3]	1364	0	0	0	0	0	0	0	\N
1365	[O:10]=[#6:2]1-[#6:3]=[#6:4]-[#6:5](=[O:9])-[#6:6]=[#6:7]-1	7	Reaction pattern	9	0	[O:10]=[#6:2]1-[#6:3]=[#6:4]-[#6:5](=[O:9])-[#6:6]=[#6:7]-1	1365	0	0	0	0	0	0	0	\N
1366	[c:1]-[c:2]	7	Reaction pattern	9	0	[c:1]-[c:2]	1366	0	0	0	0	0	0	0	\N
1367	[c:2]-,:[N&+:1]#[N:3]	7	Reaction pattern	9	0	[c:2]-,:[N&+:1]#[N:3]	1367	0	0	0	0	0	0	0	\N
1368	[#1:11]-,:[#7:1](-,:[#1:10])-[c:8]1:,-[c:7]:,-[c:6]:,-[c:5]:,-[c:4]:,-[c:9]:,-1-[#7:3](-,:[#1:12])-,:[#1:13]	6	Reaction pattern	9	0	[#1:11]-,:[#7:1](-,:[#1:10])-[c:8]1:,-[c:7]:,-[c:6]:,-[c:5]:,-[c:4]:,-[c:9]:,-1-[#7:3](-,:[#1:12])-,:[#1:13]	1368	0	0	0	0	0	0	0	\N
1369	[#1:7]-,:[#8:3]-[#6:4]	7	Reaction pattern	9	0	[#1:7]-,:[#8:3]-[#6:4]	1369	0	0	0	0	0	0	0	\N
1370	[#1:3]-,:[#8:2]-[#6:1](-[#1,#6:5])-[#1,#6:4]	6	Reaction pattern	9	0	[#1:3]-,:[#8:2]-[#6:1](-[#1,#6:5])-[#1,#6:4]	1370	0	0	0	0	0	0	0	\N
1371	[#6:2]-[#7&X3:1]	7	Reaction pattern	9	0	[#6:2]-[#7&X3:1]	1371	0	0	0	0	0	0	0	\N
1373	[#6:5]-,:[S:1](-,:[#7,#8,#17:6])(=[O:3])=[O:4]	6	Reaction pattern	9	0	[#6:5]-,:[S:1](-,:[#7,#8,#17:6])(=[O:3])=[O:4]	1373	0	0	0	0	0	0	0	\N
1374	[#1:5]-,:[#8:2]-,:[C:1](-,:[#1:6])(-,:[#6:3])-,:[#1,#6:4]	6	Reaction pattern	9	0	[#1:5]-,:[#8:2]-,:[C:1](-,:[#1:6])(-,:[#6:3])-,:[#1,#6:4]	1374	0	0	0	0	0	0	0	\N
1375	[#1:5]-,:[#6:2](-[#1,#6:1])-[#6:3]-[F,Cl,Br,I:4]	7	Reaction pattern	9	0	[#1:5]-,:[#6:2](-[#1,#6:1])-[#6:3]-[F,Cl,Br,I:4]	1375	0	0	0	0	0	0	0	\N
1376	[#7:7]-[c:1]1:,-[c:6]:,-[c:5]:,-[c:4]:,-[c:3]:,-[c:2]:,-1-[#1,#7,#8:8]	6	Reaction pattern	9	0	[#7:7]-[c:1]1:,-[c:6]:,-[c:5]:,-[c:4]:,-[c:3]:,-[c:2]:,-1-[#1,#7,#8:8]	1376	0	0	0	0	0	0	0	\N
1377	[#6:1]-[#6:2](=[O:3])-[#7:4](-[#1,#6:6])-[#1,#6:5]	7	Reaction pattern	9	0	[#6:1]-[#6:2](=[O:3])-[#7:4](-[#1,#6:6])-[#1,#6:5]	1377	0	0	0	0	0	0	0	\N
1378	[#8&-:3]	6	Reaction pattern	9	0	[#8&-:3]	1378	0	0	0	0	0	0	0	\N
1379	[#1:9]-,:[#6:2](-[#6:1])-[#6:3](=[O:4])-[#8:5]-[#6:6]	6	Reaction pattern	9	0	[#1:9]-,:[#6:2](-[#6:1])-[#6:3](=[O:4])-[#8:5]-[#6:6]	1379	0	0	0	0	0	0	0	\N
1380	[#6:3]1=,:[#6:2]-[#6:1]-[#6:6]-[#6:5]-[#6:4]-1	7	Reaction pattern	9	0	[#6:3]1=,:[#6:2]-[#6:1]-[#6:6]-[#6:5]-[#6:4]-1	1380	0	0	0	0	0	0	0	\N
1381	[#1:4]-,:[#8:3]-[#6:1](-[#1,#6:7])=[O:2]	6	Reaction pattern	9	0	[#1:4]-,:[#8:3]-[#6:1](-[#1,#6:7])=[O:2]	1381	0	0	0	0	0	0	0	\N
1382	[#1:5]-,:[#6:3](=[O:4])-[c:1]1:,-[c:6](-[#1,#6:11]):,-[c:7](-[#1,#6:12]):,-[c:8](!@&-[#1,#6:13]):,-[c:9](-[#1,#6:14]):,-[c:10]:,-1-[#1,#6:15]	7	Reaction pattern	9	0	[#1:5]-,:[#6:3](=[O:4])-[c:1]1:,-[c:6](-[#1,#6:11]):,-[c:7](-[#1,#6:12]):,-[c:8](!@&-[#1,#6:13]):,-[c:9](-[#1,#6:14]):,-[c:10]:,-1-[#1,#6:15]	1382	0	0	0	0	0	0	0	\N
1383	[#6:7]-[#6:6]1=[#7:2]-[#6:1](-[#6:3])=[#7:4]-[#7:5]-1	7	Reaction pattern	9	0	[#6:7]-[#6:6]1=[#7:2]-[#6:1](-[#6:3])=[#7:4]-[#7:5]-1	1383	0	0	0	0	0	0	0	\N
1385	[c:3]-[#8:1]-[#6:4]=[O:5]	7	Reaction pattern	9	0	[c:3]-[#8:1]-[#6:4]=[O:5]	1385	0	0	0	0	0	0	0	\N
1387	[#1,#6]-[#6:2]=[#6:1]	6	Reaction pattern	9	0	[#1,#6]-[#6:2]=[#6:1]	1387	0	0	0	0	0	0	0	\N
1388	[#8&-:7]-[#7&+:6](=[O:8])-,:[C:2](-,:[Br:5])(-,:[#1,#6:4])-,:[#1,#6:3]	7	Reaction pattern	9	0	[#8&-:7]-[#7&+:6](=[O:8])-,:[C:2](-,:[Br:5])(-,:[#1,#6:4])-,:[#1,#6:3]	1388	0	0	0	0	0	0	0	\N
1389	[#1:6]-,:[#8:2]-,:[C:1](-,:[#1:5])(-,:[#6:4])-,:[#6:3]	6	Reaction pattern	9	0	[#1:6]-,:[#8:2]-,:[C:1](-,:[#1:5])(-,:[#6:4])-,:[#6:3]	1389	0	0	0	0	0	0	0	\N
1390	[#1:8]-,:[c:1]1:,-c:,-c:,-[c:3](-[#7:5]-[#7:6]-[c:4]2:,-c:,-c:,-[c:2](-,:[#1:7]):,-c:,-c:,-2):,-c:,-c:,-1	6	Reaction pattern	9	0	[#1:8]-,:[c:1]2:,-c:,-c:,-[c:3](-[#7:5]-[#7:6]-[c:4]1:,-c:,-c:,-[c:2](-,:[#1:7]):,-c:,-c:,-1):,-c:,-c:,-2	1390	0	0	0	0	0	0	0	\N
1391	[#6:4]-[#8:3]-[#6:1](-[#6:5])=[O:2]	6	Reaction pattern	9	0	[#6:4]-[#8:3]-[#6:1](-[#6:5])=[O:2]	1391	0	0	0	0	0	0	0	\N
1392	[#7:4]-[#6:1]=[O:2]	7	Reaction pattern	9	0	[#7:4]-[#6:1]=[O:2]	1392	0	0	0	0	0	0	0	\N
1393	[#1:3]-,:[C:1]#[C:2]-,:[#1,#6:4]	6	Reaction pattern	9	0	[#1:3]-,:[C:1]#[C:2]-,:[#1,#6:4]	1393	0	0	0	0	0	0	0	\N
1394	[#1:7]-,:[n:4]1:,-[n:5]:,-[n:6]:,-[n:2]:,-[c:1]:,-1-[#6:3]	7	Reaction pattern	9	0	[#1:7]-,:[n:4]1:,-[n:5]:,-[n:6]:,-[n:2]:,-[c:1]:,-1-[#6:3]	1394	0	0	0	0	0	0	0	\N
1395	[#7,#8:7]1-[#6:3]=[#6:2]-[#6:1]=[#7:6]-1	7	Reaction pattern	9	0	[#7,#8:7]1-[#6:3]=[#6:2]-[#6:1]=[#7:6]-1	1395	0	0	0	0	0	0	0	\N
1396	[#9,#17,#35,#53:3]-[#6:1]-[#6:2]-[#9,#17,#35,#53:4]	7	Reaction pattern	9	0	[#9,#17,#35,#53:3]-[#6:1]-[#6:2]-[#9,#17,#35,#53:4]	1396	0	0	0	0	0	0	0	\N
1397	[#1:4]-,:[#8:1]-,:[C:2](-,:[#1:3])(-,:[#1,#6:5])-,:[#1,#6:6]	6	Reaction pattern	9	0	[#1:4]-,:[#8:1]-,:[C:2](-,:[#1:3])(-,:[#1,#6:5])-,:[#1,#6:6]	1397	0	0	0	0	0	0	0	\N
1398	[O&D1]-[#6]-[#6]-[O&D1]	7	Reaction pattern	9	0	[O&D1]-[#6]-[#6]-[O&D1]	gem-diol	0	0	0	0	0	0	0	\N
1399	[#6:12]-[#6:9](-[#8,#9,#17:11])=[O:10]	6	Reaction pattern	9	0	[#6:12]-[#6:9](-[#8,#9,#17:11])=[O:10]	1399	0	0	0	0	0	0	0	\N
1400	[#6:5]-[c:1]1:,-[n:16]:,-[c:10](-[#6:14]):,-[c:11](-[#6:12]=[O:13]):,-[c:7]:,-[c:2]:,-1-[#6:3]=[O:4]	7	Reaction pattern	9	0	[#6:5]-[c:1]1:,-[n:16]:,-[c:10](-[#6:14]):,-[c:11](-[#6:12]=[O:13]):,-[c:7]:,-[c:2]:,-1-[#6:3]=[O:4]	1400	0	0	0	0	0	0	0	\N
1401	[#1:5]-,:[#7:1](-,:[#1:4])-[c:2]	6	Reaction pattern	9	0	[#1:5]-,:[#7:1](-,:[#1:4])-[c:2]	1401	0	0	0	0	0	0	0	\N
1402	[c:1]-[#9,#17,#35,#53:3]	6	Reaction pattern	9	0	[c:1]-[#9,#17,#35,#53:3]	1402	0	0	0	0	0	0	0	\N
1403	[#1:5]-,:[#8:4]-[#6:1](=[O:3])-,:[C:2](-,:[#6:8])(-,:[#6:9])-,:[#8:6]-,:[#1:7]	7	Reaction pattern	9	0	[#1:5]-,:[#8:4]-[#6:1](=[O:3])-,:[C:2](-,:[#6:8])(-,:[#6:9])-,:[#8:6]-,:[#1:7]	1403	0	0	0	0	0	0	0	\N
1404	[#6:6]=[#6:5]	6	Reaction pattern	9	0	[#6:6]=[#6:5]	1404	0	0	0	0	0	0	0	\N
1405	c1:,-c:,-n:,-n:,-n:,-1-[#6]	6	Reaction pattern	9	0	c1:,-c:,-n:,-n:,-n:,-1-[#6]	1,2,3-triazole	0	0	0	0	0	0	0	\N
1422	[#6:9]-,:[#7:4](-,:[#6,#7:5])-[#6:2](-,:[#7:3]-[$(*)])=[#7:1]-[$(*)]	7	Reaction pattern	9	0	[#6:9]-,:[#7:4](-,:[#6,#7:5])-[#6:2](-,:[#7:3]-[$([#1,*])])=[#7:1]-[$([#1,*])]	1422	0	0	0	0	0	0	0	\N
1408	[#1,#6:13]-[#6:12]1-[#7:1]-[#6:2]-[#6:3]-[c:4]2:,-[c:5]:,-[c:6]:,-[c:7]:,-[c:8]:,-[c:9]:,-2-1	7	Reaction pattern	9	0	[#1,#6:13]-[#6:12]2-[#7:1]-[#6:2]-[#6:3]-[c:4]1:,-[c:5]:,-[c:6]:,-[c:7]:,-[c:8]:,-[c:9]:,-1-2	1408	0	0	0	0	0	0	0	\N
1409	[#17,#35,#53:4]-[#6:2]-[#6,#15]=O	6	Reaction pattern	9	0	[#17,#35,#53:4]-[#6:2]-[#6,#15]=O	1409	0	0	0	0	0	0	0	\N
1410	[#6:1]-[#6:2](=[O:3])-[#7:4](-[#1,#6:7])-[#1,#6:6]	6	Reaction pattern	9	0	[#6:1]-[#6:2](=[O:3])-[#7:4](-[#1,#6:7])-[#1,#6:6]	1410	0	0	0	0	0	0	0	\N
1412	[#6:8]-[#8:6]-[#6:1]=[O:2]	7	Reaction pattern	9	0	[#6:8]-[#8:6]-[#6:1]=[O:2]	1412	0	0	0	0	0	0	0	\N
1413	[C:1]-,:[#9,#17,#35,#53:5]	6	Reaction pattern	9	0	[C:1]-,:[#9,#17,#35,#53:5]	1413	0	0	0	0	0	0	0	\N
1414	[#1,#6:15]-[#6:2](-[#1,#6:16])=[O:14]	6	Reaction pattern	9	0	[#1,#6:15]-[#6:2](-[#1,#6:16])=[O:14]	1414	0	0	0	0	0	0	0	\N
1415	[#1,#6,#11,#14,#19:5]-,:[C:3]#[N:4]	6	Reaction pattern	9	0	[#1,#6,#11,#14,#19:5]-,:[C:3]#[N:4]	1415	0	0	0	0	0	0	0	\N
1416	[#6:12]1-[#6:11]-[#6:1]2-[#6:2]=[#6:3]-[#6:4]-1-[c:5]1:,-[c:10]:,-[c:9]:,-[c:8]:,-[c:7]:,-[c:6]:,-1-2	7	Reaction pattern	9	0	[#6:12]1-[#6:11]-[#6:1]3-[#6:2]=[#6:3]-[#6:4]-1-[c:5]2:,-[c:10]:,-[c:9]:,-[c:8]:,-[c:7]:,-[c:6]:,-2-3	1416	0	0	0	0	0	0	0	\N
1417	[#6:1]=[O:3]	6	Reaction pattern	9	0	[#6:1]=[O:3]	1417	0	0	0	0	0	0	0	\N
1418	[#1:11]-,:[#7:4](-,:[#1:10])-[#7:5](-,:[#1:9])-[#6:6](-[#6:7])=[O:8]	6	Reaction pattern	9	0	[#1:11]-,:[#7:4](-,:[#1:10])-[#7:5](-,:[#1:9])-[#6:6](-[#6:7])=[O:8]	1418	0	0	0	0	0	0	0	\N
1421	[#1:4]-,:[#7:3](-,:[#1:5])-[#6:2](-[#6:1])=[O:6]	7	Reaction pattern	9	0	[#1:4]-,:[#7:3](-,:[#1:5])-[#6:2](-[#6:1])=[O:6]	1421	0	0	0	0	0	0	0	\N
1508	[#8:5]-[#6:1](-[#1,#6:3])=[O:6]	7	Reaction pattern	9	0	[#8:5]-[#6:1](-[#1,#6:3])=[O:6]	1508	0	0	0	0	0	0	0	\N
1423	[#1:6]-,:[#7:3]=[#6:4]-,:[#7:5](-,:[#1:11])-,:[#1:10]	6	Reaction pattern	9	0	[#1:6]-,:[#7:3]=[#6:4]-,:[#7:5](-,:[#1:11])-,:[#1:10]	1423	0	0	0	0	0	0	0	\N
1424	[#6:4]-[#7:1]=[C:2]=[#8,#16:3]	6	Reaction pattern	9	0	[#6:4]-[#7:1]=[C:2]=[#8,#16:3]	1424	0	0	0	0	0	0	0	\N
1426	[#1:5]-,:[#7,#8:1]-[c:10]1:,-[c:9]:,-[c:8]:,-[c:7]:,-[c:6]:,-[c:4]:,-1-[#6:2]=[O:3]	7	Reaction pattern	9	0	[#1:5]-,:[#7,#8:1]-[c:10]1:,-[c:9]:,-[c:8]:,-[c:7]:,-[c:6]:,-[c:4]:,-1-[#6:2]=[O:3]	1426	0	0	0	0	0	0	0	\N
1427	[O:6]=[#6:5]1-[#6:4]~[#6:3]-[#6:1](=[O:2])-[#8:7]-1	7	Reaction pattern	9	0	[O:6]=[#6:5]1-[#6:4]~[#6:3]-[#6:1](=[O:2])-[#8:7]-1	1427	0	0	0	0	0	0	0	\N
1428	[#17,#35:9]-[#6:8]-[#6:7](-[#1,#6:11])=[O:10]	6	Reaction pattern	9	0	[#17,#35:9]-[#6:8]-[#6:7](-[#1,#6:11])=[O:10]	1428	0	0	0	0	0	0	0	\N
1430	[O:10]=[#6:2]1-[#6:3]=[#6:4]-[#6:5]=[#6:6]-[#6:1]-1=[O:9]	7	Reaction pattern	9	0	[O:10]=[#6:2]1-[#6:3]=[#6:4]-[#6:5]=[#6:6]-[#6:1]-1=[O:9]	1430	0	0	0	0	0	0	0	\N
1431	[Cl:8]-,:[#6:6](=[O:7])-[#8:2]-[#6:1](-[#1,#6:4])-[#1,#6:5]	7	Reaction pattern	9	0	[Cl:8]-,:[#6:6](=[O:7])-[#8:2]-[#6:1](-[#1,#6:4])-[#1,#6:5]	1431	0	0	0	0	0	0	0	\N
1433	[S:6]=[#6:5]1-[#7:1]-[#6:2]=[#6:3]-[#7:4]-1	7	Reaction pattern	9	0	[S:6]=[#6:5]1-[#7:1]-[#6:2]=[#6:3]-[#7:4]-1	1433	0	0	0	0	0	0	0	\N
1434	[Cl:5]-,:[#6:3]-[#6:1]=[O:2]	7	Reaction pattern	9	0	[Cl:5]-,:[#6:3]-[#6:1]=[O:2]	1434	0	0	0	0	0	0	0	\N
1435	[#7&X3:1]-,:[#1:4]	6	Reaction pattern	9	0	[#7&X3:1]-,:[#1:4]	1435	0	0	0	0	0	0	0	\N
1436	[#6:1]-[#7,#8,#16:2]	7	Reaction pattern	9	0	[#6:1]-[#7,#8,#16:2]	1436	0	0	0	0	0	0	0	\N
1437	[C:1]-,:[#8:3]	7	Reaction pattern	9	0	[C:1]-,:[#8:3]	1437	0	0	0	0	0	0	0	\N
1452	[#1]-,:[#8]-[#6:1](-[#1,#6:3])=O	7	Reaction pattern	9	0	[#1]-,:[#8]-[#6:1](-[#1,#6:3])=O	1452	0	0	0	0	0	0	0	\N
1438	[#1:14]-,:[#6:4]1=[#7:5]-[#7:6](-[#1,#6:7])-[#6:1](=[O:8])-[c:2]2:,-c:,-c:,-c:,-c:,-[c:3]:,-2-1	7	Reaction pattern	9	0	[#1:14]-,:[#6:4]2=[#7:5]-[#7:6](-[#1,#6:7])-[#6:1](=[O:8])-[c:2]1:,-c:,-c:,-c:,-c:,-[c:3]:,-1-2	1438	0	0	0	0	0	0	0	\N
1439	[#1,#6:5]-[#6:2](-[#1,#6:6])=[O:1]	7	Reaction pattern	9	0	[#1,#6:5]-[#6:2](-[#1,#6:6])=[O:1]	1439	0	0	0	0	0	0	0	\N
1440	[#6:2]-[#7:1]-[#6:5](-[#6:9])=[O:6]	7	Reaction pattern	9	0	[#6:2]-[#7:1]-[#6:5](-[#6:9])=[O:6]	1440	0	0	0	0	0	0	0	\N
1441	[#1:4]-,:[#6:3]-[#6:1](=[O:2])-[#8,#16:5]-[#6:6]	6	Reaction pattern	9	0	[#1:4]-,:[#6:3]-[#6:1](=[O:2])-[#8,#16:5]-[#6:6]	1441	0	0	0	0	0	0	0	\N
1442	[c:1]-[#7&+:2](-[#8])=O	6	Reaction pattern	9	0	[c:1]-[#7&+:2](-[#8])=O	1442	0	0	0	0	0	0	0	\N
1443	Cl-,:[#6:2](-,:Cl)-,:Cl	6	Reaction pattern	9	0	[Cl]-,:[#6:2](-,:[Cl])-,:[Cl]	1443	0	0	0	0	0	0	0	\N
1444	[#1:5]-,:[#6:2]-[#6:1](-,:[#1:3])-,:[Br:4]	7	Reaction pattern	9	0	[#1:5]-,:[#6:2]-[#6:1](-,:[#1:3])-,:[Br:4]	1444	0	0	0	0	0	0	0	\N
1445	[#1,#6,#14:6]-[#6:5]-[#6:4]1=[#6:1](-[#7:8]=[#6:9]-[#8:10]-1)-[#6:7]1=[#6]-[#6]=[#6]-[#6]=[#6]-1	7	Reaction pattern	9	0	[#1,#6,#14:6]-[#6:5]-[#6:4]1=[#6:1](-[#7:8]=[#6:9]-[#8:10]-1)-[#6:7]2=[#6]-[#6]=[#6]-[#6]=[#6]-2	1445	0	0	0	0	0	0	0	\N
1446	[#1,#6:10]-[c:2]1:,-[c:1]:,-[s:5]:,-[c:4]:,-[n:3]:,-1	7	Reaction pattern	9	0	[#1,#6:10]-[c:2]1:,-[c:1]:,-[s:5]:,-[c:4]:,-[n:3]:,-1	1446	0	0	0	0	0	0	0	\N
1447	[#1:4]-,:[#8:3]-[#6:1]=[O:2]	7	Reaction pattern	9	0	[#1:4]-,:[#8:3]-[#6:1]=[O:2]	1447	0	0	0	0	0	0	0	\N
1450	[#6:2]-[#7:1](-[#6:3])-[#6:4]	6	Reaction pattern	9	0	[#6:2]-[#7:1](-[#6:3])-[#6:4]	1450	0	0	0	0	0	0	0	\N
1557	[#7&X3:1]-,:[#1:5]	6	Reaction pattern	9	0	[#7&X3:1]-,:[#1:5]	1557	0	0	0	0	0	0	0	\N
1453	[#6]-c1:,-c:,-c:,-c(-,:c:,-c:,-1)-,:S(=O)(=O)-,:[#8]-[#6:1]-[#6:2]-[#8]-,:S(=O)(=O)-,:c1:,-c:,-c:,-c(-[#6]):,-c:,-c:,-1	7	Reaction pattern	9	0	[#6]-c1:,-c:,-c:,-c(-,:c:,-c:,-1)-,:S(=O)(=O)-,:[#8]-[#6:1]-[#6:2]-[#8]-,:S(=O)(=O)-,:c2:,-c:,-c:,-c(-[#6]):,-c:,-c:,-2	1453	0	0	0	0	0	0	0	\N
1454	[#1:3]-,:[#8:2]-,:[C:1]	6	Reaction pattern	9	0	[#1:3]-,:[#8:2]-,:[C:1]	1454	0	0	0	0	0	0	0	\N
1455	[#8:5]-[#6:3](=[O:4])-[c:2]1:,-[c:7]:,-[c:8]:,-[o:6]:,-[c:1]:,-1	7	Reaction pattern	9	0	[#8:5]-[#6:3](=[O:4])-[c:2]1:,-[c:7]:,-[c:8]:,-[o:6]:,-[c:1]:,-1	1455	0	0	0	0	0	0	0	\N
1456	[#1:4]-,:[#8:3]-,:[C:1](-,:[#1,#6:6])(-,:[#1,#6:7])-,:[#8:2]-,:[#1:5]	7	Reaction pattern	9	0	[#1:4]-,:[#8:3]-,:[C:1](-,:[#1,#6:6])(-,:[#1,#6:7])-,:[#8:2]-,:[#1:5]	1456	0	0	0	0	0	0	0	\N
1457	[O&D1]-c1:,-c:,-c:,-c:,-c:,-c:,-1	6	Reaction pattern	9	0	[O&D1]-c1:,-c:,-c:,-c:,-c:,-c:,-1	phenol	0	0	0	0	0	0	0	\N
1458	[c:1]-[#9,#17,#35,#53:2]	6	Reaction pattern	9	0	[c:1]-[#9,#17,#35,#53:2]	1458	0	0	0	0	0	0	0	\N
1460	[#7,#8,#16:5]-,:[#1:6]	6	Reaction pattern	9	0	[#7,#8,#16:5]-,:[#1:6]	1460	0	0	0	0	0	0	0	\N
1461	[#1:10]-,:[#8:6]-,:[C:5](-,:[#6:9])(-,:[#1,#6:8])-,:[#6:3]-[#6:1](-[#6:7])=[O:2]	7	Reaction pattern	9	0	[#1:10]-,:[#8:6]-,:[C:5](-,:[#6:9])(-,:[#1,#6:8])-,:[#6:3]-[#6:1](-[#6:7])=[O:2]	1461	0	0	0	0	0	0	0	\N
1462	[#6:8]-[#6:6](=[O:7])-[c:5]1:,-[c:4]:,-[c:3]:,-[c:2]-,:[#7,#8,#16;a:1]-,:1	7	Reaction pattern	9	0	[#6:8]-[#6:6](=[O:7])-[c:5]1:,-[c:4]:,-[c:3]:,-[c:2]-,:[#7,#8,#16;a:1]-,:1	1462	0	0	0	0	0	0	0	\N
1463	[c:1]-[#6,#16:2]=[#8,#16]	6	Reaction pattern	9	0	[c:1]-[#6,#16:2]=[#8,#16]	1463	0	0	0	0	0	0	0	\N
1464	[#1:5]-,:[#8:2]-[#6:3]	6	Reaction pattern	9	0	[#1:5]-,:[#8:2]-[#6:3]	1464	0	0	0	0	0	0	0	\N
1506	[#6:3]-[#6:1](-[#1,#6:4])=[O:2]	7	Reaction pattern	9	0	[#6:3]-[#6:1](-[#1,#6:4])=[O:2]	1506	0	0	0	0	0	0	0	\N
1465	[#1:5]-,:[#7:1](-,:[#1:6])-[#6:2](-[#6,#1:16])-[#6:3](-[#6,#1:17])=[O:4]	6	Reaction pattern	9	0	[#1:5]-,:[#7:1](-,:[#1:6])-[#6:2](-[#6,#1:16])-[#6:3](-[#6,#1:17])=[O:4]	1465	0	0	0	0	0	0	0	\N
1466	[#7&X3:1]	6	Reaction pattern	9	0	[#7&X3:1]	1466	0	0	0	0	0	0	0	\N
1467	[#1:7]-,:[#6:5]=[O:6]	6	Reaction pattern	9	0	[#1:7]-,:[#6:5]=[O:6]	1467	0	0	0	0	0	0	0	\N
1469	C1-,:C-,:C-,:[#7&X3:1]-,:[C:3]-,:1	7	Reaction pattern	9	0	C1-,:C-,:C-,:[#7&X3:1]-,:[C:3]-,:1	1469	0	0	0	0	0	0	0	\N
1470	[#1:5]-,:[#8:4]-,:[#1:6]	7	Reaction pattern	9	0	[#1:5]-,:[#8:4]-,:[#1:6]	1470	0	0	0	0	0	0	0	\N
1471	[#6:1]1-[#6:6]-[#6:5]-[#6:4]-[#6:3]-[#6:2]-1	7	Reaction pattern	9	0	[#6:1]1-[#6:6]-[#6:5]-[#6:4]-[#6:3]-[#6:2]-1	1471	0	0	0	0	0	0	0	\N
1472	[#6]-[#6:2]=[#6:1]-[#6:3]	7	Reaction pattern	9	0	[#6]-[#6:2]=[#6:1]-[#6:3]	1472	0	0	0	0	0	0	0	\N
1473	[#8&-:7]-[#7&+:6](=[O:8])-[c:5]1:,-[c:4]:,-[c:3]:,-[c:2]-,:[#7,#8,#16;a:1]-,:1	7	Reaction pattern	9	0	[#8&-:7]-[#7&+:6](=[O:8])-[c:5]1:,-[c:4]:,-[c:3]:,-[c:2]-,:[#7,#8,#16;a:1]-,:1	1473	0	0	0	0	0	0	0	\N
1474	[#1:4]-,:[#6:2]=[O:3]	6	Reaction pattern	9	0	[#1:4]-,:[#6:2]=[O:3]	1474	0	0	0	0	0	0	0	\N
1475	[#6:8]-[#6:1](=[O:3])-[#6:2](-[#6:9])=[O:6]	6	Reaction pattern	9	0	[#6:8]-[#6:1](=[O:3])-[#6:2](-[#6:9])=[O:6]	1475	0	0	0	0	0	0	0	\N
1476	[#1:4]-,:[#6:1]-[#8:2]-,:[#1:3]	6	Reaction pattern	9	0	[#1:4]-,:[#6:1]-[#8:2]-,:[#1:3]	1476	0	0	0	0	0	0	0	\N
1477	[#7:5]-[#6:1](-[#1,#6:7])=[O:2]	7	Reaction pattern	9	0	[#7:5]-[#6:1](-[#1,#6:7])=[O:2]	1477	0	0	0	0	0	0	0	\N
1478	[c:3]-[#7&+:4](-[#8])=O	6	Reaction pattern	9	0	[c:3]-[#7&+:4](-[#8])=O	1478	0	0	0	0	0	0	0	\N
1480	[#1:7]-,:[#8:8]-[#6:5]-[#6:1](=[O:2])-[#8:3]-,:[#1:4]	7	Reaction pattern	9	0	[#1:7]-,:[#8:8]-[#6:5]-[#6:1](=[O:2])-[#8:3]-,:[#1:4]	1480	0	0	0	0	0	0	0	\N
1481	[#1:10]-,:[#8:9]-[#6:7](=[O:8])-[#6:6]!@&-[#6:5]-,:[#6:4]!@&-[#6:3]-[#6:1](=[O:2])-[#8:11]-,:[#1:12]	6	Reaction pattern	9	0	[#1:10]-,:[#8:9]-[#6:7](=[O:8])-[#6:6]!@&-[#6:5]-,:[#6:4]!@&-[#6:3]-[#6:1](=[O:2])-[#8:11]-,:[#1:12]	1481	0	0	0	0	0	0	0	\N
1483	[#1,#6:6]-[#6:1](-[#1,#6:7])=[O:2]	6	Reaction pattern	9	0	[#1,#6:6]-[#6:1](-[#1,#6:7])=[O:2]	1483	0	0	0	0	0	0	0	\N
1484	[I:5]-,:[#6:3]-[#6:1]=[O:2]	7	Reaction pattern	9	0	[I:5]-,:[#6:3]-[#6:1]=[O:2]	1484	0	0	0	0	0	0	0	\N
1485	[#1:5]-,:[#8:2]-[#6:1](-[#6:3])-[#1,#6:4]	7	Reaction pattern	9	0	[#1:5]-,:[#8:2]-[#6:1](-[#6:3])-[#1,#6:4]	1485	0	0	0	0	0	0	0	\N
1487	[#1:10]-,:[#6:1](-[#17,#35:6])-[#6:2](-[#1,#6:10])=[O:7]	6	Reaction pattern	9	0	[#1:10]-,:[#6:1](-[#17,#35:6])-[#6:2](-[#1,#6:10])=[O:7]	1487	0	0	0	0	0	0	0	\N
1488	[#1:6]-,:[#8:2]-,:[C:1](-,:[#1:5])(-,:[#1:4])-,:[#6:3]	7	Reaction pattern	9	0	[#1:6]-,:[#8:2]-,:[C:1](-,:[#1:5])(-,:[#1:4])-,:[#6:3]	1488	0	0	0	0	0	0	0	\N
1489	[#1:11]-,:[#6:4](-[#6:2](-[#6:1])=[O:3])-[#6:5](=[O:6])-[#8:7]-[#6:8]	6	Reaction pattern	9	0	[#1:11]-,:[#6:4](-[#6:2](-[#6:1])=[O:3])-[#6:5](=[O:6])-[#8:7]-[#6:8]	1489	0	0	0	0	0	0	0	\N
1490	[#1:4]-,:[#6:1]=[#6:2]-[C:3]#N	7	Reaction pattern	9	0	[#1:4]-,:[#6:1]=[#6:2]-[C:3]#N	1490	0	0	0	0	0	0	0	\N
1491	[#6]-[#6:1](-[#1,#6:3])=[#6:2](-[#3,#17,#35,#53:4])-[#1,#3,#17,#35,#53:5]	6	Reaction pattern	9	0	[#6]-[#6:1](-[#1,#6:3])=[#6:2](-[#3,#17,#35,#53:4])-[#1,#3,#17,#35,#53:5]	1491	0	0	0	0	0	0	0	\N
1492	[#1:6]-,:[#8:5]-,:[C:4](-,:[#6:1])(-,:[#1,#6:7])-,:[#1,#6:8]	7	Reaction pattern	9	0	[#1:6]-,:[#8:5]-,:[C:4](-,:[#6:1])(-,:[#1,#6:7])-,:[#1,#6:8]	1492	0	0	0	0	0	0	0	\N
1493	[C:1]-,:[#9,#17,#35,#53:2]	6	Reaction pattern	9	0	[C:1]-,:[#9,#17,#35,#53:2]	1493	0	0	0	0	0	0	0	\N
1494	[#1:10]-,:[#8:9]-[#6:1](=[O:2])-[#6:3]~[#6:4]-[#6:5](=[O:6])-[#8:7]-,:[#1:8]	6	Reaction pattern	9	0	[#1:10]-,:[#8:9]-[#6:1](=[O:2])-[#6:3]~[#6:4]-[#6:5](=[O:6])-[#8:7]-,:[#1:8]	1494	0	0	0	0	0	0	0	\N
1495	[#1:5]-,:[#6:1](-[#6:6])=[O:2]	7	Reaction pattern	9	0	[#1:5]-,:[#6:1](-[#6:6])=[O:2]	1495	0	0	0	0	0	0	0	\N
1496	[#1:10]-,:[#7:6]-[c:4]1:,-c:,-c:,-[c:2](-,:c:,-c:,-1)-[c:1]1:,-c:,-c:,-[c:3](-[#7:5]-,:[#1:9]):,-c:,-c:,-1	7	Reaction pattern	9	0	[#1:10]-,:[#7:6]-[c:4]1:,-c:,-c:,-[c:2](-,:c:,-c:,-1)-[c:1]2:,-c:,-c:,-[c:3](-[#7:5]-,:[#1:9]):,-c:,-c:,-2	1496	0	0	0	0	0	0	0	\N
1497	[#1:6]-,:[#8:3]-[c:2]	7	Reaction pattern	9	0	[#1:6]-,:[#8:3]-[c:2]	1497	0	0	0	0	0	0	0	\N
1498	[#1:5]-,:[#8:6]-[#6:3]	6	Reaction pattern	9	0	[#1:5]-,:[#8:6]-[#6:3]	1498	0	0	0	0	0	0	0	\N
1499	[C:1]-,:N(=O)=O	7	Reaction pattern	9	0	[C:1]-,:N(=O)=O	1499	0	0	0	0	0	0	0	\N
1500	[#1,#6:8]-[#6:1](=[O:6])-[#6:2](-[#1,#6:9])=[O:7]	6	Reaction pattern	9	0	[#1,#6:8]-[#6:1](=[O:6])-[#6:2](-[#1,#6:9])=[O:7]	1500	0	0	0	0	0	0	0	\N
1501	[#7:1]	6	Reaction pattern	9	0	[#7:1]	1501	0	0	0	0	0	0	0	\N
1502	[#1,#14:6]-,:[C:3]#[C:4]	6	Reaction pattern	9	0	[#1,#14:6]-,:[C:3]#[C:4]	1502	0	0	0	0	0	0	0	\N
1503	[#6:12]-[c:9]1:,-[n:3]:,-[c:2](-[#6,#7:1]):,-[n:4]:,-[o:5]:,-1	7	Reaction pattern	9	0	[#6:12]-[c:9]1:,-[n:3]:,-[c:2](-[#6,#7:1]):,-[n:4]:,-[o:5]:,-1	1503	0	0	0	0	0	0	0	\N
1504	[#1:4]-,:[#6:1](-[#6:5])=[O:2]	7	Reaction pattern	9	0	[#1:4]-,:[#6:1](-[#6:5])=[O:2]	1504	0	0	0	0	0	0	0	\N
1505	[#6:8]-[#6:5](!@&-[#1,#8,#17,#35:7])=[O:6]	6	Reaction pattern	9	0	[#6:8]-[#6:5](!@&-[#1,#8,#17,#35:7])=[O:6]	1505	0	0	0	0	0	0	0	\N
1509	[#1:4]-,:[#7&X3:1]=[#6:2]	7	Reaction pattern	9	0	[#1:4]-,:[#7&X3:1]=[#6:2]	1509	0	0	0	0	0	0	0	\N
1510	[#6]-[#6:2]=[#6:1]	6	Reaction pattern	9	0	[#6]-[#6:2]=[#6:1]	1510	0	0	0	0	0	0	0	\N
1512	[#1:12]-,:[#7:6]1-[#6:5](-[#1,#6:11])=[#7:4]-[c:3]2:,-[c:10]:,-[c:9]:,-[c:8]:,-[c:7]:,-[c:2]:,-2-[#6:1]-1=[O:13]	6	Reaction pattern	9	0	[#1:12]-,:[#7:6]2-[#6:5](-[#1,#6:11])=[#7:4]-[c:3]1:,-[c:10]:,-[c:9]:,-[c:8]:,-[c:7]:,-[c:2]:,-1-[#6:1]-2=[O:13]	1512	0	0	0	0	0	0	0	\N
1513	[#1:6]-,:[#6:2]=[#6:1]	6	Reaction pattern	9	0	[#1:6]-,:[#6:2]=[#6:1]	1513	0	0	0	0	0	0	0	\N
1514	[#1:5]-,:[#8:3]-[#6:4]	6	Reaction pattern	9	0	[#1:5]-,:[#8:3]-[#6:4]	1514	0	0	0	0	0	0	0	\N
1516	[O:8]=[#6:7]-[#6:6]-[#16:5]-[#6:9]-[#6:10]=[O:11]	6	Reaction pattern	9	0	[O:8]=[#6:7]-[#6:6]-[#16:5]-[#6:9]-[#6:10]=[O:11]	1516	0	0	0	0	0	0	0	\N
1517	c1:,-n:,-n:,-n(-[#6]):,-c:,-1-[#6]	7	Reaction pattern	9	0	c1nnn(C)c1[#6]	1,2,3-triazole	0	0	0	0	0	0	0	\N
1518	[#8:3]-[#7]=O	6	Reaction pattern	9	0	[#8:3]-[#7]=O	1518	0	0	0	0	0	0	0	\N
1520	[c:2]1:,-[c:3]:,-[o:4]:,-[c:5]:,-[n:1]:,-1	7	Reaction pattern	9	0	[c:2]1:,-[c:3]:,-[o:4]:,-[c:5]:,-[n:1]:,-1	1520	0	0	0	0	0	0	0	\N
1521	[#6:3]-[#6:1]-[#1,#6:4]	7	Reaction pattern	9	0	[#6:3]-[#6:1]-[#1,#6:4]	1521	0	0	0	0	0	0	0	\N
1522	[#6:9]-[#6:5](-[#1,#6:8])=[O:6]	6	Reaction pattern	9	0	[#6:9]-[#6:5](-[#1,#6:8])=[O:6]	1522	0	0	0	0	0	0	0	\N
1523	[#1:4]-,:[#7:3](-,:[#1:5])-[c:1]	7	Reaction pattern	9	0	[#1:4]-,:[#7:3](-,:[#1:5])-[c:1]	1523	0	0	0	0	0	0	0	\N
1524	[#6:3]-[#8:2]-,:[C:1](-,:[#6:7])(-,:[#6:6])-,:[#6:8]	6	Reaction pattern	9	0	[#6:3]-[#8:2]-,:[C:1](-,:[#6:7])(-,:[#6:6])-,:[#6:8]	1524	0	0	0	0	0	0	0	\N
143	[C&X3]-,:[C&D2]=O	6	aldehyde-Csp2	0	1772715346	[CX3][CD2]=O	aldehyde-Csp2	27033	708	549	663	4	32194	0	1142
1526	[#6:7]-,:[C:1](-,:[#6:8])(-,:[#6:6])-,:[I:4]	7	Reaction pattern	9	0	[#6:7]-,:[C:1](-,:[#6:8])(-,:[#6:6])-,:[I:4]	1526	0	0	0	0	0	0	0	\N
1527	[#6:3]-[#6:1](=O)-[#6:2](-[#6:4])=O	7	Reaction pattern	9	0	[#6:3]-[#6:1](=O)-[#6:2](-[#6:4])=O	1527	0	0	0	0	0	0	0	\N
1528	[#1,#6:6]-[#6:2]=[O:5]	7	Reaction pattern	9	0	[#1,#6:6]-[#6:2]=[O:5]	1528	0	0	0	0	0	0	0	\N
1529	[#1:6]-,:[C:1](-,:[#1:5])(-,:[#6:3])-,:[#1,#6:4]	7	Reaction pattern	9	0	[#1:6]-,:[C:1](-,:[#1:5])(-,:[#6:3])-,:[#1,#6:4]	1529	0	0	0	0	0	0	0	\N
1530	[#6:1]-[#17,#35,#53:2]	6	Reaction pattern	9	0	[#6:1]-[#17,#35,#53:2]	1530	0	0	0	0	0	0	0	\N
1532	[#1:4]-,:[#8:3]-,:[#1:5]	6	Reaction pattern	9	0	[#1:4]-,:[#8:3]-,:[#1:5]	1532	0	0	0	0	0	0	0	\N
1533	[#1:4]-,:[#8:3]-[#6:1]=[O:2]	6	Reaction pattern	9	0	[#1:4]-,:[#8:3]-[#6:1]=[O:2]	1533	0	0	0	0	0	0	0	\N
1534	[#7&X3:1]-[#6:2]-[#6:3]-[#8:4]	7	Reaction pattern	9	0	[#7&X3:1]-[#6:2]-[#6:3]-[#8:4]	1534	0	0	0	0	0	0	0	\N
1535	[#1:19]-,:[C:9]1(-,:[#1:20])-,:[#6:7](=[O:8])-[c:1]2:,-[c:6]:,-[c:5]:,-[c:4]:,-[c:3]:,-[c:2]:,-2-[#8:10]-,:[C:12]-,:12-,:[#6:16]-[#6:15]-[#6,#7:14]-[#6:13]-,:2	7	Reaction pattern	9	0	[#1:19]-,:[C:9]2(-,:[#1:20])-,:[#6:7](=[O:8])-[c:1]1:,-[c:6]:,-[c:5]:,-[c:4]:,-[c:3]:,-[c:2]:,-1-[#8:10]-,:[C:12]-,:23-,:[#6:16]-[#6:15]-[#6,#7:14]-[#6:13]-,:3	1535	0	0	0	0	0	0	0	\N
1536	[#1:16]-,:[#6:5](-[#6:6](-[#1,#6:7])=[O:8])-[#6:4](-[#1,#6:10])=[O:9]	6	Reaction pattern	9	0	[#1:16]-,:[#6:5](-[#6:6](-[#1,#6:7])=[O:8])-[#6:4](-[#1,#6:10])=[O:9]	1536	0	0	0	0	0	0	0	\N
1537	[#6:5]-[#6:1](-,:[Cl:3])=[O:2]	6	Reaction pattern	9	0	[#6:5]-[#6:1](-,:[Cl:3])=[O:2]	1537	0	0	0	0	0	0	0	\N
1538	[C:2]-,:[#7:1](-[#6:3])-[#6:4]	6	Reaction pattern	9	0	[C:2]-,:[#7:1](-[#6:3])-[#6:4]	1538	0	0	0	0	0	0	0	\N
1539	[#1:13]-,:[#6:1](!@&-[#6:2]!@&-[#6:3]!@&-[#6:4]-[#6:5](=[O:6])-[#8:11]-[#6:12])-[#6:7](=[O:8])-[#8:9]-[#6:10]	6	Reaction pattern	9	0	[#1:13]-,:[#6:1](!@&-[#6:2]!@&-[#6:3]!@&-[#6:4]-[#6:5](=[O:6])-[#8:11]-[#6:12])-[#6:7](=[O:8])-[#8:9]-[#6:10]	1539	0	0	0	0	0	0	0	\N
1541	[#8&-]-[#7&+](=O)-,:[C:1]=[#6:2]	7	Reaction pattern	9	0	[#8&-]-[#7&+](=O)-,:[C:1]=[#6:2]	1541	0	0	0	0	0	0	0	\N
1542	[#1:5]-,:[#7,#8:3]-[#6:1]-[#6:2]-[#6,#15]=O	7	Reaction pattern	9	0	[#1:5]-,:[#7,#8:3]-[#6:1]-[#6:2]-[#6,#15]=O	1542	0	0	0	0	0	0	0	\N
1545	[#6:4]-[#9,#17,#35,#53:5]	6	Reaction pattern	9	0	[#6:4]-[#9,#17,#35,#53:5]	1545	0	0	0	0	0	0	0	\N
1546	[#6:4]-[#8:3]-[#6:1](-[#6:6])=[O:2]	6	Reaction pattern	9	0	[#6:4]-[#8:3]-[#6:1](-[#6:6])=[O:2]	1546	0	0	0	0	0	0	0	\N
1547	[#6:6]-[#6:1](=[O:4])-[#6:2]-[#6:3](-[#7,#8:7])=[O:5]	6	Reaction pattern	9	0	[#6:6]-[#6:1](=[O:4])-[#6:2]-[#6:3](-[#7,#8:7])=[O:5]	1547	0	0	0	0	0	0	0	\N
1549	[#1:1]-,:[C:2](-,:[#1,#6:3])(-,:[#1,#6:4])-,:[#7&+:6](-[#8&-:7])=[O:8]	6	Reaction pattern	9	0	[#1:1]-,:[C:2](-,:[#1,#6:3])(-,:[#1,#6:4])-,:[#7&+:6](-[#8&-:7])=[O:8]	1549	0	0	0	0	0	0	0	\N
1551	[#1:8]-,:[#8:1]-[c:2]1:,-[c:3]:,-[c:4]:,-[c:5]:,-[c:6]:,-[c:7]:,-1	6	Reaction pattern	9	0	[#1:8]-,:[#8:1]-[c:2]1:,-[c:3]:,-[c:4]:,-[c:5]:,-[c:6]:,-[c:7]:,-1	1551	0	0	0	0	0	0	0	\N
1552	[#6:1]-[#1,#6:2]	7	Reaction pattern	9	0	[#6:1]-[#1,#6:2]	1552	0	0	0	0	0	0	0	\N
1553	[#1:11]-,:[#7:1](-,:[#1:12])-[c:2]1:,-[c:3]:,-[c:4]:,-[c:5](-[#1,#7,#8:8]):,-[c:6]:,-[c:7]:,-1	6	Reaction pattern	9	0	[#1:11]-,:[#7:1](-,:[#1:12])-[c:2]1:,-[c:3]:,-[c:4]:,-[c:5](-[#1,#7,#8:8]):,-[c:6]:,-[c:7]:,-1	1553	0	0	0	0	0	0	0	\N
1555	[#6:6]-[#6:1]1=[#6:2](-[#7:8]=[#6:9]-[#8:4]-1)-[#6:3](-[#7,#8:7])=[O:5]	7	Reaction pattern	9	0	[#6:6]-[#6:1]1=[#6:2](-[#7:8]=[#6:9]-[#8:4]-1)-[#6:3](-[#7,#8:7])=[O:5]	1555	0	0	0	0	0	0	0	\N
1556	[#6:2]-[#7:1]=[N&+:3]=[#7&-:4]	6	Reaction pattern	9	0	[#6:2]-[#7:1]=[N&+:3]=[#7&-:4]	1556	0	0	0	0	0	0	0	\N
1558	[#6:6]-[#8,#16:5]-[#6:1](=[O:2])-[#6:3]-[#6:7]=[O:8]	7	Reaction pattern	9	0	[#6:6]-[#8,#16:5]-[#6:1](=[O:2])-[#6:3]-[#6:7]=[O:8]	1558	0	0	0	0	0	0	0	\N
1559	[#1:11]-,:[#7:1](-,:[#1:10])-[#6:2]-[#6:3]-[c:4]1:,-[c:9]:,-[c:8]:,-[c:7]:,-[c:6]:,-[c:5]:,-1	6	Reaction pattern	9	0	[#1:11]-,:[#7:1](-,:[#1:10])-[#6:2]-[#6:3]-[c:4]1:,-[c:9]:,-[c:8]:,-[c:7]:,-[c:6]:,-[c:5]:,-1	1559	0	0	0	0	0	0	0	\N
1560	[#6:1]=,:[#6:2]-,:[C:3]#[C:4]	7	Reaction pattern	9	0	[#6:1]=,:[#6:2]-,:[C:3]#[C:4]	1560	0	0	0	0	0	0	0	\N
1561	[#6,#14:7]-[#7:6]=[N&+:5]=[#7&-:4]	6	Reaction pattern	9	0	[#6,#14:7]-[#7:6]=[N&+:5]=[#7&-:4]	1561	0	0	0	0	0	0	0	\N
1562	[#1,#6:3]-[#7:1]=[C:5]=[O:6]	7	Reaction pattern	9	0	[#1,#6:3]-[#7:1]=[C:5]=[O:6]	1562	0	0	0	0	0	0	0	\N
1564	[#1:4]-,:[#8:2]-,:[C:1](-,:[#1:3])(-,:[#1,#6:6])-,:[#1,#6:5]	6	Reaction pattern	9	0	[#1:4]-,:[#8:2]-,:[C:1](-,:[#1:3])(-,:[#1,#6:6])-,:[#1,#6:5]	1564	0	0	0	0	0	0	0	\N
1565	[#6:1]-[#6:2](-[#6:4])=[O:3]	7	Reaction pattern	9	0	[#6:1]-[#6:2](-[#6:4])=[O:3]	1565	0	0	0	0	0	0	0	\N
1566	[#6:1]-,:[#12:2]-,:[#9,#17,#35,#53:7]	6	Reaction pattern	9	0	[#6:1]-,:[#12:2]-,:[#9,#17,#35,#53:7]	1566	0	0	0	0	0	0	0	\N
1567	C-,:[#6:1](-,:C)=O	7	Reaction pattern	9	0	C-,:[#6:1](-,:C)=O	1567	0	0	0	0	0	0	0	\N
1568	[#1:4]-,:[#8:3]-[#6:1](=[O:5])-[#6:2]-,:[Cl:7]	7	Reaction pattern	9	0	[#1:4]-,:[#8:3]-[#6:1](=[O:5])-[#6:2]-,:[Cl:7]	1568	0	0	0	0	0	0	0	\N
1569	[#1,#6:6]-[#6:1](-[#1,#6:5])=[O:2]	7	Reaction pattern	9	0	[#1,#6:6]-[#6:1](-[#1,#6:5])=[O:2]	1569	0	0	0	0	0	0	0	\N
1570	[$(*)]-[#7:1]=[C:2]=[#7:3]-[$(*)]	6	Reaction pattern	9	0	[$([#1,*])]-[#7:1]=[C:2]=[#7:3]-[$([#1,*])]	1570	0	0	0	0	0	0	0	\N
1571	[#1:5]-,:[#8:2]-[#6:1]-[#6:7]	6	Reaction pattern	9	0	[#1:5]-,:[#8:2]-[#6:1]-[#6:7]	1571	0	0	0	0	0	0	0	\N
1572	[#1:5]-,:[#8:4]-,:[C:3]-,:[C:2]#[C:1]-,:[#1,#6:4]	6	Reaction pattern	9	0	[#1:5]-,:[#8:4]-,:[C:3]-,:[C:2]#[C:1]-,:[#1,#6:4]	1572	0	0	0	0	0	0	0	\N
1573	[#7:1]-[#6:2]-[#6:3]=[O:7]	6	Reaction pattern	9	0	[#7:1]-[#6:2]-[#6:3]=[O:7]	1573	0	0	0	0	0	0	0	\N
1574	[*:3]-,:[#6:1](-*)=[#6:2](-*)-[*:4]	6	Reaction pattern	9	0	[*,#1:3]-,:[#6:1](-[*,#1])=[#6:2](-[*,#1])-[*,#1:4]	1574	0	0	0	0	0	0	0	\N
1575	[#6:7]-[#9,#17,#35,#53:9]	6	Reaction pattern	9	0	[#6:7]-[#9,#17,#35,#53:9]	1575	0	0	0	0	0	0	0	\N
1576	[#6:4]-[#7:2](-[#1,#6:1])-,:[C:5]#[N:6]	7	Reaction pattern	9	0	[#6:4]-[#7:2](-[#1,#6:1])-,:[C:5]#[N:6]	1576	0	0	0	0	0	0	0	\N
1577	[#6:3]=[#7,#8:4]	6	Reaction pattern	9	0	[#6:3]=[#7,#8:4]	1577	0	0	0	0	0	0	0	\N
1578	[#6:3]1-[#6:2]-[#7:1]-1	7	Reaction pattern	9	0	[#6:3]1-[#6:2]-[#7:1]-1	1578	0	0	0	0	0	0	0	\N
1580	[#1:5]-,:[#6:3](-[c:1])=[O:4]	7	Reaction pattern	9	0	[#1:5]-,:[#6:3](-[c:1])=[O:4]	1580	0	0	0	0	0	0	0	\N
1581	[#6:3]-,:[C:2]#[C:1]-,:[#1,#6,#7:8]	6	Reaction pattern	9	0	[#6:3]-,:[C:2]#[C:1]-,:[#1,#6,#7:8]	1581	0	0	0	0	0	0	0	\N
1582	[#1:9]-,:[#8:8]-[#6:6](=[O:7])-[#6:5]-[#6:1](=[O:2])-[#8:3]-,:[#1:4]	6	Reaction pattern	9	0	[#1:9]-,:[#8:8]-[#6:6](=[O:7])-[#6:5]-[#6:1](=[O:2])-[#8:3]-,:[#1:4]	1582	0	0	0	0	0	0	0	\N
1584	[#6:6]-[#8:5]-[#6:3](=[O:4])-[#6:2](-[#6:1])-[#6:7]	7	Reaction pattern	9	0	[#6:6]-[#8:5]-[#6:3](=[O:4])-[#6:2](-[#6:1])-[#6:7]	1584	0	0	0	0	0	0	0	\N
1585	[#6:1]-[#6:2]	7	Reaction pattern	9	0	[#6:1]-[#6:2]	1585	0	0	0	0	0	0	0	\N
1586	[#1,#6:1]-[#6:2]=[#6:3]	6	Reaction pattern	9	0	[#1,#6:1]-[#6:2]=[#6:3]	1586	0	0	0	0	0	0	0	\N
1587	[#9,#17,#35,#53:4]-[#6:2]-[#6:1]-[#9,#17,#35,#53:3]	6	Reaction pattern	9	0	[#9,#17,#35,#53:4]-[#6:2]-[#6:1]-[#9,#17,#35,#53:3]	1587	0	0	0	0	0	0	0	\N
1588	[#1:14]-,:[#6:5](-[#6:15])=[O:8]	6	Reaction pattern	9	0	[#1:14]-,:[#6:5](-[#6:15])=[O:8]	1588	0	0	0	0	0	0	0	\N
1589	[#6:3]-[#6:1](-[#1,#6:4])=[O:2]	6	Reaction pattern	9	0	[#6:3]-[#6:1](-[#1,#6:4])=[O:2]	1589	0	0	0	0	0	0	0	\N
1590	[#8]-[#6:2]-[#6:1]-[#8]	7	Reaction pattern	9	0	[#8]-[#6:2]-[#6:1]-[#8]	1590	0	0	0	0	0	0	0	\N
1591	[#1]-,:[#7:3](-,:[#1])-[#6:2]-[#6:1]	7	Reaction pattern	9	0	[#1]-,:[#7:3](-,:[#1])-[#6:2]-[#6:1]	1591	0	0	0	0	0	0	0	\N
1592	[#1:6]-,:[#7:4](-,:[#1:5])-[#6:2](-[#6:1])=[O:3]	6	Reaction pattern	9	0	[#1:6]-,:[#7:4](-,:[#1:5])-[#6:2](-[#6:1])=[O:3]	1592	0	0	0	0	0	0	0	\N
2000	C-C(-N-C)-C	1	reductive-amination-product	0	0	C-[C&*](-N-C)-C	reductive-amination-product	0	0	0	0	0	0	0	0
2001	C(=O)-C-c	1	alpha arylation product	0	0	C(=O)-[C&*]-c	alpha-arylation-product	0	0	0	0	0	0	0	0
2002	C-N1-N=N-C(-C)=C-1	1	click-1-4-product	0	0	C-N1-N=N-C(-C)=C-1	click-1-4-product	0	0	0	0	0	0	0	0
175	[O&D1]-[c&r6]:[c&H1]	1	phenol bearing alpha proton	14	1600000000	[OD1]-[cr6]:[cH]	hartwig-2012	0	0	0	0	0	0	0	0
589	c1:c(:c:c:c:c:1)-[#6&!H0&!H1]-[#7&!H0]-c1:[c&!H0]:[c&!H0]:c(:[c&!H0]:[c&!H0]:1)-[#8&!H0]	2	anil_OH_alk_A(8)	8	1772735344	c:1:c(:c:c:c:c:1)-[#6](-[#1])(-[#1])-[#7](-[#1])-c:2:c(:c(:c(:c(:c:2-[#1])-[#1])-[#8]-[#1])-[#1])-[#1]	anil_oh_alk_a_8_	356	0	0	0	0	360	10	58
517	[#7]-[#6]=&!@[#6]1-[#6](=[#8])-c2:c:c:c:c:c:2-[!#6&!#1]-1	2	ene_five_het_E(44)	8	1772735344	[#7]-[#6]=!@[#6]-2-[#6](=[#8])-c:1:c:c:c:c:c:1-[!#6&!#1]-2	ene_five_het_e_44_	767	2	1	0	1	814	10	76
664	[#6]-[#16&X2]-c1:n:[c&!H0]:c:s:1	2	thiazol_SC_A(3)	8	1772687395	[#6]-[#16;X2]-c:1:n:c(:c:s:1)-[#1]	thiazol_sc_a_3_	20343	0	0	0	0	20573	10	39
27	N-,:P(=O)(-,:N)-,:N	1	phosphoramides	1	1772715346	N-,:P(=O)(-,:N)-,:N	phosphoramides	721	1	0	7	0	839	50	51
561	[#7&!H0&!H1]-[#6]1=[#6](-[#6]#[#7])-[#6&!H0](-[#6]:[#6])-[#6](=[#6](-[#6]=[#6])-[#8]-1)-[#6&!H0&!H1]	2	dhp_amino_CN_A(13)	8	1772735344	[#7](-[#1])(-[#1])-[#6]-1=[#6](-[#6]#[#7])-[#6](-[#1])(-[#6]:[#6])-[#6](=[#6](-[#6]=[#6])-[#8]-1)-[#6](-[#1])-[#1]	dhp_amino_cn_a_13_	464	0	0	0	0	490	10	99
486	[#6&!H0&!H1]-[#7](-[#6&!H0&!H1])-c1:c:[c&!H0]:c(:c(:c:1)-[$([#6&X4&H2]),$([#8]-[#6&X4&H2]-[#6&X4&H2])])-[#7]	2	anil_di_alk_A(478)	8	1772735344	[#6](-[#1])(-[#1])-[#7](-[#6](-[#1])-[#1])-c:1:c:c(:c(:[c;!H0,$(c-[#6](-[#1])-[#1]),$(c-[#8]-[#6](-[#1])(-[#1])-[#6](-[#1])-[#1])](:c:1))-[#7])-[#1]	anil_di_alk_a_478_	21294	0	0	0	1	21383	10	14
513	c1:c:c2:c(:c:c:1)-[#6]1-[#6](-[#6]-[#7]-2)-[#6]-[#6]=[#6]-1	2	anil_alk_ene(51)	8	1772735344	c:1:c:c-2:c(:c:c:1)-[#6]-3-[#6](-[#6]-[#7]-2)-[#6]-[#6]=[#6]-3	anil_alk_ene_51_	69413	24	0	0	0	71473	10	1642
711	[#8]=[#6]1-c2:c(:c:c:c:c:2)-[#6]2=[#6](-[#8&!H0])-[#6](=[#8])-[#7]-c3:c-2:c-1:c:c:c:3	2	quinone_C(2)	8	1772687395	[#8]=[#6]-3-c:1:c(:c:c:c:c:1)-[#6]-2=[#6](-[#8]-[#1])-[#6](=[#8])-[#7]-c:4:c-2:c-3:c:c:c:4	quinone_c_2_	0	0	0	0	0	0	10	0
671	[#7]1(-c2:c:c:c:c:c:2-[#6&!H0&!H1])-[#6](=[#16])-[#7](-[#6&!H0&!H1]-[!#1]:[!#1]:[!#1]:[!#1]:[!#1])-[#6&!H0&!H1]-[#6]-1=[#8]	2	rhod_sat_B(3)	8	1772687395	[#7]-2(-c:1:c:c:c:c:c:1-[#6](-[#1])-[#1])-[#6](=[#16])-[#7](-[#6](-[#1])(-[#1])-[!#1]:[!#1]:[!#1]:[!#1]:[!#1])-[#6](-[#1])(-[#1])-[#6]-2=[#8]	rhod_sat_b_3_	18	0	0	0	0	18	10	0
655	c1(:c(:[c&!H0]:[c&!H0]:s:1)-[$([#1]),$([#6](-[#1])-[#1])])-[#6&!H0]=[#7]-[#7&!H0]-c1:c:c:c:c:c:1	2	hzone_thiophene_B(4)	8	1772687395	c:1(:[c;!H0,$(c-[#6;!H0;!H1])](:c(:c(:s:1)-[#1])-[#1]))-[#6](-[#1])=[#7]-[#7](-[#1])-c:2:c:c:c:c:c:2	hzone_thiophene_b_4_	0	0	0	0	0	0	10	0
721	[#6](-[#7](-[#6&!H0])-[#6&!H0]):[#6]-[#7&!H0]-[#6](=[#16])-[#6&!H0]	2	thio_amide_D(2)	8	1772687395	[#6](-[#7](-[#6]-[#1])-[#6]-[#1]):[#6]-[#7](-[#1])-[#6](=[#16])-[#6]-[#1]	thio_amide_d_2_	11	0	0	0	0	11	10	4
638	c1:c(:c2:c(:c:c:1):c:c:c:c:2)-[#8]-c1:[c&!H0]:[c&!H0]:c(:[c&!H0]:[c&!H0]:1)-[#7&!H0]	2	anil_OC_no_alk_B(4)	8	1772687395	c:1:c(:c:2:c(:c:c:1):c:c:c:c:2)-[#8]-c:3:c(:c(:c(:c(:c:3-[#1])-[#1])-[#7]-[#1])-[#1])-[#1]	anil_oc_no_alk_b_4_	238	0	0	0	0	241	10	14
626	[#8]=[#6]-[#6]=[#6&!H0]-[#8&!H0]	2	keto_keto_beta_D(5)	8	1772687395	[#8]=[#6]-[#6]=[#6](-[#1])-[#8]-[#1]	keto_keto_beta_d_5_	2692	3	2	2	0	2806	10	148
696	[#6](-[#6]#[#7])(-[#6]#[#7])=[#6](-[#16])-[#16]	2	ene_cyano_D(3)	8	1772687395	[#6](-[#6]#[#7])(-[#6]#[#7])=[#6](-[#16])-[#16]	ene_cyano_d_3_	39	0	0	0	0	47	10	11
622	c1:c(:c:c:c:c:1)-[#7]1-[#6&!H0]-[#6&!H0]-[#7](-[#6&!H0]-[#6&!H0]-1)-[#16](=[#8])(=[#8])-c1:c:c:c:c2:n:s:n:c:1:2	2	diazox_sulfon_B(5)	8	1772687395	c:1:c(:c:c:c:c:1)-[#7]-2-[#6](-[#1])-[#6](-[#1])-[#7](-[#6](-[#1])-[#6]-2-[#1])-[#16](=[#8])(=[#8])-c:3:c:c:c:c:4:n:s:n:c:3:4	diazox_sulfon_b_5_	100	0	0	0	0	100	10	3
656	[#6&!H0&!H1]-[#16&X2]-[#6]1=[#6](-[#6]#[#7])-[#6&!H0](-[#6]:[#6])-[#6](-[#6]#[#7])-[#6](=[#8])-[#7]-1	2	dhp_amino_CN_E(4)	8	1772687395	[#6](-[#1])(-[#1])-[#16;X2]-[#6]-1=[#6](-[#6]#[#7])-[#6](-[#1])(-[#6]:[#6])-[#6](-[#6]#[#7])-[#6](=[#8])-[#7]-1	dhp_amino_cn_e_4_	94	0	0	0	0	98	10	38
644	[c&!H0]1:[c&!H0]:[c&!H0]:c(:[c&!H0]:c:1-[#7&!H0]-[#6](=[#8])-c1:c:c:c:c:c:1)-[#7](-[#6&!H0&!H1])-[#6&!H0&!H1]	2	anil_di_alk_I(4)	8	1772687395	c:1(:c(:c(:c(:c(:c:1-[#7](-[#1])-[#6](=[#8])-c:2:c:c:c:c:c:2)-[#1])-[#7](-[#6](-[#1])-[#1])-[#6](-[#1])-[#1])-[#1])-[#1])-[#1]	anil_di_alk_i_4_	2764	0	0	0	0	2797	10	15
614	c1:c:c2:c(:c:c:1)-[#6](-c1:,-c:,-c:,-c:,-c3:,-n:,-o:,-c-2:,-c:,-1:,-3)=[#8]	2	quinone_B(5)	8	1772687395	c:1:c:c-2:c(:c:c:1)-[#6](-c3cccc4noc-2c34)=[#8]	quinone_b_5_	1339	0	0	0	0	1354	10	56
708	[#6&!H0]-[#7&!H0]-c1:n:c(:c:s:1)-c1:,-c:,-n:,-c2:,-n:,-1:,-c:,-c:,-s:,-2	2	thiazole_amine_F(2)	8	1772687395	[#6](-[#1])-[#7](-[#1])-c:1:n:c(:c:s:1)-c2cnc3n2ccs3	thiazole_amine_f_2_	3	0	0	0	0	3	10	0
716	[#6&!H0]-[#7&!H0]-c1:c(:[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:1)-[#7&!H0]-[#6&!H0]	2	anil_NH_alk_C(2)	8	1772687395	[#6](-[#1])-[#7](-[#1])-c:1:c(:c(:c(:c(:c:1-[#1])-[#1])-[#1])-[#1])-[#7](-[#1])-[#6]-[#1]	anil_nh_alk_c_2_	2249	0	0	0	0	2280	10	81
610	n1:,-c2:,-c:,-c:,-c:,-c:,-n:,-2:,-c(-,:c:,-1-[$([#6](-[!#1])=[#6](-[#1])-[#6]:[#6]),$([#6]:[#8]:[#6])])-[#7]-[#6]:[#6]	2	het_65_C(6)	8	1772687395	n2c1ccccn1c(c2-[$([#6](-[!#1])=[#6](-[#1])-[#6]:[#6]),$([#6]:[#8]:[#6])])-[#7]-[#6]:[#6]	het_65_c_6_	144	0	0	0	0	144	10	11
720	[#6]1=[#6]-[#7]-[#6](-[#16]-[#6&X4]-1)=[#16]	2	thio_carbam_ene(2)	8	1772687395	[#6]-1=[#6]-[#7]-[#6](-[#16]-[#6;X4]-1)=[#16]	thio_carbam_ene_2_	22	0	0	0	0	22	10	1
650	n1(-c2:[c&!H0]:c:c(:[c&!H0]:c:2)-[$([#7](-[#1])-[#1]),$([#6]:[#7])]):,-[c&!H0]-,:[c&!H0]:,-[c&!H0]-,:[c&!H0]:,-1	2	pyrrole_G(4)	8	1772687395	n2(-c:1:c(:c:c(:c(:c:1)-[#1])-[$([#7](-[#1])-[#1]),$([#6]:[#7])])-[#1])c(c(-[#1])c(c2-[#1])-[#1])-[#1]	pyrrole_g_4_	229	0	0	0	0	251	10	153
648	c12:c(:[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:1):o:c1:[c&!H0]:c(:c(-[#8]-[#6&!H0&!H1]):[c&!H0]:c:2:1)-[#7&!H0]-[#6&!H0&!H1]	2	anil_OC_alk_A(4)	8	1772687395	c:1:2:c(:c(:c(:c(:c:1-[#1])-[#1])-[#1])-[#1]):o:c:3:c(-[#1]):c(:c(-[#8]-[#6](-[#1])-[#1]):c(:c:2:3)-[#1])-[#7](-[#1])-[#6](-[#1])-[#1]	anil_oc_alk_a_4_	358	0	0	0	0	358	10	0
673	c1(:c(:c2:c(:s:1):c:c:c:c:2)-[#6&!H0&!H1])-[#6](=[#8])-[#6&!H0&!H1]-[#6&!H0&!H1]	2	keto_thiophene(3)	8	1772687395	c:1(:c(:c:2:c(:s:1):c:c:c:c:2)-[#6](-[#1])-[#1])-[#6](=[#8])-[#6](-[#1])(-[#1])-[#6](-[#1])-[#1]	keto_thiophene_3_	23	0	0	0	0	24	10	5
609	[c&!H0]1:[c&!H0]:[c&!H0]:c(:[c&!H0]:c:1-[#7&!H0]-[#16](=[#8])(=[#8])-[#6]1:[#6]:[!#1]:[#6]:[#6]:[#6]:1)-[#7](-[#6&!H0&!H1])-[#6&!H0&!H1]	2	anil_di_alk_H(6)	8	1772687395	c:1(:c(:c(:c(:c(:c:1-[#7](-[#1])-[#16](=[#8])(=[#8])-[#6]:2:[#6]:[!#1]:[#6]:[#6]:[#6]:2)-[#1])-[#7](-[#6](-[#1])-[#1])-[#6](-[#1])-[#1])-[#1])-[#1])-[#1]	anil_di_alk_h_6_	619	0	0	0	0	642	10	4
640	c1:c:c:c2:c(:c:c:c:2):c:c:1	2	azulene(4)	8	1772687395	c:2:c:c:c:1:c(:c:c:c:1):c:c:2	azulene_4_	9	0	0	0	0	9	10	0
629	c12:c(:c:c:c:c:1):c1:n:n:c(-[#16]-[#6&!H0&!H1]-[#6]=[#8]):n:c:1:n:2-[#6&!H0&!H1]-[#6&!H0]=[#6&!H0&!H1]	2	het_thio_656a(5)	8	1772687395	c:1:3:c(:c:c:c:c:1):c:2:n:n:c(-[#16]-[#6](-[#1])(-[#1])-[#6]=[#8]):n:c:2:n:3-[#6](-[#1])(-[#1])-[#6](-[#1])=[#6](-[#1])-[#1]	het_thio_656a_5_	124	0	0	0	0	124	10	52
620	c1:,-c:,-n2:,-c(-,:n:,-c(-,:c:,-2-[#7]-[#6])-c2:c:c:c:c:n:2):,-c:,-c:,-1	2	het_65_Db(5)	8	1772687395	c3cn1c(nc(c1-[#7]-[#6])-c:2:c:c:c:c:n:2)cc3	het_65_db_5_	335	0	0	0	0	343	10	2
662	[!#1]1:[!#1]:[!#1]:[!#1](:[!#1]:[!#1]:1)-[#6&!H0]=[#6&!H0]-[#6](-[#7]-c1:c:c:c2:c(:c:1):c:c:c(:n:2)-[#7](-[#6])-[#6])=[#8]	2	ene_one_A(3)	8	1772687395	[!#1]:1:[!#1]:[!#1]:[!#1](:[!#1]:[!#1]:1)-[#6](-[#1])=[#6](-[#1])-[#6](-[#7]-c:2:c:c:c:3:c(:c:2):c:c:c(:n:3)-[#7](-[#6])-[#6])=[#8]	ene_one_a_3_	170	0	0	0	0	191	10	0
611	[#6]1-[#7&!H0]-[#7&!H0]-[#6](=[#16])-[#7]-[#7&!H0]-1	2	thio_urea_F(6)	8	1772687395	[#6]-1-[#7](-[#1])-[#7](-[#1])-[#6](=[#16])-[#7]-[#7]-1-[#1]	thio_urea_f_6_	57	0	0	0	0	57	10	10
710	[#6](-[#16])(-[#7])=[#6&!H0]-[#6]=[#6&!H0]-[#6]=[#8]	2	ene_one_B(2)	8	1772687395	[#6](-[#16])(-[#7])=[#6](-[#1])-[#6]=[#6](-[#1])-[#6]=[#8]	ene_one_b_2_	13	0	0	0	0	13	10	3
5	C=C-[C&D2]=O	1	propenaldehydes	1	1772715346	C=C-[CD2]=O	propenaldehydes	23543	706	543	657	4	28611	50	953
714	[#7]1(-[#6](=[#8])-c2:c(:[c&!H0]:[c&!H0]:c(:[c&!H0]:2)-[#6](=[#8])-[#8&!H0])-[#6]-1=[#8])-c1:[c&!H0]:c:c(:[c&!H0]:c:1)-[#8]	2	phthalimide_misc(2)	8	1772687395	[#7]-2(-[#6](=[#8])-c:1:c(:c(:c(:c(:c:1-[#1])-[#6](=[#8])-[#8]-[#1])-[#1])-[#1])-[#6]-2=[#8])-c:3:c(:c:c(:c(:c:3)-[#1])-[#8])-[#1]	phthalimide_misc_2_	69	0	0	0	0	80	10	27
612	c1(:c:c:c:o:1)-[#6&!H0]=&!@[#6]1-[#6](=[#8])-c2:c:c:c:c:c:2-[!#6&!#1]-1	2	ene_five_het_I(6)	8	1772687395	c:1(:c:c:c:o:1)-[#6](-[#1])=!@[#6]-3-[#6](=[#8])-c:2:c:c:c:c:c:2-[!#6&!#1]-3	ene_five_het_i_6_	995	0	0	0	0	1007	10	51
639	c1:c:c2:c(:c:c:1)-[#6]-[#16]-c1:,-c(-[#6]-2=[#6]):,-c:,-c:,-s:,-1	2	styrene_C(4)	8	1772687395	c:1:c:c-2:c(:c:c:1)-[#6]-[#16]-c3c(-[#6]-2=[#6])ccs3	styrene_c_4_	27	0	0	0	0	27	10	2
679	[#7&!H0](-[#6]1:[#6]:[#6]:[!#1]:[#6]:[#6]:1)-c1:c:c:c(:c:c:1)-[#7&!H0]-[#6&!H0]	2	anil_NH_alk_B(3)	8	1772687395	[#7](-[#1])(-[#6]:1:[#6]:[#6]:[!#1]:[#6]:[#6]:1)-c:2:c:c:c(:c:c:2)-[#7](-[#1])-[#6]-[#1]	anil_nh_alk_b_3_	941	0	0	0	0	1007	10	21
619	[#8]=[#6]1-[#6](=[#6]-[#6](=[#7]-[#7]-1)-[#6]=[#8])-[#6]#[#7]	2	cyano_pyridone_D(5)	8	1772687395	[#8]=[#6]-1-[#6](=[#6]-[#6](=[#7]-[#7]-1)-[#6]=[#8])-[#6]#[#7]	cyano_pyridone_d_5_	0	0	0	0	0	0	10	0
99	[#7]=[N&+]=[#7&-]	6	azide	1	1772715346	[#7]=[N&+]=[#7&-]	azide	75962	7	0	8	7	81772	0	3640
670	c12:c(:c:c:c:c:1)-[#6&!H0&!H1]-[#6&!H0&!H1]-[#7]=[#6]-2-[#16&X2]-[#6&!H0&!H1]-[#6](=[#8])-c1:c:c:c:c:c:1	2	het_thio_66_A(3)	8	1772687395	c:1-2:c(:c:c:c:c:1)-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#7]=[#6]-2-[#16;X2]-[#6](-[#1])(-[#1])-[#6](=[#8])-c:3:c:c:c:c:c:3	het_thio_66_a_3_	5	0	0	0	0	5	10	1
698	[#6]1=,:[#6]-[#6](-[#6](-[$([#8]),$([#16])]-1)=[#6]-[#6]=[#8])=[#8]	2	ene_five_het_M(3)	8	1772687395	[#6]-1=,:[#6]-[#6](-[#6](-[$([#8]),$([#16])]-1)=[#6]-[#6]=[#8])=[#8]	ene_five_het_m_3_	187	0	0	0	0	202	10	12
627	[#7]12-[#6](=[#7]-[#6](=[#8])-[#6](=[#7]-1)-[#6&!H0&!H1])-[#16]-[#6](=[#6&!H0]-[#6]:[#6])-[#6]-2=[#8]	2	ene_rhod_H(5)	8	1772687395	[#7]-1-2-[#6](=[#7]-[#6](=[#8])-[#6](=[#7]-1)-[#6](-[#1])-[#1])-[#16]-[#6](=[#6](-[#1])-[#6]:[#6])-[#6]-2=[#8]	ene_rhod_h_5_	0	0	0	0	0	0	10	0
605	[#7]1=[#6]-[#6](-[#6](-[#7]-1)=[#16])=[#6]	2	ene_five_het_H(6)	8	1772687395	[#7]-1=[#6]-[#6](-[#6](-[#7]-1)=[#16])=[#6]	ene_five_het_h_6_	166	0	0	0	0	169	10	4
645	[#6&!H0&!H1]-[#16&X2]-c1:n:n:c(:c(:n:1)-c1:[c&!H0]:[c&!H0]:[c&!H0]:o:1)-c1:[c&!H0]:[c&!H0]:[c&!H0]:o:1	2	het_thio_6_furan(4)	8	1772687395	[#6](-[#1])(-[#1])-[#16;X2]-c:1:n:n:c(:c(:n:1)-c:2:c(:c(:c(:o:2)-[#1])-[#1])-[#1])-c:3:c(:c(:c(:o:3)-[#1])-[#1])-[#1]	het_thio_6_furan_4_	152	0	0	0	0	162	10	28
678	c12:c(:n:c(:n:c:1-[#7&!H0]-[#6&!H0&!H1]-c1:[c&!H0]:[c&!H0]:[c&!H0]:o:1)-[#7&!H0]-c1:c:c(:c(:c:c:1-[$([#1]),$([#6](-[#1])-[#1]),$([#16&X2]),$([#8]-[#6]-[#1]),$([#7&X3])])-[$([#1]),$([#6](-[#1])-[#1]),$([#16&X2]),$([#8]-[#6]-[#1]),$([#7&X3])])-[$([#1]),$([#6](-[#1])-[#1]),$([#16&X2]),$([#8]-[#6]-[#1]),$([#7&X3])]):c:c:c:c:2	2	melamine_A(3)	8	1772687395	c:1:4:c(:n:c(:n:c:1-[#7](-[#1])-[#6](-[#1])(-[#1])-c:2:c(:c(:c(:o:2)-[#1])-[#1])-[#1])-[#7](-[#1])-c:3:c:[c;!H0,$(c-[#6](-[#1])-[#1]),$(c-[#16;X2]),$(c-[#8]-[#6]-[#1]),$(c-[#7;X3])](:[c;!H0,$(c-[#6](-[#1])-[#1]),$(c-[#16;X2]),$(c-[#8]-[#6]-[#1]),$(c-[#7;X3])](:c:[c;!H0,$(c-[#6](-[#1])-[#1]),$(c-[#16;X2]),$(c-[#8]-[#6]-[#1]),$(c-[#7;X3])]:3))):c:c:c:c:4	melamine_a_3_	0	0	0	0	0	0	10	0
677	n1:c(:[c&!H0]:c(:c(:c:1-[#16]-[#6&!H0])-[#6]#[#7])-c1:c:c:c(:c:c:1)-[#8]-[#6&!H0&!H1])-[#6]:[#6]	2	het_thio_pyr_A(3)	8	1772687395	n:1:c(:c(:c(:c(:c:1-[#16]-[#6]-[#1])-[#6]#[#7])-c:2:c:c:c(:c:c:2)-[#8]-[#6](-[#1])-[#1])-[#1])-[#6]:[#6]	het_thio_pyr_a_3_	681	0	0	0	0	692	10	206
702	c1:c2:c(:c:c(:c:1)-[#6](=[#8])-[#7&!H0]-c1:c(:c:c:c:c:1)-[#6](=[#8])-[#8&!H0])-[#6](-[#7](-[#6]-2=[#8])-[#6&!H0&!H1])=[#8]	2	anthranil_acid_B(3)	8	1772687395	c:1:c-3:c(:c:c(:c:1)-[#6](=[#8])-[#7](-[#1])-c:2:c(:c:c:c:c:2)-[#6](=[#8])-[#8]-[#1])-[#6](-[#7](-[#6]-3=[#8])-[#6](-[#1])-[#1])=[#8]	anthranil_acid_b_3_	84	0	0	0	0	90	10	10
683	[#6&!H0&!H1]-[#16&X2]-c1:,-n:,-c2:,-c(-,:n(-,:n:,-c:,-2-[#6&!H0&!H1])-c2:c:c:c:c:c:2):,-n:,-n:,-1	2	het_thio_65_A(3)	8	1772687395	[#6](-[#1])(-[#1])-[#16;X2]-c3nc1c(n(nc1-[#6](-[#1])-[#1])-c:2:c:c:c:c:c:2)nn3	het_thio_65_a_3_	2	0	0	0	0	4	10	0
690	[#6]=[#7&!R]-c1:c:c:c:c:c:1-[#8&!H0]	2	imine_phenol_A(3)	8	1772687395	[#6]=[#7;!R]-c:1:c:c:c:c:c:1-[#8]-[#1]	imine_phenol_a_3_	3197	1	0	0	3	3781	10	265
607	[#6]=[#6](-[#6]#[#7])-[#6](=[#7&!H0])-[#7]-[#7]	2	ene_cyano_C(6)	8	1772687395	[#6]=[#6](-[#6]#[#7])-[#6](=[#7]-[#1])-[#7]-[#7]	ene_cyano_c_6_	2	0	0	0	0	2	10	0
633	c1(:[c&!H0]:c(:c(:[c&!H0]:c:1-[C&D2])-[#8]-[#6&!H0&!H1])-[#6&!H0&!H1]-[$([#7&D3]-[#6](=[#8])-[#6&X4]-[#6&X4]-[#6&X4]),$([#6&X4](-[#6&X4])-[#7&X3]-,:[#6](=[#16])-[#7&X3])])-[#8]-[#6&!H0&!H1]	2	anisol_A(5)	8	1772687395	c:1(:c(:c(:c(:c(:[c;!H0,$(c-[#6](-[#1])-[#1])]:1)-[#1])-[#8]-[#6](-[#1])-[#1])-[#6](-[#1])(-[#1])-[$([#7](-[#1])-[#6](=[#8])-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#6](-[#1])-[#1]),$([#6](-[#1])(-[#6](-[#1])-[#1])-[#7](-[#1])-[#6](=[#16])-[#7]-[#1])])-[#1])-[#8]-[#6](-[#1])-[#1]	anisol_a_5_	0	0	0	0	0	0	10	0
709	[#7]1-[#6](=[#8])-[#6&!H0]=[#6](-[#6])-[#16]-[#6]-1=[#16]	2	thio_ester_C(2)	8	1772687395	[#7]-1-[#6](=[#8])-[#6](=[#6](-[#6])-[#16]-[#6]-1=[#16])-[#1]	thio_ester_c_2_	0	0	0	0	0	0	10	0
692	[#7]=[#6]1-[#7]=[#6]-[#7]-[#16]-1	2	het_thio_N_5A(3)	8	1772687395	[#7]=[#6]-1-[#7]=[#6]-[#7]-[#16]-1	het_thio_n_5a_3_	0	0	0	0	0	0	10	0
658	[#6]:[#6]-[#6&!H0]=[#6&!H0]-[#6&!H0]=[#7]-[#7]=[#6]	2	imine_imine_B(3)	8	1772687395	[#6]:[#6]-[#6](-[#1])=[#6](-[#1])-[#6](-[#1])=[#7]-[#7]=[#6]	imine_imine_b_3_	470	0	0	0	0	547	10	15
682	[$([#1]),$([#6](-[#1])-[#1])]-[#8]-c1:c(:[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:1)-[#7&!H0]-[#6&!H0&!H1]-c1:n:c:c:n:1	2	anil_OC_alk_C(3)	8	1772687395	[#8;!H0,$([#8]-[#6](-[#1])-[#1])]-c:1:c(:c(:c(:c(:c:1-[#1])-[#1])-[#1])-[#1])-[#7](-[#1])-[#6](-[#1])(-[#1])-c:2:n:c:c:n:2	anil_oc_alk_c_3_	0	0	0	0	0	0	10	0
669	c12:c(:c:c:c:c:1)-[#7]1-[#6](=[#8])-[#6](=[#6](-[F,Cl,Br,I])-[#6]-1=[#8])-[#7&!H0]-[#6]:[#6]:[#6]:[#6](-[#8]-[#6&!H0&!H1]):[#6]:[#6]:2	2	anil_OC_alk_B(3)	8	1772687395	c:1:3:c(:c:c:c:c:1)-[#7]-2-[#6](=[#8])-[#6](=[#6](-[F,Cl,Br,I])-[#6]-2=[#8])-[#7](-[#1])-[#6]:[#6]:[#6]:[#6](-[#8]-[#6](-[#1])-[#1]):[#6]:[#6]:3	anil_oc_alk_b_3_	0	0	0	0	0	0	10	0
618	[#6]1=[#6]-[#6](-[#8]-[#6]-1-[#8])(-[#8])-[#6]	2	ene_misc_A(5)	8	1772687395	[#6]-1=[#6]-[#6](-[#8]-[#6]-1-[#8])(-[#8])-[#6]	ene_misc_a_5_	406	2	16	23	0	479	10	52
615	[#8&!H0]-c1:n:c(:c:c:c:1)-[#8&!H0]	2	het_6_pyridone_OH(5)	8	1772687395	[#8](-[#1])-c:1:n:c(:c:c:c:1)-[#8]-[#1]	het_6_pyridone_oh_5_	3379	0	0	0	0	3436	10	20
675	[#6]1(:[#6](-[#6&!H0&!H1]):[#6]2:[#6](-[#7]=[#6](-[#7](-[#6]-2=[!#6&!#1&X1])-[#6&!H0]-[$([#6](=[#8])-[#8]),$([#6]:[#6])])-[$([#1]),$([#16]-[#6](-[#1])-[#1])]):[!#6&!#1&X2]:1)-[#6&!H0&!H1]-[#6&!H0&!H1]	2	het_65_pyridone_A(3)	8	1772687395	[#6]:2(:[#6](-[#6](-[#1])-[#1]):[#6]-1:[#6](-[#7]=[#6;!H0,$([#6]-[#16]-[#6](-[#1])-[#1])](-[#7](-[#6]-1=[!#6&!#1;X1])-[#6](-[#1])-[$([#6](=[#8])-[#8]),$([#6]:[#6])])):[!#6&!#1;X2]:2)-[#6](-[#1])(-[#1])-[#6](-[#1])-[#1]	het_65_pyridone_a_3_	0	0	0	0	0	0	10	0
637	[#7]=[#6]1-[#7&!H0]-[#6](=[#6](-[#7&!H0])-[#7]=[#7]-1)-[#7&!H0]	2	het_6_imidate_A(4)	8	1772687395	[#7]=[#6]-1-[#7](-[#1])-[#6](=[#6](-[#7]-[#1])-[#7]=[#7]-1)-[#7]-[#1]	het_6_imidate_a_4_	0	0	0	0	0	0	10	0
684	[#6]-[#6](=[#8])-[#6&!H0&!H1]-[#16&X2]-c1:n:n:c2:c3:[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:c:3:[n&!H0]:c:2:n:1	2	het_thio_656b(3)	8	1772687395	[#6]-[#6](=[#8])-[#6](-[#1])(-[#1])-[#16;X2]-c:3:n:n:c:2:c:1:c(:c(:c(:c(:c:1:n(:c:2:n:3)-[#1])-[#1])-[#1])-[#1])-[#1]	het_thio_656b_3_	24	0	0	0	0	32	10	6
628	[#6]:[#6]-[#6&!H0]=[#6&!H0]-[#6&!H0]=[#7]-[#7](-[#6&X4])-[#6&X4]	2	imine_ene_A(5)	8	1772687395	[#6]:[#6]-[#6](-[#1])=[#6](-[#1])-[#6](-[#1])=[#7]-[#7](-[#6;X4])-[#6;X4]	imine_ene_a_5_	124	0	0	0	0	124	10	6
616	c12:[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:c:1:[c&!H0]:c(:[c&!H0]:[c&!H0]:2)-[#6]=[#7]-[#7&!H0]-[$([#6]:[#6]),$([#6]=[#16])]	2	hzone_naphth_A(5)	8	1772687395	c:1:2:c(:c(:c(:c(:c:1:c(:c(:c(:c:2-[#1])-[#1])-[#6]=[#7]-[#7](-[#1])-[$([#6]:[#6]),$([#6]=[#16])])-[#1])-[#1])-[#1])-[#1])-[#1]	hzone_naphth_a_5_	101	0	0	0	0	105	10	17
685	s1:c(:[n&+](-[#6&!H0&!H1]):c(:[c&!H0]:1)-[#6])-[#7&!H0]-c1:c:c:c:c:c:1-,:[$([#6](-[#1])-[#1]),$([#6]:[#6])]	2	thiazole_amine_D(3)	8	1772687395	s:1:c(:[n+](-[#6](-[#1])-[#1]):c(:c:1-[#1])-[#6])-[#7](-[#1])-c:2:c:c:c:c:c:2[$([#6](-[#1])-[#1]),$([#6]:[#6])]	thiazole_amine_d_3_	3	0	0	0	0	3	10	0
624	[c&!H0]1:[c&!H0]:c2:c(:[c&!H0]:c:1-[#7&!H0]-[#16](=[#8])(=[#8])-c1:c:c:c(:c:c:1)-[!#6&!#1])-[#8]-[#6&!H0&!H1]-[#8]-2	2	sulfonamide_C(5)	8	1772687395	c:1(:c(:c-3:c(:c(:c:1-[#7](-[#1])-[#16](=[#8])(=[#8])-c:2:c:c:c(:c:c:2)-[!#6&!#1])-[#1])-[#8]-[#6](-[#8]-3)(-[#1])-[#1])-[#1])-[#1]	sulfonamide_c_5_	272	0	0	0	0	276	10	13
693	[#7]1-[#16]-[#6]2=[#6](-[#6]:[#6]-[#7]-[#6]-2)-[#6]-1=[#16]	2	het_thio_N_65A(3)	8	1772687395	[#7]-2-[#16]-[#6]-1=[#6](-[#6]:[#6]-[#7]-[#6]-1)-[#6]-2=[#16]	het_thio_n_65a_3_	0	0	0	0	0	0	10	0
707	[#8]=[#6]-[#7&!H0]-c1:c(-[#6]:[#6]):n:c(-[#6&!H0&!H1]-[#6]#[#7]):s:1	2	thiazole_amine_E(2)	8	1772687395	[#8]=[#6]-[#7](-[#1])-c:1:c(-[#6]:[#6]):n:c(-[#6](-[#1])(-[#1])-[#6]#[#7]):s:1	thiazole_amine_e_2_	27	0	0	0	0	27	10	2
667	[#6]1(-[#6](=[#6]-[#6]=[#6]-[#6]=[#6]-1)-[#7&!H0])=[#7]-[#6]	2	colchicine_A(3)	8	1772687395	[#6]-1(-[#6](=[#6]-[#6]=[#6]-[#6]=[#6]-1)-[#7]-[#1])=[#7]-[#6]	colchicine_a_3_	13	0	0	0	0	35	10	0
723	s1:[c&!H0]:[c&!H0]:c(:c:1-[#6](=[#8])-[#7&!H0]-[#7&!H0])-[#8]-[#6&!H0&!H1]	2	thiophene_D(2)	8	1772687395	s:1:c(:c(-[#1]):c(:c:1-[#6](=[#8])-[#7](-[#1])-[#7]-[#1])-[#8]-[#6](-[#1])-[#1])-[#1]	thiophene_d_2_	472	0	0	0	0	472	10	19
666	c1(:[c&!H0]:[c&!H0]:c(:o:1)-[#6&!H0&!H1])-[#6&!H0](-[#8&!H0])-[#6]#[#6]-[#6&X4]	2	furan_A(3)	8	1772687395	c:1(:c(:c(:c(:o:1)-[#6](-[#1])-[#1])-[#1])-[#1])-[#6](-[#1])(-[#8]-[#1])-[#6]#[#6]-[#6;X4]	furan_a_3_	16	0	0	0	0	16	10	2
642	[#6&!H0]-[#6]1=[#6&!H0]-[#6](=[#6](-[#6]#[#7])-[#6](=[#8])-[#7&!H0]-1)-[#6]:[#8]	2	cyano_pyridone_E(4)	8	1772687395	[!#1]:[#6]-[#6]-1=[#6](-[#1])-[#6](=[#6](-[#6]#[#7])-[#6](=[#8])-[#7]-1-[#1])-[#6]:[#8]	cyano_pyridone_e_4_	0	0	0	0	0	0	10	0
686	[#6]1(=[#16])-[#7](-[#6&!H0&!H1]-c2:c:c:c:o:2)-[#6](=[#7]-[#7&!H0]-1)-[#6]:[#6]	2	thio_urea_H(3)	8	1772687395	[#6]-2(=[#16])-[#7](-[#6](-[#1])(-[#1])-c:1:c:c:c:o:1)-[#6](=[#7]-[#7]-2-[#1])-[#6]:[#6]	thio_urea_h_3_	0	0	0	0	0	0	10	0
697	[#6]1(-[#6]#[#7])(-[#6]#[#7])-[#6&!H0](-[#6](=[#8])-[#6])-[#6&!H0]-1	2	cyano_cyano_B(3)	8	1772687395	[#6]-1(-[#6]#[#7])(-[#6]#[#7])-[#6](-[#1])(-[#6](=[#8])-[#6])-[#6]-1-[#1]	cyano_cyano_b_3_	122	0	0	0	0	122	10	19
604	[#7]1(-c2:c:c:c:c:c:2)-[#7]=[#6](-[#6]=[#8])-[#6&X4]-[#6]-1=[#8]	2	het_5_A(7)	8	1772687395	[#7]-2(-c:1:c:c:c:c:c:1)-[#7]=[#6](-[#6]=[#8])-[#6;X4]-[#6]-2=[#8]	het_5_a_7_	292	0	0	0	0	298	10	39
703	Cl-c1:c:c2:n:o:n:c:2:c:c:1	2	diazox_B(3)	8	1772687395	[Cl]-c:2:c:c:1:n:o:n:c:1:c:c:2	diazox_b_3_	43	0	0	0	0	47	10	17
695	n12:,-c:,-c:,-c:,-c:,-1-[#6]=[#7](-[#6])-[#6]-[#6]-2	2	pyrrole_H(3)	8	1772687395	n1-2cccc1-[#6]=[#7](-[#6])-[#6]-[#6]-2	pyrrole_h_3_	43	0	0	0	0	43	10	7
660	[#6]1(-[#6]=[#7]-c2:c:c:c:c:c:2-[#7]-1)=[#6&!H0]-[#6]=[#8]	2	imine_ene_one_A(3)	8	1772687395	[#6]-2(-[#6]=[#7]-c:1:c:c:c:c:c:1-[#7]-2)=[#6](-[#1])-[#6]=[#8]	imine_ene_one_a_3_	36	0	0	0	0	41	10	6
636	[#7&!H0]-c1:n:c(:c:s:1)-c1:c:n:c(-[#7&!H0&!H1]):s:1	2	thiazole_amine_A(4)	8	1772687395	[#7](-[#1])-c:1:n:c(:c:s:1)-c:2:c:n:c(-[#7](-[#1])-[#1]):s:2	thiazole_amine_a_4_	70	0	0	0	0	73	10	17
700	c1(:c:c:c:c:c:1)-[#7&!H0]-[#6](=[#16])-[#7&!H0]-[#7]=[#6]-c1:c:n:c:c:1	2	thio_urea_I(3)	8	1772687395	c:1(:c:c:c:c:c:1)-[#7](-[#1])-[#6](=[#16])-[#7](-[#1])-[#7]=[#6]-c:2:c:n:c:c:2	thio_urea_i_3_	218	0	0	0	0	227	10	4
488	[!#6&!#1]=[#6]1-[#6]=,:[#6]-[#6](=[!#6&!#1])-[#6]=,:[#6]-1	2	quinone_A(370)	8	1772735344	[!#6&!#1]=[#6]-1-[#6]=,:[#6]-[#6](=[!#6&!#1])-[#6]=,:[#6]-1	quinone_a_370_	30185	1117	309	477	51	54448	10	2643
719	[#6&!H0&!H1]-c1:[c&!H0]:c(:[c&!H0]:[c&!H0]:c:1-[#8]-[#6&!H0&!H1])-[#6&!H0&!H1]-[#7&!H0]-[#6&X4]	2	anisol_B(2)	8	1772687395	[#6](-[#1])(-[#1])-c:1:c(:c(:c(:c(:c:1-[#8]-[#6](-[#1])-[#1])-[#1])-[#1])-[#6](-[#1])(-[#1])-[#7](-[#1])-[#6;X4])-[#1]	anisol_b_2_	14021	0	0	0	0	14029	10	56
652	[#6]=[#6]-[#6](-[#6]#[#7])(-[#6]#[#7])-[#6](-[#6]#[#7])=[#6]-[#7&!H0&!H1]	2	cyano_ene_amine_B(4)	8	1772687395	[#6]=[#6]-[#6](-[#6]#[#7])(-[#6]#[#7])-[#6](-[#6]#[#7])=[#6]-[#7](-[#1])-[#1]	cyano_ene_amine_b_4_	15	0	0	0	0	15	10	9
649	[#16]=[#6]1-[#7&!H0]-[#6]=[#6]-[#6]2=[#6]-1-[#6](=[#8])-[#8]-[#6]-2=[#6&!H0]	2	ene_five_het_J(4)	8	1772687395	[#16]=[#6]-1-[#7](-[#1])-[#6]=[#6]-[#6]-2=[#6]-1-[#6](=[#8])-[#8]-[#6]-2=[#6]-[#1]	ene_five_het_j_4_	0	0	0	0	0	0	10	0
634	n1(-[#6]2:[#6](-[#6]#[#7]):[#6]:[#6]:[!#6&!#1]:2):,-[c&!H0]-,:[c&!H0]:,-[c&!H0]-,:c:,-1	2	pyrrole_F(5)	8	1772687395	n2(-[#6]:1:[#6](-[#6]#[#7]):[#6]:[#6]:[!#6&!#1]:1)c(c(-[#1])c(c2)-[#1])-[#1]	pyrrole_f_5_	4036	0	0	0	0	4037	10	21
717	s1:,-c(-,:c(-,:c2:,-c:,-1-[#7&!H0]-[#6](-[#6](=[#6&!H0]-2)-[#6](=[#8])-[#8&!H0])=[#8])-[#7&!H0&!H1])-[#6](=[#8])-[#7&!H0]	2	het_65_E(2)	8	1772687395	s1c(c(c-2c1-[#7](-[#1])-[#6](-[#6](=[#6]-2-[#1])-[#6](=[#8])-[#8]-[#1])=[#8])-[#7](-[#1])-[#1])-[#6](=[#8])-[#7]-[#1]	het_65_e_2_	0	0	0	0	0	0	10	0
587	[#16]1-[#6](=&!@[#7]-[$([#1]),$([#7](-[#1])-[#6]:[#6])])-[#7](-[$([#1]),$([#6]:[#7]:[#6]:[#6]:[#16])])-[#6](=[#8])-[#6]-1=[#6&!H0]-[#6]:[#6]-[$([#17]),$([#8]-[#6]-[#1])]	2	ene_rhod_D(8)	8	1772735344	[#16]-1-[#6](=!@[#7;!H0,$([#7]-[#7](-[#1])-[#6]:[#6])])-[#7;!H0,$([#7]-[#6]:[#7]:[#6]:[#6]:[#16])]-[#6](=[#8])-[#6]-1=[#6](-[#1])-[#6]:[#6]-[$([#17]),$([#8]-[#6]-[#1])]	ene_rhod_d_8_	0	0	0	0	0	0	10	0
674	[#7](-[#6&!H0&!H1])(-[#6&!H0&!H1])-[#6&!H0]=[#7]-[#6](-[#6&!H0&!H1])=[#7]-[#7](-[#6&!H0&!H1])-[#6]:[#6]	2	imine_imine_C(3)	8	1772687395	[#7](-[#6](-[#1])-[#1])(-[#6](-[#1])-[#1])-[#6](-[#1])=[#7]-[#6](-[#6](-[#1])-[#1])=[#7]-[#7](-[#6](-[#1])-[#1])-[#6]:[#6]	imine_imine_c_3_	27	0	0	0	0	27	10	1
617	[#6]1=[#6](-[#16]-[#6](-[#6]=[#6]-1)=[#16])-[#7]	2	thio_ester_A(5)	8	1772687395	[#6]-1=[#6](-[#16]-[#6](-[#6]=[#6]-1)=[#16])-[#7]	thio_ester_a_5_	0	0	0	0	0	0	10	0
676	c1(:n:c(:[c&!H0]:s:1)-[!#1]:[!#1]:[!#1](-[$([#8]-[#6](-[#1])-[#1]),$([#6](-[#1])-[#1])]):[!#1]:[!#1])-[#7&!H0]-[#6&!H0&!H1]-c1:[c&!H0]:[c&!H0]:[c&!H0]:o:1	2	thiazole_amine_C(3)	8	1772687395	c:1(:n:c(:c(-[#1]):s:1)-[!#1]:[!#1]:[!#1](-[$([#8]-[#6](-[#1])-[#1]),$([#6](-[#1])-[#1])]):[!#1]:[!#1])-[#7](-[#1])-[#6](-[#1])(-[#1])-c:2:c(-[#1]):c(:c(-[#1]):o:2)-[#1]	thiazole_amine_c_3_	0	0	0	0	0	0	10	0
613	[#8]=[#6]1-[#6&X4]-[#6]-[#6](=[#8])-c2:c:c:c:c:c:2-1	2	keto_keto_gamma(5)	8	1772687395	[#8]=[#6]-1-[#6;X4]-[#6]-[#6](=[#8])-c:2:c:c:c:c:c-1:2	keto_keto_gamma_5_	1064	346	52	74	0	2641	10	99
689	[#6&!H0&!H1]-[#7]1-[#6](=[$([#16]),$([#7])])-[!#6&!#1]-[#6](=[#6]2-[#6&!H0]=[#6&!H0]-[#6]:[#6]-[#7]-2-[#6&!H0&!H1])-[#6]-1=[#8]	2	ene_rhod_J(3)	8	1772687395	[#6](-[#1])(-[#1])-[#7]-2-[#6](=[$([#16]),$([#7])])-[!#6&!#1]-[#6](=[#6]-1-[#6](=[#6](-[#1])-[#6]:[#6]-[#7]-1-[#6](-[#1])-[#1])-[#1])-[#6]-2=[#8]	ene_rhod_j_3_	136	0	0	0	0	138	10	14
713	[#6&!H0](-c1:c:c:c:c:c:1)(-c1:c:c:c:c:c:1)-[#6](=[#16])-[#7&!H0]	2	thio_amide_C(2)	8	1772687395	[#6](-[#1])(-c:1:c:c:c:c:c:1)(-c:2:c:c:c:c:c:2)-[#6](=[#16])-[#7]-[#1]	thio_amide_c_2_	12	0	0	0	0	16	10	2
704	[#6]-[#6&!H0]=[#16]	2	thio_aldehyd_A(3)	8	1772687395	[#6]-[#6](=[#16])-[#1]	thio_aldehyd_a_3_	5601	9	4	4	0	5699	10	127
120	[C&X3]-,:C(=O)-,:Cl	1	acyl-chloride-sp2	1	1772715346	[CX3]C(=O)Cl	acyl-chloride-sp2	1578	0	0	0	0	1633	50	431
718	[c&!H0]1:c2:[c&!H0]:[c&!H0]:c(:[c&!H0]:c:2:[c&!H0]:[c&!H0]:[c&!H0]:1)-[#7&!H0]-[#7&!H0]-[#6]=[#8]	2	hzide_naphth(2)	8	1772687395	c:2(:c:1:c(:c(:c(:c(:c:1:c(:c(:c:2-[#1])-[#1])-[#1])-[#1])-[#7](-[#1])-[#7](-[#1])-[#6]=[#8])-[#1])-[#1])-[#1]	hzide_naphth_2_	7	0	0	0	0	8	10	1
621	[#7]1-c2:c:c:c:c:c:2-[#6](=[#7])-c2:c-1:c:c:c:c:2	2	het_666_A(5)	8	1772687395	[#7]-2-c:1:c:c:c:c:c:1-[#6](=[#7])-c:3:c-2:c:c:c:c:3	het_666_a_5_	1	0	0	0	0	5	10	0
701	[#7&!H0&!H1]-[#6]1=[#6](-[#6]#[#7])-[#6&!H0](-c2:c:c:c:s:2)-[#6](=[#6](-[#6&!H0&!H1])-[#8]-1)-[#6](=[#8])-[#8]-[#6]	2	dhp_amino_CN_F(3)	8	1772687395	[#7](-[#1])(-[#1])-[#6]-2=[#6](-[#6]#[#7])-[#6](-[#1])(-c:1:c:c:c:s:1)-[#6](=[#6](-[#6](-[#1])-[#1])-[#8]-2)-[#6](=[#8])-[#8]-[#6]	dhp_amino_cn_f_3_	136	0	0	0	0	136	10	82
647	[#7&!H0](-c1:c:c:c:c:c:1)-[#7]=[#6](-[#6](=[#8])-[#6&!H0&!H1])-[#7&!H0]-[$([#7]-[#1]),$([#6]:[#6])]	2	imine_one_B(4)	8	1772687395	[#7](-[#1])(-c:1:c:c:c:c:c:1)-[#7]=[#6](-[#6](=[#8])-[#6](-[#1])-[#1])-[#7](-[#1])-[$([#7]-[#1]),$([#6]:[#6])]	imine_one_b_4_	15	0	0	0	0	20	10	1
651	n1(-[#6]):,-[c&!H0]-,:[c&!H0]:,-[c&!H0]-,:c:,-1-[#6&!H0]=[#6]1-[#6](=[#8])-[!#6&!#1]-[#6]=,:[!#1]-1	2	ene_five_het_K(4)	8	1772687395	n1(-[#6])c(c(-[#1])c(c1-[#6](-[#1])=[#6]-2-[#6](=[#8])-[!#6&!#1]-[#6]=,:[!#1]-2)-[#1])-[#1]	ene_five_het_k_4_	67	0	0	0	0	69	10	8
625	[#6&!H0]-[#6]1:[#7]:[#7](-c2:c:c:c:c:c:2):[#16]2:[!#6&!#1]:[!#1]:[#6]:[#6]:1:2	2	het_thio_N_55(5)	8	1772687395	[#6](-[#1])-[#6]:2:[#7]:[#7](-c:1:c:c:c:c:c:1):[#16]:3:[!#6&!#1]:[!#1]:[#6]:[#6]:2:3	het_thio_n_55_5_	0	0	0	0	0	0	10	0
643	[#6]12=[#6](-[#6](-[#7]-c3:c:c:c:c:c:3-1)(-[#6])-[#6])-[#16]-[#16]-[#6&!H0]-2	2	anil_alk_thio(4)	8	1772687395	[#6]-1-3=[#6](-[#6](-[#7]-c:2:c:c:c:c:c-1:2)(-[#6])-[#6])-[#16]-[#16]-[#6]-3=[!#1]	anil_alk_thio_4_	12	0	0	0	0	12	10	0
641	c1(:[c&!H0]:c(:c(:o:1)-[#6&!H0&!H1])-[#6&!H0&!H1]-[#8]-[#6]:[#6])-[#6](=[#8])-[#8&!H0]	2	furan_acid_A(4)	8	1772687395	c:1(:c(:c(:c(:o:1)-[#6](-[#1])-[#1])-[#6](-[#1])(-[#1])-[#8]-[#6]:[#6])-[#1])-[#6](=[#8])-[#8]-[#1]	furan_acid_a_4_	262	0	0	0	0	285	10	12
632	c1(:c:c:c:c:c:1)-[#7&!H0]-[#6](=[#16])-[#7]-[#7&!H0]-[#6](-,:[#7&R])-,:[#7&R]	2	thio_urea_G(5)	8	1772687395	c:1(:c:c:c:c:c:1)-[#7](-[#1])-[#6](=[#16])-[#7]-[#7](-[#1])-[#6]([#7;R])[#7;R]	thio_urea_g_5_	177	0	0	0	0	181	10	6
699	[#6]:[#6]-[#6](=[#8])-[#7&!H0]-[#6](=[#8])-[#6](-[#6]#[#7])=[#6&!H0]-[#7&!H0]-[#6]:[#6]	2	cyano_ene_amine_C(3)	8	1772687395	[#6]:[#6]-[#6](=[#8])-[#7](-[#1])-[#6](=[#8])-[#6](-[#6]#[#7])=[#6](-[#1])-[#7](-[#1])-[#6]:[#6]	cyano_ene_amine_c_3_	16	0	0	0	0	16	10	4
680	[#7]1(-c2:c:c:c:c:c:2)-[#6](=[#7]-[#6]=[#8])-[#16]-[#6&!H0&!H1]-[#6]-1=[#8]	2	rhod_sat_C(3)	8	1772687395	[#7]-2(-c:1:c:c:c:c:c:1)-[#6](=[#7]-[#6]=[#8])-[#16]-[#6](-[#1])(-[#1])-[#6]-2=[#8]	rhod_sat_c_3_	61	0	0	0	0	61	10	5
657	[#7]1(-c2:c:c:c:c:c:2)-[#7]=[#6](-[#7&!H0]-[#6]=[#8])-[#6&!H0&!H1]-[#6]-1=[#8]	2	het_5_B(4)	8	1772687395	[#7]-2(-c:1:c:c:c:c:c:1)-[#7]=[#6](-[#7](-[#1])-[#6]=[#8])-[#6](-[#1])(-[#1])-[#6]-2=[#8]	het_5_b_4_	339	0	0	0	0	342	10	24
661	[#8](-c1:c:c:c:c:c:1)-c1:c:c2:n:o:n:c:2:c:c:1	2	diazox_A(3)	8	1772687395	[#8](-c:1:c:c:c:c:c:1)-c:3:c:c:2:n:o:n:c:2:c:c:3	diazox_a_3_	5	0	0	0	0	6	10	1
631	n1(-[#6]2:[!#1]:[!#6&!#1]:[!#1]:[#6&!H0]:2):,-c(-,:[c&!H0]:,-[c&!H0]-,:c:,-1-[#6&X4])-[#6&X4]	2	pyrrole_E(5)	8	1772687395	n2(-[#6]:1:[!#1]:[!#6&!#1]:[!#1]:[#6]:1-[#1])c(c(-[#1])c(c2-[#6;X4])-[#1])-[#6;X4]	pyrrole_e_5_	2286	0	0	0	0	2318	10	105
635	[#7&!H0&!H1]-[#6]1=[#6](-[#6]#[#7])-[#6&!H0](-[#6]:[#6])-c2:c(:c:c:s:2)-[#8]-1	2	dhp_amino_CN_D(5)	8	1772687395	[#7](-[#1])(-[#1])-[#6]-2=[#6](-[#6]#[#7])-[#6](-[#1])(-[#6]:[#6])-c:1:c(:c:c:s:1)-[#8]-2	dhp_amino_cn_d_5_	194	0	0	0	0	200	10	108
681	[#6]=[#6]-[#6](=[#8])-[#7]-c1:c(:c(:c(:s:1)-[#6](=[#8])-[#8])-[#6&!H0])-[#6]#[#7]	2	thiophene_amino_D(3)	8	1772687395	[#6]=[#6]-[#6](=[#8])-[#7]-c:1:c(:c(:c(:s:1)-[#6](=[#8])-[#8])-[#6]-[#1])-[#6]#[#7]	thiophene_amino_d_3_	130	0	0	0	0	130	10	0
608	c1(:[c&!H0]:[c&!H0]:c:o:1)-[#6]=[#7]-[#7&!H0]-c1:n:c:c:s:1	2	hzone_furan_A(6)	8	1772687395	c:1(:c(:c(:[c;!H0,$(c-[#6;!H0;!H1])](:o:1))-[#1])-[#1])-[#6;!H0,$([#6]-[#6;!H0;!H1])]=[#7]-[#7](-[#1])-c:2:n:c:c:s:2	hzone_furan_a_6_	257	0	0	0	0	293	10	10
659	c1(:c:c:c(:c:c:1)-[#6&!H0&!H1])-c1:c(:s:c(:n:1)-[#7&!H0&!H1])-[#6&!H0&!H1&!H2]	2	thiazole_amine_B(3)	8	1772687395	c:1(:c:c:c(:c:c:1)-[#6](-[#1])-[#1])-c:2:c(:s:c(:n:2)-[#7](-[#1])-[#1])-[#6](-[#1])(-[#1])-[#1]	thiazole_amine_b_3_	40	0	0	0	0	44	10	13
672	[#7]1(-[#6&!H0&!H1])-[#6](=[#16])-[#7&!H0]-[#6](=[#6&!H0]-c2:c:c:c:c(:c:2)-Br)-[#6]-1=[#8]	2	ene_rhod_I(3)	8	1772687395	[#7]-2(-[#6](-[#1])-[#1])-[#6](=[#16])-[#7](-[#1])-[#6](=[#6](-[#1])-c:1:c:c:c:c(:c:1)-[Br])-[#6]-2=[#8]	ene_rhod_i_3_	309	0	0	0	0	309	10	3
653	[#6]:[#6]-[#6](=[#16&X1])-[#16&X2]-[#6&!H0]-[$([#6](-[#1])-[#1]),$([#6]:[#6])]	2	thio_ester_B(4)	8	1772687395	[#6]:[#6]-[#6](=[#16;X1])-[#16;X2]-[#6](-[#1])-[$([#6](-[#1])-[#1]),$([#6]:[#6])]	thio_ester_b_4_	53	0	0	0	0	53	10	14
715	c1:c:c(:c:c:c:1-[#7&!H0]-[#16](=[#8])=[#8])-[#7&!H0]-[#16](=[#8])=[#8]	2	sulfonamide_D(2)	8	1772687395	c:1:c:c(:c:c:c:1-[#7](-[#1])-[#16](=[#8])=[#8])-[#7](-[#1])-[#16](=[#8])=[#8]	sulfonamide_d_2_	1299	0	0	0	0	1340	10	20
691	[#8]=[#6]1-[#16]-c2:c(:c(:c:c:c:2)-[#8]-[#6&!H0&!H1])-[#8]-1	2	thio_carbonate_B(3)	8	1772687395	[#8]=[#6]-2-[#16]-c:1:c(:c(:c:c:c:1)-[#8]-[#6](-[#1])-[#1])-[#8]-2	thio_carbonate_b_3_	0	0	0	0	0	0	10	0
663	[#7&!H0&!H1]-c1:c(:c:c:c:n:1)-[#8]-[#6&!H0&!H1]-[#6]:[#6]	2	anil_OC_no_alk_C(3)	8	1772687395	[#7](-[#1])(-[#1])-c:1:c(:c:c:c:n:1)-[#8]-[#6](-[#1])(-[#1])-[#6]:[#6]	anil_oc_no_alk_c_3_	682	0	0	0	0	705	10	13
126	[C&X3]~[C&X3]-,:Cl	1	vinyl-chloride	0	1772715346	[CX3]=,~[CX3]Cl	vinyl-chloride	375793	90	22	108	26	383629	0	3872
706	[#6&!H0&!H1]-[#6&!H0&!H1]-[#16]-[#6&!H0&!H1]-c1:,-c:,-[n&!H0]-,:c:,-n:,-1	2	imidazole_B(2)	8	1772687395	[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#16]-[#6](-[#1])(-[#1])-c1cn(cn1)-[#1]	imidazole_b_2_	307	0	0	3	1	359	10	7
630	n1(-[#6]):,-[c&!H0]-,:[c&!H0]:,-[c&!H0]-,:c:,-1-[#6&!H0&!H1]-[#7&!H0]-[#6](=[#16])-[#7&!H0]	2	pyrrole_D(5)	8	1772687395	n1(-[#6])c(c(-[#1])c(c1-[#6](-[#1])(-[#1])-[#7](-[#1])-[#6](=[#16])-[#7]-[#1])-[#1])-[#1]	pyrrole_d_5_	28	0	0	0	0	30	10	0
694	[#6&!H0&!H1]-[#7](-[#6&!H0&!H1])-c1:[c&!H0]:[c&!H0]:c(:[c&!H0]:[c&!H0]:1)-[#6&!H0]=[#7]-[#7]=[#6](-[#6])-[#6]:[#6]	2	anil_di_alk_J(3)	8	1772687395	[#6](-[#1])(-[#1])-[#7](-[#6](-[#1])-[#1])-c:1:c(:c(:c(:c(:c:1-[#1])-[#1])-[#6](-[#1])=[#7]-[#7]=[#6](-[#6])-[#6]:[#6])-[#1])-[#1]	anil_di_alk_j_3_	39	0	0	0	0	39	10	4
646	[#6&!H0&!H1]-[#7](-[#6&!H0&!H1])-[#6]1=[#6]-c2:c(:c:c:c:c:2)-[#6&!H0&!H1]-1	2	anil_di_alk_ene_B(4)	8	1772687395	[#6](-[#1])(-[#1])-[#7](-[#6](-[#1])-[#1])-[#6]-2=[#6]-c:1:c(:c:c:c:c:1)-[#6]-2(-[#1])-[#1]	anil_di_alk_ene_b_4_	72	0	0	0	0	72	10	18
712	c12:c:c:c:c(:c:1:c(:c:c:c:2)-[$([#8]-[#1]),$([#7](-[#1])-[#1])])-[#6](-[#6])=[#8]	2	keto_naphthol_A(2)	8	1772687395	c:1:2:c:c:c:c(:c:1:c(:c:c:c:2)-[$([#8]-[#1]),$([#7](-[#1])-[#1])])-[#6](-[#6])=[#8]	keto_naphthol_a_2_	0	0	0	0	0	0	10	0
20	C-,:O-,:S(=O)-,:O-,:[C,c]	1	sulfate-ester	1	1772715346	C-,:O-,:S(=O)-,:O-,:[C,c]	sulfate-ester	974	1	2	3	0	1113	30	126
722	n1:,-n:,-c(-,:c2:,-c:,-c:,-c:,-c:,-2:,-c:,-1-[#6])-[#6]	2	het_65_Da(2)	8	1772687395	n2nc(c1cccc1c2-[#6])-[#6]	het_65_da_2_	18	0	0	0	0	21	10	0
668	[#6&!H0&!H1]-[#7](-[#6&!H0&!H1])-[#6&!H0]=[#6]-[#6](=[#8])-c1:c(-[#16&X2]):s:c(:c:1)-[$([#6]#[#7]),$([#6]=[#8])]	2	thiophene_C(3)	8	1772687395	[#6](-[#1])(-[#1])-[#7](-[#6](-[#1])-[#1])-[#6](-[#1])=[#6]-[#6](=[#8])-c:1:c(-[#16;X2]):s:c(:c:1)-[$([#6]#[#7]),$([#6]=[#8])]	thiophene_c_3_	3	0	0	0	0	3	10	0
687	[#7]1(-c2:c:c:c:c:c:2)-[#6](=[#8])-[#6](=[#6]-[#6](=[#7]-1)-[#6]#[#7])-[#6]#[#7]	2	cyano_pyridone_F(3)	8	1772687395	[#7]-2(-c:1:c:c:c:c:c:1)-[#6](=[#8])-[#6](=[#6]-[#6](=[#7]-2)-[#6]#[#7])-[#6]#[#7]	cyano_pyridone_f_3_	0	0	0	0	0	0	10	0
606	[c&!H0]1-,:c:,-o:,-c(-,:[c&!H0]:,-1)-[#6](=[#16])-[#7]1-[#6&!H0&!H1]-[#6&!H0&!H1]-[!#1]-[#6&!H0&!H1]-[#6&!H0&!H1]-1	2	thio_amide_A(6)	8	1772687395	c1(coc(c1-[#1])-[#6](=[#16])-[#7]-2-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[!#1]-[#6](-[#1])(-[#1])-[#6]-2(-[#1])-[#1])-[#1]	thio_amide_a_6_	227	0	0	0	0	229	10	12
688	[#7]1(-c2:c:c:c:c:c:2)-[#6](=[#8])-[#16]-[#6&!H0](-[#6&!H0&!H1]-[#6](=[#8])-[#7&!H0]-[#6]:[#6])-[#6]-1=[#8]	2	rhod_sat_D(3)	8	1772687395	[#7]-2(-c:1:c:c:c:c:c:1)-[#6](=[#8])-[#16]-[#6](-[#1])(-[#6](-[#1])(-[#1])-[#6](=[#8])-[#7](-[#1])-[#6]:[#6])-[#6]-2=[#8]	rhod_sat_d_3_	422	0	0	0	0	422	10	0
654	[#8]=[#6]1-[#6](=&!@[#6&!H0]-c2:c:n:c:c:2)-c2:c:c:c:c:c:2-[#7]-1	2	ene_five_het_L(4)	8	1772687395	[#8]=[#6]-3-[#6](=!@[#6](-[#1])-c:1:c:n:c:c:1)-c:2:c:c:c:c:c:2-[#7]-3	ene_five_het_l_4_	1169	0	0	0	0	1332	10	24
705	[#6&X4]-[#7&!H0]-[#6](-[#6]:[#6])=[#6&!H0]-[#6](=[#16])-[#7&!H0]-c1:c:c:c:c:c:1	2	thio_amide_B(2)	8	1772687395	[#6;X4]-[#7](-[#1])-[#6](-[#6]:[#6])=[#6](-[#1])-[#6](=[#16])-[#7](-[#1])-c:1:c:c:c:c:c:1	thio_amide_b_2_	25	0	0	0	0	25	10	1
623	c1(:[c&!H0]:c2:c(:[c&!H0]:[c&!H0]:1)-[#7&!H0]-[#6](-[#7&!H0]-2)=[#8])-[#7&!H0]-[#6&!H0&!H1]	2	anil_NH_alk_A(5)	8	1772687395	c:1(:c(:c-2:c(:c(:c:1-[#1])-[#1])-[#7](-[#6](-[#7]-2-[#1])=[#8])-[#1])-[#1])-[#7](-[#1])-[#6](-[#1])-[#1]	anil_nh_alk_a_5_	0	0	0	0	0	0	10	0
665	c1:c2:c(:c:c:c:1)-[#7](-c1:c:c:c:c:c:1-[#8]-2)-[#6&!H0&!H1]-[#6&!H0&!H1]	2	het_666_B(3)	8	1772687395	c:1:c-3:c(:c:c:c:1)-[#7](-c:2:c:c:c:c:c:2-[#8]-3)-[#6](-[#1])(-[#1])-[#6](-[#1])-[#1]	het_666_b_3_	52	0	0	1	0	76	10	19
489	[#7&!R]=[#7]	2	azo_A(324)	8	1772735344	[#7;!R]=[#7]	azo_a_324_	117440	38	36	78	11	132141	10	6618
533	[#6]1(-[#6](=[#8])-[#7]-[#6](=[#8])-[#7]-[#6]-1=[#8])=[#7]	2	imine_one_sixes(27)	8	1772735344	[#6]-1(-[#6](=[#8])-[#7]-[#6](=[#8])-[#7]-[#6]-1=[#8])=[#7]	imine_one_sixes_27_	376	1	0	0	0	377	10	45
487	n1(-,:c(-,:c(-,:c2:c:1:c:c:c:[c&!H0]:2)-[#6&X4&!H0])-[$([#6](-[#1])-[#1]),$([#6]=,:[!#6&!#1]),$([#6](-[#1])-[#7]),$([#6](-[#1])(-[#6](-[#1])-[#1])-[#6](-[#1])(-[#1])-[#7](-[#1])-[#6](-[#1])-[#1])])-[$([#1]),$([#6](-[#1])-[#1])]	2	indol_3yl_alk(461)	8	1772735344	[n;!H0,$(n-[#6;!H0;!H1])]:1(c(c(c:2:c:1:c:c:c:c:2-[#1])-[#6;X4]-[#1])-[$([#6](-[#1])-[#1]),$([#6]=,:[!#6&!#1]),$([#6](-[#1])-[#7]),$([#6](-[#1])(-[#6](-[#1])-[#1])-[#6](-[#1])(-[#1])-[#7](-[#1])-[#6](-[#1])-[#1])])	indol_3yl_alk_461_	0	0	0	0	0	0	10	0
576	c1:c:c:c:c:c:1-[#7&!H0]-[#6](=[#16])-[#7&!H0]-[#6&!H0&!H1]-[#6&!H0&!H1]-[#7](-[#6&!H0&!H1])-c1:c:c:c:c:c:1	2	thio_urea_B(9)	8	1772735344	c:1:c:c:c:c:c:1-[#7](-[#1])-[#6](=[#16])-[#7](-[#1])-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#7](-[#6](-[#1])-[#1])-c:2:c:c:c:c:c:2	thio_urea_b_9_	304	0	0	0	0	304	10	0
509	[#6]=&!@[#6&!H0]-&@[#6](=&!@[!#6&!#1])-&@[#6&!H0]=&!@[#6]	2	ene_one_ene_A(57)	8	1772735344	[#6]=!@[#6](-[!#1])-@[#6](=!@[!#6&!#1])-@[#6](=!@[#6])-[!#1]	ene_one_ene_a_57_	3966	1	0	2	1	4733	10	281
519	[#6]-[#6](=[#16])-[#6]	2	thio_ketone(43)	8	1772735344	[#6]-[#6](=[#16])-[#6]	thio_ketone_43_	11483	0	4	4	0	11712	10	330
586	[#6&!H0&!H1]-[#7](-[#6&!H0&!H1])-[#6]1=[#6&!H0]-c2:c(:c:c:c:c:2)-[#16&X2]-c2:c-1:c:c:c:c:2	2	anil_di_alk_ene_A(8)	8	1772735344	[#6](-[#1])(-[#1])-[#7](-[#6](-[#1])-[#1])-[#6]-2=[#6](-[#1])-c:1:c(:c:c:c:c:1)-[#16;X2]-c:3:c-2:c:c:c:c:3	anil_di_alk_ene_a_8_	20	0	0	0	0	22	10	0
542	n1:c(:[n&!H0]:c(:c:1-c1:c:c:c:c:c:1)-c1:c:c:c:c:c:1)-[#6&!H0]	2	imidazole_A(19)	8	1772735344	n:1:c(:n(:c(:c:1-c:2:c:c:c:c:c:2)-c:3:c:c:c:c:c:3)-[#1])-[#6]:[!#1]	imidazole_a_19_	62	0	0	0	0	113	10	5
527	[#6&!H0&!H1]-[#7](-[#6&!H0&!H1])-c1:[c&!H0]:[c&!H0]:c(:[c&!H0]:[c&!H0]:1)-[#6&!H0]=[#7]-[#7]-[$([#6](=[#8])-[#6](-[#1])(-[#1])-[#16]-[#6]:[#7]),$([#6](=[#8])-[#6](-[#1])(-[#1])-[!#1]:[!#1]:[#7]),$([#6](=[#8])-[#6]:[#6]-[#8]-[#1]),$([#6]:[#7]),$([#6](-[#1])(-[#1])-[#6](-[#1])-[#8]-[#1])]	2	hzone_anil_di_alk(35)	8	1772735344	[#6](-[#1])(-[#1])-[#7](-[#6](-[#1])-[#1])-c:1:c(:c(:c(:c(:c:1-[#1])-[#1])-[#6](-[#1])=[#7]-[#7]-[$([#6](=[#8])-[#6](-[#1])(-[#1])-[#16]-[#6]:[#7]),$([#6](=[#8])-[#6](-[#1])(-[#1])-[!#1]:[!#1]:[#7]),$([#6](=[#8])-[#6]:[#6]-[#8]-[#1]),$([#6]:[#7]),$([#6](-[#1])(-[#1])-[#6](-[#1])-[#8]-[#1])])-[#1])-[#1]	hzone_anil_di_alk_35_	1685	0	0	0	0	1707	10	40
165	[N&R0]-[N&R0]-[c&r6]	1	phenylhydrazine	1	1772715346	[NR0]-[NR0]-[cr6]	phenylhydrazine	2521154	9	7	34	9	2529442	0	8559
499	[#6&!H0]-[#7](-[#6&!H0&!H1])-c1:[c&!H0]:[c&!H0]:c(:c(:[c&!H0]:1)-[$([#1]),$([#6](-[#1])-[#1])])-[#6&!H0]-[$([#1]),$([#6]-[#1])]	2	anil_di_alk_E(186)	8	1772735344	[#6](-[#1])-[#7](-[#6](-[#1])-[#1])-c:1:c(:c(:c(:[c;!H0,$(c-[#6](-[#1])-[#1])](:c:1-[#1]))-[#6&!H0;!H1,$([#6]-[#6;!H0])])-[#1])-[#1]	anil_di_alk_e_186_	0	0	0	0	0	0	10	0
512	[#6]1(=[!#1]-[!#1]=[!#1]-[#7&!H0]-[#6]-1=[#16])-[#6]#[#7]	2	cyano_pyridone_A(54)	8	1772735344	[#6]-1(=[!#1]-[!#1]=[!#1]-[#7](-[#6]-1=[#16])-[#1])-[#6]#[#7]	cyano_pyridone_a_54_	0	0	0	0	0	0	10	0
558	[c&!H0]1:c2-[#16]-c3:c(-[#7](-c:2:[c&!H0]:[c&!H0]:[c&!H0]:1)-[$([#1]),$([#6](-[#1])(-[#1])-[#1]),$([#6](-[#1])(-[#1])-[#6]-[#1])]):c(:c(~[$([#1]),$([#6]:[#6])]):c(:[c&!H0]:3)-[$([#1]),$([#7](-[#1])-[#1]),$([#8]-[#6&X4])])~[$([#1]),$([#7](-[#1])-[#6&X4]),$([#6]:[#6])]	2	het_thio_666_A(13)	8	1772735344	c:2(:c:1-[#16]-c:3:c(-[#7;!H0,$([#7]-[CH3]),$([#7]-[#6;!H0;!H1]-[#6;!H0])](-c:1:c(:c(:c:2-[#1])-[#1])-[#1])):[c;!H0,$(c~[#7](-[#1])-[#6;X4]),$(c~[#6]:[#6])](:[c;!H0,$(c~[#6]:[#6])]:[c;!H0,$(c-[#7](-[#1])-[#1]),$(c-[#8]-[#6;X4])]:c:3-[#1]))-[#1]	het_thio_666_a_13_	0	0	0	0	0	0	10	0
550	[#6]1(=[#6](-&!@[#6](=[#8])-[#7]-[#6&!H0&!H1])-[#16]-[#6](-[#7]-1-[$([#6](-[#1])(-[#1])-[#6](-[#1])=[#6](-[#1])-[#1]),$([#6]:[#6])])=[#16])-[$([#7]-[#6](=[#8])-[#6]:[#6]),$([#7](-[#1])-[#1])]	2	thiaz_ene_B(17)	8	1772735344	[#6]-1(=[#6](-!@[#6](=[#8])-[#7]-[#6](-[#1])-[#1])-[#16]-[#6](-[#7]-1-[$([#6](-[#1])(-[#1])-[#6](-[#1])=[#6](-[#1])-[#1]),$([#6]:[#6])])=[#16])-[$([#7]-[#6](=[#8])-[#6]:[#6]),$([#7](-[#1])-[#1])]	thiaz_ene_b_17_	0	0	0	0	0	0	10	0
572	[#6]1(=[#8])-[#6](=[#6&!H0]-[$([#6]1:[#6]:[#6]:[#6]:[#6]:[#6]:1),$([#6]1:[#6]:[#6]:[#6]:[!#6&!#1]:1)])-[#7]=[#6](-[!#1]:[!#1]:[!#1])-[$([#16]),$([#7]-[!#1]:[!#1])]-1	2	ene_five_het_G(10)	8	1772735344	[#6]-1(=[#8])-[#6](=[#6](-[#1])-[$([#6]:1:[#6]:[#6]:[#6]:[#6]:[#6]:1),$([#6]:1:[#6]:[#6]:[#6]:[!#6&!#1]:1)])-[#7]=[#6](-[!#1]:[!#1]:[!#1])-[$([#16]),$([#7]-[!#1]:[!#1])]-1	ene_five_het_g_10_	3365	0	0	0	0	3469	10	54
596	c1:c:c2:c(:c:c:1)-[#6](=[#6](-[#6]-2=[#8])-[#6])-[#8&!H0]	2	keto_keto_beta_C(7)	8	1772735344	c:1:c:c-2:c(:c:c:1)-[#6](=[#6](-[#6]-2=[#8])-[#6])-[#8]-[#1]	keto_keto_beta_c_7_	83	0	0	0	0	217	10	12
525	[#7&!H0]-[#7]=[#6](-[#6]#[#7])-[#6]=[!#6&!#1&!R]	2	cyano_imine_A(37)	8	1772735344	[#7](-[#1])-[#7]=[#6](-[#6]#[#7])-[#6]=[!#6&!#1;!R]	cyano_imine_a_37_	1028	0	0	0	0	1099	10	159
538	[#16]=[#6]1-[#6]=,:[#6]-[!#6&!#1]-[#6]=,:[#6]-1	2	thio_dibenzo(23)	8	1772735344	[#16]=[#6]-1-[#6]=,:[#6]-[!#6&!#1]-[#6]=,:[#6]-1	thio_dibenzo_23_	2	0	0	0	0	2	10	1
577	c12:c(:[c&!H0]:c(:[c&!H0]:[c&!H0]:1)-[#7&!H0]-[#6&!H0&!H1]-c1:c:c:c:c:c:1):n:[c&!H0]:n:2-[#6]	2	anil_alk_bim(9)	8	1772735344	c:1:3:c(:c(:c(:c(:c:1-[#1])-[#1])-[#7](-[#1])-[#6](-[#1])(-[#1])-c:2:c:c:c:c:c:2)-[#1]):n:c(-[#1]):n:3-[#6]	anil_alk_bim_9_	162	0	0	0	0	191	10	12
588	[#16]1-[#6](=[#8])-[#7]-[#6](=[#16])-[#6]-1=[#6&!H0]-[#6]:[#6]	2	ene_rhod_E(8)	8	1772735344	[#16]-1-[#6](=[#8])-[#7]-[#6](=[#16])-[#6]-1=[#6](-[#1])-[#6]:[#6]	ene_rhod_e_8_	447	0	0	0	0	470	10	36
540	c12:[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:c:1:[c&!H0]:c(:c(:[c&!H0]:2)-[#8&!H0])-[#6](=[#8])-[#7&!H0]-[#7]=[#6]	2	hzone_acyl_naphthol(22)	8	1772735344	c:1:2:c(:c(:c(:c(:c:1:c(:c(:c(:c:2-[#1])-[#8]-[#1])-[#6](=[#8])-[#7](-[#1])-[#7]=[#6])-[#1])-[#1])-[#1])-[#1])-[#1]	hzone_acyl_naphthol_22_	1143	0	0	0	0	1205	10	209
562	[#8]=[#16](=[#8])-[#6](-[#6]#[#7])=[#7]-[#7&!H0]	2	cyano_imine_C(12)	8	1772735344	[#8]=[#16](=[#8])-[#6](-[#6]#[#7])=[#7]-[#7]-[#1]	cyano_imine_c_12_	66	0	0	0	0	78	10	28
584	c1:c:c2:c(:c:c:1)-[#6](-c1:c(-[$([#16&X2]),$([#6&X4])]-2):c:c:c(:c:1)-[$([#1]),$([#17]),$([#6&X4])])=[#6]-[#6]	2	styrene_B(8)	8	1772735344	c:1:c:c-2:c(:c:c:1)-[#6](-c:3:c(-[$([#16;X2]),$([#6;X4])]-2):c:c:[c;!H0,$(c-[#17]),$(c-[#6;X4])](:c:3))=[#6]-[#6]	styrene_b_8_	118	0	0	8	5	132	10	14
496	[#6]1(=[#6])-[#6]=[#7]-[!#6&!#1]-[#6]-1=[#8]	2	ene_five_het_A(201)	8	1772735344	[#6]-1(=[#6])-[#6]=[#7]-[!#6&!#1]-[#6]-1=[#8]	ene_five_het_a_201_	25797	21	0	0	0	26293	10	1721
505	[#6]1(-[#6](-[#6]=[#6]-[!#6&!#1]-1)=[#6])=[!#6&!#1]	2	ene_five_het_C(85)	8	1772735344	[#6]-1(-[#6](-[#6]=[#6]-[!#6&!#1]-1)=[#6])=[!#6&!#1]	ene_five_het_c_85_	13123	12	1	1	0	13226	10	558
491	[#7]-[#6&X4]-c1:c:c:c:c:c:1-[#8&!H0]	2	mannich_A(296)	8	1772735344	[#7]-[#6;X4]-c:1:c:c:c:c:c:1-[#8]-[#1]	mannich_a_296_	661104	602	12	26	8	674690	10	3591
599	[#6&!H0]-[#6&!H0&!H1]-c1:c(:c(:c(:s:1)-[#7&!H0]-[#6](=[#8])-[#6]-[#6]-[#6]=[#8])-[$([#6](=[#8])-[#8]),$([#6]#[#7])])-[#6&!H0&!H1]	2	thiophene_amino_C(7)	8	1772735344	[#6](-[#1])-[#6](-[#1])(-[#1])-c:1:c(:c(:c(:s:1)-[#7](-[#1])-[#6](=[#8])-[#6]-[#6]-[#6]=[#8])-[$([#6](=[#8])-[#8]),$([#6]#[#7])])-[#6](-[#1])-[#1]	thiophene_amino_c_7_	2201	0	0	0	0	2279	10	109
555	c1:c:c(:c:c:c:1-[#6&X4]-c1:c:c:c(:c:c:1)-[#7](-[$([#1]),$([#6&X4])])-[$([#1]),$([#6&X4])])-[#7](-[$([#1]),$([#6&X4])])-[$([#1]),$([#6&X4])]	2	anil_di_alk_F(14)	8	1772735344	c:1:c:c(:c:c:c:1-[#6;X4]-c:2:c:c:c(:c:c:2)-[#7&H2,$([#7;!H0]-[#6;X4]),$([#7](-[#6X4])-[#6X4])])-[#7&H2,$([#7;!H0]-[#6;X4]),$([#7](-[#6X4])-[#6X4])]	anil_di_alk_f_14_	396	0	0	0	0	3436	10	66
515	[#6]1(=[#6])-[#6](=[#8])-[#7]-[#7]-[#6]-1=[#8]	2	ene_five_het_D(46)	8	1772735344	[#6]-1(=[#6])-[#6](=[#8])-[#7]-[#7]-[#6]-1=[#8]	ene_five_het_d_46_	6392	0	0	0	0	6509	10	270
592	[#7](-c1:c:c:c:c:c:1)-c1:,-[n&+]:,-c(-,:c:,-s:,-1)-c1:c:c:c:c:c:1	2	thiaz_ene_D(8)	8	1772735344	[#7](-c:1:c:c:c:c:c:1)-c2[n+]c(cs2)-c:3:c:c:c:c:c:3	thiaz_ene_d_8_	203	0	0	0	0	206	10	2
564	c1:c(:c:c:c:c:1)-[#7&!H0]-c1:c(:c(:c(:s:1)-[$([#6]=[#8]),$([#6]#[#7]),$([#6](-[#8]-[#1])=[#6])])-[#7])-[$([#6]#[#7]),$([#6](:[#7]):[#7])]	2	thiophene_amino_B(12)	8	1772735344	c:1:c(:c:c:c:c:1)-[#7](-[#1])-c:2:c(:c(:c(:s:2)-[$([#6]=[#8]),$([#6]#[#7]),$([#6](-[#8]-[#1])=[#6])])-[#7])-[$([#6]#[#7]),$([#6](:[#7]):[#7])]	thiophene_amino_b_12_	100	0	0	0	0	102	10	27
518	c1(:[c&!H0]:c(:[c&!H0]:c(:c:1-[#8&!H0])-[F,Cl,Br,I])-[F,Cl,Br,I])-[#16](=[#8])(=[#8])-[#7]	2	sulfonamide_A(43)	8	1772735344	c:1(:c(:c(:c(:c(:c:1-[#8]-[#1])-[F,Cl,Br,I])-[#1])-[F,Cl,Br,I])-[#1])-[#16](=[#8])(=[#8])-[#7]	sulfonamide_a_43_	65	0	0	0	0	123	10	2
560	[#16]1-[#6](=[#7]-[#6]:[#6])-[#7](-[$([#1]),$([#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#8]),$([#6]:[#6])])-[#6](=[#8])-[#6]-1=[#6&!H0]-[$([#6]:[#6]:[#6]-[#17]),$([#6]:[!#6&!#1])]	2	ene_rhod_C(13)	8	1772735344	[#16]-1-[#6](=[#7]-[#6]:[#6])-[#7;!H0,$([#7]-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#8]),$([#7]-[#6]:[#6])]-[#6](=[#8])-[#6]-1=[#6](-[#1])-[$([#6]:[#6]:[#6]-[#17]),$([#6]:[!#6&!#1])]	ene_rhod_c_13_	1303	0	0	0	0	1336	10	52
557	c1(-,:n:,-n(-,:c(-,:c:,-1-[$([#1]),$([#6]-[#1])])-[#8&!H0])-c1:[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:1)-[#6&X4]	2	het_5_pyrazole_OH(14)	8	1772735344	c1(nn(c([c;!H0,$(c-[#6;!H0])]1)-[#8]-[#1])-c:2:c(:c(:c(:c(:c:2-[#1])-[#1])-[#1])-[#1])-[#1])-[#6;X4]	het_5_pyrazole_oh_14_	0	0	0	0	0	0	10	0
565	[#6&X4]1-[#6](=[#8])-[#7]-[#7]-[#6]-1=[#8]	2	keto_keto_beta_B(12)	8	1772735344	[#6;X4]-1-[#6](=[#8])-[#7]-[#7]-[#6]-1=[#8]	keto_keto_beta_b_12_	651	0	0	10	11	938	10	71
598	c1:c:c:c:c:c:1-[#7&!H0]-[#6](=[#16])-[#7&!H0]-[#6&!H0&!H1]-c1:n:c:c:c:c:1	2	thio_urea_E(7)	8	1772735344	c:1:c:c:c:c:c:1-[#7](-[#1])-[#6](=[#16])-[#7](-[#1])-[#6](-[#1])(-[#1])-c:2:n:c:c:c:c:2	thio_urea_e_7_	733	0	0	0	0	733	10	4
494	[#7]1-[#6](=[#16])-[#16]-[#6](=[#6])-[#6]-1=[#8]	2	ene_rhod_A(235)	8	1772735344	[#7]-1-[#6](=[#16])-[#16]-[#6](=[#6])-[#6]-1=[#8]	ene_rhod_a_235_	130347	5	0	0	1	131728	10	4415
504	[#6]1=[!#1]-[!#6&!#1]-[#6](-[#6]-1=[!#6&!#1&!R])=[#8]	2	imine_one_fives(89)	8	1772735344	[#6]-1=[!#1]-[!#6&!#1]-[#6](-[#6]-1=[!#6&!#1;!R])=[#8]	imine_one_fives_89_	3678	0	0	2	0	3838	10	405
569	c12:c(:[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:1):[!#6&!#1]:[#6](:[#6]:2-[#6&!H0]=[#7]-[#7&!H0]-[$([#6]1:[#7]:[#6]:[#6](-[#1]):[#16]:1),$([#6]:[#6](-[#1]):[#6]-[#1]),$([#6]:[#7]:[#6]:[#7]:[#6]:[#7]),$([#6]:[#7]:[#7]:[#7]:[#7])])-[$([#1]),$([#8]-[#1]),$([#6](-[#1])-[#1])]	2	hzone_thiophene_A(11)	8	1772735344	c:1:2:c(:c(:c(:c(:c:1-[#1])-[#1])-[#1])-[#1]):[!#6&!#1]:[#6;!H0,$([#6]-[OH]),$([#6]-[#6;H2,H3])](:[#6]:2-[#6](-[#1])=[#7]-[#7](-[#1])-[$([#6]:1:[#7]:[#6]:[#6](-[#1]):[#16]:1),$([#6]:[#6](-[#1]):[#6]-[#1]),$([#6]:[#7]:[#6]:[#7]:[#6]:[#7]),$([#6]:[#7]:[#7]:[#7]:[#7])])	hzone_thiophene_a_11_	0	0	0	0	0	0	10	0
523	[#7&+]1(:[#6]:[#6]:[!#1]:c2:c:1:[c&!H0]:c(-[$([#1]),$([#7])]):c:c:2)-[$([#6](-[#1])(-[#1])-[#1]),$([#8&X1]),$([#6](-[#1])(-[#1])-[#6](-[#1])=[#6](-[#1])-[#1]),$([#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#8]-[#1]),$([#6](-[#1])(-[#1])-[#6](=[#8])-[#6]),$([#6](-[#1])(-[#1])-[#6](=[#8])-[#7](-[#1])-[#6]:[#6]),$([#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#1])]	2	het_pyridiniums_A(39)	8	1772735344	[#7+]:1(:[#6]:[#6]:[!#1]:c:2:c:1:c(:[c;!H0,$(c-[#7])]:c:c:2)-[#1])-[$([#6](-[#1])(-[#1])-[#1]),$([#8;X1]),$([#6](-[#1])(-[#1])-[#6](-[#1])=[#6](-[#1])-[#1]),$([#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#8]-[#1]),$([#6](-[#1])(-[#1])-[#6](=[#8])-[#6]),$([#6](-[#1])(-[#1])-[#6](=[#8])-[#7](-[#1])-[#6]:[#6]),$([#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#1])]	het_pyridiniums_a_39_	56	0	0	0	0	102	10	23
6	c-,:P-,:c	1	phosphenes	1	1772715346	c-,:P-,:c	phosphenes	12607	0	0	1	0	13581	50	1492
601	[#8&!H0]-[#6](=[#8])-c1:c:c(:c:c:c:1)-[#6]:[!#1]:[#6]-[#6&!H0]=[#6]1-[#6](=[!#6&!#1])-[#7]-[#6](=[!#6&!#1])-[!#6&!#1]-1	2	ene_rhod_G(7)	8	1772735344	[#8](-[#1])-[#6](=[#8])-c:1:c:c(:c:c:c:1)-[#6]:[!#1]:[#6]-[#6](-[#1])=[#6]-2-[#6](=[!#6&!#1])-[#7]-[#6](=[!#6&!#1])-[!#6&!#1]-2	ene_rhod_g_7_	1460	0	0	0	0	1530	10	26
500	[#6]1(=[#6;!H0,$([#6]-[#6&!H0&!H1]),$([#6]-[#6]=[#8])]-[#16]-[#6](-[#7;!H0,$([#7]-[#6&!H0]),$([#7]-[#6]:[#6])]-1)=[#7&R0])-[$([#6&X4&H2]),$([#6]:[#6])]	2	thiaz_ene_A(128)	8	1772735344	[#6]-1(=[#6;!H0,$([#6]-[#6;!H0;!H1]),$([#6]-[#6]=[#8])]-[#16]-[#6](-[#7;!H0,$([#7]-[#6;!H0]),$([#7]-[#6]:[#6])]-1)=[#7;!R])-[$([#6](-[#1])-[#1]),$([#6]:[#6])]	thiaz_ene_a_128_	1	0	0	0	0	1	10	0
503	[#6]1(=[#6])-[#6](-[#7]=[#6]-[#16]-1)=[#8]	2	ene_five_het_B(90)	8	1772735344	[#6]-1(=[#6])-[#6](-[#7]=[#6]-[#16]-1)=[#8]	ene_five_het_b_90_	15495	0	0	0	0	16090	10	572
573	[#7&+](:[!#1]:[!#1]:[!#1])-[!#1]=[#8]	2	acyl_het_A(9)	8	1772735344	[#7+](:[!#1]:[!#1]:[!#1])-[!#1]=[#8]	acyl_het_a_9_	336	1	0	0	0	476	10	10
528	[#7]1-[#6](=[#16])-[#16]-[#6&X4]-[#6]-1=[#8]	2	rhod_sat_A(33)	8	1772735344	[#7]-1-[#6](=[#16])-[#16]-[#6;X4]-[#6]-1=[#8]	rhod_sat_a_33_	5190	0	0	4	0	5356	10	481
522	[$([#1]),$([#6](-[#1])-[#1]),$([#6]:[#6])]-c1:c(:c(:c(:s:1)-[#7&!H0]-[#6](=[#8])-[#6])-[#6](=[#8])-[#8])-[$([#6]1:[#6]:[#6]:[#6]:[#6]:[#6]:1),$([#6]1:[#16]:[#6]:[#6]:[#6]:1)]	2	thiophene_amino_Ab(40)	8	1772735344	[c;!H0,$(c-[#6](-[#1])-[#1]),$(c-[#6]:[#6])]:1:c(:c(:c(:s:1)-[#7](-[#1])-[#6](=[#8])-[#6])-[#6](=[#8])-[#8])-[$([#6]:1:[#6]:[#6]:[#6]:[#6]:[#6]:1),$([#6]:1:[#16]:[#6]:[#6]:[#6]:1)]	thiophene_amino_ab_40_	5	0	0	0	0	6	10	1
563	c1:c:c:c:c:c:1-[#7&!H0]-[#6](=[#16])-[#7&!H0]-[#6&!H0&!H1]-[#6&!H0&!H1]-[#6&!H0&!H1]-[#7](-[#6&!H0&!H1])-c1:c:c:c:c:c:1	2	thio_urea_A(12)	8	1772735344	c:1:c:c:c:c:c:1-[#7](-[#1])-[#6](=[#16])-[#7](-[#1])-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#7](-[#6](-[#1])-[#1])-c:2:c:c:c:c:c:2	thio_urea_a_12_	293	0	0	0	0	293	10	0
516	[#7&!H0&!H1]-c1:c(:[c&!H0]:[c&!H0]:s:1)-[#6]=[#8]	2	thiophene_amino_Aa(45)	8	1772735344	[#7](-[#1])(-[#1])-c:1:c(:c(:c(:s:1)-[!#1])-[!#1])-[#6]=[#8]	thiophene_amino_aa_45_	190	0	0	0	0	199	10	45
495	c1(:c:c:c(:c:c:1)-[#6]=[#7]-[#7])-[#8&!H0]	2	hzone_phenol_B(215)	8	1772735344	c:1(:c:c:c(:c:c:1)-[#6]=[#7]-[#7])-[#8]-[#1]	hzone_phenol_b_215_	33370	4	0	2	0	34914	10	1809
128	[#6]~[S&+](~[#6])~[#6]	1	sulfonium	0	1772715346	[#6]~[S+](~[#6])~[#6]	sulfonium	1007	1	7	12	13	1592	0	104
593	n1:c:c:c(:c:1-[#6&!H0&!H1])-[#6&!H0]=[#6]1-[#6](=[#8])-[#7]-[#6](=[!#6&!#1])-[#7]-1	2	ene_rhod_F(8)	8	1772735344	n:1:c:c:c(:c:1-[#6](-[#1])-[#1])-[#6](-[#1])=[#6]-2-[#6](=[#8])-[#7]-[#6](=[!#6&!#1])-[#7]-2	ene_rhod_f_8_	2630	0	0	0	0	2634	10	19
502	c1:c:c(:c(:c:c:1)-[#8&!H0])-[#8&!H0]	2	catechol_A(92)	8	1772735344	c:1:c:c(:c(:c:c:1)-[#8]-[#1])-[#8]-[#1]	catechol_a_92_	128976	3286	3373	4568	66	159969	10	2508
571	c1:c:c2:c(:c:c:1)-[#6]-[#6](-c1:c(-[#16]-2):[c&!H0]:[c&!H0]:c(:[c&!H0]:1)-[$([#1]),$([#8]),$([#16&X2]),$([#6&X4]),$([#7](-[$([#1]),$([#6&X4])])-[$([#1]),$([#6&X4])])])-[#7](-[$([#1]),$([#6&X4])])-[$([#1]),$([#6&X4])]	2	het_thio_676_A(10)	8	1772735344	c:1:c:c-2:c(:c:c:1)-[#6]-[#6](-c:3:c(-[#16]-2):c(:c(-[#1]):[c;!H0,$(c-[#8]),$(c-[#16;X2]),$(c-[#6;X4]),$(c-[#7;H2,H3,$([#7!H0]-[#6;X4]),$([#7](-[#6;X4])-[#6;X4])])](:c:3-[#1]))-[#1])-[#7;H2,H3,$([#7;!H0]-[#6;X4]),$([#7](-[#6;X4])-[#6;X4])]	het_thio_676_a_10_	90	0	0	0	2	112	10	2
600	[#6](-c1:[c&!H0]:[c&!H0]:c(:c:[c&!H0]:1)-[$([#6&X4]),$([#1])])(-c1:[c&!H0]:[c&!H0]:c(:[c&!H0]:[c&!H0]:1)-[$([#1]),$([#17])])=[$([#7]-[#8]-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#7](-[#6](-[#1])-[#1])-[#6](-[#1])-[#1]),$([#7]-[#8]-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#7](-[#6](-[#1])-[#1])-[#6](-[#1])-[#1]),$([#7]-[#7](-[#1])-[#6](=[#7]-[#1])-[#7](-[#1])-[#1]),$([#6](-[#1])-[#7])]	2	hzone_phenone(7)	8	1772735344	[#6](-c:1:c(:c(:[c;!H0,$(c-[#6;X4])]:c:c:1-[#1])-[#1])-[#1])(-c:2:c(:c(:[c;!H0,$(c-[#17])](:c(:c:2-[#1])-[#1]))-[#1])-[#1])=[$([#7]-[#8]-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#7](-[#6](-[#1])-[#1])-[#6](-[#1])-[#1]),$([#7]-[#8]-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#7](-[#6](-[#1])-[#1])-[#6](-[#1])-[#1]),$([#7]-[#7](-[#1])-[#6](=[#7]-[#1])-[#7](-[#1])-[#1]),$([#6](-[#1])-[#7])]	hzone_phenone_7_	0	0	0	0	0	0	10	0
552	[#8]1-[#6](-[#16]-c2:c-1:c:c:c(:c:2)-[$([#7]),$([#8])])=[$([#8]),$([#16])]	2	thio_carbonate_A(15)	8	1772735344	[#8]-1-[#6](-[#16]-c:2:c-1:c:c:c(:c:2)-[$([#7]),$([#8])])=[$([#8]),$([#16])]	thio_carbonate_a_15_	0	0	0	0	0	0	10	0
602	[#6]1(=[#6]-[#6](-c2:c:c(:c(:n:c:2-1)-[#7&!H0&!H1])-[#6]#[#7])=[#6])-[#6]#[#7]	2	ene_cyano_B(7)	8	1772735344	[#6]-1(=[#6]-[#6](-c:2:c:c(:c(:n:c-1:2)-[#7](-[#1])-[#1])-[#6]#[#7])=[#6])-[#6]#[#7]	ene_cyano_b_7_	546	0	0	0	0	557	10	68
514	c1:c2:c(:c:c:c:1):n:c1:c(:c:2-[#7]):c:c:c:c:1	2	amino_acridine_A(46)	8	1772735344	c:1:c:2:c(:c:c:c:1):n:c:3:c(:c:2-[#7]):c:c:c:c:3	amino_acridine_a_46_	1449	0	0	3	5	3799	10	117
567	[#6]1(-[#6](=[#6](-[#6]#[#7])-[#6](~[#8])~[#7]~[#6]-1~[#8])-[#6&!H0&!H1])=[#6&!H0]-[#6]:[#6]	2	cyano_pyridone_C(11)	8	1772735344	[#6]-1(-[#6](=[#6](-[#6]#[#7])-[#6](~[#8])~[#7]~[#6]-1~[#8])-[#6](-[#1])-[#1])=[#6](-[#1])-[#6]:[#6]	cyano_pyridone_c_11_	5368	0	0	0	0	5368	10	10
520	c1:c:c(:c:c:c:1-[#8&!H0])-[#7&!H0]-[#16](=[#8])=[#8]	2	sulfonamide_B(41)	8	1772735344	c:1:c:c(:c:c:c:1-[#8]-[#1])-[#7](-[#1])-[#16](=[#8])=[#8]	sulfonamide_b_41_	13383	0	0	0	0	13847	10	204
551	[#16]1-[#6](=[#8])-[#7]-[#6](=[#8])-[#6]-1=[#6&!H0]-[$([#6]-[#35]),$([#6]:[#6](-[#1]):[#6](-[F,Cl,Br,I]):[#6]:[#6]-[F,Cl,Br,I]),$([#6]:[#6](-[#1]):[#6](-[#1]):[#6]-[#16]-[#6](-[#1])-[#1]),$([#6]:[#6]:[#6]:[#6]:[#6]:[#6]:[#6]:[#6]:[#6]:[#6]-[#8]-[#6](-[#1])-[#1]),$([#6]1:[#6](-[#6](-[#1])-[#1]):[#7](-[#6](-[#1])-[#1]):[#6](-[#6](-[#1])-[#1]):[#6]:1)]	2	ene_rhod_B(16)	8	1772735344	[#16]-1-[#6](=[#8])-[#7]-[#6](=[#8])-[#6]-1=[#6](-[#1])-[$([#6]-[#35]),$([#6]:[#6](-[#1]):[#6](-[F,Cl,Br,I]):[#6]:[#6]-[F,Cl,Br,I]),$([#6]:[#6](-[#1]):[#6](-[#1]):[#6]-[#16]-[#6](-[#1])-[#1]),$([#6]:[#6]:[#6]:[#6]:[#6]:[#6]:[#6]:[#6]:[#6]:[#6]-[#8]-[#6](-[#1])-[#1]),$([#6]:1:[#6](-[#6](-[#1])-[#1]):[#7](-[#6](-[#1])-[#1]):[#6](-[#6](-[#1])-[#1]):[#6]:1)]	ene_rhod_b_16_	5	0	0	0	0	5	10	0
549	[#6](-[#6]#[#7])(-[#6]#[#7])=[#7]-[#7&!H0]-c1:c:c:c:c:c:1	2	cyano_imine_B(17)	8	1772735344	[#6](-[#6]#[#7])(-[#6]#[#7])=[#7]-[#7](-[#1])-c:1:c:c:c:c:c:1	cyano_imine_b_17_	124	0	0	0	1	124	10	42
511	c12:c(:c:c:c:c:1)-[#6](=[#8])-[#6](=[#6])-[#6]-2=[#8]	2	ene_five_one_A(55)	8	1772735344	c:1-2:c(:c:c:c:c:1)-[#6](=[#8])-[#6](=[#6])-[#6]-2=[#8]	ene_five_one_a_55_	2756	0	0	0	0	2815	10	331
529	[#7&!H0]-[#7]=[#6]-[#6](-[$([#1]),$([#6])])=[#6](-[#6])-&!@[$([#7]),$([#8]-[#1])]	2	hzone_enamin(30)	8	1772735344	[#7](-[#1])-[#7]=[#6]-[#6;!H0,$([#6]-[#6])]=[#6](-[#6])-!@[$([#7]),$([#8]-[#1])]	hzone_enamin_30_	222	0	0	0	0	253	10	0
492	c1:c:c(:c:c:c:1-[#7](-[#6&X4])-[#6&X4])-[#6]=[#6]	2	anil_di_alk_B(251)	8	1772735344	c:1:c:c(:c:c:c:1-[#7](-[#6;X4])-[#6;X4])-[#6]=[#6]	anil_di_alk_b_251_	59177	7	7	10	1	60843	10	1309
539	[#6](-[#6]#[#7])(-[#6]#[#7])-[#6](-[$([#6]#[#7]),$([#6]=[#7])])-[#6]#[#7]	2	cyano_cyano_A(23)	8	1772735344	[#6](-[#6]#[#7])(-[#6]#[#7])-[#6](-[$([#6]#[#7]),$([#6]=[#7])])-[#6]#[#7]	cyano_cyano_a_23_	1554	0	0	0	0	1662	10	220
583	[#6](=[#8])-[#6]1=[#6]-[#7]-c2:c(-[#16]-1):c:c:c:c:2	2	het_thio_66_one(8)	8	1772735344	[#6](=[#8])-[#6]-1=[#6]-[#7]-c:2:c(-[#16]-1):c:c:c:c:2	het_thio_66_one_8_	1471	0	0	0	0	1495	10	784
498	[#8]=[#6]1-[#6](=&!@[#7]-[#7])-c2:c:c:c:c:c:2-[#7]-1	2	imine_one_isatin(189)	8	1772735344	[#8]=[#6]-2-[#6](=!@[#7]-[#7])-c:1:c:c:c:c:c:1-[#7]-2	imine_one_isatin_189_	19811	1	0	1	0	21040	10	967
590	n1(-[#6&X4]):,-c(-,:[c&!H0]:,-[c&!H0]-,:c:,-1-[#6]:[#6])-[#6&!H0&!H1]	2	pyrrole_C(8)	8	1772735344	n1(-[#6;X4])c(c(-[#1])c(c1-[#6]:[#6])-[#1])-[#6](-[#1])-[#1]	pyrrole_c_8_	743	0	1	1	0	867	10	37
603	[#7&!H0&!H1]-[#6]1=[#6](-[#6]#[#7])-[#6&!H0](-[#6]:[#6])-[#6](=[#6](-[#6]:[#6])-[#8]-1)-[#6]#[#7]	2	dhp_amino_CN_C(7)	8	1772735344	[#7](-[#1])(-[#1])-[#6]-1=[#6](-[#6]#[#7])-[#6](-[#1])(-[#6]:[#6])-[#6](=[#6](-[#6]:[#6])-[#8]-1)-[#6]#[#7]	dhp_amino_cn_c_7_	46	0	0	0	0	80	10	8
544	c1(:c:c:c:c:c:1-[#7&!H0]-[#7]=[#6])-[#6](=[#8])-[#8&!H0]	2	anthranil_acid_A(19)	8	1772735344	c:1(:c:c:c:c:c:1-[#7](-[#1])-[#7]=[#6])-[#6](=[#8])-[#8]-[#1]	anthranil_acid_a_19_	321	0	0	0	0	353	10	31
580	[#7&!R]=[#6]1-[#6](=[#8])-c2:c:c:c:c:c:2-[#16]-1	2	imine_one_fives_B(9)	8	1772735344	[#7;!R]=[#6]-2-[#6](=[#8])-c:1:c:c:c:c:c:1-[#16]-2	imine_one_fives_b_9_	129	0	0	0	0	131	10	3
510	[#6](-[#6]#[#7])(-[#6]#[#7])-[#6](-[#7&!H0&!H1])=[#6]-[#6]#[#7]	2	cyano_ene_amine_A(56)	8	1772735344	[#6](-[#6]#[#7])(-[#6]#[#7])-[#6](-[#7](-[#1])-[#1])=[#6]-[#6]#[#7]	cyano_ene_amine_a_56_	3403	0	0	0	0	3415	10	858
535	c1:c2:c:c:c:c3:c:2:c(:c:c:1)-[#7]-[#6]=[#7]-3	2	naphth_amino_A(25)	8	1772735344	c:2:c:1:c:c:c:c-3:c:1:c(:c:c:2)-[#7]-[#6]=[#7]-3	naphth_amino_a_25_	0	0	0	0	0	0	10	0
568	[#6]1(=[#6](-&!@[#6]=[#7])-[#16]-[#6](-[#7]-1)=[#8])-[$([F,Cl,Br,I]),$([#7&+](:[#6]):[#6])]	2	thiaz_ene_C(11)	8	1772735344	[#6]-1(=[#6](-!@[#6]=[#7])-[#16]-[#6](-[#7]-1)=[#8])-[$([F,Cl,Br,I]),$([#7+](:[#6]):[#6])]	thiaz_ene_c_11_	0	0	0	0	0	0	10	0
493	c1:c:c(:c:c:c:1-[#8]-[#6&X4])-[#7](-[#6&X4])-[$([#1]),$([#6&X4])]	2	anil_di_alk_C(246)	8	1772735344	c:1:c:c(:c:c:c:1-[#8]-[#6;X4])-[#7;!H0,$([#7]-[#6;X4])]-[#6;X4]	anil_di_alk_c_246_	127913	9	7	18	9	132157	10	1386
506	[#6]-[#7]1-[#6&!H0&!H1]-[#6&!H0&!H1]-[#7](-[#6&!H0&!H1]-[#6&!H0&!H1]-1)-[#7]=[#6&!H0]-[#6&!H0]	2	hzone_pipzn(79)	8	1772735344	[#6]-[#7]-1-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#7](-[#6](-[#1])(-[#1])-[#6]-1(-[#1])-[#1])-[#7]=[#6](-[#1])-[#6]:[!#1]	hzone_pipzn_79_	147	0	0	0	0	154	10	5
507	c12:c(:c:c:c:c:1)-[#6](=[#8])-[#6&X4]-[#6]-2=[#8]	2	keto_keto_beta_A(68)	8	1772735344	c:1-2:c(:c:c:c:c:1)-[#6](=[#8])-[#6;X4]-[#6]-2=[#8]	keto_keto_beta_a_68_	9319	2	1	6	4	9863	10	462
485	c1:c:c(:c(:c:c:1)-[#6]=[#7]-[#7])-[#8&D1]	2	hzone_phenol_A(479)	8	1772735344	c:1:c:c(:c(:c:c:1)-[#6]=[#7]-[#7])-[#8]-[#1]	hzone_phenol_a_479_	42696	12	0	18	1	44786	10	2681
594	[#6]1(=[#6](-[#6&!H0](-[#6])-[#6])-[#16]-[#6](-[#7]-1-[$([#1]),$([#6](-[#1])-[#1])])=[#8])-[#16]-[#6&R]	2	thiaz_ene_E(8)	8	1772735344	[#6]-1(=[#6](-[#6](-[#1])(-[#6])-[#6])-[#16]-[#6](-[#7;!H0,$([#7]-[#6;!H0;!H1])]-1)=[#8])-[#16]-[#6;R]	thiaz_ene_e_8_	0	0	0	0	0	0	10	0
566	c1:c2:c(:c:c:c:1)-[#6]1:[#7]:[!#1]:[#6]:[#6]:[#6]:1-[#6]-2=[#8]	2	keto_phenone_A(11)	8	1772735344	c:1:c-3:c(:c:c:c:1)-[#6]:2:[#7]:[!#1]:[#6]:[#6]:[#6]:2-[#6]-3=[#8]	keto_phenone_a_11_	624	2	0	0	0	1404	10	78
597	c1:c:c2:n:n:c(:n:c:2:c:c:1)-[#6&!H0&!H1]-[#6]=[#8]	2	het_66_A(7)	8	1772735344	c:2:c:c:1:n:n:c(:n:c:1:c:c:2)-[#6](-[#1])(-[#1])-[#6]=[#8]	het_66_a_7_	64	0	0	0	0	67	10	3
543	[#6](-[#6]#[#7])(-[#6]#[#7])=[#6]-c1:c:c:c:c:c:1	2	ene_cyano_A(19)	8	1772735344	[#6](-[#6]#[#7])(-[#6]#[#7])=[#6]-c:1:c:c:c:c:c:1	ene_cyano_a_19_	2502	3	1	1	0	2635	10	357
508	n1(-[#6]):,-[c&!H0]-,:[c&!H0]:,-[c&!H0]-,:c:,-1-[#6]=[#7]-[#7]	2	hzone_pyrrol(64)	8	1772735344	n1(-[#6])c(c(-[#1])c(c1-[#6]=[#7]-[#7])-[#1])-[#1]	hzone_pyrrol_64_	3443	0	0	0	0	3463	10	38
501	n1(-[#6]2:[!#1]:[#6]:[#6]:[#6]:[#6]:2):,-c(-,:c:,-[c&!H0]-,:c:,-1-[#6&X4])-[#6&X4]	2	pyrrole_A(118)	8	1772735344	n2(-[#6]:1:[!#1]:[#6]:[#6]:[#6]:[#6]:1)c(cc(c2-[#6;X4])-[#1])-[#6;X4]	pyrrole_a_118_	150820	1	0	2	1	156100	10	1555
85	[C&X4]-,:[S&R1](=O)(=O)-,:[N&D2]	1	secondary-sultam	0	1772715346	[CX4][SR1](=O)(=O)[ND2]	secondary-sultam	92077	1	0	6	0	92898	0	208
553	[#7](-[#6&!H0&!H1])(-[#6&!H0&!H1])-c1:[c&!H0]:[c&!H0]:c(:o:1)-[#6]=[#7]-[#7&!H0]-[#6]=[!#6&!#1]	2	anil_di_alk_furan_A(15)	8	1772735344	[#7](-[#6](-[#1])-[#1])(-[#6](-[#1])-[#1])-c:1:c(:c(:c(:o:1)-[#6]=[#7]-[#7](-[#1])-[#6]=[!#6&!#1])-[#1])-[#1]	anil_di_alk_furan_a_15_	778	0	0	0	0	786	10	11
536	c1:c2:c:c:c:c3:c:2:c(:c:c:1)-[#7&!H0]-[#6&X4]-[#7&!H0]-3	2	naphth_amino_B(25)	8	1772735344	c:2:c:1:c:c:c:c-3:c:1:c(:c:c:2)-[#7](-[#6;X4]-[#7]-3-[#1])-[#1]	naphth_amino_b_25_	306	0	0	0	0	311	10	182
574	[#6&X4]-[#7](-[#6&X4])-c1:[c&!H0]:[c&!H0]:c(:[c&!H0]:[c&!H0]:1)-[#6]1=,:[#7]-,:[#6]:[#6]:[!#1]-,:1	2	anil_di_alk_G(9)	8	1772735344	[#6;X4]-[#7](-[#6;X4])-c:1:c(:c(:c(:c(:c:1-[#1])-[#1])-[#6]2=,:[#7][#6]:[#6]:[!#1]2)-[#1])-[#1]	anil_di_alk_g_9_	1063	0	0	0	0	1951	10	84
575	[#7]1(-[$([#6&X4]),$([#1])])-[#6]=,:[#6](-[#6](=[#8])-[#6]:[#6]:[#6])-[#6](-[#6])-[#6](=[#6]-1-[#6&!H0&!H1&!H2])-[$([#6]=[#8]),$([#6]#[#7])]	2	dhp_keto_A(9)	8	1772735344	[#7;!H0,$([#7]-[#6;X4])]-1-[#6]=,:[#6](-[#6](=[#8])-[#6]:[#6]:[#6])-[#6](-[#6])-[#6](=[#6]-1-[#6](-[#1])(-[#1])-[#1])-[$([#6]=[#8]),$([#6]#[#7])]	dhp_keto_a_9_	19	0	0	0	0	21	10	0
579	c1(:c:c:c:c:c:1)-[#7&!H0]-[#6](=[#16])-[#7]-[#7&!H0]-[#6](=[#8])-[#6]1:[!#1]:[!#6&!#1]:[#6]:[#6]-1	2	thio_urea_C(9)	8	1772735344	c:1(:c:c:c:c:c:1)-[#7](-[#1])-[#6](=[#16])-[#7]-[#7](-[#1])-[#6](=[#8])-[#6]-2:[!#1]:[!#6&!#1]:[#6]:[#6]-2	thio_urea_c_9_	0	0	0	0	0	0	10	0
530	n1(-[#6]2:[!#1]:[#6]:[#6]:[#6]:[#6]:2):,-c(-,:c:,-[c&!H0]-,:c:,-1-[#6]:[#6])-[#6&X4]	2	pyrrole_B(29)	8	1772735344	n2(-[#6]:1:[!#1]:[#6]:[#6]:[#6]:[#6]:1)c(cc(c2-[#6]:[#6])-[#1])-[#6;X4]	pyrrole_b_29_	4268	0	0	2	0	5329	10	383
497	c1:c:c(:c:c:c:1-[#7](-[#6&X4])-[#6&X4])-[#6&X4]-[$([#8]-[#1]),$([#6]=[#6]-[#1]),$([#7]-[#6&X4])]	2	anil_di_alk_D(198)	8	1772735344	c:1:c:c(:c:c:c:1-[#7](-[#6;X4])-[#6;X4])-[#6;X4]-[$([#8]-[#1]),$([#6]=[#6]-[#1]),$([#7]-[#6;X4])]	anil_di_alk_d_198_	552394	168	0	1	0	557595	10	2115
581	[$([#7](-[#1])-[#1]),$([#8]-[#1])]-[#6]1=[#6](-[#6]#[#7])-[#6&!H0](-[#6]:[#6])-c2:c(:n(-[#6]):n:c:2)-[#8]-1	2	dhp_amino_CN_B(9)	8	1772735344	[$([#7](-[#1])-[#1]),$([#8]-[#1])]-[#6]-2=[#6](-[#6]#[#7])-[#6](-[#1])(-[#6]:[#6])-c:1:c(:n(-[#6]):n:c:1)-[#8]-2	dhp_amino_cn_b_9_	0	0	0	0	0	0	10	0
521	[N&D1]-,:c1:,-[c&D2]:,-[c&D2]:,-c(-,:[c&D2]:,-[c&D2]:,-1)-,:[$([#8]),$([#7]),$([#6&X4&D2])]	2	anil_no_alk(40)	8	1772735344	c:1(:c(:c(:c(:c(:c:1-[#1])-[#1])-[$([#8]),$([#7]),$([#6](-[#1])-[#1])])-[#1])-[#1])-[#7](-[#1])-[#1]	anil_no_alk_40_	123402	13	4	14	1	127080	10	2913
526	[#7](-c1:c:c:c:c:c:1)-[#16](=[#8])(=[#8])-[#6]1:[#6]:[#6]:[#6]:[#6]2:[#7]:[$([#8]),$([#16])]:[#7]:[#6]:1:2	2	diazox_sulfon_A(36)	8	1772735344	[#7](-c:1:c:c:c:c:c:1)-[#16](=[#8])(=[#8])-[#6]:2:[#6]:[#6]:[#6]:[#6]:3:[#7]:[$([#8]),$([#16])]:[#7]:[#6]:2:3	diazox_sulfon_a_36_	2534	0	0	0	0	2649	10	37
537	[#6]-[#6](=[#8])-[#6&!H0]=[#6](-[#7&!H0]-[#6])-[#6](=[#8])-[#8]-[#6]	2	ene_one_ester(24)	8	1772735344	[#6]-[#6](=[#8])-[#6](-[#1])=[#6](-[#7](-[#1])-[#6])-[#6](=[#8])-[#8]-[#6]	ene_one_ester_24_	404	1	0	0	0	417	10	35
570	[!#1]:[!#1]-[#6](-[$([#1]),$([#6]#[#7])])=[#6]1-[#6]=,:[#6]-[#6](=[$([#8]),$([#7&!R])])-[#6]=,:[#6]-1	2	ene_quin_methide(10)	8	1772735344	[!#1]:[!#1]-[#6;!H0,$([#6]-[#6]#[#7])]=[#6]-1-[#6]=,:[#6]-[#6](=[$([#8]),$([#7;!R])])-[#6]=,:[#6]-1	ene_quin_methide_10_	104	0	0	0	0	113	10	3
532	[#6]1(=[#6](-[#6](=[#8])-[#7]-[#6](=[#7]-1)-[!#6&!#1])-[#6]#[#7])-[#6]	2	cyano_pyridone_B(27)	8	1772735344	[#6]-1(=[#6](-[#6](=[#8])-[#7]-[#6](=[#7]-1)-[!#6&!#1])-[#6]#[#7])-[#6]	cyano_pyridone_b_27_	0	0	0	0	0	0	10	0
531	s1:,-c:,-c:,-c(-,:c:,-1)-[#8&!H0]	2	thiophene_hydroxy(28)	8	1772735344	s1ccc(c1)-[#8]-[#1]	thiophene_hydroxy_28_	7138	0	1	2	0	7294	10	220
548	[#6]-[#6]=[#6](-[F,Cl,Br,I])-[#6](=[#8])-[#6]	2	ene_one_hal(17)	8	1772735344	[#6]-[#6]=[#6](-[F,Cl,Br,I])-[#6](=[#8])-[#6]	ene_one_hal_17_	4270	57	1	9	1	6405	10	572
490	[#6]-[#6](=[!#6&!#1&!R])-[#6](=[!#6&!#1&!R])-[$([#6]),$([#16](=[#8])=[#8])]	2	imine_one_A(321)	8	1772735344	[#6]-[#6](=[!#6&!#1;!R])-[#6](=[!#6&!#1;!R])-[$([#6]),$([#16](=[#8])=[#8])]	imine_one_a_321_	15978	112	147	163	8	21000	10	1425
595	[!#1]1:[!#1]2:[!#1](:[!#1]:[!#1]:[!#1]:1)-[#7&!H0]-[#7](-[#6]-2=[#8])-[#6]	2	het_65_B(7)	8	1772735344	[!#1]:1:[!#1]-2:[!#1](:[!#1]:[!#1]:[!#1]:1)-[#7](-[#1])-[#7](-[#6]-2=[#8])-[#6]	het_65_b_7_	24	0	0	0	0	24	10	0
545	[#7&+](-,:[#6]:[#6])=,:[#6]-[#6&!H0]=[#6]-[#7](-[#6&X4])-[#6]	2	dyes3A(19)	8	1772735344	[#7+]([#6]:[#6])=,:[#6]-[#6](-[#1])=[#6]-[#7](-[#6;X4])-[#6]	dyes3a_19_	344	0	0	0	0	389	10	9
17	N=C=N	1	carbodiimides	1	1772715346	N=C=N	carbodiimides	2838	0	0	0	0	2848	70	26
26	P=S	1	lawssons-reagent	15	1772715346	P=S	lawssons-reagent	192	1	0	20	0	298	50	1
591	c1(:c:c:c:c:c:1)-[#7&!H0]-[#6](=[#16])-[#7]-[#7&!H0]-c1:c:c:c:c:c:1	2	thio_urea_D(8)	8	1772735344	c:1(:c:c:c:c:c:1)-[#7](-[#1])-[#6](=[#16])-[#7]-[#7](-[#1])-c:2:c:c:c:c:c:2	thio_urea_d_8_	442	0	0	0	0	450	10	18
559	[#6]1-[#6]-c2:c(:c:c:c:c:2)-[#6](-c2:c:c:c:c:c:2-1)=[#6]-[#6]	2	styrene_A(13)	8	1772735344	[#6]-2-[#6]-c:1:c(:c:c:c:c:1)-[#6](-c:3:c:c:c:c:c-2:3)=[#6]-[#6]	styrene_a_13_	128	0	6	7	7	229	10	17
582	[#7&!H0&!H1]-c1:[c&!H0]:[c&!H0]:c(:n:[c&!H0]:1)-[#8]-c1:c:c:c:c:c:1	2	anil_OC_no_alk_A(8)	8	1772735344	[#7](-[#1])(-[#1])-c:1:c(:c(:c(:n:c:1-[#1])-[#8]-c:2:c:c:c:c:c:2)-[#1])-[#1]	anil_oc_no_alk_a_8_	317	0	0	0	0	321	10	62
541	[#8]=[#6]-c1:,-c2:,-n:,-c(-[#6&!H0&!H1]):,-c:,-c(-[#8&!H0]):,-n:,-2:,-n:,-c:,-1	2	het_65_A(21)	8	1772735344	[#8]=[#6]-c2c1nc(-[#6](-[#1])-[#1])cc(-[#8]-[#1])n1nc2	het_65_a_21_	3058	0	0	0	0	3103	10	20
585	[#6&!H0&!H1]-[#16&X2]-c1:n:[c&!H0]:c(:n:1-&!@[#6&!H0&!H1])-c1:c:c:c:c:c:1	2	het_thio_5_A(8)	8	1772735344	[#6](-[#1])(-[#1])-[#16;X2]-c:1:n:c(:c(:n:1-!@[#6](-[#1])-[#1])-c:2:c:c:c:c:c:2)-[#1]	het_thio_5_a_8_	5216	1	0	0	0	5236	10	7
169	[#14&H1,#14&H2,#14&H3]	1	silane	1	1772715346	[#14&H1,#14&H2,#14&H3]	silane	4059	0	0	1	0	4208	70	286
108	[#7&R1&+]-[O&-]	1	n-oxide-cyclic	0	1772715346	[#7R1+]-[O-]	n-oxide-cyclic	87364	26	32	29	39	93019	0	772
554	c1(:c:c:c:c:c:1)-[#6&!H0]=&!@[#6]1-[#6](=[#8])-c2:c:c:c:c:c:2-[#16]-1	2	ene_five_het_F(15)	8	1772735344	c:1(:c:c:c:c:c:1)-[#6](-[#1])=!@[#6]-3-[#6](=[#8])-c:2:c:c:c:c:c:2-[#16]-3	ene_five_het_f_15_	822	0	0	0	0	825	10	93
547	[#7]~[#6]1:[#7]:[#7]:[#6](:[$([#7]),$([#6]-[#1]),$([#6]-[#7]-[#1])]:[$([#7]),$([#6]-[#7])]:1)-[$([#7]-[#1]),$([#8]-[#6](-[#1])-[#1])]	2	het_6_tetrazine(18)	8	1772735344	[#7]~[#6]:1:[#7]:[#7]:[#6](:[$([#7]),$([#6]-[#1]),$([#6]-[#7]-[#1])]:[$([#7]),$([#6]-[#7])]:1)-[$([#7]-[#1]),$([#8]-[#6](-[#1])-[#1])]	het_6_tetrazine_18_	0	0	0	0	0	0	10	0
578	c1:c:c2:c(:c:c:1)-[#7]=[#6]-[#6]-2=[#7&!R]	2	imine_imine_A(9)	8	1772735344	c:1:c:c-2:c(:c:c:1)-[#7]=[#6]-[#6]-2=[#7;!R]	imine_imine_a_9_	1346	0	0	0	0	1432	10	41
546	[#7&!H0&!H1]-[#6]1=[#6](-[#6]#[#7])-[#6&!H0](-[#6]:[#6])-[#6](=[#6](-[#7&!H0&!H1])-[#16]-1)-[#6]#[#7]	2	dhp_bis_amino_CN(19)	8	1772735344	[#7](-[#1])(-[#1])-[#6]-1=[#6](-[#6]#[#7])-[#6](-[#1])(-[#6]:[#6])-[#6](=[#6](-[#7](-[#1])-[#1])-[#16]-1)-[#6]#[#7]	dhp_bis_amino_cn_19_	134	1	0	0	0	134	10	81
524	c1:c:c:c:c(:c:1-[#7&!H0]-[!$([#6]=[#8])])-[#6](-[#6]:[#6])=[#8]	2	anthranil_one_A(38)	8	1772735344	c:1:c:c:c:c(:c:1-[#7&!H0;!H1,!$([#7]-[#6]=[#8])])-[#6](-[#6]:[#6])=[#8]	anthranil_one_a_38_	4093	3	0	7	1	5680	10	332
534	[#6&!H0&!H1]-[#7](-,:[#6]:[#6])~[#6]-,:[#6]=,:[#6]-[#6]~[#6]-,:[#7]	2	dyes5A(27)	8	1772735344	[#6](-[#1])(-[#1])-[#7]([#6]:[#6])~[#6][#6]=,:[#6]-[#6]~[#6][#7]	dyes5a_27_	28826	6	17	47	7	30573	10	252
484	[#6]1(-[#6](~[!#6&!#1]~[#6]-[!#6&!#1]-[#6]-1=[!#6&!#1])~[!#6&!#1])=[#6&!R&!H0]	2	ene_six_het_A(483)	8	1772735344	[#6]-1(-[#6](~[!#6&!#1]~[#6]-[!#6&!#1]-[#6]-1=[!#6&!#1])~[!#6&!#1])=[#6;!R]-[#1]	ene_six_het_a_483_	132761	16	0	0	0	133205	10	3109
556	c1(:[c&!H0]:[c&!H0]:c(:[c&!H0]:[c&!H0]:1)-[#7&!H0&!H1])-[#6]=[#7]-[#7&!H0]	2	hzone_anil(14)	8	1772735344	c:1(:c(:c(:c(:c(:c:1-[#1])-[#1])-[#7](-[#1])-[#1])-[#1])-[#1])-[#6]=[#7]-[#7]-[#1]	hzone_anil_14_	930	0	0	0	1	977	10	85
155	S(=O)(=O)-,:F	1	sulfonyl-fluoride	3	1772715346	S(=O)(=O)F	sulfonyl-fluoride	33495	0	0	0	0	34098	70	3922
58	[C&X4]-C#N	6	nitrile-Csp3	20	1772715346	[CX4]-C#N	nitrile-Csp3	11652324	182	228	401	39	11687250	30	25798
151	[#14]-,:O	1	silyl-ether	20	1772715346	[Si]O	silyl-ether	44386	10	2	4	3	47167	50	2731
2	[C&X4]-,:[S&D1]	1	thiol-Csp3	2	1772715346	[C&X4]-,:[S&D1]	thiol-Csp3	201218	9	542	430	14	207521	30	1888
15	P=C	1	phosphoranes	15	1772715346	P=C	phosphoranes	1120	0	0	0	0	1527	70	93
62	C-,:S(=O)(=O)-,:[O&D1]	1	aliphatic-sulfonate	0	1772715346	CS(=O)(=O)[OD1]	aliphatic-sulfonate	27683	47	98	166	21	29400	0	1253
14	S-,:C#N	1	thiocyanate	1	1772715346	S-,:C#N	thiocyanate	14692	2	5	6	0	15436	50	599
32	[N&D4&+]	1	quarternary-N	11	1772715346	[N&D4&+]	quarternary-n	24317	317	1624	1972	119	37758	5	2177
60	c-,:[S&D1]	1	aromatic-thiol	0	1772715346	c[SD1]	aromatic-thiol	1015550	0	14	20	12	1022867	0	7570
12	O-,:O	1	peroxide	15	1772715346	O-,:O	peroxide	6165	470	129	169	16	16198	50	354
147	c-,:[C&D2]=O	6	aldehyde-aromatic	0	1772715346	c[CD2]=O	aldehyde-aromatic	892370	424	356	444	7	905621	0	23577
77	c12:c(-[C&X4&D2]-[C&X4&D2]-[N&D2]-C-1(-[C&X4])-,:[C&X4]):c:c:c:c:2	1	pictet-spengler-ketone-product	0	1772715346	c12c([CX4D2][CX4D2][ND2]C1([CX4])[CX4])cccc2	pictet-spengler-ketone-product	112	4	0	0	0	136	0	22
13	N=C=[S,O]	1	iso(thio)cyanate	1	1772715346	N=C=[S,O]	iso_thio_cyanate	44922	7	57	63	2	46307	50	2196
113	[C&X3]-,:C(=O)-,:O-,:[C&X3]	1	ester-sp2-sp2	0	1772715346	[CX3]C(=O)O[CX3]	ester-sp2-sp2	39820	499	49	58	0	42419	0	341
35	C=[N&R0]-,:*	1	imines	1	1772715346	C=[N&R0]-,:*	imines	4580705	850	704	1200	166	4675098	30	68496
41	[#8&D2]-,:[#5](-,:[#6])-,:[#8&D2]	1	boronic ester	15	1772715346	R-OB(C)O-R	protected-boronic	136452	0	0	1	1	137989	30	7588
69	[C&X4]-,:[C&X3](=[C&D1])-,:[C&X4]	1	alkene-internal-sp3	0	1772715346	[CX4][CX3](=[CD1])[CX4]	alkene-internal-sp3	1766429	3687	3032	3983	26	1802017	30	3665
131	[C&X3]-,:[#50](-,:[C&X4])(-,:[C&X4])-,:[C&X4]	1	stannanes	0	1772715346	CX3][Sn]([CX4])([CX4])[CX4]	stannanes	547	0	0	0	0	550	0	26
110	[C&X4]-,:C(=O)-,:[N&X3&D2]-,:[O&D1]	1	hydroxamate-sp3	1	1772715346	[CX4]C(=O)[NX3D2][OD1]	hydroxamate-sp3	6886	0	0	4	0	15462	5	189
122	[C&X3]-,:C(=O)-,:Br	1	acyl-bromide-sp2	1	1772715346	[CX3]C(=O)Br	acyl-bromide-sp2	24	0	0	0	0	24	50	2
123	[C&X4]-,:C(=O)-,:I	1	acyl-iodide-sp3	1	1772715346	[CX4]C(=O)I	acyl-iodide-sp3	21	0	0	0	0	22	50	5
149	[C&D1]=[C&D2]-C(=O)-[N&X3]	6	acrylamide-terminal	0	1772715346	[CD1]=[CD2]-C(=O)-[NX3]	acrylamide-terminal	84576	1	5	6	1	86452	0	799
127	[C&X3]~[C&X3]-,:I	1	vinyl-iodide	0	1772715346	[CX3]=,~[CX3]I	vinyl-iodide	4712	0	0	1	0	5714	0	178
66	[C&X4]-,:[C&X3]=[C&X3&D1]	1	alkene-terminal-sp3	0	1772715346	[CX4][CX3]=[CX3D1]	alkene-terminal-sp3	9128668	8089	4809	6341	102	9216401	30	23476
170	[#6]-[#7]-[#16](=[#8])(=[#8])-[#6&X3&D2]=[#6&X3&D1]	1	vinyl-sulfonamide-terminal	1	1772715346	[#6]-[#7]-[#16](=[#8])(=[#8])-[#6X3D2]=[#6X3D1]	vinyl-sulfonamide-terminal	1858	0	0	0	0	2190	0	6
100	c1=,:n-,:n=,:n-,:[n&H1]-,:1	6	tetrazole	1	1772715346	c1nnn[nH]1	tetrazole	95160	1	6	21	10	100035	0	1048
9	F.F.F.F.F.F.F	1	7+ fluorines	13	1772715346	F.F.F.F.F.F.F	per-fluorinated	148737	6	1	21	6	157478	30	4074
29	[C&+,Cl&+,I&+,P&+,S&+]	1	quarts	11	1772715346	[C&+,Cl&+,I&+,P&+,S&+]	quarts	18976	1192	7	12	13	21395	30	657
132	[#14&X4](-,:[C&X4])(-,:[C&X4])-,:[C&X4]	1	silanes	0	1772715346	[SiX4]([CX4])([CX4])[CX4]	silanes	98717	10	1	1	1	102209	0	3751
67	[C&X3]-,:[C&X3]=[C&X3&D1]	1	alkene-terminal-sp2	0	1772715346	[CX3][CX3]=[CX3D1]	alkene-terminal-sp2	270187	3169	881	1121	27	293010	0	3370
21	C-,:O-,:S(=O)(=O)-,:[C,c]	1	sulfonates	1	1772715346	C-,:O-,:S(=O)(=O)-,:[C,c]	sulfonates	26866	35	1	16	3	29385	30	2106
84	[C&X4;C&H1,C&H2]-,:I	1	alkyl-iodide	3	1772715346	[C&X4;C&H1,C&H2]-I	alkyl-iodide	70189	15	3	31	5	71482	50	2754
82	[C&X4;C&H1,C&H2]-,:Br	1	alkyl-bromide	3	1772715346	[C&X4;C&H1,C&H2]-[Br]	alkyl-bromide	1787944	39	7	29	3	1811014	50	18021
36	[#7]-,:O-,:[#6,#16]=O	1	Aminooxy(oxo)	1	1772715346	[#7]-,:O-,:[#6,#16]=O	aminooxy_oxo_	26458	57	314	449	0	30401	30	3461
10	O=C-,:N=[N&+]=[N&-]	1	carbazides	10	1772715346	O=C-,:N=[N&+]=[N&-]	carbazides	2147	0	0	0	0	2160	70	38
75	[C&X3]-,:C(=O)-,:[C&X4]	1	ketone-mixed	0	1772715346	[CX3]C(=O)[CX4]	ketone-mixed	628857	5215	3324	4371	139	712681	0	31228
111	[C&X3]-,:C(=O)-,:[N&X3&D2]-,:[O&D1]	1	hydroxamate-sp2	1	1772715346	[CX3]C(=O)[NX3D2][OD1]	hydroxamate-sp2	451	0	0	0	0	1926	5	17
61	c-,:S(=O)(=O)-,:[O&D1]	1	aromatic-sulfonate	0	1772715346	cS(=O)(=O)[OD1]	aromatic-sulfonate	14401	4	43	75	5	18185	0	2212
30	[N&R0]-,:[N&R0]-,:C=O	1	acylhydrazides	1	1772715346	[N&R0]-,:[N&R0]-,:C=O	acylhydrazides	6197217	83	12	90	20	6222348	50	40438
31	C(=O)-,:C-,:[N&+,n&+]	1	beta-carbonyl-quarternary-N	1	1772715346	C(=O)-,:C-,:[N&+,n&+]	beta-carbonyl-quarternary-n	43082	20	71	129	3	45789	30	1259
70	[O&D1]-C(=O)-,:[C&X4]	1	carboxylate-sp3	1	1772715346	[O&D1]-C(=O)[CX4]	carboxylate-sp3	14540228	7962	10851	11958	840	14741498	0	130508
124	[C&X3]-,:C(=O)-,:I	1	acyl-iodide-sp2	1	1772715346	[CX3]C(=O)I	acyl-iodide-sp2	1	0	0	0	0	1	50	0
150	c1:,-c:,-o:,-c(-c):,-n@1	6	benzoxazole	0	1772715346	c1coc(-c)n@1	benzoxazole	1937713	66	2	17	0	1955690	0	8548
1	[C&X4]-,:[C&D2]=O	6	aldehyde-Csp3	1	1772715346	[CX4][CD2]=O	aldehyde-Csp3	279619	873	931	1130	17	291498	30	5336
40	[#8&D1]-,:[#5](-,:[#6])-,:[#8&D1]	1	boronic acid	3	1772715346	HOB(C)OH	unprotected-boronic	220123	0	1	2	1	221335	50	7096
89	[C&X4]-,:[S&D3](=O)-,:[C&X4]	1	sulfoxide	0	1772715346	[CX4][SD3](=O)[CX4]	sulfoxide	4427414	18	166	222	4	4431810	0	1578
121	[C&X4]-,:C(=O)-,:Br	1	acyl-bromide-sp3	1	1772715346	[CX4]C(=O)Br	acyl-bromide-sp3	186	0	0	0	0	195	50	40
42	F-,:[#5](-,:F)-,:F	1	Trifluoroborate	3	1772715346	FB(F)F	trifluoroborate	22712	0	0	0	0	22720	70	686
3	S(=O)(=O)-,:[Cl,Br]	1	sulfonyl-halide	3	1772715346	S(=O)(=O)-,:[Cl,Br]	sulfonyl-halide	140664	0	0	0	0	144531	70	6681
119	[C&X4]-,:C(=O)-,:Cl	1	acyl-chloride-sp3	1	1772715346	[CX4]C(=O)Cl	acyl-chloride-sp3	11045	0	0	2	0	11301	50	1751
133	[C&X4]-,:B(-,:F)(-,:F)-,:F	1	boron-trifluoride	0	1772715346	[CX4][B](F)(F)F	boron-trifluoride	7290	0	0	0	0	7292	0	222
163	Br-[c:1]:[c&r6]-[N&D1]	1	aniline-2-bromo	1	1772715346	[Br]-[c:1]:[c&r6]-[N&D1]	aniline-2-bromo	110640	3	0	1	4	111638	0	1910
52	[#14]-[I,Br,Cl,F]	1	silicon-halide	1	1772715346	[Si]-[I,Br,Cl,F]	silicon-halide	2776	0	0	0	0	2836	70	474
114	[C&X4]-,:C(=O)-,:O-,:[C&X3]	1	ester-sp3-sp2	0	1772715346	[CX4]C(=O)O[CX3]	ester-sp3-sp2	20670	296	32	32	0	22823	0	1548
74	[C&X3]-,:C(=O)-,:[C&X3]	1	ketone-sp2-sp2	0	1772715346	[CX3]C(=O)[CX3]	ketone-sp2-sp2	170163	751	400	622	75	195226	0	2731
71	[O&D1]-C(=O)-,:[#6&X3]	1	carboxylate-sp2	1	1772715346	[O&D1]-C(=O)[#6X3]	carboxylate-sp2	4661897	2847	1302	1865	199	4759524	0	72810
59	C1-O-C-,:1	1	epoxide	20	1772715346	C1OC1	epoxide	121938	995	695	968	41	133062	30	4194
86	[C&X4]-,:[S&R1](=O)(=O)-,:[N&D3]	1	tertiary-sultam	0	1772715346	[CX4][SR1](=O)(=O)[ND3]	tertiary-sultam	890748	0	0	1	0	894056	0	485
18	N#C-,:C-,:[O&H1]	1	cyanohydrines	1	1772715346	N#C-,:C-,:[O&H1]	cyanohydrines	22900	4	2	5	0	22947	50	301
118	[C&X3]-,:[N&+]#[C&-]	1	isonitrile-sp2	1	1772715346	[CX3][N+]#[C-]	isonitrile-sp2	209	0	0	1	0	306	50	8
166	[#6]-C(=O)-[N&X3]-[O&D1]	1	hydroxamate	1	1772715346	[#6]-C(=O)-[NX3]-[OD1]	hydroxamate	25718	27	33	64	5	41893	30	734
64	[#6&X4]-[N&+](=O)-[O&-]	1	nitro-sp3	1	1772715346	[#6X4]-[N+](=O)-[O-]	nitro-sp3	58592	20	15	25	0	62058	5	1998
146	[c&r6:1](-[S&D1:2]):[c&r6:3]-[N&D1:4]	1	aminobenzenethiol	0	1772715346	[cr6]([SD1])[c&r][ND1]	aminobenzenethiol	1603	0	0	0	0	1611	0	84
83	[C&X4;C&H1,C&H2]-,:Cl	1	alkyl-chloride	3	1772715346	[C&X4;C&H1,C&H2]-[Cl]	alkyl-chloride	2634656	237	165	372	76	2671885	50	30775
25	O-,:S(=O)(=O)-,:C(-,:F)(-,:F)-,:F	1	triflates	15	1772715346	O-,:S(=O)(=O)-,:C(-,:F)(-,:F)-,:F	triflates	4241	0	1	2	0	4613	70	479
24	C(=O)-,:O-,:n:,-n:,-n	1	HOBt-esters	1	1772715346	C(=O)-,:O-,:n:,-n:,-n	hobt-esters	64	0	0	0	0	91	70	17
79	[c&r6:1](-[N&X3&D2:2]):[c&r6:3]-[N&D1:4]	1	ortho-aryldiamine	0	1772715346	[cr6:1](-[NX3D2:2]):[cr6:3]-[ND1:4]	ortho-aryldiamine	486330	2	19	19	1	490064	0	2306
107	c1-,:n=,:n-,:[n&H1]-,:n=,:1	6	tetrazole2	1	1772715346	c1nn[nH]n1	tetrazole2	595096	0	0	2	4	595729	0	501
63	[#6&X3]-[N&+](=O)-[O&-]	1	nitro-sp2	1	1772715346	[#6X3]-[N+](=O)-[O-]	nitro-sp2	19221405	373	29	232	61	19345526	5	80507
101	[C&D2]#[C&D2]	6	alkyne-internal	20	1772715346	[CD2]#[CD2]	alkyne-internal	1324883	2599	479	611	17	1407263	30	6934
28	c-,:N=[N&+]=[N&-]	1	aromatic-azide	1	1772715346	c-,:N=[N&+]=[N&-]	aromatic-azide	4399	0	0	1	0	5544	30	454
8	O-,:Cl(-,:O)(-,:O)-,:O	1	perchlorates	15	1772715346	O-,:[Cl](-,:O)(-,:O)-,:O	perchlorates	44	0	0	1	0	46	70	1
22	C(=O)-,:O-,:c1:,-c(-,:F):,-c(-,:F):,-c(-,:F):,-c(-,:F):,-c:,-1-,:F	1	pentafluorophenyl-esters	1	1772715346	C(=O)-,:O-,:c1:,-c(-,:F):,-c(-,:F):,-c(-,:F):,-c(-,:F):,-c:,-1-,:F	pentafluorophenyl-esters	360	0	0	0	0	391	70	178
125	[C&X3]~[C&X3]-,:Br	1	vinyl-bromide	0	1772715346	[CX3]=,~[CX3]Br	vinyl-bromide	175954	19	0	38	0	180148	0	2069
4	[S,C](=[O,S])-,:[F,Br,Cl,I]	1	acid-halide	3	1772715346	[S,C](=[O,S])-,:[F,Br,Cl,I]	acid-halide	212540	0	0	2	0	217737	50	17387
115	[C&X3]-,:C(=O)-,:O-,:[C&X4]	1	ester-sp2-sp3	0	1772715346	[CX3]C(=O)O[CX4]	ester-sp2-sp3	1769943	5813	3349	4594	43	1839528	0	9922
16	[P,S]-,:[Cl,Br,F,I]	1	p-s-halides	15	1772715346	[P,S]-,:[Cl,Br,F,I]	p-s-halides	220938	0	1	2	1	228878	50	12240
37	S-,:S	1	disulfide	10	1772715346	S-,:S	disulfide	55820	1462	270	328	23	64156	50	1048
11	C(=O)-,:O-,:C=O	1	acid-anhydride	1	1772715346	C(=O)-,:O-,:C=O	acid-anhydride	16602	27	27	27	1	18005	50	1847
91	C#[C&D1]	6	alkyne-terminal	20	1772715346	C#[CD1]	alkyne-terminal	3359228	362	61	165	45	3370495	30	9243
117	[C&X4]-,:[N&+]#[C&-]	1	isonitrile-sp3	1	1772715346	[CX4][N+]#[C-]	isonitrile-sp3	7207	1	0	0	0	7519	50	419
65	[#6&X3]-,:C#N	1	nitrile-Csp2	1	1772715346	[#6X3]C#N	nitrile-Csp2	16226730	1082	91	224	26	16310944	30	60138
164	I-[c:1]:[c&r6]-[N&D1]	1	aniline-2-iodo	1	1772715346	I-[c:1]:[c&r6]-[N&D1]	aniline-2-iodo	20569	0	0	6	2	21079	0	355
34	N#C-,:C=C	1	acrylonitriles	1	1772715346	N#C-,:C=C	acrylonitriles	942462	179	86	154	6	954068	50	22311
33	C=C-,:C(=O)-,:[!#7&!#8]	1	Propenals	1	1772715346	C=C-,:C(=O)-,:[!#7&!#8]	propenals	1423358	6465	3820	5110	244	1541123	30	44587
116	[O&D1]-,:[n&+]1:,-c:,-c:,-c:,-c:,-c:,-1	1	pyridine-n-oxide	0	1772715346	[OD1][n+]1ccccc1	pyridine-n-oxide	82068	5	7	15	13	84270	0	628
154	[C&D1]-,:[#14](-,:[C&D1])(-,:[C&D1])-,:C#C-,:[#6]	1	alkyne-tms	0	1772715346	[CD1][Si]([CD1])([CD1])C#C[#6]	alkyne-tms	5550	0	0	0	0	5664	0	379
148	[O&D1]-,:c1:,-c:,-c:,-c:,-c:,-c:,-1-,:[N&D1]	6	aminophenol	0	1772715346	[OD1]c1ccccc1[ND1]	aminophenol	26993	1	4	6	1	27502	0	517
78	c12:c(-[C&X4&D2]-[C&X4&D2]-[N&D2]-C-1-[C&X4]):c:c:c:c:2	1	pictet-spengler-aldehyde-product	0	1772715346	c12c([CX4D2][CX4D2][ND2]C1[CX4])cccc2	pictet-spengler-aldehyde-product	50698	100	43	51	1	51850	0	356
76	[N&D1]-,:[C&X4&D2]-,:[C&X4&D2]-,:c1:,-c:,-c:,-c:,-c:,-c:,-1	6	beta-arylenylamine	0	1772715346	[ND1][CX4D2][CX4D2]c1ccccc1	beta-arylenylamine	127056	3	15	10	5	127273	0	531
23	C(=O)-,:O-,:c1:,-c:,-c:,-c(-,:[N&+](=O)-,:[O&-]):,-c:,-c:,-1	1	paranitrophenyl-esters	1	1772715346	C(=O)-,:O-,:c1:,-c:,-c:,-c(-,:[N+](=O)[O-]):,-c:,-c:,-1	paranitrophenyl-esters	28045	0	2	3	0	28299	50	454
68	[C&X3]-[C&X3]=[C&X3;D2,D3]	1	alkene-internal-sp2	14	1772517372	[CX3][CX3]=[CX3;D2,D3]	alkene-internal-sp2	1337257	5609	3537	4917	369	1429083	0	113365
45	[C&D4&X4]-,:[O&D1]	1	alcohol-tertiary	14	1772517372	[CD4X4][OD1]	alcohol-tertiary	646759	763	588	1022	250	648873	0	27197
39	C=C-,:C=C-,:C=C-,:C=C-,:C=C-,:C=C-,:C=C	1	chromophore-congugation	5	1772715346	C=CC=CC=CC=CC=CC=CC=C	chromophore-congugation	424	111	553	629	15	2733	5	136
130	[C&X4]-,:[N&D3]-,:[S&R](=O)(=O)-,:O-,:[C&X4]	1	sulfamidates	0	1772715346	[CX4][ND3][SR](=O)(=O)O[CX4]	sulfamidates	161	0	0	0	0	185	0	32
38	a:a:a:a:a:a:a:a:a:a:a:a:a:a	1	chromophore-aromatic	5	1772715346	a:a:a:a:a:a:a:a:a:a:a:a:a:a	chromophore-aromatic	176155	797	704	925	36	211368	5	5607
7	[C&D1]-,:[C&D2]-,:[C&D2]-,:[C&D2]-,:[C&D2]-,:[C&D2]-,:[C&D2]	1	heptanes	12	1772715346	[C&D1]-,:[C&D2]-,:[C&D2]-,:[C&D2]-,:[C&D2]-,:[C&D2]-,:[C&D2]	heptanes	428395	1309	28536	32314	32	517594	30	10649
153	[N&D1]-,:c1:,-[c,n]:,-[c,n]:,-[c,n]:,-[c,n]:,-[c,n]:,-1	1	aniline	14	1772517372	[ND1]c1[c,n][c,n][c,n][c,n][c,n]1	aniline	1310892	121	257	472	127	1311226	0	63823
167	C-c1:c:c(-[C&D2]=O):c:c:c:1	1	benzaldehyde-meta	14	1772517372	C-c1cc([CD2]=O)ccc1	benzaldehyde-meta	76605	143	189	245	2	79215	0	2014
43	[C&D2&X4]-,:[O&D1]	1	alcohol-primary	14	1772517372	[CD2X4][OD1]	alcohol-primary	1363018	1514	1596	2077	264	1364205	0	66578
162	[C&X4]-[N&D2]-[C&X4]	1	amine-sp3-2	14	1772517372	[CX4][ND2][CX4]	amine-sp3-2	5983664	528	440	1052	380	5984566	0	146562
152	[C&X4]-,:[N&D1]	1	amine-sp3-1	14	1772517372	[CX4][ND1]	amine-sp3-1	3654075	249	1393	1449	188	3655141	0	108766
102	[C&X4]-,:[C&R1](=O)-,:[C&X4]	6	lactone	14	1772517372	[CX4][CR1](=O)[CX4]	lactone	206027	204	297	423	58	206468	0	14839
46	[N&D1]-,:[S&R0](=O)=O	1	sulfonamide-primary	14	1772517372	[ND1][SR0](=O)=O	sulfonamide-primary	107186	1	3	66	40	107202	0	5830
105	[C&X4]-,:[C&r5](=O)-,:[N&X3]-,:[C&X4]	6	lactam-gamma	14	1772517372	[CX4][C;r5](=O)[NX3][CX4]	lactam-gamma	314920	44	43	130	36	315216	0	31147
72	[C&X4]-,:[C&R1](=O)-,:[C&X4]	1	ketone-cyclic-sp3-sp3	14	1772517372	[CX4][CR1](=O)[CX4]	ketone-cyclic-sp3-sp3	206029	204	297	423	58	206468	0	14164
157	O=C-,:[C&X4&H1]-,:[#6]	1	enolizable ketone	14	1772517372	O=C[CX4H1][#6]	hartwig-2	3764027	1516	3206	3889	625	3767090	0	237025
104	[C&X4]-,:[C&r4](=O)-,:[N&X3]-,:[C&X4]	6	lactam-beta	14	1772517372	[CX4][C;r4](=O)[NX3][CX4]	lactam-beta	21906	8	17	165	67	21970	0	4168
103	[C&X4]-,:[C&R1](=O)-,:[N&X3]-,:[C&X4]	6	lactam	14	1772517372	[CX4][CR1](=O)[NX3][CX4]	lactam	609587	292	92	419	147	610080	0	53252
172	[C&X4&!H0]-[C&R&!r3](=O)-[C&X4&D4]	1	cyclic enolizable ketone one side only	14	1772517372	[C&X4&!H0]-[CR!r3](=O)-[C&X4D4]	hartwig-1235	35229	167	117	157	25	35390	0	3589
106	[C&X4]-,:[C&r6](=O)-,:[N&X3]-,:[C&X4]	6	lactam-delta	14	1772517372	[CX4][C;r6](=O)[NX3][CX4]	lactam-delta	222236	172	21	66	24	222336	0	14985
142	[C&X4]-,:c1:,-n:,-[n&H1]:,-c(-,:[C&X4]):,-n:,-1	6	tetrazole-1,2,4-sub3,5	14	1772517372	[CX4]c1n[nH]c([CX4])n1	tetrazole-1-2-4-sub3-5	9640	0	0	0	0	9640	0	1399
168	C-c1:c:c:c(-[C&D2]=O):c:c:1	1	benzaldehyde-para	14	1772517372	C-c1ccc([CD2]=O)cc1	benzaldehyde-para	41557	123	35	40	0	42831	0	831
161	O=C-,:[C&X4&H1]-,:S(=O)(=O)-,:[#6,#7]	1	hartwig3	14	1772517372	O=C[CX4H1]S(=O)(=O)[#6,#7]	hartwig-3	25094	0	0	0	0	25098	0	930
81	[O&D1]-c1:,-c:,-c:,-c:,-c:,-c:,-1-[#8]-[#6]	7	Reaction pattern	14	1772517372	[OD1]c1ccccc1OC	ortho-methoxy-phenol	38082	621	391	450	41	38194	0	8726
141	[C&X4]-,:c1:,-n(-,:[C&X4]):,-n:,-n:,-n:,-1	6	tetrazole-1,5	14	1772517372	[CX4]c1n([CX4])nnn1	tetrazole-1,5	21003	0	0	1	0	21005	0	426
140	[C&X4]-,:c1:,-n:,-n(-,:[C&X4]):,-n:,-n:,-1	6	tetrazole-2,5	14	1772517372	[CX4]c1nn([CX4])nn1	tetrazole-2,5	16546	0	0	2	0	16547	0	169
112	[C&X4]-,:C(=O)-,:O-,:[C&X4]	1	ester-sp3-sp3	14	1772517372	[CX4]C(=O)O[CX4]	ester-sp3-sp3	709245	577	959	1295	119	710661	0	55357
88	[C&X4]-,:[S&R0](=O)(=O)-,:[C&X4]	1	sulfone-acyclic	14	1772517372	[CX4][SR0](=O)(=O)[CX4]	sulfone-acyclic	216110	3	5	13	4	216136	0	13059
87	[C&X4]-,:[S&R1](=O)(=O)-,:[C&X4]	1	sulfone-cyclic	14	1772517372	[CX4][SR1](=O)(=O)[CX4]	sulfone-cyclic	188548	5	3	14	2	188561	0	17703
173	[C&X4&H2]-[C&R&!r3](=O)-[C&X4&H1]	1	cyclic enolizable ketone, steric control	14	1772517372	[C&X4&H2]-[C&R&!r3](=O)-[C&X4H1]	hartwig-1236	102001	51	131	190	22	102200	0	6695
156	O=C-,:[C&X4&H1]-,:C#N	1	hartwig1	14	1772517372	O=C[CX4H1]C#N	hartwig-1	35656	0	0	2	0	35681	0	1836
174	[C&X4&!H0]-[C&R&!r3](=O)-c	1	cyclic enolizable ketone, aryl one side	14	1772517372	[C&X4!H0]-[C&R&!r3](=O)-c	hartwig-1237	43594	278	178	215	15	43719	0	6631
899	[#6&!H0]1(-n2:[c&!H0]:n:[c&!H0]:[c&!H0]:2)-c2:c(:[c&!H0]:[c&!H0]:c(:[c&!H0]:2)-Br)-[#6&!H0&!H1]-[#6&!H0&!H1]-c2:c-1:[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:2	2	imidazole_C(1)	8	1772697397	[#6]-3(-[#1])(-n:1:c(:n:c(:c:1-[#1])-[#1])-[#1])-c:2:c(:c(:c(:c(:c:2-[#1])-[Br])-[#1])-[#1])-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-c:4:c-3:c(:c(:c(:c:4-[#1])-[#1])-[#1])-[#1]	imidazole_c_1_	0	0	0	0	0	0	10	0
885	[#7]1(-c2:c:c:c:c:c:2)-[#6](=[#8])-[#16]-[#6&!H0](-[#7&!H0]-c2:c:c:c:c3:c:c:c:c:c:2:3)-[#6]-1=[#8]	2	rhod_sat_E(1)	8	1772697397	[#7]-4(-c:1:c:c:c:c:c:1)-[#6](=[#8])-[#16]-[#6](-[#1])(-[#7](-[#1])-c:2:c:c:c:c:3:c:c:c:c:c:2:3)-[#6]-4=[#8]	rhod_sat_e_1_	16	0	0	0	0	16	10	4
866	c1:c(:c:c:c:c:1)-[#6&!H0]-[#7]-[#6](=[#8])-[#6](-[#7&!H0]-[#6&!H0&!H1])=[#6&!H0]-[#6](=[#8])-c1:c:c:c(:c:c:1)-[#8]-[#6&!H0&!H1]	2	ene_one_amide_A(1)	8	1772697397	c:1:c(:c:c:c:c:1)-[#6](-[#1])-[#7]-[#6](=[#8])-[#6](-[#7](-[#1])-[#6](-[#1])-[#1])=[#6](-[#1])-[#6](=[#8])-c:2:c:c:c(:c:c:2)-[#8]-[#6](-[#1])-[#1]	ene_one_amide_a_1_	8	0	0	0	0	8	10	4
924	c12:[c&!H0]:[c&!H0]:[c&!H0]:c(:c:1-[#8]-[#6&!H0&!H1]-[#8]-2)-[#6&!H0&!H1]-[#7]1-[#6&!H0&!H1]-[#6&!H0&!H1]-[#6]:[#6]-1	2	het_65_mannich(1)	8	1772697397	c:1-2:c(:c(:c(:c(:c:1-[#8]-[#6](-[#1])(-[#1])-[#8]-2)-[#6](-[#1])(-[#1])-[#7]-3-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#6]:[#6]-3)-[#1])-[#1])-[#1]	het_65_mannich_1_	5	0	0	0	0	5	10	0
860	c12:c(:[c&!H0]:c(:[c&!H0]:[c&!H0]:1)-[#7](-[#6&!H0&!H1])-[#6&!H0&!H1]):c(:[c&!H0]:[n&!H0]:2)-[#16](=[#8])=[#8]	2	anil_di_alk_indol(1)	8	1772697397	c:1:2:c(:c(:c(:c(:c:1-[#1])-[#1])-[#7](-[#6](-[#1])-[#1])-[#6](-[#1])-[#1])-[#1]):c(:c(-[#1]):n:2-[#1])-[#16](=[#8])=[#8]	anil_di_alk_indol_1_	2	0	0	0	0	2	10	1
941	[#8]=[#6]-[#6]1=[#6](-[#16]-[#6](=[#6&!H0]-[#6])-[#16]-1)-[#6]=[#8]	2	ene_one_one_A(1)	8	1772697397	[#8]=[#6]-[#6]-1=[#6](-[#16]-[#6](=[#6](-[#1])-[#6])-[#16]-1)-[#6]=[#8]	ene_one_one_a_1_	7	0	0	0	0	8	10	2
794	[#6](-c1:c:c:c(:c:c:1)-[#8&!H0])(-c1:c:c:c(:c:c:1)-[#8&!H0])-[#8]-[#16](=[#8])=[#8]	2	phenol_sulfite_A(1)	8	1772697389	[#6](-c:1:c:c:c(:c:c:1)-[#8]-[#1])(-c:2:c:c:c(:c:c:2)-[#8]-[#1])-[#8]-[#16](=[#8])=[#8]	phenol_sulfite_a_1_	41	0	1	3	0	82	10	30
844	c1(:c2:c:c:c:c:c:2:c2:c(:c:1)-[#6](-c1:c:c:c:c:c:1-2)=[#8])-[#8&!H0]	2	keto_phenone_C(1)	8	1772697397	c:2(:c:1:c:c:c:c:c:1:c-3:c(:c:2)-[#6](-c:4:c:c:c:c:c-3:4)=[#8])-[#8]-[#1]	keto_phenone_c_1_	3	0	0	0	0	3	10	0
896	[#7&!H0](-c1:[c&!H0]:[c&!H0]:c(:[c&!H0]:[c&!H0]:1)-[#6&!H0](-[#6&!H0&!H1])-[#6&!H0&!H1])-[#6&!H0&!H1]-[#6&!H0&!H1]-[#7](-[#6&!H0&!H1])-[#6&!H0&!H1]	2	anil_alk_D(1)	8	1772697397	[#7](-[#1])(-c:1:c(:c(:c(:c(:c:1-[#1])-[#1])-[#6](-[#1])(-[#6](-[#1])-[#1])-[#6](-[#1])-[#1])-[#1])-[#1])-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#7](-[#6](-[#1])-[#1])-[#6](-[#1])-[#1]	anil_alk_d_1_	41	0	0	0	0	41	10	0
865	c1:c2:c(:c:c:c:1):c(:c1:c(:c:2):c:c:c:c:1)-[#6]=[#7]-[#7&!H0]-c1:c:c:c:c:c:1	2	hzone_anthran_Z(1)	8	1772697397	c:1:c:2:c(:c:c:c:1):c(:c:3:c(:c:2):c:c:c:c:3)-[#6]=[#7]-[#7](-[#1])-c:4:c:c:c:c:c:4	hzone_anthran_z_1_	21	0	0	0	0	21	10	4
888	[#7]1(-[#6&!H0&!H1])-[#6](=[#16])-[#7](-[#6]:[#6])-[#6](=[#7]-[#6]:[#6])-[#6]-1=[#7]-[#6]:[#6]	2	het_thio_5_imine_B(1)	8	1772697397	[#7]-1(-[#6](-[#1])-[#1])-[#6](=[#16])-[#7](-[#6]:[#6])-[#6](=[#7]-[#6]:[#6])-[#6]-1=[#7]-[#6]:[#6]	het_thio_5_imine_b_1_	14	0	0	0	0	14	10	0
902	c1(:n:c(:[c&!H0]:s:1)-c1:c:c:c:c:c:1)-[#6&!H0](-[#6&!H0&!H1])-[#6&!H0&!H1]-[#6&!H0&!H1]-[#7]-[#6&!H0&!H1]-c1:c:c:c:[n&!H0]:1	2	misc_pyrrole_thiaz(1)	8	1772697397	c:1(:n:c(:c(-[#1]):s:1)-c:2:c:c:c:c:c:2)-[#6](-[#1])(-[#6](-[#1])-[#1])-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#7]-[#6](-[#1])(-[#1])-c:3:c:c:c:n:3-[#1]	misc_pyrrole_thiaz_1_	0	0	0	0	0	0	10	0
958	[#6]1(-[#6](=[#8])-[#6&!H0&!H1]-[#6]-[#6&!H0&!H1]-[#6]-1=[#8])=[#6](-[#7&!H0])-[#6]=[#8]	2	ene_one_one_B(1)	8	1772697397	[#6]-1(-[#6](=[#8])-[#6](-[#1])(-[#1])-[#6]-[#6](-[#1])(-[#1])-[#6]-1=[#8])=[#6](-[#7]-[#1])-[#6]=[#8]	ene_one_one_b_1_	1	0	0	0	0	1	10	0
847	c1(-,:n:,-c2:c(:[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:2):,-n:,-1-[#6])-[#7&!H0]-[#6](-[#7&!H0]-c1:[c&!H0]:c:c:c:[c&!H0]:1)=[#8]	2	het_65_imidazole(1)	8	1772697397	c2(nc:1:c(:c(:c(:c(:c:1-[#1])-[#1])-[#1])-[#1])n2-[#6])-[#7](-[#1])-[#6](-[#7](-[#1])-c:3:c(:c:c:c:c:3-[#1])-[#1])=[#8]	het_65_imidazole_1_	31	0	0	0	0	31	10	0
956	n1(-c2:c(:[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:2)-[#6](=[#8])-[#7&!H0]-[#6&!H0](-[#6&!H0&!H1])-[#6&!H0&!H1]-[#8]-[#6]:[#6]):,-[c&!H0]-,:[c&!H0]:,-[c&!H0]-,:[c&!H0]:,-1	2	misc_pyrrole_benz(1)	8	1772697397	n2(-c:1:c(:c(:c(:c(:c:1-[#1])-[#1])-[#1])-[#1])-[#6](=[#8])-[#7](-[#1])-[#6](-[#1])(-[#6](-[#1])-[#1])-[#6](-[#1])(-[#1])-[#8]-[#6]:[#6])c(c(-[#1])c(c2-[#1])-[#1])-[#1]	misc_pyrrole_benz_1_	0	0	0	0	0	0	10	0
882	[#6]1:[#6]-[#6](=[#8])-[#6]=[#6]-1-[#7]=[#6&!H0]-[#7](-[#6&X4])-[#6&X4]	2	imine_ene_one_B(1)	8	1772697397	[#6]-1:[#6]-[#6](=[#8])-[#6]=[#6]-1-[#7]=[#6](-[#1])-[#7](-[#6;X4])-[#6;X4]	imine_ene_one_b_1_	1	0	0	0	0	1	10	0
944	[#8&!H0]-[#6](=[#8])-c1:[c&!H0]:[c&!H0]:c(:[c&!H0]:c:1-[#8&!H0])-c1:[c&!H0]:[c&!H0]:c(:o:1)-[#6&!H0]=[#6](-[#6]#[#7])-c1:n:c:c:n:1	2	ene_cyano_F(1)	8	1772697397	[#8](-[#1])-[#6](=[#8])-c:1:c(:c(:c(:c(:c:1-[#8]-[#1])-[#1])-c:2:c(-[#1]):c(:c(:o:2)-[#6](-[#1])=[#6](-[#6]#[#7])-c:3:n:c:c:n:3)-[#1])-[#1])-[#1]	ene_cyano_f_1_	3	0	0	0	0	3	10	1
907	n1:c(:c(:c(:c(:c:1-[#16&X2]-c1:c:c:c:c:c:1-[#7&!H0&!H1])-[#6]#[#7])-c1:c:c:c:c:c:1)-[#6]#[#7])-[#7&!H0&!H1]	2	cyano_amino_het_B(1)	8	1772697397	n:1:c(:c(:c(:c(:c:1-[#16;X2]-c:2:c:c:c:c:c:2-[#7](-[#1])-[#1])-[#6]#[#7])-c:3:c:c:c:c:c:3)-[#6]#[#7])-[#7](-[#1])-[#1]	cyano_amino_het_b_1_	1	0	0	0	0	4	10	0
873	c1:c(:c:c:c:c:1)-[#7]1-[#6](=[#8])-[#6](=[#6&!H0]-[#6]-1=[#8])-[#16]-c1:c:c:c:c:c:1	2	thio_imide_A(1)	8	1772697397	c:1:c(:c:c:c:c:1)-[#7]-2-[#6](=[#8])-[#6](=[#6](-[#1])-[#6]-2=[#8])-[#16]-c:3:c:c:c:c:c:3	thio_imide_a_1_	5	0	0	0	0	5	10	1
880	[#6&!H0]1(-[#8&!H0])-[#6]2:[#7]:[!#6&!#1]:[#7]:[#6]:2-[#6&!H0](-[#8&!H0])-[#6]=[#6]-1	2	diazox_D(1)	8	1772697397	[#6]-2(-[#1])(-[#8]-[#1])-[#6]:1:[#7]:[!#6&!#1]:[#7]:[#6]:1-[#6](-[#1])(-[#8]-[#1])-[#6]=[#6]-2	diazox_d_1_	8	0	0	0	0	8	10	4
923	[#16](=[#8])(=[#8])(-c1:c:n(-[#6&!H0&!H1]):c:n:1)-[#7&!H0]-c1:c:n(:n:c:1)-[#6&!H0&!H1]-[#6]:[#6]-[#8]-[#6&!H0&!H1]	2	sulfonamide_I(1)	8	1772697397	[#16](=[#8])(=[#8])(-c:1:c:n(-[#6](-[#1])-[#1]):c:n:1)-[#7](-[#1])-c:2:c:n(:n:c:2)-[#6](-[#1])(-[#1])-[#6]:[#6]-[#8]-[#6](-[#1])-[#1]	sulfonamide_i_1_	0	0	0	0	0	0	10	0
867	s1:[c&!H0]:[c&!H0]:[c&!H0]:c:1-[#6]1=[#7]-c2:c:c:c:c:c:2-[#6](=[#7]-[#7&!H0]-1)-c1:c:c:n:c:c:1	2	het_76_A(1)	8	1772697397	s:1:c(:c(-[#1]):c(:c:1-[#6]-3=[#7]-c:2:c:c:c:c:c:2-[#6](=[#7]-[#7]-3-[#1])-c:4:c:c:n:c:c:4)-[#1])-[#1]	het_76_a_1_	0	0	0	0	0	0	10	0
931	c1(:n:s:c(:n:1)-[#7](-[#6&!H0&!H1])-[#6&!H0&!H1]-[#6&!H0&!H1]-[#7]-[#6](=[#8])-c1:c:c:c:c:c:1-[#6](=[#8])-[#8&!H0])-c1:c:c:c:c:c:1	2	misc_phthal_thio_N(1)	8	1772697397	c:1(:n:s:c(:n:1)-[#7](-[#6](-[#1])-[#1])-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#7]-[#6](=[#8])-c:2:c:c:c:c:c:2-[#6](=[#8])-[#8]-[#1])-c:3:c:c:c:c:c:3	misc_phthal_thio_n_1_	1	0	0	0	0	1	10	0
946	[#7&!H0&!H1]-c1:[c&!H0]:[c&!H0]:c(:[c&!H0]:[c&!H0]:1)-c1:[c&!H0]:c(:c(-[#6&!H0&!H1]):o:1)-[#6]=[#8]	2	anil_no_alk_C(1)	8	1772697397	[#7](-[#1])(-[#1])-c:1:c(:c(:c(:c(:c:1-[#1])-[#1])-c:2:c(-[#1]):c(:c(-[#6](-[#1])-[#1]):o:2)-[#6]=[#8])-[#1])-[#1]	anil_no_alk_c_1_	1	0	0	0	0	1	10	1
910	[#6]#[#6]-[#6](=[#8])-[#6]#[#6]	2	ene_one_yne_A(1)	8	1772697397	[#6]#[#6]-[#6](=[#8])-[#6]#[#6]	ene_one_yne_a_1_	33	1	0	0	0	41	10	2
852	[#7&!H0&!H1]-c1:c:c:c(:c:c:1-[#8&!H0])-[#16](=[#8])(=[#8])-[#8&!H0]	2	anil_OH_no_alk_A(1)	8	1772697397	[#7](-[#1])(-[#1])-c:1:c:c:c(:c:c:1-[#8]-[#1])-[#16](=[#8])(=[#8])-[#8]-[#1]	anil_oh_no_alk_a_1_	17	0	0	0	0	17	10	3
863	[#7]1-[#6]=[#6](-[#6]=[#8])-[#6](-c2:c:c:c(:c:c:2)-[#7](-[#6&!H0&!H1])-[#6&!H0&!H1])-[#6]2=[#6]-1~[#7]~[#6](~[#16])~[#7]~[#6]~2~[#7]	2	anil_di_alk_dhp(1)	8	1772697397	[#7]-2-[#6]=[#6](-[#6]=[#8])-[#6](-c:1:c:c:c(:c:c:1)-[#7](-[#6](-[#1])-[#1])-[#6](-[#1])-[#1])-[#6]~3=[#6]-2~[#7]~[#6](~[#16])~[#7]~[#6]~3~[#7]	anil_di_alk_dhp_1_	0	0	0	0	0	0	10	0
892	c1(:[c&!H0]:c(:c(:[c&!H0]:[c&!H0]:1)-[#6&!H0&!H1])-[#7&!H0]-[#6](=[#8])-[#6&!H0&!H1]-[#6&!H0&!H1]-[#6]:[#6])-[#7&!H0]-[#6](=[#8])-[#6&!H0&!H1]-[#6&!H0&!H1]-[#6]:[#6]	2	misc_anilide_A(1)	8	1772697397	c:1(:c(:c(:c(:c(:c:1-[#1])-[#1])-[#6](-[#1])-[#1])-[#7](-[#1])-[#6](=[#8])-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#6]:[#6])-[#1])-[#7](-[#1])-[#6](=[#8])-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#6]:[#6]	misc_anilide_a_1_	1	0	0	0	0	1	10	0
869	c1:c(:c:c:c:c:1)-[#7](-[#6&!H0])-[#6&!H0]-[#6&!H0]-[#6&!H0]-[#7&!H0]-[#6](=[#8])-[#6]1=[#6](-[#8]-[#6](-[#6&!H0]=[#6]-1-[#6&!H0&!H1])=[#8])-[#6&!H0&!H1]	2	anil_di_alk_coum(1)	8	1772697397	c:1:c(:c:c:c:c:1)-[#7](-[#6]-[#1])-[#6](-[#1])-[#6](-[#1])-[#6](-[#1])-[#7](-[#1])-[#6](=[#8])-[#6]-2=[#6](-[#8]-[#6](-[#6](=[#6]-2-[#6](-[#1])-[#1])-[#1])=[#8])-[#6](-[#1])-[#1]	anil_di_alk_coum_1_	0	0	0	0	0	0	10	0
938	[#16]=[#6]-[#6](-[#6&!H0&!H1])=[#6](-[#6&!H0&!H1])-[#7](-[#6&!H0&!H1])-[#6&!H0&!H1]	2	thio_ene_amine_A(1)	8	1772697397	[#16]=[#6]-[#6](-[#6](-[#1])-[#1])=[#6](-[#6](-[#1])-[#1])-[#7](-[#6](-[#1])-[#1])-[#6](-[#1])-[#1]	thio_ene_amine_a_1_	8	0	0	0	0	8	10	0
935	[#7&!H0&!H1]-c1:[c&!H0]:c(:c(:[c&!H0]:c:1-[#7&!H0]-[#16](=[#8])=[#8])-[#7&!H0]-[#6&!H0&!H1])-[F,Cl,Br,I]	2	anil_NH_no_alk_B(1)	8	1772697397	[#7](-[#1])(-[#1])-c:1:c(:c(:c(:c(:c:1-[#7](-[#1])-[#16](=[#8])=[#8])-[#1])-[#7](-[#1])-[#6](-[#1])-[#1])-[F,Cl,Br,I])-[#1]	anil_nh_no_alk_b_1_	0	0	0	0	0	0	10	0
870	c12:c:c:c3:c:c:c:c:c:3:c:,-1-[#6&!H0]-[#6&X4]-[#7]-[#6]-2=[#6&!H0]-[#6](=[#8])-[#7](-[#6&!H0&!H1])-[#6&!H0&!H1]	2	ene_one_amide_B(1)	8	1772697397	c2-3:c:c:c:1:c:c:c:c:c:1:c2-[#6](-[#1])-[#6;X4]-[#7]-[#6]-3=[#6](-[#1])-[#6](=[#8])-[#7](-[#6](-[#1])-[#1])-[#6](-[#1])-[#1]	ene_one_amide_b_1_	8	0	0	0	0	8	10	0
872	[#6]1(=[#8])-[#6](=[#6](-[#6&!H0&!H1])-[#7&!H0]-[#6&!H0&!H1]-[#6&!H0&!H1]-[#6&!H0&!H1])-[#7]=[#6](-c2:c:c:c:c:c:2)-[#8]-1	2	het_5_ene(1)	8	1772697397	[#6]-2(=[#8])-[#6](=[#6](-[#6](-[#1])-[#1])-[#7](-[#1])-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#6](-[#1])-[#1])-[#7]=[#6](-c:1:c:c:c:c:c:1)-[#8]-2	het_5_ene_1_	44	0	0	0	0	44	10	19
881	[#6]1(-[#6&!H0&!H1]-[#6&!H0&!H1]-1)(-[#6](=[#8])-[#7&!H0]-c1:c:c:c(:c:c:1)-[#8]-[#6&!H0&!H1]-[#8])-[#16](=[#8])(=[#8])-[#6]:[#6]	2	misc_cyclopropane(1)	8	1772697397	[#6]-1(-[#6](-[#1])(-[#1])-[#6]-1(-[#1])-[#1])(-[#6](=[#8])-[#7](-[#1])-c:2:c:c:c(:c:c:2)-[#8]-[#6](-[#1])(-[#1])-[#8])-[#16](=[#8])(=[#8])-[#6]:[#6]	misc_cyclopropane_1_	1	0	0	0	0	2	10	0
886	[#7]1(-[#6](=[#8])-c2:c:c:c:c:c:2)-[#6](=[#7]-c2:c:c:c:c:c:2)-[#16]-[#6&!H0&!H1]-[#6]-1=[#8]	2	rhod_sat_imine_A(1)	8	1772697397	[#7]-3(-[#6](=[#8])-c:1:c:c:c:c:c:1)-[#6](=[#7]-c:2:c:c:c:c:c:2)-[#16]-[#6](-[#1])(-[#1])-[#6]-3=[#8]	rhod_sat_imine_a_1_	1	0	0	0	0	2	10	0
919	c12:c(:c:c:c:c:1)-,:[#6]=,:[#6](-,:[#6](=[#8])-,:[#7]-,:c1:n:o:c:c:1-Br)-,:[#6](=[#8])-,:[#8]-,:2	2	coumarin_F(1)	8	1772697397	c:1-3:c(:c:c:c:c:1)-[#6](=[#6](-[#6](=[#8])-[#7](-[#1])-c:2:n:o:c:c:2-[Br])-[#6](=[#8])-[#8]-3)-[#1]	coumarin_f_1_	0	0	0	0	0	0	10	0
947	[#8&!H0]-[#6](=[#8])-c1:c:c:c(:c:c:1)-[#7]-[#7]=[#6&!H0]-[#6]1:[#6&!H0]:[#6&!H0]:[#6](:[!#1]:1)-c1:c:c:c:c:c:1	2	hzone_acid_D(1)	8	1772697397	[#8](-[#1])-[#6](=[#8])-c:1:c:c:c(:c:c:1)-[#7]-[#7]=[#6](-[#1])-[#6]:2:[#6](:[#6](:[#6](:[!#1]:2)-c:3:c:c:c:c:c:3)-[#1])-[#1]	hzone_acid_d_1_	9	0	0	0	0	10	10	0
883	c1:c:c(:c:c2:c:1-,:[#6](=,:[#6]-,:[#6](=[#8])-,:[#8]-,:2)-,:c1:c:c:c:c:c:1)-,:[#8]-,:[#6]-,:[#6]-,:[#8]-,:[#6]	2	coumarin_D(1)	8	1772697397	c:1:c:c(:c:c-2:c:1-[#6](=[#6](-[#1])-[#6](=[#8])-[#8]-2)-c:3:c:c:c:c:c:3)-[#8]-[#6](-[#1])(-[#1])-[#6]:[#8]:[#6]	coumarin_d_1_	289	0	0	0	0	300	10	32
920	c12:c(:c:c(:c:c:1-[F,Cl,Br,I])-[F,Cl,Br,I])-[#6&!H0]=[#6](-[#6](=[#8])-[#7&!H0&!H1])-[#6](=[#7&!H0])-[#8]-2	2	coumarin_G(1)	8	1772697397	c:1-2:c(:c:c(:c:c:1-[F,Cl,Br,I])-[F,Cl,Br,I])-[#6](=[#6](-[#6](=[#8])-[#7](-[#1])-[#1])-[#6](=[#7]-[#1])-[#8]-2)-[#1]	coumarin_g_1_	0	0	0	0	0	0	10	0
871	c1:c(:c:c:c:c:1)-[#6]1=[#7]-[#7]2:[#6](:[#7&+]:c3:c:2:c:c:c:c:3)-[#16]-[#6&X4]-1	2	het_thio_656c(1)	8	1772697397	c:1:c(:c:c:c:c:1)-[#6]-4=[#7]-[#7]:2:[#6](:[#7+]:c:3:c:2:c:c:c:c:3)-[#16]-[#6;X4]-4	het_thio_656c_1_	9	0	0	0	0	9	10	0
897	n12:c:c:c(:c:c:1:c:c(:c:2-[#6](=[#8])-[#6]:[#6])-[#6]:[#6])-[#6](~[#8])~[#8]	2	het_65_I(1)	8	1772697397	n:1:2:c:c:c(:c:c:1:c:c(:c:2-[#6](=[#8])-[#6]:[#6])-[#6]:[#6])-[#6](~[#8])~[#8]	het_65_i_1_	3	0	0	0	0	3	10	0
912	c1(:[c&!H0]:[c&!H0]:c(:o:1)-[$([#1]),$([#6](-[#1])-[#1])])-[#6](=[#8])-[#7&!H0]-[#7]=[#6](-[$([#1]),$([#6](-[#1])-[#1])])-c1:c:c:c:c(:c:1)-*-*-*-c1:c:c:c:o:1	2	hzone_acyl_misc_A(1)	8	1772697397	c:1(:c(:c(:[c;!H0,$(c-[#6;!H0;!H1])](:o:1))-[#1])-[#1])-[#6](=[#8])-[#7](-[#1])-[#7]=[#6;!H0,$([#6]-[#6;!H0!H1])]-c:2:c:c:c:c(:c:2)-[*]-[*]-[*]-c:3:c:c:c:o:3	hzone_acyl_misc_a_1_	0	0	0	0	0	0	10	0
937	[#7&!H0&!H1]-c1:[c&!H0]:c(:c(:[c&!H0]:c:1-n1:c:c:c:c:1)-[#6&!H0&!H1])-[#6&!H0&!H1]	2	anil_no_alk_B(1)	8	1772697397	[#7](-[#1])(-[#1])-c:1:c(:c(:c(:c(:c:1-n:2:c:c:c:c:2)-[#1])-[#6](-[#1])-[#1])-[#6](-[#1])-[#1])-[#1]	anil_no_alk_b_1_	19	0	0	0	0	19	10	2
895	c12:[c&!H0]:c(:c(:[c&!H0]:c:1-[#8]-[#6&!H0&!H1]-[#7](-[#6&!H0&!H1])-[#6&!H0&!H1]-2)-[#8])-[#8]	2	mannich_catechol_A(1)	8	1772697397	c:1-2:c(:c(:c(:c(:c:1-[#8]-[#6](-[#1])(-[#1])-[#7](-[#6](-[#1])-[#1])-[#6]-2(-[#1])-[#1])-[#1])-[#8])-[#8])-[#1]	mannich_catechol_a_1_	11	0	0	0	0	11	10	0
894	c12:[c&!H0]:c:c:[c&!H0]:c:1-[#8]-[#6&!H0&!H1]-[#7](-[#6]:[#6]-[#8]-[#6&!H0&!H1])-[#6&!H0&!H1]-2	2	mannich_B(1)	8	1772697397	c:1-2:c(:c:c:c(:c:1-[#8]-[#6](-[#1])(-[#1])-[#7](-[#6]:[#6]-[#8]-[#6](-[#1])-[#1])-[#6]-2(-[#1])-[#1])-[#1])-[#1]	mannich_b_1_	2	0	0	0	0	2	10	1
936	[#7&!H0&!H1]-c1:[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:c:1-[#7]=[#6]1-[#6&!H0]=[#6]~[#6]~[#6]=[#6]-1	2	anil_no_alk_A(1)	8	1772697397	[#7](-[#1])(-[#1])-c:1:c(:c(:c(:c(:c:1-[#7]=[#6]-2-[#6](=[#6]~[#6]~[#6]=[#6]-2)-[#1])-[#1])-[#1])-[#1])-[#1]	anil_no_alk_a_1_	5	0	0	0	0	5	10	0
855	n1:,-n:,-s:,-c:,-c:,-1-c1:,-n:,-c(-,:n:,-o:,-1)-[#6]:[#6]	2	het_thio_N_5D(1)	8	1772697397	n1nscc1-c2nc(no2)-[#6]:[#6]	het_thio_n_5d_1_	10	0	0	0	0	10	10	0
849	c12:c(:c:c:c:c:1)-,:[#16]-,:[#6](=,:[#7]-,:[#7]=,:[#6]1-,:[#6]=,:[#6]-,:[#6]=,:[#6]-,:[#6]=,:[#6]-,:1)-,:[#7]-,:2-[#6&!H0&!H1]	2	colchicine_het(1)	8	1772697397	c:1-3:c(:c:c:c:c:1)-[#16]-[#6](=[#7]-[#7]=[#6]-2-[#6]=[#6]-[#6]=[#6]-[#6]=[#6]-2)-[#7]-3-[#6](-[#1])-[#1]	colchicine_het_1_	0	0	0	0	0	0	10	0
861	c12:c(:[c&!H0]:c(:[c&!H0]:[c&!H0]:1)-[#7&!H0&!H1]):[c&!H0]:[c&!H0]:n:2-[#6&!H0&!H1]	2	anil_no_alk_indol_A(1)	8	1772697397	c:1:2:c(:c(:c(:c(:c:1-[#1])-[#1])-[#7](-[#1])-[#1])-[#1]):c(:c(-[#1]):n:2-[#6](-[#1])-[#1])-[#1]	anil_no_alk_indol_a_1_	808	0	0	0	0	809	10	29
953	n1(-[#6&!H0&!H1]):,-c(-,:c(-[#6](=[#8])-[#6]):,-c(-,:c:,-1-[#6]:[#6])-[#6])-[#6&!H0&!H1]	2	pyrrole_O(1)	8	1772697397	n1(-[#6](-[#1])-[#1])c(c(-[#6](=[#8])-[#6])c(c1-[#6]:[#6])-[#6])-[#6](-[#1])-[#1]	pyrrole_o_1_	4	0	0	0	0	27	10	0
933	[#6&!H0&!H1&!H2]-[#6](-[#6&!H0&!H1&!H2])(-[#6&!H0&!H1&!H2])-c1:[c&!H0]:c(:[c&!H0]:c(:c:1-[#8&!H0])-[#6](-[#6&!H0&!H1&!H2])(-[#6&!H0&!H1&!H2])-[#6&!H0&!H1&!H2])-[#6&!H0&!H1]-c1:c:c:c(:[c&!H0]:[c&!H0]:1)-[#8&!H0]	2	tert_butyl_B(1)	8	1772697397	[#6](-[#1])(-[#1])(-[#1])-[#6](-[#6](-[#1])(-[#1])-[#1])(-[#6](-[#1])(-[#1])-[#1])-c:1:c(:c(:c(:c(:c:1-[#8]-[#1])-[#6](-[#6](-[#1])(-[#1])-[#1])(-[#6](-[#1])(-[#1])-[#1])-[#6](-[#1])(-[#1])-[#1])-[#1])-[#6](-[#1])(-[#1])-c:2:c:c:c(:c(:c:2-[#1])-[#1])-[#8]-[#1])-[#1]	tert_butyl_b_1_	4	0	0	0	0	4	10	0
875	[c&!H0]1:[c&!H0]:c2:c(:[c&!H0]:c:1-[#7&!H0]-[#6](=[#16])-[#7&!H0]-[#6&!H0]-c1:[c&!H0]:[c&!H0]:c(:o:1)-[#6&!H0])-[#8]-[#6&!H0&!H1]-[#8]-2	2	thio_urea_O(1)	8	1772697397	c:1(:c(:c-3:c(:c(:c:1-[#7](-[#1])-[#6](=[#16])-[#7](-[#1])-[#6](-[#1])-c:2:c(:c(:c(:o:2)-[#6]-[#1])-[#1])-[#1])-[#1])-[#8]-[#6](-[#8]-3)(-[#1])-[#1])-[#1])-[#1]	thio_urea_o_1_	0	0	0	0	0	0	10	0
961	[#6&!H0&!H1]-[#8]-c1:c(:[c&!H0]:c(:[c&!H0]:[c&!H0]:1)-[#8]-[#6&!H0&!H1])-[#7&!H0]-c1:n:c(:c:s:1)-c1:c:c:c(:c:c:1)-[#8]-[#6&!H0&!H1]	2	thiazole_amine_N(1)	8	1772697397	[#6](-[#1])(-[#1])-[#8]-c:1:c(:c(:c(:c(:c:1-[#1])-[#1])-[#8]-[#6](-[#1])-[#1])-[#1])-[#7](-[#1])-c:2:n:c(:c:s:2)-c:3:c:c:c(:c:c:3)-[#8]-[#6](-[#1])-[#1]	thiazole_amine_n_1_	9	0	0	0	0	9	10	0
908	[#7]1(-c2:c:c:c(:c:c:2)-[#8]-[#6&!H0&!H1])-[#6](=[#8])-[#6](=[#6]-[#6](=[#7]-1)-n1:c:n:c:c:1)-[#6]#[#7]	2	cyano_pyridone_G(1)	8	1772697397	[#7]-2(-c:1:c:c:c(:c:c:1)-[#8]-[#6](-[#1])-[#1])-[#6](=[#8])-[#6](=[#6]-[#6](=[#7]-2)-n:3:c:n:c:c:3)-[#6]#[#7]	cyano_pyridone_g_1_	0	0	0	0	0	0	10	0
932	n1:c(:[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:1)-[#6](=[#8])-[#7&!H0]-[#7]=[#6&!H0]-c1:c:c:c:c:c:1-[#8]-[#6&!H0&!H1]-[#6](=[#8])-[#8&!H0]	2	hzone_acyl_misc_B(1)	8	1772697397	n:1:c(:c(:c(:c(:c:1-[#1])-[#1])-[#1])-[#1])-[#6](=[#8])-[#7](-[#1])-[#7]=[#6](-[#1])-c:2:c:c:c:c:c:2-[#8]-[#6](-[#1])(-[#1])-[#6](=[#8])-[#8]-[#1]	hzone_acyl_misc_b_1_	1	0	0	0	0	1	10	0
943	[#8]=[#6]-[#6&!H0]=[#6](-[#6]#[#7])-[#6]	2	ene_cyano_E(1)	8	1772697397	[#8]=[#6]-[#6](-[#1])=[#6](-[#6]#[#7])-[#6]	ene_cyano_e_1_	152	0	0	0	0	169	10	6
959	[#7&!H0&!H1]-[#6]1=[#6](-[#6]#[#7])-[#6&!H0](-[#6]:[#6])-[#16]-[#6&X4]-[#16]-1	2	dhp_amino_CN_H(1)	8	1772697397	[#7](-[#1])(-[#1])-[#6]-1=[#6](-[#6]#[#7])-[#6](-[#1])(-[#6]:[#6])-[#16]-[#6;X4]-[#16]-1	dhp_amino_cn_h_1_	10	0	0	0	0	10	10	2
884	c1:c(:o:c(:c:1-[#6&!H0&!H1])-[#6&!H0&!H1])-[#6&!H0&!H1]-[#7]-[#6&!H0&!H1]-[#6&!H0](-[#8]-[#6&!H0&!H1])-[#6&!H0&!H1]-[#8]-c1:c:c2:c(:c:c:1)-[#8]-[#6&!H0&!H1]-[#8]-2	2	misc_furan_A(1)	8	1772697397	c:1:c(:o:c(:c:1-[#6](-[#1])-[#1])-[#6](-[#1])-[#1])-[#6](-[#1])(-[#1])-[#7]-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#8]-[#6](-[#1])-[#1])-[#6](-[#1])(-[#1])-[#8]-c:2:c:c-3:c(:c:c:2)-[#8]-[#6](-[#8]-3)(-[#1])-[#1]	misc_furan_a_1_	0	0	0	0	0	0	10	0
915	[#6&!H0&!H1]-[#8]-c1:c(:[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:1)-[#7&!H0]-[#6&!H0](-[#6]=[#8])-[#16]	2	anil_OC_alk_F(1)	8	1772697397	[#6](-[#1])(-[#1])-[#8]-c:1:c(:c(:c(:c(:c:1-[#1])-[#1])-[#1])-[#1])-[#7](-[#1])-[#6](-[#1])(-[#6]=[#8])-[#16]	anil_oc_alk_f_1_	40	0	0	0	0	40	10	2
952	n1(-[#6&!H0]-c2:[c&!H0]:[c&!H0]:c:[c&!H0]:[c&!H0]:2):,-c(-,:[c&!H0]:,-[c&!H0]-,:c:,-1-[#6&!H0])-[#6&!H0]	2	pyrrole_N(1)	8	1772697397	n2(-[#6](-[#1])-c:1:c(:c(:c:c(:c:1-[#1])-[#1])-[#1])-[#1])c(c(-[#1])c(c2-[#6]-[#1])-[#1])-[#6]-[#1]	pyrrole_n_1_	163	0	0	0	0	166	10	30
950	[#6]1(=[!#6&!#1])-[#6](-[#7]=[#6]-[#16]-1)=[#8]	2	imine_one_fives_D(1)	8	1772697397	[#6]-1(=[!#6&!#1])-[#6](-[#7]=[#6]-[#16]-1)=[#8]	imine_one_fives_d_1_	36	0	0	0	0	37	10	1
926	[#7]1(-c2:c:c:c:c:c:2)-[#6&!H0]=[#7&+](-c2:c:c:c:c:c:2)-[#6](=[#7]-c2:c:c:c:c:c:2)-[#7]-1	2	het_5_inium(1)	8	1772697397	[#7]-4(-c:1:c:c:c:c:c:1)-[#6](=[#7+](-c:2:c:c:c:c:c:2)-[#6](=[#7]-c:3:c:c:c:c:c:3)-[#7]-4)-[#1]	het_5_inium_1_	0	0	0	0	0	0	10	0
868	o1:[c&!H0]:[c&!H0]:[c&!H0]:c:1-[#6&!H0&!H1]-[#7&!H0]-[#6](=[#16])-[#7](-[#6&!H0])-[#6&!H0&!H1]-c1:c:c:c:c:c:1	2	thio_urea_N(1)	8	1772697397	o:1:c(:c(-[#1]):c(:c:1-[#6](-[#1])(-[#1])-[#7](-[#1])-[#6](=[#16])-[#7](-[#6]-[#1])-[#6](-[#1])(-[#1])-c:2:c:c:c:c:c:2)-[#1])-[#1]	thio_urea_n_1_	99	0	0	0	0	99	10	1
891	[#6&!H0&!H1]-[#16]-[#6](=[#16])-[#7&!H0]-[#6&!H0&!H1]-[#6]:[#6]	2	thio_carbam_A(1)	8	1772697397	[#6](-[#1])(-[#1])-[#16]-[#6](=[#16])-[#7](-[#1])-[#6](-[#1])(-[#1])-[#6]:[#6]	thio_carbam_a_1_	64	0	3	3	0	185	10	9
858	c12:c(:c:c3:c:c:c:c:c:3:c:1)-[#7](-[#6&!H0&!H1])-[#6](=[#8])-[#6](=[#7]-2)-[#6]:[#6]-[#7&!H0]-[#6&!H0&!H1]	2	het_666_C(1)	8	1772697397	c:2-3:c(:c:c:1:c:c:c:c:c:1:c:2)-[#7](-[#6](-[#1])-[#1])-[#6](=[#8])-[#6](=[#7]-3)-[#6]:[#6]-[#7](-[#1])-[#6](-[#1])-[#1]	het_666_c_1_	0	0	0	0	0	0	10	0
925	[#6&!H0&!H1]-[#8]-[#6]:[#6]-[#6&!H0&!H1]-[#7&!H0]-c1:[c&!H0]:[c&!H0]:c2:n(:[c&!H0]:n:c:2:[c&!H0]:1)-[#6&!H0]	2	anil_alk_A(1)	8	1772697397	[#6](-[#1])(-[#1])-[#8]-[#6]:[#6]-[#6](-[#1])(-[#1])-[#7](-[#1])-c:2:c(:c(:c:1:n(:c(:n:c:1:c:2-[#1])-[#1])-[#6]-[#1])-[#1])-[#1]	anil_alk_a_1_	22	0	0	0	0	22	10	1
960	[#6&!H0&!H1]-[#8]-c1:c(:[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:1)-[#7&!H0]-c1:c:c:n:c2:c(:c:c:c(:c:1:2)-[#8]-[#6&!H0&!H1])-[#8]-[#6&!H0&!H1]	2	het_66_anisole(1)	8	1772697397	[#6](-[#1])(-[#1])-[#8]-c:1:c(:c(:c(:c(:c:1-[#1])-[#1])-[#1])-[#1])-[#7](-[#1])-c:2:c:c:n:c:3:c(:c:c:c(:c:2:3)-[#8]-[#6](-[#1])-[#1])-[#8]-[#6](-[#1])-[#1]	het_66_anisole_1_	1	0	0	0	0	1	10	0
745	c1(:[c&!H0]:[c&!H0]:c(:s:1)-[$([#1]),$([#6](-[#1])-[#1])])-[#6](-[$([#1]),$([#6](-[#1])-[#1])])-[#6](=[#8])-[#7&!H0]-c1:n:c:c:s:1	2	thiophene_E(2)	8	1772697389	c:1(:c(:c(:[c;!H0,$(c-[#6;!H0,!H1])](:s:1))-[#1])-[#1])-[#6;!H0,$([#6]-[#6;!H0;!H1])]-[#6](=[#8])-[#7](-[#1])-c:2:n:c:c:s:2	thiophene_e_2_	0	0	0	0	0	0	10	0
878	[#6](-F)(-F)-[#6](=[#8])-[#7&!H0]-c1:[c&!H0]:n(-[#6&!H0&!H1]-[#6&!H0&!H1]-[#8]-[#6&!H0&!H1]-[#6]:[#6]):n:[c&!H0]:1	2	het_pyraz_misc(1)	8	1772697397	[#6](-[F])(-[F])-[#6](=[#8])-[#7](-[#1])-c:1:c(-[#1]):n(-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#8]-[#6](-[#1])(-[#1])-[#6]:[#6]):n:c:1-[#1]	het_pyraz_misc_1_	0	0	0	0	0	0	10	0
921	c12:c(:c:c:c:c:1)-[#6&!H0]=[#6](-[#6](=[#8])-[#7&!H0]-c1:n:c(:c:s:1)-[#6]:[#16]:[#6&!H0])-[#6](=[#8])-[#8]-2	2	coumarin_H(1)	8	1772697397	c:1-3:c(:c:c:c:c:1)-[#6](=[#6](-[#6](=[#8])-[#7](-[#1])-c:2:n:c(:c:s:2)-[#6]:[#16]:[#6]-[#1])-[#6](=[#8])-[#8]-3)-[#1]	coumarin_h_1_	0	0	0	0	0	0	10	0
854	c1:,-c(-[#7&!H0&!H1]):,-n:,-n:,-c:,-1-c1:,-c(-[#6&!H0&!H1]):,-o:,-[c&!H0]-,:[c&!H0]:,-1	2	pyrazole_amino_A(1)	8	1772697397	c1c(-[#7](-[#1])-[#1])nnc1-c2c(-[#6](-[#1])-[#1])oc(c2-[#1])-[#1]	pyrazole_amino_a_1_	266	0	0	0	0	266	10	7
876	[c&!H0]1:[c&!H0]:[c&!H0]:c(:[c&!H0]:c:1-[#7&!H0]-[#6](=[#16])-[#7&!H0]-c1:c:c:c:c:c:1)-[#7](-[#6&!H0&!H1])-[#6&!H0&!H1]	2	anil_di_alk_O(1)	8	1772697397	c:1(:c(:c(:c(:c(:c:1-[#7](-[#1])-[#6](=[#16])-[#7](-[#1])-c:2:c:c:c:c:c:2)-[#1])-[#7](-[#6](-[#1])-[#1])-[#6](-[#1])-[#1])-[#1])-[#1])-[#1]	anil_di_alk_o_1_	163	0	0	0	0	163	10	0
945	c1:c(:c:c:c:c:1)-[#7](-c1:c:c:c:c:c:1)-[#7]=[#6&!H0]-[#6]1:[#6&!H0]:[#6&!H0]:[#6](:[!#1]:1)-c1:c:c:c:c(:c:1)-[#6](=[#8])-[#8&!H0]	2	hzone_furan_C(1)	8	1772697397	c:1:c(:c:c:c:c:1)-[#7](-c:2:c:c:c:c:c:2)-[#7]=[#6](-[#1])-[#6]:3:[#6](:[#6](:[#6](:[!#1]:3)-c:4:c:c:c:c(:c:4)-[#6](=[#8])-[#8]-[#1])-[#1])-[#1]	hzone_furan_c_1_	1	0	0	0	0	1	10	1
889	[#16]1-[#6](=[#7]-[#7&!H0])-[#16]-[#6](=[#7]-[#6]:[#6])-[#6]-1=[#7]-[#6]:[#6]	2	het_thio_5_imine_C(1)	8	1772697397	[#16]-1-[#6](=[#7]-[#7]-[#1])-[#16]-[#6](=[#7]-[#6]:[#6])-[#6]-1=[#7]-[#6]:[#6]	het_thio_5_imine_c_1_	11	0	0	0	0	11	10	0
864	c1:c(:c:c:c:c:1)-[#6](=[#8])-[#7&!H0]-c1:c(:c:c:c:c:1)-[#6](=[#8])-[#7&!H0]-[#7&!H0]-c1:n:c:c:s:1	2	anthranil_amide_A(1)	8	1772697397	c:1:c(:c:c:c:c:1)-[#6](=[#8])-[#7](-[#1])-c:2:c(:c:c:c:c:2)-[#6](=[#8])-[#7](-[#1])-[#7](-[#1])-c:3:n:c:c:s:3	anthranil_amide_a_1_	1	0	0	0	0	1	10	0
928	c12:[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:c:1:c(:[c&!H0]:[c&!H0]:[c&!H0]:2)-[#6](-[#6&!H0&!H1])=[#7]-[#7&!H0]-[#6](=[#16])-[#7&!H0]-[#6]:[#6]:[#6]	2	thio_urea_Q(1)	8	1772697397	c:1:2:c(:c(:c(:c(:c:1:c(:c(-[#1]):c(:c:2-[#1])-[#1])-[#6](-[#6](-[#1])-[#1])=[#7]-[#7](-[#1])-[#6](=[#16])-[#7](-[#1])-[#6]:[#6]:[#6])-[#1])-[#1])-[#1])-[#1]	thio_urea_q_1_	3	0	0	0	0	3	10	0
898	c1(:[c&!H0]:c(:[c&!H0]:[c&!H0]:[c&!H0]:1)-[#6](=[#6&!H0&!H1])-[#6&!H0&!H1])-[#6](-[#6&X4])(-[#6&X4])-[#7&!H0]-[#6](=[#8])-[#7](-[#6&!H0&!H1]-[#6&!H0&!H1])-[#6&!H0&!H1]-[#6&!H0&!H1]-[#6&!H0]-[#6&!H0&!H1]-[#6]:[#6]	2	misc_urea_A(1)	8	1772697397	c:1(:c(:c(:c(:c(:c:1-[#1])-[#1])-[#1])-[#6](=[#6](-[#1])-[#1])-[#6](-[#1])-[#1])-[#1])-[#6](-[#6;X4])(-[#6;X4])-[#7](-[#1])-[#6](=[#8])-[#7](-[#6](-[#1])(-[#1])-[#6](-[#1])-[#1])-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#6](-[#1])-[#6](-[#1])(-[#1])-[#6]:[#6]	misc_urea_a_1_	1	0	0	0	0	1	10	1
955	n1(-c2:c:c:c:c:c:2-[#7&!H0]-[#16](=[#8])(=[#8])-c2:c:c:c:s:2):,-[c&!H0]-,:[c&!H0]:,-[c&!H0]-,:[c&!H0]:,-1	2	sulfonamide_J(1)	8	1772697397	n3(-c:1:c:c:c:c:c:1-[#7](-[#1])-[#16](=[#8])(=[#8])-c:2:c:c:c:s:2)c(c(-[#1])c(c3-[#1])-[#1])-[#1]	sulfonamide_j_1_	10	0	0	0	0	10	10	0
853	s1:c:c:c(:[c&!H0]:1)-c1:c:s:c(:n:1)-[#7&!H0&!H1]	2	thiazole_amine_L(1)	8	1772697397	s:1:c:c:c(:c:1-[#1])-c:2:c:s:c(:n:2)-[#7](-[#1])-[#1]	thiazole_amine_l_1_	23	0	0	0	0	23	10	1
893	c1(:c(:[c&!H0]:c(:[c&!H0]:c:1-[#6&!H0&!H1])-Br)-[#6&!H0&!H1])-[#7&!H0]-[#6](=[#8])-[#7&!H0]-[#6&!H0&!H1]-[#6&!H0&!H1]-[#6&!H0&!H1]	2	misc_anilide_B(1)	8	1772697397	c:1(:c(:c(:c(:c(:c:1-[#6](-[#1])-[#1])-[#1])-[Br])-[#1])-[#6](-[#1])-[#1])-[#7](-[#1])-[#6](=[#8])-[#7](-[#1])-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#6](-[#1])-[#1]	misc_anilide_b_1_	117	0	0	0	0	117	10	0
879	[#7]1=[#7]-[#6]2:[#7]:[!#6&!#1]:[#7]:[#6]:2-[#7]=[#7]-[#6]:[#6]-1	2	diazox_C(1)	8	1772697397	[#7]-2=[#7]-[#6]:1:[#7]:[!#6&!#1]:[#7]:[#6]:1-[#7]=[#7]-[#6]:[#6]-2	diazox_c_1_	1	0	0	0	0	1	10	0
942	[#8]=[#6]1-[#7]-[#7]-[#6](=[#7]-[#6]-1=[#6&!H0])-[!#1]:[!#1]	2	ene_six_het_D(1)	8	1772697397	[#8]=[#6]-1-[#7]-[#7]-[#6](=[#7]-[#6]-1=[#6]-[#1])-[!#1]:[!#1]	ene_six_het_d_1_	23	0	0	0	0	33	10	0
904	c1(:n:c2:c(:[c&!H0]:c:c(:[c&!H0]:2)-[F,Cl,Br,I]):[n&!H0]:1)-[#16]-[#6&!H0&!H1]-[#6](=[#8])-[#7&!H0]-[#6]:[#6]	2	het_thio_65_D(1)	8	1772697397	c:2(:n:c:1:c(:c(:c:c(:c:1-[#1])-[F,Cl,Br,I])-[#1]):n:2-[#1])-[#16]-[#6](-[#1])(-[#1])-[#6](=[#8])-[#7](-[#1])-[#6]:[#6]	het_thio_65_d_1_	208	0	0	0	0	212	10	0
900	[#6](=[#6&!H0]-[#6&!H0&!H1]-n1:[c&!H0]:n:[c&!H0]:[c&!H0]:1)(-[#6]:[#6])-[#6]:[#6]	2	styrene_imidazole_A(1)	8	1772697397	[#6](=[#6](-[#1])-[#6](-[#1])(-[#1])-n:1:c(:n:c(:c:1-[#1])-[#1])-[#1])(-[#6]:[#6])-[#6]:[#6]	styrene_imidazole_a_1_	0	0	0	0	0	2	10	0
939	[#6]1:[#6]-[#8]-[#6]2-[#6&!H0&!H1]-[#6](=[#8])-[#8]-[#6]-1-2	2	het_55_B(1)	8	1772697397	[#6]-1:[#6]-[#8]-[#6]-2-[#6](-[#1])(-[#1])-[#6](=[#8])-[#8]-[#6]-1-2	het_55_b_1_	11	0	0	0	0	11	10	0
890	[#6]1(=[#8])-[#6](=[#6&!H0]-c2:c(:c:c:c(:c:2)-[F,Cl,Br,I])-[#8]-[#6&!H0&!H1])-[#7]=[#6](-[#16]-[#6&!H0&!H1])-[#16]-1	2	ene_five_het_N(1)	8	1772697397	[#6]-2(=[#8])-[#6](=[#6](-[#1])-c:1:c(:c:c:c(:c:1)-[F,Cl,Br,I])-[#8]-[#6](-[#1])-[#1])-[#7]=[#6](-[#16]-[#6](-[#1])-[#1])-[#16]-2	ene_five_het_n_1_	59	0	0	0	0	59	10	1
922	[#6&!H0&!H1]-[#16&X2]-c1:n:n:c2-[#6]:[#6]-[#7]=[#6]-[#8]-c:2:n:1	2	het_thio_67_A(1)	8	1772697397	[#6](-[#1])(-[#1])-[#16;X2]-c:2:n:n:c:1-[#6]:[#6]-[#7]=[#6]-[#8]-c:1:n:2	het_thio_67_a_1_	50	0	0	0	0	50	10	0
859	[#6](-[#8&!H0]):[#6]-[#6](=[#8])-[#6&!H0]=[#6](-[#6])-[#6]	2	ene_one_D(1)	8	1772697397	[#6](-[#8]-[#1]):[#6]-[#6](=[#8])-[#6](-[#1])=[#6](-[#6])-[#6]	ene_one_d_1_	116	57	18	26	0	538	10	20
906	[#7&!H0]1-[#6](=[#16])-[#6&!H0](-[#6]#[#7])-[#6&!H0](-[#6]:[#6])-[#6&!H0]=[#6]-1-[#6]:[#6]	2	thio_cyano_A(1)	8	1772697397	[#7]-1(-[#1])-[#6](=[#16])-[#6](-[#1])(-[#6]#[#7])-[#6](-[#1])(-[#6]:[#6])-[#6](=[#6]-1-[#6]:[#6])-[#1]	thio_cyano_a_1_	12	0	0	0	0	12	10	0
913	[#16](=[#8])(=[#8])-[#7&!H0]-c1:c(:c(:c(:s:1)-[#6&!H0])-[#6&!H0])-[#6](=[#8])-[#7&!H0]	2	thiophene_F(1)	8	1772697397	[#16](=[#8])(=[#8])-[#7](-[#1])-c:1:c(:c(:c(:s:1)-[#6]-[#1])-[#6]-[#1])-[#6](=[#8])-[#7]-[#1]	thiophene_f_1_	309	0	0	0	0	378	10	6
845	[#6]1(-,:[#6]=,:[#7]-,:c2:c:c(:c:c:c:2-,:[#8]-,:1)-,:Cl)=[#8]	2	coumarin_C(1)	8	1772697397	[#6]-2(-[#6]=[#7]-c:1:c:c(:c:c:c:1-[#8]-2)-[Cl])=[#8]	coumarin_c_1_	19	0	0	0	0	26	10	3
848	[#7&!H0](-[#6]:[#6])-c1:c(-[#6](=[#8])-[#8&!H0]):c:c:c(:n:1)-[#6]:[#6]	2	anthranil_acid_J(1)	8	1772697397	[#7](-[#1])(-[#6]:[#6])-c:1:c(-[#6](=[#8])-[#8]-[#1]):c:c:c(:n:1)-[#6]:[#6]	anthranil_acid_j_1_	4	0	0	0	0	4	10	0
846	[#6]1=[#6]-[#7](-[#6](-c2:c-1:c:c:c:c:2)(-[#6]#[#7])-[#6](=[#16])-[#16])-[#6]=[#8]	2	thio_est_cyano_A(1)	8	1772697397	[#6]-1=[#6]-[#7](-[#6](-c:2:c-1:c:c:c:c:2)(-[#6]#[#7])-[#6](=[#16])-[#16])-[#6]=[#8]	thio_est_cyano_a_1_	8	0	0	0	0	8	10	0
905	c1(:[c&!H0]:c2:c(:[c&!H0]:c:1-[#8]-[#6&!H0&!H1])-[#6]=[#6]-[#6&!H0]-[#16]-2)-[#8]-[#6&!H0&!H1]	2	ene_misc_E(1)	8	1772697397	c:1(:c(:c-2:c(:c(:c:1-[#8]-[#6](-[#1])-[#1])-[#1])-[#6]=[#6]-[#6](-[#1])-[#16]-2)-[#1])-[#8]-[#6](-[#1])-[#1]	ene_misc_e_1_	4	0	0	0	0	4	10	0
874	[#7&!H0]1-[#7]=[#6](-[#7&!H0])-[#16]-[#6](=[#6]-1-[#6]:[#6])-[#6]:[#6]	2	dhp_amidine_A(1)	8	1772697397	[#7]-1(-[#1])-[#7]=[#6](-[#7]-[#1])-[#16]-[#6](=[#6]-1-[#6]:[#6])-[#6]:[#6]	dhp_amidine_a_1_	1	0	0	0	0	1	10	0
916	n1:,-n:,-n:,-n:,-c2:,-c:,-c:,-c:,-c:,-1:,-2	2	het_65_K(1)	8	1772697397	n1nnnc2cccc12	het_65_k_1_	1	0	0	0	0	1	10	0
957	c1(:c:c:c:c:c:1)-[#7&!H0]-[#6](=[#16])-[#7]-[#7&!H0]-[#6&!H0]=[#6&!H0]-[#6]=[#8]	2	thio_urea_R(1)	8	1772697397	c:1(:c:c:c:c:c:1)-[#7](-[#1])-[#6](=[#16])-[#7]-[#7](-[#1])-[#6](-[#1])=[#6](-[#1])-[#6]=[#8]	thio_urea_r_1_	3	0	0	0	0	3	10	0
909	o1:c(:c:c2:c:1:[c&!H0]:c(:c(:[c&!H0]:2)-[#8]-[#6&!H0&!H1])-[#8]-[#6&!H0&!H1])-[#6](~[#8])~[#8]	2	het_65_J(1)	8	1772697397	o:1:c(:c:c:2:c:1:c(:c(:c(:c:2-[#1])-[#8]-[#6](-[#1])-[#1])-[#8]-[#6](-[#1])-[#1])-[#1])-[#6](~[#8])~[#8]	het_65_j_1_	12	0	0	0	0	12	10	1
951	n1(-c2:c:c:c:c:c:2):,-[c&!H0]-,:[c&!H0]:,-[c&!H0]-,:c:,-1-[#6]=[#7]-[#8&!H0]	2	pyrrole_M(1)	8	1772697397	n2(-c:1:c:c:c:c:c:1)c(c(-[#1])c(c2-[#6]=[#7]-[#8]-[#1])-[#1])-[#1]	pyrrole_m_1_	32	0	0	0	0	34	10	4
954	n1(-[#6]):,-[c&!H0]-,:[c&!H0]:,-[c&!H0]-,:c:,-1-[#6&!H0]=[#6](-[#6]#[#7])-c1:n:c:c:s:1	2	ene_cyano_G(1)	8	1772697397	n1(-[#6])c(c(-[#1])c(c1-[#6](-[#1])=[#6](-[#6]#[#7])-c:2:n:c:c:s:2)-[#1])-[#1]	ene_cyano_g_1_	41	0	0	0	0	41	10	1
851	c12:c(:[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:1):,-c(-,:c(-[#6]:[#6]):,-n:,-2-&!@[#6]:[#6])-[#6&!H0&!H1]	2	indole_3yl_alk_B(1)	8	1772697397	c:12:c(:c(:c(:c(:c:1-[#1])-[#1])-[#1])-[#1])c(c(-[#6]:[#6])n2-!@[#6]:[#6])-[#6](-[#1])-[#1]	indole_3yl_alk_b_1_	9	0	0	0	0	10	10	1
918	c12:c(:c3:c(:c:c:1-Br):o:c:c:3)-,:[#6]=,:[#6]-,:[#6](=[#8])-,:[#8]-,:2	2	coumarin_E(1)	8	1772697397	c:1-3:c(:c:2:c(:c:c:1-[Br]):o:c:c:2)-[#6](=[#6]-[#6](=[#8])-[#8]-3)-[#1]	coumarin_e_1_	12	0	0	0	0	12	10	1
911	c1(:c2:[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:c:2:[c&!H0]:c(:c:1-[#8&!H0])-[#6]=[#8])-[#7&!H0&!H1]	2	anil_OH_no_alk_B(1)	8	1772697397	c:2(:c:1:c(:c(:c(:c(:c:1:c(:c(:c:2-[#8]-[#1])-[#6]=[#8])-[#1])-[#1])-[#1])-[#1])-[#1])-[#7](-[#1])-[#1]	anil_oh_no_alk_b_1_	3	0	0	0	0	3	10	2
930	n1:c(:n:c(:n:c:1-[#7](-[#6&!H0&!H1])-[#6&!H0&!H1])-[#7](-[#6&!H0&!H1])-[#6&!H0&!H1])-[#7](-[#6&!H0])-[#6]=[#8]	2	melamine_B(1)	8	1772697397	n:1:c(:n:c(:n:c:1-[#7](-[#6](-[#1])-[#1])-[#6](-[#1])-[#1])-[#7](-[#6](-[#1])-[#1])-[#6](-[#1])-[#1])-[#7](-[#6]-[#1])-[#6]=[#8]	melamine_b_1_	14	0	0	0	0	14	10	0
948	[#8&!H0]-[#6](=[#8])-c1:c:c:c:c(:c:1)-[#6]:[!#1]:[#6]-[#6]=[#7]-[#7&!H0]-[#6](=[#8])-[#6&!H0&!H1]-[#8]	2	hzone_furan_E(1)	8	1772697397	[#8](-[#1])-[#6](=[#8])-c:1:c:c:c:c(:c:1)-[#6]:[!#1]:[#6]-[#6]=[#7]-[#7](-[#1])-[#6](=[#8])-[#6](-[#1])(-[#1])-[#8]	hzone_furan_e_1_	62	0	0	0	0	63	10	0
850	c12:c(:[c&!H0]:c(:c(:[c&!H0]:1)-[#8]-[#6&!H0&!H1])-[#8]-[#6&!H0&!H1])-[#6](=[#6](-[#6])-[#16]-[#6&!H0&!H1]-2)-[#6]	2	ene_misc_D(1)	8	1772697397	c:1-2:c(:c(:c(:c(:c:1-[#1])-[#8]-[#6](-[#1])-[#1])-[#8]-[#6](-[#1])-[#1])-[#1])-[#6](=[#6](-[#6])-[#16]-[#6]-2(-[#1])-[#1])-[#6]	ene_misc_d_1_	0	0	0	0	0	0	10	0
856	c1(:c:c2:c(:c:c:1)-[#7]-[#6]1-c3:c:c:c:c:c:3-[#6]-[#6]-2-1)-[#6&X4]	2	anil_alk_indane(1)	8	1772697397	c:1(:c:c-3:c(:c:c:1)-[#7]-[#6]-4-c:2:c:c:c:c:c:2-[#6]-[#6]-3-4)-[#6;X4]	anil_alk_indane_1_	4	0	0	0	0	4	10	0
857	c12:c(:[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:1)-[#6&!H0]=[#6&!H0]-[#6]1-[#6](-[#6]#[#7])-[#6&!H0&!H1]-[#6&!H0]-[#7]-2-1	2	anil_di_alk_N(1)	8	1772697397	c:1-2:c(:c(:c(:c(:c:1-[#1])-[#1])-[#1])-[#1])-[#6](=[#6](-[#1])-[#6]-3-[#6](-[#6]#[#7])-[#6](-[#1])(-[#1])-[#6](-[#1])-[#7]-2-3)-[#1]	anil_di_alk_n_1_	14	0	0	0	0	14	10	0
914	[#6&!H0&!H1]-[#8]-c1:c(:[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:1)-[#7&!H0]-[#6&!H0&!H1]-[#6&!H0](-[#8&!H0])-[#6&!H0&!H1]	2	anil_OC_alk_E(1)	8	1772697397	[#6](-[#1])(-[#1])-[#8]-c:1:c(:c(:c(:c(:c:1-[#1])-[#1])-[#1])-[#1])-[#7](-[#1])-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#8]-[#1])-[#6](-[#1])-[#1]	anil_oc_alk_e_1_	358	0	0	0	0	364	10	22
962	[#6]12~[#7](-[#6]:[#6])~[#6]~[#6]~[#6]~[#6]~1~[#6]1~[#7]~[#6]~[#6]~[#6]~[#7&+]~1~[#7]~2	2	het_pyridiniums_C(1)	8	1772697397	[#6]~1~3~[#7](-[#6]:[#6])~[#6]~[#6]~[#6]~[#6]~1~[#6]~2~[#7]~[#6]~[#6]~[#6]~[#7+]~2~[#7]~3	het_pyridiniums_c_1_	0	0	0	0	0	0	10	0
877	[#8]=[#6]-&!@n1:c:c:c2:c:1-[#7&!H0]-[#6](=[#16])-[#7&!H0]-2	2	thio_urea_P(1)	8	1772697397	[#8]=[#6]-!@n:1:c:c:c-2:c:1-[#7](-[#1])-[#6](=[#16])-[#7]-2-[#1]	thio_urea_p_1_	0	0	0	0	0	0	10	0
917	c12:[c&!H0]:s:c(:c:1-[#6](=[#8])-[#7]-[#7]=[#6]-2-[#7&!H0&!H1])-[#6]=[#8]	2	het_65_L(1)	8	1772697397	c:1-2:c(-[#1]):s:c(:c:1-[#6](=[#8])-[#7]-[#7]=[#6]-2-[#7](-[#1])-[#1])-[#6]=[#8]	het_65_l_1_	0	0	0	0	0	0	10	0
816	[#6]:[#6]-[#7](-[#6&!H0&!H1])-[#6&!H0&!H1]-[#6&!H0&!H1]-[#6&!H0&!H1]-[#7&!H0]-[#6](=[#16])-[#7&!H0]-c1:[c&!H0]:[c&!H0]:c(:[c&!H0]:c:1-[F,Cl,Br,I])-[#6&!H0&!H1]	2	thio_urea_M(1)	8	1772697389	[#6]:[#6]-[#7](-[#6](-[#1])-[#1])-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#7](-[#1])-[#6](=[#16])-[#7](-[#1])-c:1:c(:c(:c(:c(:c:1-[F,Cl,Br,I])-[#1])-[#6](-[#1])-[#1])-[#1])-[#1]	thio_urea_m_1_	3	0	0	0	0	3	10	0
940	[#8]-[#6](=[#8])-[#6&!H0&!H1]-[#16&X2]-[#6](=[#7]-[#6]#[#7])-[#7&!H0]-c1:c:c:c:c:c:1	2	cyanamide_A(1)	8	1772697397	[#8]-[#6](=[#8])-[#6](-[#1])(-[#1])-[#16;X2]-[#6](=[#7]-[#6]#[#7])-[#7](-[#1])-c:1:c:c:c:c:c:1	cyanamide_a_1_	0	0	0	0	0	0	10	0
901	c1(:n:c(:[c&!H0]:s:1)-c1:c:c:n:c:c:1)-[#7&!H0]-[#6]:[#6]-[#6&!H0&!H1]	2	thiazole_amine_M(1)	8	1772697397	c:1(:n:c(:c(-[#1]):s:1)-c:2:c:c:n:c:c:2)-[#7](-[#1])-[#6]:[#6]-[#6](-[#1])-[#1]	thiazole_amine_m_1_	8	0	0	0	0	9	10	0
887	[#7]1(-c2:c:c:c:c:c:2)-[#6](=[#8])-[#16]-[#6&!H0&!H1]-[#6]-1=[#16]	2	rhod_sat_F(1)	8	1772697397	[#7]-2(-c:1:c:c:c:c:c:1)-[#6](=[#8])-[#16]-[#6](-[#1])(-[#1])-[#6]-2=[#16]	rhod_sat_f_1_	4	0	0	0	0	4	10	1
862	[#16&X2]1-[#6]=[#6](-[#6]#[#7])-[#6](-[#6])(-[#6]=[#8])-[#6](=[#6]-1-[#7&!H0&!H1])-[$([#6]=[#8]),$([#6]#[#7])]	2	dhp_amino_CN_G(1)	8	1772697397	[#16;X2]-1-[#6]=[#6](-[#6]#[#7])-[#6](-[#6])(-[#6]=[#8])-[#6](=[#6]-1-[#7](-[#1])-[#1])-[$([#6]=[#8]),$([#6]#[#7])]	dhp_amino_cn_g_1_	4	0	0	0	0	4	10	2
949	[#8&!H0]-[#6]1:[#6](:[#6]:[!#1]:[#6](:[#7]:1)-[#7&!H0&!H1])-[#6&!H0&!H1]-[#6](=[#8])-[#8]	2	het_6_pyridone_NH2(1)	8	1772697397	[#8](-[#1])-[#6]:1:[#6](:[#6]:[!#1]:[#6](:[#7]:1)-[#7](-[#1])-[#1])-[#6](-[#1])(-[#1])-[#6](=[#8])-[#8]	het_6_pyridone_nh2_1_	15	0	0	0	0	15	10	1
744	c1(:[c&!H0]:[c&!H0]:c(:o:1)-[$([#1]),$([#6](-[#1])-[#1])])-[#6](-[$([#1]),$([#6](-[#1])-[#1])])=[#7]-[#7&!H0]-c1:c:c:n:c:c:1	2	hzone_furan_B(2)	8	1772697389	c:1(:c(:c(:[c;!H0,$(c-[#6;!H0;!H1])](:o:1))-[#1])-[#1])-[#6;!H0,$([#6]-[#6;!H0;!H1])]=[#7]-[#7](-[#1])-c:2:c:c:n:c:c:2	hzone_furan_b_2_	0	0	0	0	0	0	10	0
934	[#7&!H0&!H1]-c1:c(-[#7&!H0&!H1]):[c&!H0]:[c&!H0]:c2:n:o:n:c:1:2	2	diazox_E(1)	8	1772697397	[#7](-[#1])(-[#1])-c:1:c(-[#7](-[#1])-[#1]):c(:c(-[#1]):c:2:n:o:n:c:1:2)-[#1]	diazox_e_1_	1	0	0	0	0	1	10	1
929	[#6]1(:[#7]:[#6](:[#7]:[!#1]:[#7]:1)-c1:[c&!H0]:[c&!H0]:[c&!H0]:o:1)-[#16]-[#6&X4]	2	thio_pyridine_A(1)	8	1772697397	[#6]:1(:[#7]:[#6](:[#7]:[!#1]:[#7]:1)-c:2:c(:c(:c(:o:2)-[#1])-[#1])-[#1])-[#16]-[#6;X4]	thio_pyridine_a_1_	107	0	0	0	0	109	10	2
903	[n&!H0]1:c(:c(-[#6&!H0&!H1]):c(:c:1-[#6&!H0&!H1]-[#6&!H0&!H1])-[#6&!H0&!H1]-[#6&!H0&!H1])-[#6](=[#8])-[#8]-[#6&!H0&!H1]	2	pyrrole_L(1)	8	1772697397	n:1(-[#1]):c(:c(-[#6](-[#1])-[#1]):c(:c:1-[#6](-[#1])(-[#1])-[#6](-[#1])-[#1])-[#6](-[#1])(-[#1])-[#6](-[#1])-[#1])-[#6](=[#8])-[#8]-[#6](-[#1])-[#1]	pyrrole_l_1_	12	0	0	0	0	12	10	1
927	[#6&!H0&!H1]-[#7](-[#6&!H0&!H1])-c1:c:c:c2:s:c(:n:c:2:c:1)-[#16]-[#6&!H0&!H1]	2	anil_di_alk_P(1)	8	1772697397	[#6](-[#1])(-[#1])-[#7](-[#6](-[#1])-[#1])-c:2:c:c:c:1:s:c(:n:c:1:c:2)-[#16]-[#6](-[#1])-[#1]	anil_di_alk_p_1_	5	0	0	0	0	5	10	2
963	[#7]1(-c2:c3:c:c:c:c:c:3:c:c:c:2)-[#7]=[#6](-[#6&!H0&!H1])-[#6&!H0&!H1]-[#6]-1=[#8]	2	het_5_E(1)	8	1772697397	[#7]-3(-c:2:c:1:c:c:c:c:c:1:c:c:c:2)-[#7]=[#6](-[#6](-[#1])-[#1])-[#6](-[#1])(-[#1])-[#6]-3=[#8]	het_5_e_1_	1	0	0	0	0	1	10	0
818	[#7]=[#6]1-[#16]-[#6](=[#7])-[#7]=[#6]-1	2	het_thio_5_imine_A(1)	8	1772697389	[#7]=[#6]-1-[#16]-[#6](=[#7])-[#7]=[#6]-1	het_thio_5_imine_a_1_	128	0	0	0	0	143	10	1
787	c12:[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:c:1:c(:c(:[c&!H0]:[c&!H0]:2)-[#6](=[#7]-[#6]:[#6])-[#6&!H0&!H1])-[#8&!H0]	2	imine_naphthol_A(1)	8	1772697389	c:1:2:c(:c(:c(:c(:c:1:c(:c(:c(:c:2-[#1])-[#1])-[#6](=[#7]-[#6]:[#6])-[#6](-[#1])-[#1])-[#8]-[#1])-[#1])-[#1])-[#1])-[#1]	imine_naphthol_a_1_	6	0	0	0	0	6	10	0
820	c12:[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:c:1-[#6](-c1:c(-[#16]-[#6&!H0&!H1]-2):[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:1)-[#8]-[#6]:[#6]	2	het_thio_676_B(1)	8	1772697389	c:1-2:c(:c(:c(:c(:c:1-[#6](-c:3:c(-[#16]-[#6]-2(-[#1])-[#1]):c(:c(-[#1]):c(:c:3-[#1])-[#1])-[#1])-[#8]-[#6]:[#6])-[#1])-[#1])-[#1])-[#1]	het_thio_676_b_1_	4	0	0	0	0	22	10	0
770	c1:c:c:c:c:c:1-[#6](=[#8])-[#7&!H0]-[#7]=[#6]1-c2:c:c:c:c:c:2-c2:c:c:c:c:c:2-1	2	keto_phenone_zone_A(2)	8	1772697389	c:1:c:c:c:c:c:1-[#6](=[#8])-[#7](-[#1])-[#7]=[#6]-3-c:2:c:c:c:c:c:2-c:4:c:c:c:c:c-3:4	keto_phenone_zone_a_2_	48	0	0	0	0	48	10	5
785	c1(:c(:c2:c(:n:c:1-[#7&!H0&!H1]):c:c:c(:c:2-[#7&!H0&!H1])-[#6]#[#7])-[#6]#[#7])-[#6]#[#7]	2	cyano_amino_het_A(1)	8	1772697389	c:1(:c(:c:2:c(:n:c:1-[#7](-[#1])-[#1]):c:c:c(:c:2-[#7](-[#1])-[#1])-[#6]#[#7])-[#6]#[#7])-[#6]#[#7]	cyano_amino_het_a_1_	0	0	0	0	0	0	10	0
753	c12:c(:c:c:c:c:1-,:[#6]-,:[#6]=,:[#6])-,:[#6]=,:[#6](-,:[#6](=[#8])-,:[#7]-,:[#6]-,:[#6])-,:[#6](=[#8])-,:[#8]-,:2	2	coumarin_B(2)	8	1772697389	c:1-2:c(:c:c:c:c:1-[#6](-[#1])(-[#1])-[#6](-[#1])=[#6](-[#1])-[#1])-[#6](=[#6](-[#6](=[#8])-[#7](-[#1])-[#6]:[#6])-[#6](=[#8])-[#8]-2)-[#1]	coumarin_b_2_	159	0	0	0	0	175	10	45
803	[#6&!H0](-c1:[c&!H0]:[c&!H0]:c(:[c&!H0]:[c&!H0]:1)-Cl)(-c1:[c&!H0]:[c&!H0]:c(:[c&!H0]:[c&!H0]:1)-Cl)-[#8]-[#6&!H0&!H1]-[#6&!H0&!H1]-[#6&!H0&!H1]-c1:,-n:,-[c&!H0]-,:[c&!H0]-,:n:,-1-[#6&!H0&!H1&!H2]	2	misc_imidazole(1)	8	1772697389	[#6](-[#1])(-c:1:c(:c(:c(:c(:c:1-[#1])-[#1])-[Cl])-[#1])-[#1])(-c:2:c(:c(:c(:c(:c:2-[#1])-[#1])-[Cl])-[#1])-[#1])-[#8]-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-c3nc(c(n3-[#6](-[#1])(-[#1])-[#1])-[#1])-[#1]	misc_imidazole_1_	0	0	0	0	0	0	10	0
734	c1:,-c:,-s:,-c(-,:c:,-1-[#7&!H0&!H1])-[#6&!H0]=[#6&!H0]-c1:,-c:,-c:,-c:,-s:,-1	2	thiophene_amino_E(2)	8	1772697389	c1csc(c1-[#7](-[#1])-[#1])-[#6](-[#1])=[#6](-[#1])-c2cccs2	thiophene_amino_e_2_	6	0	0	0	0	6	10	2
814	[c&!H0]1:c2:c(:n:[c&!H0]:c:1-[#6&!H0&!H1]-[#7]1-c3:[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:c:3-[#6&!H0&!H1]-[#6&!H0&!H1]-1):[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:2	2	anil_di_alk_M(1)	8	1772697389	c:1(:c:4:c(:n:c(:c:1-[#6](-[#1])(-[#1])-[#7]-3-c:2:c(:c(:c(:c(:c:2-[#6](-[#1])(-[#1])-[#6]-3(-[#1])-[#1])-[#1])-[#1])-[#1])-[#1])-[#1]):c(:c(:c(:c:4-[#1])-[#1])-[#1])-[#1])-[#1]	anil_di_alk_m_1_	1	0	0	0	0	1	10	0
821	[#6&!H0&!H1&!H2]-c1:[c&!H0]:[c&!H0]:[c&!H0]:c(:n:1)-[#7&!H0]-[#16](-c1:[c&!H0]:[c&!H0]:c(:[c&!H0]:[c&!H0]:1)-[#8]-[#6&!H0&!H1]-[#6&!H0&!H1]-[#6&!H0&!H1])(=[#8])=[#8]	2	sulfonamide_G(1)	8	1772697389	[#6](-[#1])(-[#1])(-[#1])-c:1:c(:c(:c(:c(:n:1)-[#7](-[#1])-[#16](-c:2:c(:c(:c(:c(:c:2-[#1])-[#1])-[#8]-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#6](-[#1])-[#1])-[#1])-[#1])(=[#8])=[#8])-[#1])-[#1])-[#1]	sulfonamide_g_1_	1	0	0	0	0	1	10	0
732	c12:c(:c:c:c:n:1):,-c(-,:c(-,:[#6](=[#8])-,:[#8]):,-s:,-2)-[#7&!H0&!H1]	2	anthranil_acid_D(2)	8	1772697389	c:12:c(:c:c:c:n:1)c(c(-[#6](=[#8])~[#8;X1])s2)-[#7](-[#1])-[#1]	anthranil_acid_d_2_	1408	0	0	0	0	1426	10	189
738	[#7]1=[#6](-c2:c:c:c:c:c:2)-[#6&!H0&!H1]-[#6](-[#8&!H0])(-[#6](-[#9])(-[#9])-[#9])-[#7]-1-[$([#6]:[#6]:[#6]:[#6]:[#6]:[#6]),$([#6](=[#16])-[#6]:[#6]:[#6]:[#6]:[#6]:[#6])]	2	het_5_C(2)	8	1772697389	[#7]-2=[#6](-c:1:c:c:c:c:c:1)-[#6](-[#1])(-[#1])-[#6](-[#8]-[#1])(-[#6](-[#9])(-[#9])-[#9])-[#7]-2-[$([#6]:[#6]:[#6]:[#6]:[#6]:[#6]),$([#6](=[#16])-[#6]:[#6]:[#6]:[#6]:[#6]:[#6])]	het_5_c_2_	10	0	0	0	0	36	10	0
754	[#6]1(=[#16])-,:[#7]2-,:[#6]:[#6]-,:[#7]=,:[#7]-,:[#6]-,:2=,:[#7]-,:[#7&!H0]-,:1	2	thio_urea_K(2)	8	1772697389	[#6]-2(=[#16])-[#7]-1-[#6]:[#6]-[#7]=[#7]-[#6]-1=[#7]-[#7]-2-[#1]	thio_urea_k_2_	0	0	0	0	0	0	10	0
790	c1:c:c:c2:c(:c:1)-[#6&!H0&!H1]-[#6&!H0&!H1]-[#7]-2-[#6&!H0&!H1]-[#6&!H0&!H1]-[#7]1-[#6](-c2:c:c:c:c:c:2-[#6]-1=[#8])=[#8]	2	anil_di_alk_L(1)	8	1772697389	c:1:c:c:c-2:c(:c:1)-[#6](-[#6](-[#7]-2-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#7]-4-[#6](-c:3:c:c:c:c:c:3-[#6]-4=[#8])=[#8])(-[#1])-[#1])(-[#1])-[#1]	anil_di_alk_l_1_	11	0	0	0	0	11	10	1
808	c1:c:c2:c(:c:c:1)-[#7](-[#6](-[#8]-[#6]-2)(-[#6](=[#8])-[#8&!H0])-[#6&!H0&!H1])-[#6](=[#8])-[#6&!H0&!H1]	2	misc_aminal_acid(1)	8	1772697389	c:1:c:c-2:c(:c:c:1)-[#7](-[#6](-[#8]-[#6]-2)(-[#6](=[#8])-[#8]-[#1])-[#6](-[#1])-[#1])-[#6](=[#8])-[#6](-[#1])-[#1]	misc_aminal_acid_1_	0	0	0	0	0	0	10	0
831	s1:,-c:,-c:,-n:,-c:,-1-c1:,-c(-,:[n&!H0]-,:n:,-[c&!H0]:,-1)-[#7&!H0&!H1]	2	pyrazole_amino_B(1)	8	1772697389	s1ccnc1-c2c(n(nc2-[#1])-[#1])-[#7](-[#1])-[#1]	pyrazole_amino_b_1_	292	0	0	0	0	296	10	5
741	c12:c3:c(:c(-[#8&!H0]):[c&!H0]:c:1:c(:c:n:2-[#6])-[#6]=[#8]):n:c:n:3	2	het_565_A(2)	8	1772697389	c:1:2:c:3:c(:c(-[#8]-[#1]):c(:c:1:c(:c:n:2-[#6])-[#6]=[#8])-[#1]):n:c:n:3	het_565_a_2_	1	0	0	0	0	1	10	0
791	c1(:c:c:c(:c:c:1)-[#6]1=[#6]-[#6](-c2:,-c:,-o:,-c:,-c:,-2-[#6](=[#6]-1)-[#8&!H0])=[#8])-[#16]-[#6&!H0&!H1]	2	colchicine_B(1)	8	1772697389	c:1(:c:c:c(:c:c:1)-[#6]-3=[#6]-[#6](-c2cocc2-[#6](=[#6]-3)-[#8]-[#1])=[#8])-[#16]-[#6](-[#1])-[#1]	colchicine_b_1_	0	0	0	0	0	0	10	0
825	c1:c:c:c:c2:c:1:c:c1:c(:n:2):n:c2:c(:c:1-[#7]):c:c:c:c:2	2	amino_acridine_A(1)	8	1772697389	c:1:c:c:c:c:2:c:1:c:c:3:c(:n:2):n:c:4:c(:c:3-[#7]):c:c:c:c:4	amino_acridine_a_1_	4	0	0	0	0	5	10	0
840	c1:c:c2:n:c(:c(:n:c:2:c:c:1)-c1:c:c:c:c:c:1)-c1:c:c:c:c:c:1-[#8&!H0]	2	het_66_E(1)	8	1772697389	c:2:c:c:1:n:c(:c(:n:c:1:c:c:2)-c:3:c:c:c:c:c:3)-c:4:c:c:c:c:c:4-[#8]-[#1]	het_66_e_1_	8	0	0	0	0	13	10	0
760	[#6]1(-[#6]=,:[#6]-[#6]=,:[#6]-[#6]-1=[!#6&!#1])=[!#6&!#1]	2	quinone_D(2)	8	1772697389	[#6]-1(-[#6]=,:[#6]-[#6]=,:[#6]-[#6]-1=[!#6&!#1])=[!#6&!#1]	quinone_d_2_	2700	89	45	53	7	4857	10	177
836	c1(-,:c2:,-n(-[#6](-[#6]=[#6]-[#7]-2)=[#8]):,-n:,-c:,-1-c1:,-c:,-c:,-c:,-n:,-1)-[#6]#[#7]	2	het_65_H(1)	8	1772697389	c2(c-1n(-[#6](-[#6]=[#6]-[#7]-1)=[#8])nc2-c3cccn3)-[#6]#[#7]	het_65_h_1_	0	0	0	0	0	0	10	0
755	[#6]:[#6]:[#6]:[#6]:[#6]:[#6]-c1:c:c(:c(:s:1)-[#7&!H0]-[#6](=[#8])-[#6])-[#6](=[#8])-[#8&!H0]	2	thiophene_amino_G(2)	8	1772697389	[#6]:[#6]:[#6]:[#6]:[#6]:[#6]-c:1:c:c(:c(:s:1)-[#7](-[#1])-[#6](=[#8])-[#6])-[#6](=[#8])-[#8]-[#1]	thiophene_amino_g_2_	61	0	0	0	0	69	10	6
837	[#8]=[#6]1-[#6](=[#7]-[#7]-[#6]-[#6]-1)-[#6]#[#7]	2	cyano_imine_D(1)	8	1772697389	[#8]=[#6]-1-[#6](=[#7]-[#7]-[#6]-[#6]-1)-[#6]#[#7]	cyano_imine_d_1_	8	0	0	0	0	8	10	0
839	c1:c:c2:c(:c:c:1)-[#6]=[#6]-[#6](-[#7]-2-[#6](=[#8])-[#7&!H0]-c1:c:c(:c(:c:c:1)-[#8]-[#6&!H0&!H1])-[#8]-[#6&!H0&!H1])(-[#6&!H0&!H1])-[#6&!H0&!H1]	2	ene_misc_C(1)	8	1772697389	c:1:c:c-2:c(:c:c:1)-[#6]=[#6]-[#6](-[#7]-2-[#6](=[#8])-[#7](-[#1])-c:3:c:c(:c(:c:c:3)-[#8]-[#6](-[#1])-[#1])-[#8]-[#6](-[#1])-[#1])(-[#6](-[#1])-[#1])-[#6](-[#1])-[#1]	ene_misc_c_1_	1	0	0	0	0	1	10	0
829	[c&!H0]1-,:[c&!H0]:,-n(-[#6&!H0&!H1]):,-c2:c(:c(:c3:,-n(-,:[c&!H0]-,:[c&!H0]-,:c:3:c:,-1:2)-[#6&!H0&!H1])-[#8]-[#6&!H0&!H1])-[#8]-[#6&!H0&!H1]	2	het_565_indole(1)	8	1772697389	c2(c(-[#1])n(-[#6](-[#1])-[#1])c:3:c(:c(:c:1n(c(c(c:1:c2:3)-[#1])-[#1])-[#6](-[#1])-[#1])-[#8]-[#6](-[#1])-[#1])-[#8]-[#6](-[#1])-[#1])-[#1]	het_565_indole_1_	1	0	0	0	0	1	10	0
735	c1:c:c2:n:c3:c(:n:c:2:c:c:1):c:c:c1:c:3:c:c:c:c:1	2	het_6666_A(2)	8	1772697389	c:2:c:c:1:n:c:3:c(:n:c:1:c:c:2):c:c:c:4:c:3:c:c:c:c:4	het_6666_a_2_	525	0	0	0	0	754	10	38
828	c1(:[c&!H0]:[c&!H0]:c(:[c&!H0]:[c&!H0]:1)-[#7&!H0&!H1])-[#16](=[#8])(=[#8])-[#7&!H0]-c1:n:n:[c&!H0]:[c&!H0]:[c&!H0]:1	2	sulfonamide_H(1)	8	1772697389	c:1(:c(:c(:c(:c(:c:1-[#1])-[#1])-[#7](-[#1])-[#1])-[#1])-[#1])-[#16](=[#8])(=[#8])-[#7](-[#1])-c:2:n:n:c(:c(:c:2-[#1])-[#1])-[#1]	sulfonamide_h_1_	1	0	0	0	0	1	10	1
811	[#7&!H0](-c1:[c&!H0]:c(:c(:[c&!H0]:[c&!H0]:1)-[#8]-[#6&!H0&!H1&!H2])-[#8]-[#6&!H0])-[#6](=[#8])-[#7&!H0]-[#6&!H0&!H1]-[#6&!H0&!H1]-[#6&!H0&!H1]-[#7](-[#6&!H0&!H1&!H2])-[#6]:[#6]	2	misc_anisole_C(1)	8	1772697389	[#7](-[#1])(-c:1:c(:c(:c(:c(:c:1-[#1])-[#1])-[#8]-[#6](-[#1])(-[#1])-[#1])-[#8]-[#6]-[#1])-[#1])-[#6](=[#8])-[#7](-[#1])-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#7](-[#6](-[#1])(-[#1])-[#1])-[#6]:[#6]	misc_anisole_c_1_	2	0	0	0	0	2	10	0
730	c1:c:c:c2:c(:c:1):n:c(:n:c:2)-[#7&!H0]-[#6]1=[#7]-[#6](-[#6]=[#6]-[#7&!H0]-1)(-[#6&!H0&!H1])-[#6&!H0&!H1]	2	het_66_B(2)	8	1772697389	c:1:c:c:c:2:c(:c:1):n:c(:n:c:2)-[#7](-[#1])-[#6]-3=[#7]-[#6](-[#6]=[#6]-[#7]-3-[#1])(-[#6](-[#1])-[#1])-[#6](-[#1])-[#1]	het_66_b_2_	5	0	0	0	0	6	10	2
779	s1:,-c2:n:c:n:c(:c:2:,-c(-,:c:,-1-[#6&!H0&!H1])-[#6&!H0&!H1])-[#7]-[#7]=[#6]-c1:,-c:,-c:,-c:,-o:,-1	2	het_65_F(1)	8	1772697389	s2c:1:n:c:n:c(:c:1c(c2-[#6](-[#1])-[#1])-[#6](-[#1])-[#1])-[#7]-[#7]=[#6]-c3ccco3	het_65_f_1_	17	0	0	0	0	17	10	1
742	[#6&X4]-[#7&+](-[#6&X4]-[#8&!H0])=[#6]-[#16]-[#6&!H0]	2	thio_imine_ium(2)	8	1772697389	[#6;X4]-[#7+](-[#6;X4]-[#8]-[#1])=[#6]-[#16]-[#6]-[#1]	thio_imine_ium_2_	461	0	0	0	0	461	10	16
806	[#7&!H0](-c1:[c&!H0]:[c&!H0]:c(:[c&!H0]:[c&!H0]:1)-[#6&!H0&!H1])-[#6&!H0&!H1]-[#6&!H0&!H1]-c1:[c&!H0]:[c&!H0]:c(:[c&!H0]:[c&!H0]:1)-[#8]-[#6&!H0&!H1]	2	anil_alk_B(1)	8	1772697389	[#7](-[#1])(-c:1:c(:c(:c(:c(:c:1-[#1])-[#1])-[#6](-[#1])-[#1])-[#1])-[#1])-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-c:2:c(:c(:c(:c(:c:2-[#1])-[#1])-[#8]-[#6](-[#1])-[#1])-[#1])-[#1]	anil_alk_b_1_	16	0	0	0	0	16	10	1
764	n1:c(:n(:c2:c:1:c:c:c:c:2)-[#6&!H0&!H1])-[#16]-[#6&!H0&!H1]-[#6](=[#8])-[#7&!H0]-[#7]=[#6&!H0]-[#6&!H0]=[#6&!H0]	2	het_thio_65_C(2)	8	1772697389	n:1:c(:n(:c:2:c:1:c:c:c:c:2)-[#6](-[#1])-[#1])-[#16]-[#6](-[#1])(-[#1])-[#6](=[#8])-[#7](-[#1])-[#7]=[#6](-[#1])-[#6](-[#1])=[#6]-[#1]	het_thio_65_c_2_	41	0	0	0	0	43	10	0
842	c1:c2:c(:c:c3:c:1:,-n:,-c(-,:[n&!H0]:,-3)-[#6]-[#8]-[#6](=[#8])-c1:c:c(:c:c(:c:1)-[#7&!H0&!H1])-[#7&!H0&!H1]):c:c:c:c:2	2	misc_naphthimidazole(1)	8	1772697389	c:1:c:4:c(:c:c2:c:1nc(n2-[#1])-[#6]-[#8]-[#6](=[#8])-c:3:c:c(:c:c(:c:3)-[#7](-[#1])-[#1])-[#7](-[#1])-[#1]):c:c:c:c:4	misc_naphthimidazole_1_	1	0	0	0	0	1	10	0
748	[#7&!H0&!H1]-c1:c(:c(:c(:s:1)-[#7&!H0]-[#6](=[#8])-c1:c:c:c:c:c:1)-[#6]#[#7])-[#6]1:[!#1]:[!#1]:[!#1]:[!#1]:[!#1]:1	2	thiophene_amino_F(2)	8	1772697389	[#7](-[#1])(-[#1])-c:1:c(:c(:c(:s:1)-[#7](-[#1])-[#6](=[#8])-c:2:c:c:c:c:c:2)-[#6]#[#7])-[#6]:3:[!#1]:[!#1]:[!#1]:[!#1]:[!#1]:3	thiophene_amino_f_2_	1	0	0	0	0	1	10	0
749	[#6&!H0&!H1]-[#8]-c1:c(:[c&!H0]:c(:[c&!H0]:[c&!H0]:1)-[#6&!H0&!H1])-[#7&!H0]-[#6&!H0&!H1]-c1:c:c:c:c:c:1-[$([#6](-[#1])-[#1]),$([#8]-[#6](-[#1])-[#1])]	2	anil_OC_alk_D(2)	8	1772697389	[#6](-[#1])(-[#1])-[#8]-c:1:c(:c(:c(:c(:c:1-[#1])-[#1])-[#6](-[#1])-[#1])-[#1])-[#7](-[#1])-[#6](-[#1])(-[#1])-c:2:c:c:c:c:c:2-[$([#6](-[#1])-[#1]),$([#8]-[#6](-[#1])-[#1])]	anil_oc_alk_d_2_	0	0	0	0	0	0	10	0
726	c1(-,:c(-[#7&!H0&!H1]):,-n(-c2:c:c:c:c:c:2-[#6](=[#8])-[#8&!H0]):,-n:,-c:,-1-[#6]=[#8])-[$([#6]#[#7]),$([#6]=[#16])]	2	anthranil_acid_C(2)	8	1772697389	c2(c(-[#7](-[#1])-[#1])n(-c:1:c:c:c:c:c:1-[#6](=[#8])-[#8]-[#1])nc2-[#6]=[#8])-[$([#6]#[#7]),$([#6]=[#16])]	anthranil_acid_c_2_	0	0	0	0	0	0	10	0
739	c1:c(:c:c:c:c:1)-[#6](=[#8])-[#6&!H0]=[#6]1-[#6](=[#8])-[#7&!H0]-[#6](=[#8])-[#6](=[#6&!H0]-c2:c:c:c:c:c:2)-[#7&!H0]-1	2	ene_six_het_B(2)	8	1772697389	c:1:c(:c:c:c:c:1)-[#6](=[#8])-[#6](-[#1])=[#6]-3-[#6](=[#8])-[#7](-[#1])-[#6](=[#8])-[#6](=[#6](-[#1])-c:2:c:c:c:c:c:2)-[#7]-3-[#1]	ene_six_het_b_2_	0	0	0	0	0	0	10	0
795	c1:c:c2:n:c(:c(:n:c:2:c:c:1)-[#6&!H0&!H1]-[#6](=[#8])-[#6]:[#6])-[#6&!H0&!H1]-[#6](=[#8])-[#6]:[#6]	2	het_66_D(1)	8	1772697389	c:2:c:c:1:n:c(:c(:n:c:1:c:c:2)-[#6](-[#1])(-[#1])-[#6](=[#8])-[#6]:[#6])-[#6](-[#1])(-[#1])-[#6](=[#8])-[#6]:[#6]	het_66_d_1_	15	0	0	0	0	15	10	0
788	c1(:[c&!H0]:c2:c(:[c&!H0]:c:1-[#8]-[#6&!H0&!H1]):[c&!H0]:c(:[c&!H0]:c:2-[#7&!H0]-[#6&!H0&!H1&!H2])-c1:[c&!H0]:c(:c(:[c&!H0]:[c&!H0]:1)-[#8]-[#6&!H0&!H1])-[#8]-[#6&!H0&!H1])-[#8]-[#6&!H0&!H1]	2	misc_anisole_A(1)	8	1772697389	c:1(:c(:c:2:c(:c(:c:1-[#8]-[#6](-[#1])-[#1])-[#1]):c(:c(:c(:c:2-[#7](-[#1])-[#6](-[#1])(-[#1])-[#1])-[#1])-c:3:c(:c(:c(:c(:c:3-[#1])-[#1])-[#8]-[#6](-[#1])-[#1])-[#8]-[#6](-[#1])-[#1])-[#1])-[#1])-[#1])-[#8]-[#6](-[#1])-[#1]	misc_anisole_a_1_	1	0	0	0	0	1	10	0
774	c1:c:c:c(:c:c:1-[#7&!H0]-c1:,-n:,-c(-,:[c&!H0]:,-s:,-1)-c1:c:c:c(:c:c:1)-[#6&!H0](-[#6&!H0])-[#6&!H0])-[#6](=[#8])-[#8&!H0]	2	thiazole_amine_H(1)	8	1772697389	c:1:c:c:c(:c:c:1-[#7](-[#1])-c2nc(c(-[#1])s2)-c:3:c:c:c(:c:c:3)-[#6](-[#1])(-[#6]-[#1])-[#6]-[#1])-[#6](=[#8])-[#8]-[#1]	thiazole_amine_h_1_	2	0	0	0	0	2	10	0
797	[#6&!H0&!H1]-c1:,-n:,-n:,-n:,-n:,-1-c1:[c&!H0]:[c&!H0]:c(:[c&!H0]:[c&!H0]:1)-[#8]-[#6&!H0&!H1&!H2]	2	tetrazole_A(1)	8	1772697389	[#6](-[#1])(-[#1])-c1nnnn1-c:2:c(:c(:c(:c(:c:2-[#1])-[#1])-[#8]-[#6](-[#1])(-[#1])-[#1])-[#1])-[#1]	tetrazole_a_1_	246	0	0	0	0	250	10	8
724	[#6]1:[#6]-[#7]=[#6]-[#6](=[#6]-[#7]-[#6])-[#16]-1	2	het_thio_6_ene(2)	8	1772697389	[#6]-1:[#6]-[#7]=[#6]-[#6](=[#6]-[#7]-[#6])-[#16]-1	het_thio_6_ene_2_	30	0	0	0	0	46	10	4
832	c1(-,:[c&!H0]-,:c(-,:c(-,:[n&!H0]:,-1)-c1:[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:1)-[#6&!H0&!H1])-[#6](=[#8])-[#8&!H0]	2	pyrrole_K(1)	8	1772697389	c1(c(c(c(n1-[#1])-c:2:c(:c(:c(:c(:c:2-[#1])-[#1])-[#1])-[#1])-[#1])-[#6](-[#1])-[#1])-[#1])-[#6](=[#8])-[#8]-[#1]	pyrrole_k_1_	3	0	0	0	0	3	10	0
771	c1:c(:c:c:c:c:1)-[#7](-[#6&!H0&!H1])-[#6&!H0]=[#6&!H0]-[#6]=&!@[#6&!H0]-[#6&!H0]=[#6]-[#6]=&@[#7]-c1:c:c:c:c:c:1	2	dyes7A(2)	8	1772697389	c:1:c(:c:c:c:c:1)-[#7](-[#6](-[#1])-[#1])-[#6](-[#1])=[#6](-[#1])-[#6]=!@[#6](-[#1])-[#6](-[#1])=[#6]-[#6]=@[#7]-c:2:c:c:c:c:c:2	dyes7a_2_	20	0	0	0	0	25	10	0
793	n1:c(:n(:c(:c:1-c1:c:c:c:c:c:1)-c1:c:c:c:c:c:1)-[#7]=&!@[#6])-[#7&!H0&!H1]	2	imidazole_amino_A(1)	8	1772697389	n:1:c(:n(:c(:c:1-c:2:c:c:c:c:c:2)-c:3:c:c:c:c:c:3)-[#7]=!@[#6])-[#7](-[#1])-[#1]	imidazole_amino_a_1_	3	0	0	0	0	4	10	1
834	[#6&!H0]-[#6](=[#16])-[#7&!H0]-[#7&!H0]-[#6&!H0]	2	thio_amide_F(1)	8	1772697389	[!#1]:[#6]-[#6](=[#16])-[#7](-[#1])-[#7](-[#1])-[#6]:[!#1]	thio_amide_f_1_	52	0	0	0	0	55	10	0
731	c12:c(:[c&!H0]:[c&!H0]:c(:c:1)-,:[#8]-,:[#6&!H0])-,:c1:c(:[c&!H0]:c(:[c&!H0]:[c&!H0]:1)-,:[#8]-,:[#6&!H0&!H1])-,:[#6](=[#8])-,:[#8]-,:2	2	coumarin_A(2)	8	1772697389	c:1-3:c(:c(:c(:c(:c:1)-[#8]-[#6]-[#1])-[#1])-[#1])-c:2:c(:c(:c(:c(:c:2-[#1])-[#1])-[#8]-[#6](-[#1])-[#1])-[#1])-[#6](=[#8])-[#8]-3	coumarin_a_2_	202	0	0	0	0	202	10	1
743	[#6]1(=[#8])-[#6](=[#6&!H0]-[#7&!H0]-c2:c:c:c:c:c:2-[#6](=[#8])-[#8&!H0])-[#7]=[#6](-c2:c:c:c:c:c:2)-[#8]-1	2	anthranil_acid_E(2)	8	1772697389	[#6]-3(=[#8])-[#6](=[#6](-[#1])-[#7](-[#1])-c:1:c:c:c:c:c:1-[#6](=[#8])-[#8]-[#1])-[#7]=[#6](-c:2:c:c:c:c:c:2)-[#8]-3	anthranil_acid_e_2_	15	0	0	0	0	15	10	0
827	c12:c(:[c&!H0]:c(:[c&!H0]:[c&!H0]:1)-[#8]-[#6&!H0&!H1])-[#6](=[#7]-[#7&!H0]-c1:[c&!H0]:[c&!H0]:c(:[c&!H0]:[c&!H0]:1)-[#6](=[#8])-[#8&!H0])-c1:c-2:[c&!H0]:[c&!H0]:c(:[c&!H0]:1)-[#8]-[#6&!H0&!H1]	2	hzone_acid_A(1)	8	1772697389	c:1-3:c(:c(:c(:c(:c:1-[#1])-[#1])-[#8]-[#6](-[#1])-[#1])-[#1])-[#6](=[#7]-[#7](-[#1])-c:2:c(:c(:c(:c(:c:2-[#1])-[#1])-[#6](=[#8])-[#8]-[#1])-[#1])-[#1])-c:4:c-3:c(:c(:c(:c:4-[#1])-[#8]-[#6](-[#1])-[#1])-[#1])-[#1]	hzone_acid_a_1_	2	0	0	0	0	2	10	2
796	c1(:[c&!H0]:[c&!H0]:c(:c(:[c&!H0]:1)-[#8]-[#6&!H0&!H1])-[#8]-[#6&!H0&!H1])-[#6](=[#8])-[#6&!H0&!H1]-[#7](-[#6&!H0&!H1])-c1:c:c:c(-[#6&!H0&!H1]):,-c:c:1	2	misc_anisole_B(1)	8	1772697389	c:1(:c(:c(:c(:c(:c:1-[#1])-[#8]-[#6](-[#1])-[#1])-[#8]-[#6](-[#1])-[#1])-[#1])-[#1])-[#6](=[#8])-[#6](-[#1])(-[#1])-[#7](-[#6](-[#1])-[#1])-c:2:c:c:c(-[#6](-[#1])-[#1])c:c:2	misc_anisole_b_1_	1	0	0	0	0	1	10	0
783	[#6&X4]-[#16&X2]-[#6](=[#7]-[!#1]:[!#1]:[!#1]:[!#1])-[#7&!H0]-[#7]=[#6]	2	thio_urea_L(1)	8	1772697389	[#6;X4]-[#16;X2]-[#6](=[#7]-[!#1]:[!#1]:[!#1]:[!#1])-[#7](-[#1])-[#7]=[#6]	thio_urea_l_1_	1021	0	0	0	0	1024	10	2
750	[#6&!H0&!H1&!H2]-[#6](-[#6&!H0&!H1&!H2])(-[#6&!H0&!H1&!H2])-c1:[c&!H0]:c:c(:c(:[c&!H0]:1)-[#6](-[#6&!H0&!H1&!H2])(-[#6&!H0&!H1&!H2])-[#6&!H0&!H1&!H2])-[#8]-[#6&!H0]-[#7]	2	tert_butyl_A(2)	8	1772697389	[#6](-[#1])(-[#1])(-[#1])-[#6](-[#6](-[#1])(-[#1])-[#1])(-[#6](-[#1])(-[#1])-[#1])-c:1:c(:c:c(:c(:c:1-[#1])-[#6](-[#6](-[#1])(-[#1])-[#1])(-[#6](-[#1])(-[#1])-[#1])-[#6](-[#1])(-[#1])-[#1])-[#8]-[#6](-[#1])-[#7])-[#1]	tert_butyl_a_2_	34	0	0	0	0	34	10	16
799	[#6](-[#6]:[#6])(-[#6]:[#6])(-[#6]:[#6])-[#16]-[#6]:[#6]-[#6](=[#8])-[#8&!H0]	2	misc_trityl_A(1)	8	1772697389	[#6](-[#6]:[#6])(-[#6]:[#6])(-[#6]:[#6])-[#16]-[#6]:[#6]-[#6](=[#8])-[#8]-[#1]	misc_trityl_a_1_	4	0	0	0	0	4	10	0
736	[#6]:[#6]-[#7&!H0]-[#16](=[#8])(=[#8])-[#7&!H0]-[#6]:[#6]	2	sulfonamide_E(2)	8	1772697389	[#6]:[#6]-[#7](-[#1])-[#16](=[#8])(=[#8])-[#7](-[#1])-[#6]:[#6]	sulfonamide_e_2_	34	0	0	0	0	60	10	9
747	[#6]1(-[#6]=[#8])(-[#6]:[#6])-[#16&X2]-[#6]=[#7]-[#7&!H0]-1	2	het_thio_5_B(2)	8	1772697389	[#6]-1(-[#6]=[#8])(-[#6]:[#6])-[#16;X2]-[#6]=[#7]-[#7]-1-[#1]	het_thio_5_b_2_	110	0	0	0	0	152	10	16
762	[#8]=[#6]1-[#6]:[#6]-[#6&!H0&!H1]-[#7]-[#6]-1=[#6&!H0]	2	ene_six_het_C(2)	8	1772697389	[#8]=[#6]-1-[#6]:[#6]-[#6](-[#1])(-[#1])-[#7]-[#6]-1=[#6]-[#1]	ene_six_het_c_2_	0	0	0	0	0	1	10	0
759	[#6]1~[#6](~[#7]~[#7]~[#6](~[#6&!H0&!H1])~[#6&!H0&!H1])~[#7]~[#16]~[#6]~1	2	het_thio_N_5B(2)	8	1772697389	[#6]~1~[#6](~[#7]~[#7]~[#6](~[#6](-[#1])-[#1])~[#6](-[#1])-[#1])~[#7]~[#16]~[#6]~1	het_thio_n_5b_2_	37	0	0	0	0	37	10	2
725	[#6&!H0&!H1]-[#6&!H0](-[#6]#[#7])-[#6](=[#8])-[#6]	2	cyano_keto_A(2)	8	1772697389	[#6](-[#1])(-[#1])-[#6](-[#1])(-[#6]#[#7])-[#6](=[#8])-[#6]	cyano_keto_a_2_	6029	0	0	0	0	6103	10	170
729	c1:,-c:,-s:,-c(-,:n:,-1)-[#7]-[#7]-[#16](=[#8])=[#8]	2	thiazole_amine_G(2)	8	1772697389	c1csc(n1)-[#7]-[#7]-[#16](=[#8])=[#8]	thiazole_amine_g_2_	39	0	0	0	0	48	10	0
841	[#6&!H0&!H1]-[#6](-[#8&!H0])=[#6](-[#6](=[#8])-[#6&!H0&!H1])-[#6&!H0]-[#6]#[#6]	2	keto_keto_beta_F(1)	8	1772697389	[#6](-[#1])(-[#1])-[#6](-[#8]-[#1])=[#6](-[#6](=[#8])-[#6](-[#1])-[#1])-[#6](-[#1])-[#6]#[#6]	keto_keto_beta_f_1_	12	0	0	0	0	12	10	1
833	c12(:[c&!H0]:[c&!H0]:c(:o:1)-,:[#6])-,:[#6](=[#8])-,:[#7&!H0]-,:[#6]:[#6&!H0]:[#6&!H0]:[#6&!H0]:[#6&!H0]:[#6]:2-[#6](=[#8])-[#8&!H0]	2	anthranil_acid_I(1)	8	1772697389	c:1:2(:c(:c(:c(:o:1)-[#6])-[#1])-[#1])-[#6](=[#8])-[#7](-[#1])-[#6]:[#6](-[#1]):[#6](-[#1]):[#6](-[#1]):[#6](-[#1]):[#6]:2-[#6](=[#8])-[#8]-[#1]	anthranil_acid_i_1_	0	0	0	0	0	0	10	0
801	[#7]1=[#6](-[#7&!H0]-[#6](-[#6&!H0&!H1]-[#6&!H0]-1-[#6]:[#6])=[#8])-[#7&!H0]	2	het_6_hydropyridone(1)	8	1772697389	[#7]-1=[#6](-[#7](-[#6](-[#6](-[#6]-1(-[#1])-[#6]:[#6])(-[#1])-[#1])=[#8])-[#1])-[#7]-[#1]	het_6_hydropyridone_1_	401	0	0	0	0	421	10	4
792	[#6&X4]-c1:[c&!H0]:[c&!H0]:c(:[c&!H0]:[c&!H0]:1)-[#6](=[#8])-[#7&!H0]-[#6&!H0](-[#6&!H0&!H1]-[#6&!H0&!H1]-[#16]-[#6&!H0&!H1&!H2])-[#6](=[#8])-[#8&!H0]	2	misc_aminoacid_A(1)	8	1772697389	[#6;X4]-c:1:c(:c(:c(:c(:c:1-[#1])-[#1])-[#6](=[#8])-[#7](-[#1])-[#6](-[#1])(-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#1])-[#16]-[#6](-[#1])(-[#1])-[#1])-[#6](=[#8])-[#8]-[#1])-[#1])-[#1]	misc_aminoacid_a_1_	35	0	0	0	0	37	10	10
824	c12:c3:c(:c(:c:c:1)-[#7]):c:c:c:c:3-[#6](-[#6]=[#6]-2-[#6](-F)(-F)-F)=[#8]	2	naphth_ene_one_B(1)	8	1772697389	c:1-3:c:2:c(:c(:c:c:1)-[#7]):c:c:c:c:2-[#6](-[#6]=[#6]-3-[#6](-[F])(-[F])-[F])=[#8]	naphth_ene_one_b_1_	2	0	0	0	0	2	10	0
810	[#7&!H0](-c1:c:c:c:c:c:1)-[#6](-[#6])(-[#6])-c1:[c&!H0]:[c&!H0]:c(:[c&!H0]:[c&!H0]:1)-[#8]-[#6&!H0&!H1]	2	anil_alk_C(1)	8	1772697389	[#7](-[#1])(-c:1:c:c:c:c:c:1)-[#6](-[#6])(-[#6])-c:2:c(:c(:c(:c(:c:2-[#1])-[#1])-[#8]-[#6](-[#1])-[#1])-[#1])-[#1]	anil_alk_c_1_	242	0	0	0	0	243	10	0
812	c12:c:c3:c(:c:c:1-[#8]-[#6]-[#8]-2)-[#6]-[#6]-3	2	het_465_misc(1)	8	1772697389	c:1-2:c:c-3:c(:c:c:1-[#8]-[#6]-[#8]-2)-[#6]-[#6]-3	het_465_misc_1_	30	1	0	0	0	33	10	11
800	[#8]=[#6](-c1:[c&!H0]:c(:n:c(:[c&!H0]:1)-[#8]-[#6&!H0&!H1&!H2])-[#8]-[#6&!H0&!H1&!H2])-[#7&!H0]-[#6&!H0](-[#6&!H0&!H1])-[#6&!H0&!H1]	2	misc_pyridine_OC(1)	8	1772697389	[#8]=[#6](-c:1:c(:c(:n:c(:c:1-[#1])-[#8]-[#6](-[#1])(-[#1])-[#1])-[#8]-[#6](-[#1])(-[#1])-[#1])-[#1])-[#7](-[#1])-[#6](-[#1])(-[#6](-[#1])-[#1])-[#6](-[#1])-[#1]	misc_pyridine_oc_1_	2	0	0	0	0	2	10	2
733	c12:n:c(:c(:n:c:1:[#6]:[#6]:[#6]:[!#1]:2)-[#6&!H0]=[#6](-[#8&!H0])-[#6])-[#6&!H0]=[#6](-[#8&!H0])-[#6]	2	het_66_C(2)	8	1772697389	c:1:2:n:c(:c(:n:c:1:[#6]:[#6]:[#6]:[!#1]:2)-[#6](-[#1])=[#6](-[#8]-[#1])-[#6])-[#6](-[#1])=[#6](-[#8]-[#1])-[#6]	het_66_c_2_	7	0	0	0	0	12	10	1
798	[#6]1(=[#7]-c2:,-c(-,:c(-,:n:,-n:,-2-[#6](-[#6&!H0&!H1]-1)=[#8])-[#7&!H0&!H1])-[#7&!H0&!H1])-[#6]	2	het_65_G(1)	8	1772697389	[#6]-2(=[#7]-c1c(c(nn1-[#6](-[#6]-2(-[#1])-[#1])=[#8])-[#7](-[#1])-[#1])-[#7](-[#1])-[#1])-[#6]	het_65_g_1_	0	0	0	0	0	0	10	0
786	[!#1]1:[!#1]:[!#1]:[!#1](:[!#1]:[!#1]:1)-[#6&!H0]=[#6&!H0]-[#6](-[#7&!H0]-[#7&!H0]-c1:,-n:,-n:,-n:,-n:,-1-[#6])=[#8]	2	tetrazole_hzide(1)	8	1772697389	[!#1]:1:[!#1]:[!#1]:[!#1](:[!#1]:[!#1]:1)-[#6](-[#1])=[#6](-[#1])-[#6](-[#7](-[#1])-[#7](-[#1])-c2nnnn2-[#6])=[#8]	tetrazole_hzide_1_	2	0	0	0	0	2	10	0
73	[C&X4]-,:[C&R0](=O)-,:[C&X4]	1	ketone-acyclic-sp3-sp3	14	1772517372	[CX4][CR0](=O)[CX4]	ketone-acyclic-sp3-sp3	312222	123	369	485	88	313009	0	13953
781	[c&!H0]1:c2-[#6](-[#6](-[#6&!H0&!H1]-c:2:[c&!H0]:[c&!H0]:[c&!H0]:1)=[#8])=[#6](-[#6&!H0&!H1])-[#6&!H0&!H1]	2	ene_five_one_B(1)	8	1772697389	c:2(:c:1-[#6](-[#6](-[#6](-c:1:c(:c(:c:2-[#1])-[#1])-[#1])(-[#1])-[#1])=[#8])=[#6](-[#6](-[#1])-[#1])-[#6](-[#1])-[#1])-[#1]	ene_five_one_b_1_	2	0	0	0	0	2	10	1
756	[#7&!H0&!H1]-c1:[c&!H0]:[c&!H0]:[c&!H0]:c:c:1-[#7&!H0]-[#6&!H0](-[#6])-[#6&!H0]-[#6&!H0&!H1]	2	anil_NH_alk_D(2)	8	1772697389	[#7](-[#1])(-[#1])-c:1:c(:c(:c(:c:c:1-[#7](-[#1])-[#6](-[#1])(-[#6])-[#6](-[#1])-[#6](-[#1])-[#1])-[#1])-[#1])-[#1]	anil_nh_alk_d_2_	5443	0	0	0	0	5447	10	23
780	[#6](=[#8])-[#6&!H0]=[#6](-[#8&!H0])-[#6](-[#8&!H0])=[#6&!H0]-[#6](=[#8])-[#6]	2	keto_keto_beta_E(1)	8	1772697389	[#6](=[#8])-[#6](-[#1])=[#6](-[#8]-[#1])-[#6](-[#8]-[#1])=[#6](-[#1])-[#6](=[#8])-[#6]	keto_keto_beta_e_1_	41	0	0	0	0	41	10	3
826	c1:c2:c(:c:c:c:1)-[#6]1=[#7]-[!#1]=[#6]-[#6]-[#6]-1-[#6]-2=[#8]	2	keto_phenone_B(1)	8	1772697389	c:1:c-3:c(:c:c:c:1)-[#6]-2=[#7]-[!#1]=[#6]-[#6]-[#6]-2-[#6]-3=[#8]	keto_phenone_b_1_	276	0	0	0	0	276	10	28
815	c1:c(:c2:c(:c:c:1):,-c(-,:c(-,:[n&!H0]:,-2)-[#6]:[#6])-[#6]:[#6])-[#6](=[#8])-[#8&!H0]	2	anthranil_acid_H(1)	8	1772697389	c:1:c(:c2:c(:c:c:1)c(c(n2-[#1])-[#6]:[#6])-[#6]:[#6])-[#6](=[#8])-[#8]-[#1]	anthranil_acid_h_1_	1	0	0	0	0	91	10	1
784	[#6]1(=[#7]-[#7](-[#6](-[#16]-1)=[#6&!H0]-[#6]:[#6])-[#6]:[#6])-[#6]=[#8]	2	het_thio_urea_ene(1)	8	1772697389	[#6]-1(=[#7]-[#7](-[#6](-[#16]-1)=[#6](-[#1])-[#6]:[#6])-[#6]:[#6])-[#6]=[#8]	het_thio_urea_ene_1_	10	0	0	0	0	10	10	0
822	[#6](=[#8])(-[#7]1-[#6]-[#6]-[#16]-[#6]-[#6]-1)-c1:[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:c:1-[#16]-[#6&!H0&!H1]	2	thio_thiomorph_Z(1)	8	1772697389	[#6](=[#8])(-[#7]-1-[#6]-[#6]-[#16]-[#6]-[#6]-1)-c:2:c(:c(:c(:c(:c:2-[#16]-[#6](-[#1])-[#1])-[#1])-[#1])-[#1])-[#1]	thio_thiomorph_z_1_	637	0	0	0	0	637	10	0
727	c1:c2:c:c:c:c3:c:2:c(:c:c:1)-[#7&!H0]-[#7]=[#6]-3	2	naphth_amino_C(2)	8	1772697389	c:2:c:1:c:c:c:c-3:c:1:c(:c:c:2)-[#7](-[#7]=[#6]-3)-[#1]	naphth_amino_c_2_	0	0	0	0	0	0	10	0
843	c1(:c2:c:c:c:c3:c:2:c(:c:c:1)-[#6]=[#6]-[#6]-3=[#7])-[#7]	2	naphth_ene_one_C(1)	8	1772697389	c:2(:c:1:c:c:c:c-3:c:1:c(:c:c:2)-[#6]=[#6]-[#6]-3=[#7])-[#7]	naphth_ene_one_c_1_	2	0	0	0	0	2	10	1
746	[#6]:[#6]-[#6&!H0&!H1]-[#6&!H0](-[#6]=[#8])-[#7]1-[#6](=[#8])-[#6&!H0]2-[#6&!H0&!H1]-[#6]=[#6]-[#6&!H0&!H1]-[#6&!H0]-2-[#6]-1=[#8]	2	ene_misc_B(2)	8	1772697389	[#6]:[#6]-[#6](-[#1])(-[#1])-[#6](-[#1])(-[#6]=[#8])-[#7]-2-[#6](=[#8])-[#6]-1(-[#1])-[#6](-[#1])(-[#1])-[#6]=[#6]-[#6](-[#1])(-[#1])-[#6]-1(-[#1])-[#6]-2=[#8]	ene_misc_b_2_	294	0	0	0	0	300	10	5
773	[#7]1(-c2:c:c:c:c:c:2)-[#7]=[#6](-[#6&!H0&!H1])-[#6&!H0](-[#16]-[#6])-[#6]-1=[#8]	2	het_5_D(2)	8	1772697389	[#7]-2(-c:1:c:c:c:c:c:1)-[#7]=[#6](-[#6](-[#1])-[#1])-[#6](-[#1])(-[#16]-[#6])-[#6]-2=[#8]	het_5_d_2_	56	0	0	0	0	58	10	2
171	[C&X4]-[C&X4&D3](-O-[#6])-C(=O)-O-[#6]	1	enolizable ketone R1=alkyl,R2=Or,R3=OR	14	1772517372	[CX4]-[CX4D3](-O-[#6])-C(=O)-O-[#6]	hartwig-1234	18514	12	2	12	0	18534	0	1559
805	[#7&!H0](-c1:c(:[c&!H0]:[c&!H0]:[c&!H0]:[c&!H0]:1)-[#8&!H0])-[#6]1=[#6](-[#8]-[#6](-[#7]=[#7]-1)=[#7])-[#7&!H0&!H1]	2	het_6_imidate_B(1)	8	1772697389	[#7](-[#1])(-c:1:c(:c(:c(:c(:c:1-[#1])-[#1])-[#1])-[#1])-[#8]-[#1])-[#6]-2=[#6](-[#8]-[#6](-[#7]=[#7]-2)=[#7])-[#7](-[#1])-[#1]	het_6_imidate_b_1_	0	0	0	0	0	0	10	0
835	[#6]1(=[#8])-[#6](-[#6](-[#6]#[#7])=[#6&!H0]-[#7])-[#6](-[#7])-[#6]=[#6]-1	2	ene_one_C(1)	8	1772697389	[#6]-1(=[#8])-[#6](-[#6](-[#6]#[#7])=[#6](-[#1])-[#7])-[#6](-[#7])-[#6]=[#6]-1	ene_one_c_1_	4	0	0	0	0	4	10	0
772	[#6]12:[!#1]:[#7&+](:[!#1]:[#6](:[!#1]:1:[#6]:[#6]:[#6]:[#6]:2)-*)~[#6]:[#6]	2	het_pyridiniums_B(2)	8	1772697389	[#6]:1:2:[!#1]:[#7+](:[!#1]:[#6;!H0,$([#6]-[*])](:[!#1]:1:[#6]:[#6]:[#6]:[#6]:2))~[#6]:[#6]	het_pyridiniums_b_2_	60	1	0	0	0	78	10	10
768	[#6&!H0]-[#7&!H0]-c1:c(:c(:c(:s:1)-[#6&!H0])-[#6&!H0])-[#6](=[#8])-[#7&!H0]-[#6]:[#6]	2	thiophene_amino_H(2)	8	1772697389	[#6](-[#1])-[#7](-[#1])-c:1:c(:c(:c(:s:1)-[#6]-[#1])-[#6]-[#1])-[#6](=[#8])-[#7](-[#1])-[#6]:[#6]	thiophene_amino_h_2_	376	0	0	0	0	380	10	0
807	c1:c:c2:c(:c:c:1)-c1:c:c:c(:c:c:1-[#6]-2=[#6&!H0]-[#6])-[#7&!H0&!H1]	2	styrene_anil_A(1)	8	1772697389	c:1:c:c-3:c(:c:c:1)-c:2:c:c:c(:c:c:2-[#6]-3=[#6](-[#1])-[#6])-[#7](-[#1])-[#1]	styrene_anil_a_1_	8	0	0	0	0	8	10	0
728	c1:c2:c:c:c:c3:c:2:c(:c:c:1)-[#7]-[#7]=[#7]-3	2	naphth_amino_D(2)	8	1772697389	c:2:c:1:c:c:c:c-3:c:1:c(:c:c:2)-[#7]-[#7]=[#7]-3	naphth_amino_d_2_	0	0	0	0	0	0	10	0
757	[#16]=[#6]1-[#7&!H0]-[#7]=[#6](-c2:[c&!H0]:[c&!H0]:c(:[c&!H0]:[c&!H0]:2)-[#8]-[#6&!H0&!H1])-[#8]-1	2	het_thio_5_C(2)	8	1772697389	[#16]=[#6]-2-[#7](-[#1])-[#7]=[#6](-c:1:c(:c(:c(:c(:c:1-[#1])-[#1])-[#8]-[#6](-[#1])-[#1])-[#1])-[#1])-[#8]-2	het_thio_5_c_2_	0	0	0	0	0	0	10	0
809	n1:c(:c(:[c&!H0]:c(:c:1-[#7&!H0&!H1])-[#6&!H0&!H1])-[#6&!H0&!H1])-[#7&!H0&!H1]	2	anil_no_alk_D(1)	8	1772697389	n:1:c(:c(:c(:c(:c:1-[#7](-[#1])-[#1])-[#6](-[#1])-[#1])-[#1])-[#6](-[#1])-[#1])-[#7](-[#1])-[#1]	anil_no_alk_d_1_	3	0	0	0	0	5	10	1
823	c1:c:c2:c3:c(:c:1)-[#6](-[#6]=[#6](-c:3:c:c:c:2)-[#8]-[#6&!H0&!H1])=[#8]	2	naphth_ene_one_A(1)	8	1772697389	c:1:c:c:3:c:2:c(:c:1)-[#6](-[#6]=[#6](-c:2:c:c:c:3)-[#8]-[#6](-[#1])-[#1])=[#8]	naphth_ene_one_a_1_	0	0	0	0	0	40	10	0
775	[#6&!H0&!H1]-[#7&!H0]-[#6]=[#7]-[#7&!H0]-c1:,-n:,-c(-,:[c&!H0]:,-s:,-1)-[#6]:[#6]	2	thiazole_amine_I(1)	8	1772697389	[#6](-[#1])(-[#1])-[#7](-[#1])-[#6]=[#7]-[#7](-[#1])-c1nc(c(-[#1])s1)-[#6]:[#6]	thiazole_amine_i_1_	7	0	0	0	0	7	10	0
819	c1:c(:n:c:c:c:1)-[#6](=[#16])-[#7&!H0]-c1:c(:c:c:c:c:1)-[#8]-[#6&!H0&!H1]	2	thio_amide_E(1)	8	1772697389	c:1:c(:n:c:c:c:1)-[#6](=[#16])-[#7](-[#1])-c:2:c(:c:c:c:c:2)-[#8]-[#6](-[#1])-[#1]	thio_amide_e_1_	1	0	0	0	0	1	10	0
47	[N&D2]-,:[S&R0](=O)=O	1	sulfonamide-secondary	14	1772517372	[ND2][SR0](=O)=O	sulfonamide-secondary	516084	87	15	151	52	516213	0	36386
158	c-I	1	aryl-iodide	14	1772517372	cI	aryl-iodide	407488	31	14	103	32	407542	0	19495
761	[#6&!H0&!H1]-[#7](-[#6&!H0&!H1])-c1:[c&!H0]:[c&!H0]:c(:o:1)-[#6&!H0]=[#6]-[#6]#[#7]	2	anil_di_alk_furan_B(2)	8	1772697389	[#6](-[#1])(-[#1])-[#7](-[#6](-[#1])-[#1])-c:1:c(-[#1]):c(:c(:o:1)-[#6](-[#1])=[#6]-[#6]#[#7])-[#1]	anil_di_alk_furan_b_2_	794	1	0	0	0	795	10	21
737	c1:c:c(:c:c:c:1-[#7&!H0&!H1])-[#7](-[#6&X3])-[#6&X3]	2	anil_di_alk_K(2)	8	1772697389	c:1:c:c(:c:c:c:1-[#7](-[#1])-[#1])-[#7](-[#6;X3])-[#6;X3]	anil_di_alk_k_2_	5855	0	0	0	0	5866	10	59
782	[#6]:[#6]-[#7&!H0]-[#7]=[#6](-[#6&!H0&!H1])-[#6&!H0&!H1]-[#6](-[#6&!H0&!H1])=[#7]-[#7&!H0]-[#6]:[#6]	2	keto_keto_beta_zone(1)	8	1772697389	[#6]:[#6]-[#7](-[#1])-[#7]=[#6](-[#6](-[#1])-[#1])-[#6](-[#1])(-[#1])-[#6](-[#6](-[#1])-[#1])=[#7]-[#7](-[#1])-[#6]:[#6]	keto_keto_beta_zone_1_	5	0	0	0	0	5	10	1
804	n1:c(:[c&!H0]:[c&!H0]:c(:[c&!H0]:1)-[#7&!H0&!H1])-[#7&!H0]-[#6]:[#6]	2	anil_NH_no_alk_A(1)	8	1772697389	n:1:c(:c(:c(:c(:c:1-[#1])-[#7](-[#1])-[#1])-[#1])-[#1])-[#7](-[#1])-[#6]:[#6]	anil_nh_no_alk_a_1_	443	0	0	0	0	444	10	4
777	[#8]=[#16](=[#8])(-[#6]:[#6])-[#7&!H0]-c1:,-n:,-c(-,:c:,-s:,-1)-[#6]:[#6]	2	sulfonamide_F(1)	8	1772697389	[#8]=[#16](=[#8])(-[#6]:[#6])-[#7](-[#1])-c1nc(cs1)-[#6]:[#6]	sulfonamide_f_1_	8116	0	0	0	0	8182	10	10
751	c1(:c(:o:c:c:1)-[#6&!H0])-[#6]=[#7]-[#7&!H0]-[#6](=[#16])-[#7&!H0]	2	thio_urea_J(2)	8	1772697389	c:1(:c(:o:c:c:1)-[#6]-[#1])-[#6]=[#7]-[#7](-[#1])-[#6](=[#16])-[#7]-[#1]	thio_urea_j_2_	566	0	0	0	0	566	10	2
44	[C&D3&X4]-,:[O&D1]	1	alcohol-secondary	14	1772517372	[CD3X4][OD1]	alcohol-secondary	2106717	2708	3327	4434	751	2109469	0	86771
765	c1(:c:c(:c(:c:c:1)-[#8&!H0])-[#6](=&!@[#6]-[#7])-[#6]=[#8])-[#8&!H0]	2	hydroquin_A(2)	8	1772697389	c:1(:c:c(:c(:c:c:1)-[#8]-[#1])-[#6](=!@[#6]-[#7])-[#6]=[#8])-[#8]-[#1]	hydroquin_a_2_	15	0	0	0	0	15	10	2
763	[#6]:[#6]-[#7]1:[#7]:[#6]2-[#6&!H0&!H1]-[#16&X2]-[#6&!H0&!H1]-[#6]:2-[#6]:1-[#7&!H0]-[#6](=[#8])-[#6&!H0]=[#6&!H0]	2	het_55_A(2)	8	1772697389	[#6]:[#6]-[#7]:2:[#7]:[#6]:1-[#6](-[#1])(-[#1])-[#16;X2]-[#6](-[#1])(-[#1])-[#6]:1-[#6]:2-[#7](-[#1])-[#6](=[#8])-[#6](-[#1])=[#6]-[#1]	het_55_a_2_	0	0	0	0	0	0	10	0
766	c1(:c:c(:c(:c:c:1)-[#7&!H0]-[#6](=[#8])-[#6]:[#6])-[#6](=[#8])-[#8&!H0])-[#8&!H0]	2	anthranil_acid_F(2)	8	1772697389	c:1(:c:c(:c(:c:c:1)-[#7](-[#1])-[#6](=[#8])-[#6]:[#6])-[#6](=[#8])-[#8]-[#1])-[#8]-[#1]	anthranil_acid_f_2_	436	1	0	0	0	438	10	19
813	c1(:c(:[c&!H0]:c(:[c&!H0]:[c&!H0]:1)-[#8]-[#6&!H0&!H1])-[#6](=[#8])-[#8&!H0])-[#7&!H0]-[#6]:[#6]	2	anthranil_acid_G(1)	8	1772697389	c:1(:c(:c(:c(:c(:c:1-[#1])-[#1])-[#8]-[#6](-[#1])-[#1])-[#1])-[#6](=[#8])-[#8]-[#1])-[#7](-[#1])-[#6]:[#6]	anthranil_acid_g_1_	10	0	0	0	0	28	10	3
830	c1(-,:c2:,-c(-,:c(-,:n:,-1-[#6](-[#8])=[#8])-[#6&!H0&!H1])-[#16]-[#6&!H0&!H1]-[#16]-2)-[#6&!H0&!H1]	2	pyrrole_J(1)	8	1772697389	c1(c-2c(c(n1-[#6](-[#8])=[#8])-[#6](-[#1])-[#1])-[#16]-[#6](-[#1])(-[#1])-[#16]-2)-[#6](-[#1])-[#1]	pyrrole_j_1_	1	0	0	0	0	1	10	1
160	c-Br	1	aryl-bromide	14	1772517372	cBr	aryl-bromide	2416891	129	19	105	22	2417271	0	125817
159	c-Cl	1	aryl-chloride	14	1772517372	cCl	aryl-chloride	2949308	347	95	819	298	2950148	0	246007
817	n1:c2:c(:c:c3:c:1:,-n:,-c(-,:s:,-3)-[#7]):,-s:,-c(-,:n:,-2)-[#7]	2	thiazole_amine_K(1)	8	1772697389	n:1:c3:c(:c:c2:c:1nc(s2)-[#7])sc(n3)-[#7]	thiazole_amine_k_1_	2	0	0	0	0	2	10	1
802	[#6]1(=[#6](-[#6&!H0&!H1]-[#6&!H0](-[#6&!H0](-[#6&!H0&!H1]-1)-[#6](=[#8])-[#6])-[#6](=[#8])-[#8&!H0])-[#6]:[#6])-[#6]:[#6]	2	misc_stilbene(1)	8	1772697389	[#6]-1(=[#6](-[#6](-[#6](-[#6](-[#6]-1(-[#1])-[#1])(-[#1])-[#6](=[#8])-[#6])(-[#1])-[#6](=[#8])-[#8]-[#1])(-[#1])-[#1])-[#6]:[#6])-[#6]:[#6]	misc_stilbene_1_	4	0	0	0	0	4	10	0
776	[#6]:[#6]-[#7&!H0]-[#6](=[#8])-c1:,-c(-,:s:,-n:,-n:,-1)-[#7&!H0]-[#6]:[#6]	2	het_thio_N_5C(1)	8	1772697389	[#6]:[#6]-[#7](-[#1])-[#6](=[#8])-c1c(snn1)-[#7](-[#1])-[#6]:[#6]	het_thio_n_5c_1_	3	0	0	0	0	3	10	0
769	[#6]:[#6]-[#7&!R]=[#6]1-[#6](=[!#6&!#1])-c2:c:c:c:c:c:2-[#7]-1	2	imine_one_fives_C(2)	8	1772697389	[#6]:[#6]-[#7;!R]=[#6]-2-[#6](=[!#6&!#1])-c:1:c:c:c:c:c:1-[#7]-2	imine_one_fives_c_2_	5	0	0	0	0	5	10	2
758	[#16]=[#6]-c1:c:c:c2:c:c:c:c:n:1:2	2	thio_keto_het(2)	8	1772697389	[#16]=[#6]-c:1:c:c:c:2:c:c:c:c:n:1:2	thio_keto_het_2_	32	0	0	0	0	33	10	5
778	[#8]=[#16](=[#8])(-[#6]:[#6])-[#7&!H0]-[#7&!H0]-c1:,-n:,-c(-,:c:,-s:,-1)-[#6]:[#6]	2	thiazole_amine_J(1)	8	1772697389	[#8]=[#16](=[#8])(-[#6]:[#6])-[#7](-[#1])-[#7](-[#1])-c1nc(cs1)-[#6]:[#6]	thiazole_amine_j_1_	16	0	0	0	0	16	10	0
838	c1(:c2:c:c:c:c:c:2:n:n:c:1)-[#6](-[#6]:[#6])-[#6]#[#7]	2	cyano_misc_A(1)	8	1772697389	c:2(:c:1:c:c:c:c:c:1:n:n:c:2)-[#6](-[#6]:[#6])-[#6]#[#7]	cyano_misc_a_1_	6	0	0	0	0	6	10	0
752	[#7&!H0]-c1:,-n:,-c(-,:n:,-c2:,-n:,-n:,-c(-,:n:,-1:,-2)-[#16]-[#6])-[#7&!H0]-[#6]	2	het_thio_65_B(2)	8	1772697389	[#7](-[#1])-c1nc(nc2nnc(n12)-[#16]-[#6])-[#7](-[#1])-[#6]	het_thio_65_b_2_	1305	0	0	0	0	1309	10	19
789	c1:c:c2:c(:c:c:1)-[#16]-c1:,-c(-[#7]-2):,-c:,-c(-,:s:,-1)-[#6&!H0&!H1]	2	het_thio_665(1)	8	1772697389	c:1:c:c-2:c(:c:c:1)-[#16]-c3c(-[#7]-2)cc(s3)-[#6](-[#1])-[#1]	het_thio_665_1_	9	0	0	0	0	9	10	0
767	n1(-[#6&!H0&!H1]):,-c2:,-c(-[#6]:[#6]-[#6]-2=[#8]):,-c:,-c:,-1-[#6&!H0&!H1]	2	pyrrole_I(2)	8	1772697389	n2(-[#6](-[#1])-[#1])c-1c(-[#6]:[#6]-[#6]-1=[#8])cc2-[#6](-[#1])-[#1]	pyrrole_i_2_	7	0	0	0	0	7	10	3
740	[#8]=[#6]1-[#6]-[#6]-[#6]2-[#6]3-[#6](=[#8])-[#6]-[#6]4-[#6]-[#6]-[#6]-[#6]-4-[#6]-3-[#6]-[#6]-[#6]-2=[#6]-1	2	steroid_A(2)	8	1772697389	[#8]=[#6]-4-[#6]-[#6]-[#6]-3-[#6]-2-[#6](=[#8])-[#6]-[#6]-1-[#6]-[#6]-[#6]-[#6]-1-[#6]-2-[#6]-[#6]-[#6]-3=[#6]-4	steroid_a_2_	534	0	3	2	1	810	10	23
48	[N&D3]-,:[S&R0](=O)=O	1	sulfonamide-tertiary	14	1772517372	[ND3][SR0](=O)=O	sulfonamide-tertiary	392572	57	6	41	21	392692	0	37419
144	[c:3]1:[c:1]:[n:2]:[c:5](-[#6:6]):[n:4]@1	7	benzimidazole	14	1772517372	[c:3]1:[c:1]:[n:2]:[c:5](-[#6:6]):[n:4]@1	benzimidazole	391313	288	10	88	17	391380	0	27400
145	[c:3]1:[c:1]:[s:2]:[c:5](-[#6:6]):[n:4]@1	7	benzthiazole	14	1772517372	[c:3]1:[c:1]:[s:2]:[c:5](-[#6:6]):[n:4]@1	benzthiazole	442194	18	49	76	4	442241	0	15598
176	[C&D1&X4]-C(=O)-C(=O)-c1:c:c:c:c:c:1	1	phenyl-propodione	1	1772687395	[CX3]-C(=O)-C(=O)-c1ccccc1	phenyl-propodione	0	0	0	0	0	0	0	0
177	[C&D2&X4](-C#N)-[N&D2&X3]-C(-[#6])=O	1	aminoacetonitrile	1	1772687395	[CD2](-C#N)-[ND2X3]-C(-C)=O	aminoacetonitrile	0	0	0	0	0	0	0	0
178	[#6]-C(=O)-[O&D1].[#6]-[#7]=[N&+]=[#7&-]	1	del2-carboxylate-azide	14	8080401	[#6]-C(=O)[OD1].[#6]-[#7]=[N&+]=[#7&-]	del2-carboxylate-azide	0	0	0	0	0	0	0	0
179	[#6]-[C&D2]=O.[#6]-C(=O)-[O&D1]	1	del2-aldehyde-carboxylate	14	8080401	[#6]-[CD2]=O.[#6]-C(=O)[OD1]	del2-aldehyde-carboxylate	0	0	0	0	0	0	0	0
180	[#6]-[C&D2]=O.[#6]-S(=O)(=O)-[F,Cl]	1	del2-aldehyde-sulfonyl-halide	14	8080401	[#6]-[CD2]=O.[#6]-S(=O)(=O)-[F,Cl]	del2-aldehyde-sulfonyl-halide	0	0	0	0	0	0	0	0
181	[#6]-C(=O)-[O&D1].[#6]-C#[C&D1]	1	del2-carboxylate-terminal-alkyne	14	8080401	[#6]-C(=O)-[OD1].[#6]-C#[CD1]	del2-carboxylate-terminal-alkyne	0	0	0	0	0	0	0	0
182	[#6]-C(=O)-[O&D1].[#6]-[C&D2]=O	1	del3-carboxylate-aldehyde-aryl-halide	14	8080401	[#6]-C(=O)-[OD1].[#6]-[CD2]=O	del3-carboxylate-aldehyde-aryl-halide	0	0	0	0	0	0	0	0
201	[#6]-C(=O)-[O&D1].O=C(-[N&D2]-[#6])-,:O-,:C-,:C1-,:c2:,-c:,-c:,-c:,-c:,-c:,-2:,-c2:,-c:,-c:,-c:,-c:,-c:,-1:,-2	1	del2-carboxylate-nfmoc	1	0	[#6]-C(=O)-[OD1].O=C(-[ND2]-[#6])OCC3c1ccccc1c2ccccc23	del2-carboxylate-nfmoc	0	0	0	0	0	0	0	0
188	[#6]-[#7]=[N&+]=[#7&-].[#6]-S(=O)(=O)-[F,Cl]	1	del2-azide-sulfonyl-halide	14	2007740380	[#6]-[#7]=[N&+]=[#7&-].[#6]-S(=O)(=O)-[F,Cl]	del2-azide-sulfonyl-halide	0	0	0	0	0	0	0	0
191	[#6]-[C&D2]=O.c-[Cl,Br,I]	1	del2-aldehyde-aryl-halide	14	2007740380	[#6]-[CD2]=O.c-[Cl,Br,I]	del2-aldehyde-aryl-halide	0	0	0	0	0	0	0	0
193	[#6]-C(=O)-[O&D1].[#6]-C(=O)-O-[C&D1]	1	del2-carboxylate-me-ester	14	2007740380	[#6]-C(=O)-[OD1].[#6]-C(=O)-O-[CD1]	del2-carboxylate-me-ester	0	0	0	0	0	0	0	0
192	[#6]-C(=O)-[O&D1].c-[Cl,Br,I]	1	del2-carboxylate-aryl-halide	14	2007740380	[#6]-C(=O)-[OD1].c-[Cl,Br,I]	del2-carboxylate-aryl-halide	0	0	0	0	0	0	0	0
195	[#6]-C(=O)-[O&D1].S=C=N-[#6]	1	del2-carboxylate-isothiocyanate	14	2007740380	[#6]-C(=O)-[OD1].S=C=N-[#6]	del2-carboxylate-isothiocyanate	0	0	0	0	0	0	0	0
183	[#6]-C(=O)-[O&D1].[#6]-[N&+](=O)-[O&-]	1	del2-carboxylate-nitro	14	2007740380	[#6]-C(=O)-[OD1].[#6]-[N&+](=O)-[O&-]	del2-carboxylate-nitro	0	0	0	0	0	0	0	0
198	[#6]-C(=O)-O-C(-[C&D1])(-[C&D1])-[C&D1].S=C=N-[#6]	1	del2-tbu-ester-isothiocyanate	14	2007740380	[#6]-C(=O)-O-C(-[CD1])(-[CD1])-[CD1].S=C=N-[#6]	del2-tbu-ester-isothiocyanate	0	0	0	0	0	0	0	0
186	[#6]-[C&D2]=O.[#6]-[N&+](=O)-[O&-]	1	del2-aldehyde-nitro	14	2007740380	[#6]-[CD2]=O.[#6]-[N&+](=O)-[O&-]	del2-aldehyde-nitro	0	0	0	0	0	0	0	0
187	[#6]-[C&D2]=O.[#6]-[#7]=[N&+]=[#7&-]	1	del2-aldehyde-azide	14	2007740380	[#6]-[CD2]=O.[#6]-[#7]=[N&+]=[#7&-]	del2-aldehyde-azide	0	0	0	0	0	0	0	0
189	[#6]-[C&D2]=O.[#6]-C(=O)-O-[C&D1]	1	del2-aldehyde-me-ester	14	2007740380	[#6]-[CD2]=O.[#6]-C(=O)-O-[CD1]	del2-aldehyde-me-ester	0	0	0	0	0	0	0	0
197	[#6]-C(=O)-O-[C&D1].S=C=N-[#6]	1	del2-me-ester-isothiocyanate	14	2007740380	[#6]-C(=O)-O-[CD1].S=C=N-[#6]	del2-me-ester-isothiocyanate	0	0	0	0	0	0	0	0
190	[#6]-[C&D2]=O.[#6]-C(=O)-O-C(-[C&D1])(-[C&D1])-[C&D1]	1	del2-aldehyde-tbu-ester	14	2007740380	[#6]-[CD2]=O.[#6]-C(=O)-O-C(-[CD1])(-[CD1])-[CD1]	del2-aldehyde-tbu-ester	0	0	0	0	0	0	0	0
196	[#6]-[#7]=[N&+]=[#7&-].[#6]-S(=O)(=O)-[F,Cl]	1	del2-azide-sulfonyl-halide	14	2007740380	[#6]-[#7]=[N&+]=[#7&-].[#6]-S(=O)(=O)-[F,Cl]	del2-azide-sulfonyl-halide	0	0	0	0	0	0	0	0
185	[#6]-C(=O)-[O&D1].[#6]-[C&D2]=O.[#6]-[N&+](=O)-[O&-]	1	del3-carboxylate-aldehyde-nitro	14	2007740380	[#6]-C(=O)-[OD1].[#6]-[CD2]=O.[#6]-[N&+](=O)-[O&-]	del3-carboxylate-aldehyde-nitro	0	0	0	0	0	0	0	0
194	[#6]-C(=O)-[O&D1].[#6]-C(=O)-O-C(-[C&D1])(-[C&D1])-[C&D1]	1	del2-carboxylate-tbu-ester	14	2007740380	[#6]-C(=O)-[OD1].[#6]-C(=O)-O-C(-[CD1])(-[CD1])-[CD1]	del2-carboxylate-tbu-ester	0	0	0	0	0	0	0	0
184	[#6]-C(=O)-[O&D1].c-[Cl,Br,I].[#6]-[N&+](=O)-[O&-]	1	del3-carboxylate-aryl-halide-nitro	14	2007740380	[#6]-C(=O)-[OD1].c-[Cl,Br,I].[#6]-[N&+](=O)-[O&-]	del3-carboxylate-aryl-halide-nitro	0	0	0	0	0	0	0	0
200	[#6]-C(=O)-O-C(-[C&D1])(-[C&D1])-[C&D1].[#6]-S(=O)(=O)-[F,Cl]	1	del2-tbu-ester-sulfonyl-halide	14	2007740380	[#6]-C(=O)-O-C(-[CD1])(-[CD1])-[CD1].[#6]-S(=O)(=O)-[F,Cl]	del2-tbu-ester-sulfonyl-halide	0	0	0	0	0	0	0	0
199	[#6]-C(=O)-O-[C&D1].[#6]-S(=O)(=O)-[F,Cl]	1	del2-me-ester-sulfonyl-halide	14	2007740380	[#6]-C(=O)-O-[CD1].[#6]-S(=O)(=O)-[F,Cl]	del2-me-ester-sulfonyl-halide	0	0	0	0	0	0	0	0
\.


--
-- Data for Name: pattern_type; Type: TABLE DATA; Schema: public; Owner: tinuser
--

COPY public.pattern_type (pattern_type_id, description, name) FROM stdin;
20	Reaction Product	rxn-product
7	Unused2	unused2
6	Nuclophilic aromatic substitution	nas
3	Electrophile	electrophile
9	parked	Parked, not sure
16	Unused3	unused3
1	Weak electrophile	weak-electrophile
2	Weak nucleophile	weak-nucleophile
14	reagent	Benign reagent, BB only
5	Chromophore	chromophore
4	Nucleophile	nucleophile
15	Redox potential	redox
11	Not cell penetrant	not-cell-penetrant
8	PAINS	pains
10	super reactive	hot
12	too floppy for docking (entropy)	too-floppy
13	too greasy / insoluble	too-greasy
0	Functional group	named-functional-group
\.


--
-- Name: catalog_cat_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.catalog_cat_id_seq', 1, false);


--
-- Name: catalog_content_cat_content_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

--- SELECT pg_catalog.setval('public.cat_content_id_seq', 1, false);


--
-- Name: cat_content_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.cat_content_id_seq', 1, true);


--
-- Name: cat_sub_itm_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.cat_sub_itm_id_seq', 11, true);


--
-- Name: pattern_pattern_id_seq; Type: SEQUENCE SET; Schema: public; Owner: test
--

SELECT pg_catalog.setval('public.pattern_pattern_id_seq', 1, false);


--
-- Name: sub_id_seq; Type: SEQUENCE SET; Schema: public; Owner: root
--

SELECT pg_catalog.setval('public.sub_id_seq', 11, true);


--
-- Name: catalog_content catalog_contents_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.catalog_content
    ADD CONSTRAINT catalog_content_pkey PRIMARY KEY (cat_content_id);


--
-- Name: catalog catalog_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.catalog
    ADD CONSTRAINT catalog_pkey PRIMARY KEY (cat_id);


--
-- Name: catalog_substance catalog_substances_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

--- ALTER TABLE ONLY public.catalog_substance
---    ADD CONSTRAINT catalog_substances_pkey PRIMARY KEY (cat_sub_itm_id);


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
-- Name: substance substance_pkey; Type: CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.substance
    ADD CONSTRAINT substance_pkey PRIMARY KEY (sub_id, tranche_id);


--
/C-- Name: catalog_item_unique_idx; Type: INDEX; Schema: public; Owner: root
--

--- CREATE UNIQUE INDEX catalog_item_unique_idx ON public.catalog_content USING btree (cat_id_fk, supplier_code);


--
-- Name: catalog_substance_idx; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX catalog_substance_sub_id_fk_idx ON public.catalog_substance USING btree (sub_id_fk, tranche_id);

CREATE INDEX catalog_substance_cat_id_fk_idx ON public.catalog_substance USING btree (cat_content_fk);

--
-- Name: catalog_substance_unique; Type: INDEX; Schema: public; Owner: root
--

--- CREATE UNIQUE INDEX catalog_substance_unique ON public.catalog_substance USING btree (cat_content_fk, sub_id_fk);


--
-- Name: ix_catalog_contents_content_item_id; Type: INDEX; Schema: public; Owner: root
--

--- CREATE INDEX ix_catalog_contents_content_item_id ON public.catalog_content USING btree (cat_content_id, supplier_code) WHERE (NOT depleted);


--
-- Name: ix_catalog_contents_supplier_code_current; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX catalog_content_supplier_code_idx ON public.catalog_content USING hash (supplier_code);


--
-- Name: ix_catalog_free; Type: INDEX; Schema: public; Owner: root
--

CREATE INDEX ix_catalog_free ON public.catalog USING btree (free);


--
-- Name: ix_catalog_item_substance_cur; Type: INDEX; Schema: public; Owner: root
--

--- CREATE INDEX ix_catalog_item_substance_cur ON public.catalog_content USING btree (cat_id_fk, cat_content_id) WHERE (NOT depleted);


--
-- Name: ix_catalog_item_substance_current; Type: INDEX; Schema: public; Owner: root
--

--- CREATE INDEX ix_catalog_item_substance_current ON public.catalog_content USING btree (cat_content_id, cat_id_fk) WHERE (NOT depleted);


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
-- Name: substance3_logp_idx; Type: INDEX; Schema: public; Owner: root
--

--- CREATE INDEX substance3_logp_idx ON public.substance USING btree (public.mol_logp(smiles));


--
-- Name: substance3_mwt_idx; Type: INDEX; Schema: public; Owner: root
--

--- CREATE INDEX substance3_mwt_idx ON public.substance USING btree (public.mol_amw(smiles));


CREATE INDEX smiles_hash_idx on public.substance using hash (smiles);

--
-- Name: catalog_content catalog_contents_cat_id_fk_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.catalog_content
    ADD CONSTRAINT catalog_content_cat_id_fk_fkey FOREIGN KEY (cat_id_fk) REFERENCES public.catalog(cat_id) ON DELETE CASCADE;


--
-- Name: catalog_substance catalog_substances_cat_itm_fk_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.catalog_substance
    ADD CONSTRAINT catalog_substance_cat_itm_fk_fkey FOREIGN KEY (cat_content_fk) REFERENCES public.catalog_content(cat_content_id) ON DELETE CASCADE;


--
-- Name: catalog_substance catalog_substances_sub_id_fk_fkey; Type: FK CONSTRAINT; Schema: public; Owner: root
--

ALTER TABLE ONLY public.catalog_substance
    ADD CONSTRAINT catalog_substance_sub_id_fk_fkey FOREIGN KEY (sub_id_fk, tranche_id) REFERENCES public.substance(sub_id, tranche_id) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED;


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
-- Name: SEQUENCE cat_content_id_seq; Type: ACL; Schema: public; Owner: root
--

GRANT SELECT,USAGE ON SEQUENCE public.cat_content_id_seq TO zincread;
GRANT SELECT,USAGE ON SEQUENCE public.cat_content_id_seq TO zincfree;
GRANT SELECT,USAGE ON SEQUENCE public.cat_content_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.cat_content_id_seq TO adminprivate;


--
-- Name: TABLE catalog_content; Type: ACL; Schema: public; Owner: root
--

GRANT ALL ON TABLE public.catalog_content TO test;
GRANT SELECT ON TABLE public.catalog_content TO zincread;
GRANT SELECT ON TABLE public.catalog_content TO zincfree;
GRANT ALL ON TABLE public.catalog_content TO adminprivate;
GRANT ALL ON TABLE public.catalog_content TO admin;


/*
--
-- Name: SEQUENCE catalog_content_cat_content_id_seq; Type: ACL; Schema: public; Owner: root
--

GRANT SELECT,USAGE ON SEQUENCE public.catalog_content_cat_content_id_seq TO zincread;
GRANT SELECT,USAGE ON SEQUENCE public.catalog_content_cat_content_id_seq TO zincfree;
GRANT SELECT,USAGE ON SEQUENCE public.catalog_content_cat_content_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.catalog_content_cat_content_id_seq TO adminprivate;
*/

--
-- Name: TABLE catalog_substance; Type: ACL; Schema: public; Owner: root
--

GRANT ALL ON TABLE public.catalog_substance TO test;
GRANT SELECT ON TABLE public.catalog_substance TO zincread;
GRANT SELECT ON TABLE public.catalog_substance TO zincfree;
GRANT ALL ON TABLE public.catalog_substance TO adminprivate;
GRANT ALL ON TABLE public.catalog_substance TO admin;


--
-- Name: TABLE catalog_item; Type: ACL; Schema: public; Owner: root
--

GRANT SELECT ON TABLE public.catalog_item TO zincfree;
GRANT SELECT ON TABLE public.catalog_item TO zincread;
GRANT ALL ON TABLE public.catalog_item TO admin;
GRANT ALL ON TABLE public.catalog_item TO zincwrite;
GRANT ALL ON TABLE public.catalog_item TO test;


--
-- Name: SEQUENCE cat_sub_itm_id_seq; Type: ACL; Schema: public; Owner: root
--

GRANT SELECT,USAGE ON SEQUENCE public.cat_sub_itm_id_seq TO zincread;
GRANT SELECT,USAGE ON SEQUENCE public.cat_sub_itm_id_seq TO zincfree;
GRANT SELECT,USAGE ON SEQUENCE public.cat_sub_itm_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.cat_sub_itm_id_seq TO adminprivate;


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
-- Name: TABLE substance; Type: ACL; Schema: public; Owner: root
--

GRANT SELECT ON TABLE public.substance TO zincread;
GRANT SELECT ON TABLE public.substance TO zincfree;
GRANT ALL ON TABLE public.substance TO test;
GRANT ALL ON TABLE public.substance TO adminprivate;
GRANT ALL ON TABLE public.substance TO admin;


--
-- Name: SEQUENCE sub_id_seq; Type: ACL; Schema: public; Owner: root
--

GRANT ALL ON SEQUENCE public.sub_id_seq TO zincread;
GRANT ALL ON SEQUENCE public.sub_id_seq TO zincfree;
GRANT SELECT,USAGE ON SEQUENCE public.sub_id_seq TO admin;
GRANT SELECT,USAGE ON SEQUENCE public.sub_id_seq TO adminprivate;


--
-- PostgreSQL database dump complete
--

