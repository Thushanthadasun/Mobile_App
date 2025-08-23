--
-- PostgreSQL database dump
--

-- Dumped from database version 17.0
-- Dumped by pg_dump version 17.0

-- Started on 2025-04-24 17:32:27

-- Database: service-center

-- DROP DATABASE IF EXISTS "service-center";

CREATE DATABASE "service-center"
    WITH
    OWNER = postgres
    ENCODING = 'UTF8'
    LC_COLLATE = 'English_United States.1252'
    LC_CTYPE = 'English_United States.1252'
    LOCALE_PROVIDER = 'libc'
    TABLESPACE = pg_default
    CONNECTION LIMIT = -1
    IS_TEMPLATE = False;

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 236 (class 1259 OID 17014)
-- Name: invoices; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.invoices (
    invoice_id integer NOT NULL,
    customer_id character varying(15) NOT NULL,
    reservation_id integer NOT NULL,
    discount double precision,
    final_amount double precision DEFAULT 0.00,
    payment_status character varying(10) DEFAULT 'Unpaid'::character varying,
    created_datetime timestamp without time zone
);


ALTER TABLE public.invoices OWNER TO postgres;

--
-- TOC entry 235 (class 1259 OID 17013)
-- Name: invoices_invoice_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.invoices_invoice_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.invoices_invoice_id_seq OWNER TO postgres;

--
-- TOC entry 4972 (class 0 OID 0)
-- Dependencies: 235
-- Name: invoices_invoice_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.invoices_invoice_id_seq OWNED BY public.invoices.invoice_id;


--
-- TOC entry 223 (class 1259 OID 16932)
-- Name: login_history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.login_history (
    login_id integer NOT NULL,
    user_id character varying(15) NOT NULL,
    date_time timestamp without time zone
);


ALTER TABLE public.login_history OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 16931)
-- Name: login_history_login_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.login_history_login_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.login_history_login_id_seq OWNER TO postgres;

--
-- TOC entry 4973 (class 0 OID 0)
-- Dependencies: 222
-- Name: login_history_login_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.login_history_login_id_seq OWNED BY public.login_history.login_id;


--
-- TOC entry 218 (class 1259 OID 16901)
-- Name: mobile_number; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mobile_number (
    mobile_id integer NOT NULL,
    mobile_no bigint NOT NULL,
    otp character varying(70) NOT NULL,
    otp_datetime timestamp without time zone,
    isotpverified boolean
);


ALTER TABLE public.mobile_number OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16900)
-- Name: mobile_number_mobile_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mobile_number_mobile_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mobile_number_mobile_id_seq OWNER TO postgres;

--
-- TOC entry 4974 (class 0 OID 0)
-- Dependencies: 217
-- Name: mobile_number_mobile_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mobile_number_mobile_id_seq OWNED BY public.mobile_number.mobile_id;


--
-- TOC entry 238 (class 1259 OID 17033)
-- Name: payments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payments (
    payment_id integer NOT NULL,
    invoice_id integer NOT NULL,
    payhere_id character varying(50),
    payment_method character varying(10) NOT NULL,
    amount double precision NOT NULL,
    transaction_datetime timestamp without time zone NOT NULL
);


ALTER TABLE public.payments OWNER TO postgres;

--
-- TOC entry 237 (class 1259 OID 17032)
-- Name: payments_payment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.payments_payment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payments_payment_id_seq OWNER TO postgres;

--
-- TOC entry 4975 (class 0 OID 0)
-- Dependencies: 237
-- Name: payments_payment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.payments_payment_id_seq OWNED BY public.payments.payment_id;


--
-- TOC entry 234 (class 1259 OID 17002)
-- Name: reservations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reservations (
    reservation_id integer NOT NULL,
    vehicle_id character varying(15) NOT NULL,
    service_type_id integer NOT NULL,
    reserve_date date NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL
);


ALTER TABLE public.reservations OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 17001)
-- Name: reservations_reservation_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reservations_reservation_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reservations_reservation_id_seq OWNER TO postgres;

--
-- TOC entry 4976 (class 0 OID 0)
-- Dependencies: 233
-- Name: reservations_reservation_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.reservations_reservation_id_seq OWNED BY public.reservations.reservation_id;


--
-- TOC entry 232 (class 1259 OID 16985)
-- Name: service_records; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.service_records (
    service_record_id integer NOT NULL,
    license_plate character varying(15) NOT NULL,
    service_type_id integer NOT NULL,
    service_datetime character varying(45),
    description character varying(100),
    status character varying(20)
);


ALTER TABLE public.service_records OWNER TO postgres;

--
-- TOC entry 231 (class 1259 OID 16984)
-- Name: service_records_service_record_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.service_records_service_record_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.service_records_service_record_id_seq OWNER TO postgres;

--
-- TOC entry 4977 (class 0 OID 0)
-- Dependencies: 231
-- Name: service_records_service_record_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.service_records_service_record_id_seq OWNED BY public.service_records.service_record_id;


--
-- TOC entry 230 (class 1259 OID 16978)
-- Name: service_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.service_type (
    service_type_id integer NOT NULL,
    service_name character varying(100) NOT NULL,
    price double precision NOT NULL,
    description character varying(100),
    duration integer NOT NULL
);


ALTER TABLE public.service_type OWNER TO postgres;

--
-- TOC entry 229 (class 1259 OID 16977)
-- Name: service_type_service_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.service_type_service_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.service_type_service_type_id_seq OWNER TO postgres;

--
-- TOC entry 4978 (class 0 OID 0)
-- Dependencies: 229
-- Name: service_type_service_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.service_type_service_type_id_seq OWNED BY public.service_type.service_type_id;


--
-- TOC entry 220 (class 1259 OID 16908)
-- Name: user_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.user_type (
    user_type_id integer NOT NULL,
    description character varying(45) NOT NULL
);


ALTER TABLE public.user_type OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16907)
-- Name: user_type_user_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.user_type_user_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_type_user_type_id_seq OWNER TO postgres;

--
-- TOC entry 4979 (class 0 OID 0)
-- Dependencies: 219
-- Name: user_type_user_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.user_type_user_type_id_seq OWNED BY public.user_type.user_type_id;


--
-- TOC entry 221 (class 1259 OID 16914)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    user_id character varying(15) NOT NULL,
    first_name character varying(45) NOT NULL,
    last_name character varying(45),
    email character varying(100) NOT NULL,
    password character varying(255) NOT NULL,
    user_type_id integer NOT NULL,
    mobile_id integer NOT NULL,
    registered_date date,
    isemailverified boolean DEFAULT false,
    status boolean DEFAULT true
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 16951)
-- Name: vehicle_brand; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vehicle_brand (
    vehicle_brand_id integer NOT NULL,
    vehicle_brand character varying(20)
);


ALTER TABLE public.vehicle_brand OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 16950)
-- Name: vehicle_brand_vehicle_brand_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.vehicle_brand_vehicle_brand_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.vehicle_brand_vehicle_brand_id_seq OWNER TO postgres;

--
-- TOC entry 4980 (class 0 OID 0)
-- Dependencies: 226
-- Name: vehicle_brand_vehicle_brand_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.vehicle_brand_vehicle_brand_id_seq OWNED BY public.vehicle_brand.vehicle_brand_id;


--
-- TOC entry 225 (class 1259 OID 16944)
-- Name: vehicle_type; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vehicle_type (
    vehicle_type_id integer NOT NULL,
    vehicle_type character varying(45)
);


ALTER TABLE public.vehicle_type OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 16943)
-- Name: vehicle_type_vehicle_type_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.vehicle_type_vehicle_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.vehicle_type_vehicle_type_id_seq OWNER TO postgres;

--
-- TOC entry 4981 (class 0 OID 0)
-- Dependencies: 224
-- Name: vehicle_type_vehicle_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.vehicle_type_vehicle_type_id_seq OWNED BY public.vehicle_type.vehicle_type_id;


--
-- TOC entry 228 (class 1259 OID 16957)
-- Name: vehicles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vehicles (
    license_plate character varying(15) NOT NULL,
    user_id character varying(15) NOT NULL,
    vehicle_type_id integer NOT NULL,
    vehicle_brand_id integer NOT NULL,
    model character varying(50) NOT NULL,
    color character varying(45),
    make_year integer NOT NULL,
    status boolean,
    fuel_type character varying(1) NOT NULL
);


ALTER TABLE public.vehicles OWNER TO postgres;

--
-- TOC entry 4758 (class 2604 OID 17017)
-- Name: invoices invoice_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoices ALTER COLUMN invoice_id SET DEFAULT nextval('public.invoices_invoice_id_seq'::regclass);


--
-- TOC entry 4752 (class 2604 OID 16935)
-- Name: login_history login_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.login_history ALTER COLUMN login_id SET DEFAULT nextval('public.login_history_login_id_seq'::regclass);


--
-- TOC entry 4748 (class 2604 OID 16904)
-- Name: mobile_number mobile_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mobile_number ALTER COLUMN mobile_id SET DEFAULT nextval('public.mobile_number_mobile_id_seq'::regclass);


--
-- TOC entry 4761 (class 2604 OID 17036)
-- Name: payments payment_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments ALTER COLUMN payment_id SET DEFAULT nextval('public.payments_payment_id_seq'::regclass);


--
-- TOC entry 4757 (class 2604 OID 17005)
-- Name: reservations reservation_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservations ALTER COLUMN reservation_id SET DEFAULT nextval('public.reservations_reservation_id_seq'::regclass);


--
-- TOC entry 4756 (class 2604 OID 16988)
-- Name: service_records service_record_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_records ALTER COLUMN service_record_id SET DEFAULT nextval('public.service_records_service_record_id_seq'::regclass);


--
-- TOC entry 4755 (class 2604 OID 16981)
-- Name: service_type service_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_type ALTER COLUMN service_type_id SET DEFAULT nextval('public.service_type_service_type_id_seq'::regclass);


--
-- TOC entry 4749 (class 2604 OID 16911)
-- Name: user_type user_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_type ALTER COLUMN user_type_id SET DEFAULT nextval('public.user_type_user_type_id_seq'::regclass);


--
-- TOC entry 4754 (class 2604 OID 16954)
-- Name: vehicle_brand vehicle_brand_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicle_brand ALTER COLUMN vehicle_brand_id SET DEFAULT nextval('public.vehicle_brand_vehicle_brand_id_seq'::regclass);


--
-- TOC entry 4753 (class 2604 OID 16947)
-- Name: vehicle_type vehicle_type_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicle_type ALTER COLUMN vehicle_type_id SET DEFAULT nextval('public.vehicle_type_vehicle_type_id_seq'::regclass);


--
-- TOC entry 4964 (class 0 OID 17014)
-- Dependencies: 236
-- Data for Name: invoices; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.invoices (invoice_id, customer_id, reservation_id, discount, final_amount, payment_status, created_datetime) FROM stdin;
\.


--
-- TOC entry 4951 (class 0 OID 16932)
-- Dependencies: 223
-- Data for Name: login_history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.login_history (login_id, user_id, date_time) FROM stdin;
\.


--
-- TOC entry 4946 (class 0 OID 16901)
-- Dependencies: 218
-- Data for Name: mobile_number; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.mobile_number (mobile_id, mobile_no, otp, otp_datetime, isotpverified) FROM stdin;
12	702686207	$2b$10$NwYLywUAyJWyTPVr2.wEQ.BtmUtH8KwCj9Hg/i8B6fnUYLPGPhb7S	2025-03-19 11:17:30	t
13	702684507	$2b$10$787hmXHo0hIF29PKxi1LYuCaCKnDfWpZ9cXQlG5ybJPQGXuBlM.me	2025-04-09 14:50:58	t
14	702655	$2b$10$0HV5InZTBc88ucCyUhdBbObtfiS4MVv3PZgRLVptroKnjcW0hcdEO	2025-04-24 06:21:32	t
\.


--
-- TOC entry 4966 (class 0 OID 17033)
-- Dependencies: 238
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payments (payment_id, invoice_id, payhere_id, payment_method, amount, transaction_datetime) FROM stdin;
\.


--
-- TOC entry 4962 (class 0 OID 17002)
-- Dependencies: 234
-- Data for Name: reservations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reservations (reservation_id, vehicle_id, service_type_id, reserve_date, start_time, end_time) FROM stdin;
\.


--
-- TOC entry 4960 (class 0 OID 16985)
-- Dependencies: 232
-- Data for Name: service_records; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.service_records (service_record_id, license_plate, service_type_id, service_datetime, description, status) FROM stdin;
\.


--
-- TOC entry 4958 (class 0 OID 16978)
-- Dependencies: 230
-- Data for Name: service_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.service_type (service_type_id, service_name, price, description, duration) FROM stdin;
\.


--
-- TOC entry 4948 (class 0 OID 16908)
-- Dependencies: 220
-- Data for Name: user_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.user_type (user_type_id, description) FROM stdin;
1	ADMIN
2	USER
\.


--
-- TOC entry 4949 (class 0 OID 16914)
-- Dependencies: 221
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (user_id, first_name, last_name, email, password, user_type_id, mobile_id, registered_date, isemailverified, status) FROM stdin;
CUS01	Pasindu	Hathurusinghe	pasindujanith14@gmail.com	$2b$10$myqL3q7xypjIIGCLJUlb6eCImOTirpJ0JD2pKpctXiNO6LQ1s7VnO	2	12	2025-03-19	t	t
CUS11	Saman	Janith	pjhathur21334usinghe14@gmail.com	$2b$10$YOjNAoG26sezf7POy606Y.O6iBWGCRxlyAclln18rwC2RD378Ga8K	2	13	2025-04-09	t	t
CUS21	Pasindu	Hathurusinghe	pjhathurusinghe14@gmail.com	$2b$10$7ILGeZ5RPl6gbwn26/ZfLuSMAz5HcX6.SVphcmfaHrPtckhUVz5sm	2	14	2025-04-24	t	t
\.


--
-- TOC entry 4955 (class 0 OID 16951)
-- Dependencies: 227
-- Data for Name: vehicle_brand; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vehicle_brand (vehicle_brand_id, vehicle_brand) FROM stdin;
1	Toyota
2	BMW
3	Volvo
4	Nissan
5	Mercidies Benz
6	TATA
7	Honda
8	Micro
9	Jaguar
\.


--
-- TOC entry 4953 (class 0 OID 16944)
-- Dependencies: 225
-- Data for Name: vehicle_type; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vehicle_type (vehicle_type_id, vehicle_type) FROM stdin;
1	Car
2	Van
3	Jeep
4	Lorry
5	Cab
6	Bicycle
\.


--
-- TOC entry 4956 (class 0 OID 16957)
-- Dependencies: 228
-- Data for Name: vehicles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vehicles (license_plate, user_id, vehicle_type_id, vehicle_brand_id, model, color, make_year, status, fuel_type) FROM stdin;
\.


--
-- TOC entry 4982 (class 0 OID 0)
-- Dependencies: 235
-- Name: invoices_invoice_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.invoices_invoice_id_seq', 1, false);


--
-- TOC entry 4983 (class 0 OID 0)
-- Dependencies: 222
-- Name: login_history_login_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.login_history_login_id_seq', 1, false);


--
-- TOC entry 4984 (class 0 OID 0)
-- Dependencies: 217
-- Name: mobile_number_mobile_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.mobile_number_mobile_id_seq', 14, true);


--
-- TOC entry 4985 (class 0 OID 0)
-- Dependencies: 237
-- Name: payments_payment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.payments_payment_id_seq', 1, false);


--
-- TOC entry 4986 (class 0 OID 0)
-- Dependencies: 233
-- Name: reservations_reservation_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reservations_reservation_id_seq', 1, false);


--
-- TOC entry 4987 (class 0 OID 0)
-- Dependencies: 231
-- Name: service_records_service_record_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.service_records_service_record_id_seq', 1, false);


--
-- TOC entry 4988 (class 0 OID 0)
-- Dependencies: 229
-- Name: service_type_service_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.service_type_service_type_id_seq', 1, false);


--
-- TOC entry 4989 (class 0 OID 0)
-- Dependencies: 219
-- Name: user_type_user_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.user_type_user_type_id_seq', 1, false);


--
-- TOC entry 4990 (class 0 OID 0)
-- Dependencies: 226
-- Name: vehicle_brand_vehicle_brand_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.vehicle_brand_vehicle_brand_id_seq', 9, true);


--
-- TOC entry 4991 (class 0 OID 0)
-- Dependencies: 224
-- Name: vehicle_type_vehicle_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.vehicle_type_vehicle_type_id_seq', 6, true);


--
-- TOC entry 4785 (class 2606 OID 17021)
-- Name: invoices invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT invoices_pkey PRIMARY KEY (invoice_id);


--
-- TOC entry 4771 (class 2606 OID 16937)
-- Name: login_history login_history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.login_history
    ADD CONSTRAINT login_history_pkey PRIMARY KEY (login_id);


--
-- TOC entry 4763 (class 2606 OID 16906)
-- Name: mobile_number mobile_number_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mobile_number
    ADD CONSTRAINT mobile_number_pkey PRIMARY KEY (mobile_id);


--
-- TOC entry 4787 (class 2606 OID 17038)
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (payment_id);


--
-- TOC entry 4783 (class 2606 OID 17007)
-- Name: reservations reservations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT reservations_pkey PRIMARY KEY (reservation_id);


--
-- TOC entry 4781 (class 2606 OID 16990)
-- Name: service_records service_records_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_records
    ADD CONSTRAINT service_records_pkey PRIMARY KEY (service_record_id);


--
-- TOC entry 4779 (class 2606 OID 16983)
-- Name: service_type service_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_type
    ADD CONSTRAINT service_type_pkey PRIMARY KEY (service_type_id);


--
-- TOC entry 4767 (class 2606 OID 16920)
-- Name: users user_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT user_email_key UNIQUE (email);


--
-- TOC entry 4769 (class 2606 OID 16918)
-- Name: users user_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT user_pkey PRIMARY KEY (user_id);


--
-- TOC entry 4765 (class 2606 OID 16913)
-- Name: user_type user_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.user_type
    ADD CONSTRAINT user_type_pkey PRIMARY KEY (user_type_id);


--
-- TOC entry 4775 (class 2606 OID 16956)
-- Name: vehicle_brand vehicle_brand_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicle_brand
    ADD CONSTRAINT vehicle_brand_pkey PRIMARY KEY (vehicle_brand_id);


--
-- TOC entry 4773 (class 2606 OID 16949)
-- Name: vehicle_type vehicle_type_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicle_type
    ADD CONSTRAINT vehicle_type_pkey PRIMARY KEY (vehicle_type_id);


--
-- TOC entry 4777 (class 2606 OID 16961)
-- Name: vehicles vehicles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_pkey PRIMARY KEY (license_plate);


--
-- TOC entry 4797 (class 2606 OID 17027)
-- Name: invoices fk_invoices_reservations; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT fk_invoices_reservations FOREIGN KEY (reservation_id) REFERENCES public.reservations(reservation_id);


--
-- TOC entry 4798 (class 2606 OID 17022)
-- Name: invoices fk_invoices_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.invoices
    ADD CONSTRAINT fk_invoices_user FOREIGN KEY (customer_id) REFERENCES public.users(user_id);


--
-- TOC entry 4790 (class 2606 OID 16938)
-- Name: login_history fk_logins_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.login_history
    ADD CONSTRAINT fk_logins_user FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- TOC entry 4799 (class 2606 OID 17039)
-- Name: payments fk_payments_invoice; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT fk_payments_invoice FOREIGN KEY (invoice_id) REFERENCES public.invoices(invoice_id) ON DELETE CASCADE;


--
-- TOC entry 4796 (class 2606 OID 17008)
-- Name: reservations fk_reservations_service_type; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservations
    ADD CONSTRAINT fk_reservations_service_type FOREIGN KEY (service_type_id) REFERENCES public.service_type(service_type_id) ON DELETE CASCADE;


--
-- TOC entry 4794 (class 2606 OID 16996)
-- Name: service_records fk_service_records_service_type; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_records
    ADD CONSTRAINT fk_service_records_service_type FOREIGN KEY (service_type_id) REFERENCES public.service_type(service_type_id);


--
-- TOC entry 4795 (class 2606 OID 16991)
-- Name: service_records fk_service_records_vehicles; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.service_records
    ADD CONSTRAINT fk_service_records_vehicles FOREIGN KEY (license_plate) REFERENCES public.vehicles(license_plate);


--
-- TOC entry 4788 (class 2606 OID 16921)
-- Name: users fk_user_mobile; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_user_mobile FOREIGN KEY (mobile_id) REFERENCES public.mobile_number(mobile_id);


--
-- TOC entry 4789 (class 2606 OID 16926)
-- Name: users fk_user_user_type; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT fk_user_user_type FOREIGN KEY (user_type_id) REFERENCES public.user_type(user_type_id);


--
-- TOC entry 4791 (class 2606 OID 16962)
-- Name: vehicles fk_vehicles_user; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT fk_vehicles_user FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- TOC entry 4792 (class 2606 OID 16972)
-- Name: vehicles fk_vehicles_vehicle_brand; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT fk_vehicles_vehicle_brand FOREIGN KEY (vehicle_brand_id) REFERENCES public.vehicle_brand(vehicle_brand_id);


--
-- TOC entry 4793 (class 2606 OID 16967)
-- Name: vehicles fk_vehicles_vehicle_type; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT fk_vehicles_vehicle_type FOREIGN KEY (vehicle_type_id) REFERENCES public.vehicle_type(vehicle_type_id);


-- Completed on 2025-04-24 17:32:28

--
-- PostgreSQL database dump complete
--

