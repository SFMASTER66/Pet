--
-- PostgreSQL database dump
--

\restrict Z4my8VbToBNSyrsPOOGuqx6IQhrNsjSdOzZWSNWywTXZBEZfKBkSeZyLidmGz5q

-- Dumped from database version 18.4 (Homebrew)
-- Dumped by pg_dump version 18.4 (Homebrew)

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

--
-- Name: AppointmentStatus; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."AppointmentStatus" AS ENUM (
    'PENDING',
    'PAID',
    'COMPLETED',
    'CANCELLED'
);


ALTER TYPE public."AppointmentStatus" OWNER TO postgres;

--
-- Name: CoatType; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."CoatType" AS ENUM (
    'SHORT',
    'LONG_CURLY',
    'DOUBLE_A',
    'DOUBLE_B',
    'NONE'
);


ALTER TYPE public."CoatType" OWNER TO postgres;

--
-- Name: Gender; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."Gender" AS ENUM (
    'MALE',
    'FEMALE',
    'UNKNOWN'
);


ALTER TYPE public."Gender" OWNER TO postgres;

--
-- Name: PetStatus; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."PetStatus" AS ENUM (
    'ACTIVE',
    'LOST',
    'ANGEL'
);


ALTER TYPE public."PetStatus" OWNER TO postgres;

--
-- Name: UserRole; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."UserRole" AS ENUM (
    'MERCHANT_ADMIN',
    'MERCHANT_STAFF',
    'CUSTOMER'
);


ALTER TYPE public."UserRole" OWNER TO postgres;

--
-- Name: WeightTier; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public."WeightTier" AS ENUM (
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    'ALL'
);


ALTER TYPE public."WeightTier" OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: Appointment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Appointment" (
    id text NOT NULL,
    "petId" text NOT NULL,
    "groomerId" text NOT NULL,
    "merchantId" text NOT NULL,
    "startTime" timestamp(3) without time zone NOT NULL,
    "endTime" timestamp(3) without time zone NOT NULL,
    status public."AppointmentStatus" DEFAULT 'PENDING'::public."AppointmentStatus" NOT NULL,
    "durationMinutes" integer NOT NULL,
    "priceAud" double precision NOT NULL,
    "serviceItemId" integer NOT NULL
);


ALTER TABLE public."Appointment" OWNER TO postgres;

--
-- Name: Employee; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Employee" (
    id text NOT NULL,
    "merchantId" text NOT NULL,
    name text NOT NULL,
    "avatarUrl" text
);


ALTER TABLE public."Employee" OWNER TO postgres;

--
-- Name: Merchant; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Merchant" (
    id text NOT NULL,
    email text NOT NULL,
    "passwordHash" text NOT NULL,
    "businessName" text NOT NULL,
    abn text,
    "stripeAccountId" text,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "logoIcon" text,
    "primaryColor" bigint DEFAULT '4279203182'::bigint NOT NULL,
    tags text[] DEFAULT ARRAY[]::text[]
);


ALTER TABLE public."Merchant" OWNER TO postgres;

--
-- Name: MerchantBranding; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."MerchantBranding" (
    id text NOT NULL,
    "merchantId" text NOT NULL,
    "logoUrl" text NOT NULL,
    "primaryColor" text NOT NULL,
    "businessTags" jsonb NOT NULL
);


ALTER TABLE public."MerchantBranding" OWNER TO postgres;

--
-- Name: MerchantService; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."MerchantService" (
    id text NOT NULL,
    "merchantId" text NOT NULL,
    name text NOT NULL,
    description text,
    "priceAud" double precision NOT NULL,
    "durationMinutes" integer NOT NULL,
    "isActive" boolean DEFAULT true NOT NULL
);


ALTER TABLE public."MerchantService" OWNER TO postgres;

--
-- Name: MerchantUiText; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."MerchantUiText" (
    id text NOT NULL,
    "merchantId" text NOT NULL,
    "uiDictionary" jsonb NOT NULL
);


ALTER TABLE public."MerchantUiText" OWNER TO postgres;

--
-- Name: Pet; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Pet" (
    id text NOT NULL,
    "ownerId" text NOT NULL,
    "speciesId" integer NOT NULL,
    breed text NOT NULL,
    name text NOT NULL,
    "microchipNumber" text,
    status public."PetStatus" DEFAULT 'ACTIVE'::public."PetStatus" NOT NULL,
    "behaviorNotes" text,
    dob timestamp(3) without time zone,
    gender public."Gender" DEFAULT 'UNKNOWN'::public."Gender" NOT NULL,
    "isDesexed" boolean DEFAULT false NOT NULL,
    "merchantId" text NOT NULL,
    "behaviorTags" text[]
);


ALTER TABLE public."Pet" OWNER TO postgres;

--
-- Name: ServiceItem; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ServiceItem" (
    id integer NOT NULL,
    slug text NOT NULL,
    name text NOT NULL
);


ALTER TABLE public."ServiceItem" OWNER TO postgres;

--
-- Name: ServiceItem_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."ServiceItem_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."ServiceItem_id_seq" OWNER TO postgres;

--
-- Name: ServiceItem_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."ServiceItem_id_seq" OWNED BY public."ServiceItem".id;


--
-- Name: ServicePricingMatrix; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."ServicePricingMatrix" (
    id integer NOT NULL,
    "serviceItemId" integer NOT NULL,
    "speciesId" integer NOT NULL,
    "weightTier" public."WeightTier" NOT NULL,
    "coatType" public."CoatType" NOT NULL,
    "durationMinutes" integer NOT NULL,
    "priceAud" double precision NOT NULL
);


ALTER TABLE public."ServicePricingMatrix" OWNER TO postgres;

--
-- Name: ServicePricingMatrix_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."ServicePricingMatrix_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."ServicePricingMatrix_id_seq" OWNER TO postgres;

--
-- Name: ServicePricingMatrix_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."ServicePricingMatrix_id_seq" OWNED BY public."ServicePricingMatrix".id;


--
-- Name: Species; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."Species" (
    id integer NOT NULL,
    name text NOT NULL,
    "baseTimeMultiplier" double precision DEFAULT 1.0 NOT NULL
);


ALTER TABLE public."Species" OWNER TO postgres;

--
-- Name: Species_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public."Species_id_seq"
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public."Species_id_seq" OWNER TO postgres;

--
-- Name: Species_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public."Species_id_seq" OWNED BY public."Species".id;


--
-- Name: User; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public."User" (
    id text NOT NULL,
    email text NOT NULL,
    "phoneNumber" text,
    "passwordHash" text NOT NULL,
    name text NOT NULL,
    "avatarUrl" text,
    "countryCode" text DEFAULT 'AU'::text NOT NULL,
    "createdAt" timestamp(3) without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "merchantId" text NOT NULL,
    role public."UserRole" DEFAULT 'CUSTOMER'::public."UserRole" NOT NULL
);


ALTER TABLE public."User" OWNER TO postgres;

--
-- Name: _prisma_migrations; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public._prisma_migrations (
    id character varying(36) NOT NULL,
    checksum character varying(64) NOT NULL,
    finished_at timestamp with time zone,
    migration_name character varying(255) NOT NULL,
    logs text,
    rolled_back_at timestamp with time zone,
    started_at timestamp with time zone DEFAULT now() NOT NULL,
    applied_steps_count integer DEFAULT 0 NOT NULL
);


ALTER TABLE public._prisma_migrations OWNER TO postgres;

--
-- Name: ServiceItem id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ServiceItem" ALTER COLUMN id SET DEFAULT nextval('public."ServiceItem_id_seq"'::regclass);


--
-- Name: ServicePricingMatrix id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ServicePricingMatrix" ALTER COLUMN id SET DEFAULT nextval('public."ServicePricingMatrix_id_seq"'::regclass);


--
-- Name: Species id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Species" ALTER COLUMN id SET DEFAULT nextval('public."Species_id_seq"'::regclass);


--
-- Data for Name: Appointment; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Appointment" (id, "petId", "groomerId", "merchantId", "startTime", "endTime", status, "durationMinutes", "priceAud", "serviceItemId") FROM stdin;
\.


--
-- Data for Name: Employee; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Employee" (id, "merchantId", name, "avatarUrl") FROM stdin;
\.


--
-- Data for Name: Merchant; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Merchant" (id, email, "passwordHash", "businessName", abn, "stripeAccountId", "createdAt", "logoIcon", "primaryColor", tags) FROM stdin;
46a0661d-b698-42b0-bb52-3d7d524087b6	test@gmail.com	$2b$10$farTmDgcX9G9HHJtxcdg0OqYmkoa2mb1MZat0ELJQL9XCKdaRtZR2	gogo	\N	\N	2026-06-30 11:04:53.768	💇	4279203438	{"love and peace"}
\.


--
-- Data for Name: MerchantBranding; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."MerchantBranding" (id, "merchantId", "logoUrl", "primaryColor", "businessTags") FROM stdin;
\.


--
-- Data for Name: MerchantService; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."MerchantService" (id, "merchantId", name, description, "priceAud", "durationMinutes", "isActive") FROM stdin;
\.


--
-- Data for Name: MerchantUiText; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."MerchantUiText" (id, "merchantId", "uiDictionary") FROM stdin;
\.


--
-- Data for Name: Pet; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Pet" (id, "ownerId", "speciesId", breed, name, "microchipNumber", status, "behaviorNotes", dob, gender, "isDesexed", "merchantId", "behaviorTags") FROM stdin;
\.


--
-- Data for Name: ServiceItem; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."ServiceItem" (id, slug, name) FROM stdin;
\.


--
-- Data for Name: ServicePricingMatrix; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."ServicePricingMatrix" (id, "serviceItemId", "speciesId", "weightTier", "coatType", "durationMinutes", "priceAud") FROM stdin;
\.


--
-- Data for Name: Species; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."Species" (id, name, "baseTimeMultiplier") FROM stdin;
\.


--
-- Data for Name: User; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public."User" (id, email, "phoneNumber", "passwordHash", name, "avatarUrl", "countryCode", "createdAt", "merchantId", role) FROM stdin;
24938780-baaf-4bfb-a3c3-5c700abac0a4	test@gmail.com	\N	$2b$10$farTmDgcX9G9HHJtxcdg0OqYmkoa2mb1MZat0ELJQL9XCKdaRtZR2	ju	\N	AU	2026-06-30 11:04:59.361	46a0661d-b698-42b0-bb52-3d7d524087b6	MERCHANT_ADMIN
\.


--
-- Data for Name: _prisma_migrations; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public._prisma_migrations (id, checksum, finished_at, migration_name, logs, rolled_back_at, started_at, applied_steps_count) FROM stdin;
940c8f4e-c01d-427b-974d-fbaae8a59796	801ceb9fc12e34b30988776da49436c21239f6f230cc5d2da4c203535b45d361	2026-06-29 13:10:01.717008+10	20260629031001_init	\N	\N	2026-06-29 13:10:01.678732+10	1
\.


--
-- Name: ServiceItem_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."ServiceItem_id_seq"', 1, false);


--
-- Name: ServicePricingMatrix_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."ServicePricingMatrix_id_seq"', 1, false);


--
-- Name: Species_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public."Species_id_seq"', 1, false);


--
-- Name: Appointment Appointment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Appointment"
    ADD CONSTRAINT "Appointment_pkey" PRIMARY KEY (id);


--
-- Name: Employee Employee_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Employee"
    ADD CONSTRAINT "Employee_pkey" PRIMARY KEY (id);


--
-- Name: MerchantBranding MerchantBranding_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MerchantBranding"
    ADD CONSTRAINT "MerchantBranding_pkey" PRIMARY KEY (id);


--
-- Name: MerchantService MerchantService_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MerchantService"
    ADD CONSTRAINT "MerchantService_pkey" PRIMARY KEY (id);


--
-- Name: MerchantUiText MerchantUiText_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MerchantUiText"
    ADD CONSTRAINT "MerchantUiText_pkey" PRIMARY KEY (id);


--
-- Name: Merchant Merchant_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Merchant"
    ADD CONSTRAINT "Merchant_pkey" PRIMARY KEY (id);


--
-- Name: Pet Pet_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Pet"
    ADD CONSTRAINT "Pet_pkey" PRIMARY KEY (id);


--
-- Name: ServiceItem ServiceItem_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ServiceItem"
    ADD CONSTRAINT "ServiceItem_pkey" PRIMARY KEY (id);


--
-- Name: ServicePricingMatrix ServicePricingMatrix_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ServicePricingMatrix"
    ADD CONSTRAINT "ServicePricingMatrix_pkey" PRIMARY KEY (id);


--
-- Name: Species Species_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Species"
    ADD CONSTRAINT "Species_pkey" PRIMARY KEY (id);


--
-- Name: User User_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_pkey" PRIMARY KEY (id);


--
-- Name: _prisma_migrations _prisma_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public._prisma_migrations
    ADD CONSTRAINT _prisma_migrations_pkey PRIMARY KEY (id);


--
-- Name: Appointment_merchantId_startTime_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "Appointment_merchantId_startTime_idx" ON public."Appointment" USING btree ("merchantId", "startTime");


--
-- Name: MerchantBranding_merchantId_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "MerchantBranding_merchantId_key" ON public."MerchantBranding" USING btree ("merchantId");


--
-- Name: MerchantUiText_merchantId_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "MerchantUiText_merchantId_key" ON public."MerchantUiText" USING btree ("merchantId");


--
-- Name: Merchant_email_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "Merchant_email_key" ON public."Merchant" USING btree (email);


--
-- Name: Merchant_stripeAccountId_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "Merchant_stripeAccountId_key" ON public."Merchant" USING btree ("stripeAccountId");


--
-- Name: Pet_merchantId_name_status_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "Pet_merchantId_name_status_idx" ON public."Pet" USING btree ("merchantId", name, status);


--
-- Name: Pet_merchantId_ownerId_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "Pet_merchantId_ownerId_idx" ON public."Pet" USING btree ("merchantId", "ownerId");


--
-- Name: Pet_microchipNumber_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "Pet_microchipNumber_key" ON public."Pet" USING btree ("microchipNumber");


--
-- Name: ServiceItem_slug_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "ServiceItem_slug_key" ON public."ServiceItem" USING btree (slug);


--
-- Name: ServicePricingMatrix_serviceItemId_speciesId_weightTier_coa_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "ServicePricingMatrix_serviceItemId_speciesId_weightTier_coa_key" ON public."ServicePricingMatrix" USING btree ("serviceItemId", "speciesId", "weightTier", "coatType");


--
-- Name: Species_name_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "Species_name_key" ON public."Species" USING btree (name);


--
-- Name: User_email_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "User_email_key" ON public."User" USING btree (email);


--
-- Name: User_merchantId_createdAt_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "User_merchantId_createdAt_idx" ON public."User" USING btree ("merchantId", "createdAt");


--
-- Name: User_merchantId_name_idx; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "User_merchantId_name_idx" ON public."User" USING btree ("merchantId", name);


--
-- Name: User_phoneNumber_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX "User_phoneNumber_key" ON public."User" USING btree ("phoneNumber");


--
-- Name: Appointment Appointment_groomerId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Appointment"
    ADD CONSTRAINT "Appointment_groomerId_fkey" FOREIGN KEY ("groomerId") REFERENCES public."Employee"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: Appointment Appointment_merchantId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Appointment"
    ADD CONSTRAINT "Appointment_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES public."Merchant"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: Appointment Appointment_petId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Appointment"
    ADD CONSTRAINT "Appointment_petId_fkey" FOREIGN KEY ("petId") REFERENCES public."Pet"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: Appointment Appointment_serviceItemId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Appointment"
    ADD CONSTRAINT "Appointment_serviceItemId_fkey" FOREIGN KEY ("serviceItemId") REFERENCES public."ServiceItem"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: Employee Employee_merchantId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Employee"
    ADD CONSTRAINT "Employee_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES public."Merchant"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: MerchantBranding MerchantBranding_merchantId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MerchantBranding"
    ADD CONSTRAINT "MerchantBranding_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES public."Merchant"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: MerchantService MerchantService_merchantId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MerchantService"
    ADD CONSTRAINT "MerchantService_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES public."Merchant"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: MerchantUiText MerchantUiText_merchantId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."MerchantUiText"
    ADD CONSTRAINT "MerchantUiText_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES public."Merchant"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: Pet Pet_merchantId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Pet"
    ADD CONSTRAINT "Pet_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES public."Merchant"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: Pet Pet_ownerId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Pet"
    ADD CONSTRAINT "Pet_ownerId_fkey" FOREIGN KEY ("ownerId") REFERENCES public."User"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: Pet Pet_speciesId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."Pet"
    ADD CONSTRAINT "Pet_speciesId_fkey" FOREIGN KEY ("speciesId") REFERENCES public."Species"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: ServicePricingMatrix ServicePricingMatrix_serviceItemId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ServicePricingMatrix"
    ADD CONSTRAINT "ServicePricingMatrix_serviceItemId_fkey" FOREIGN KEY ("serviceItemId") REFERENCES public."ServiceItem"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: ServicePricingMatrix ServicePricingMatrix_speciesId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."ServicePricingMatrix"
    ADD CONSTRAINT "ServicePricingMatrix_speciesId_fkey" FOREIGN KEY ("speciesId") REFERENCES public."Species"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: User User_merchantId_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public."User"
    ADD CONSTRAINT "User_merchantId_fkey" FOREIGN KEY ("merchantId") REFERENCES public."Merchant"(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

\unrestrict Z4my8VbToBNSyrsPOOGuqx6IQhrNsjSdOzZWSNWywTXZBEZfKBkSeZyLidmGz5q

