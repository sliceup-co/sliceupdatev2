--
-- PostgreSQL database dump
--

-- Dumped from database version 10.14 (Ubuntu 10.14-0ubuntu0.18.04.1)
-- Dumped by pg_dump version 10.14 (Ubuntu 10.14-0ubuntu0.18.04.1)

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
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: analized_units; Type: TABLE; Schema: public; Owner: sliceup
--

CREATE TABLE public.analized_units (
    id integer NOT NULL,
    unit_name character varying
);


ALTER TABLE public.analized_units OWNER TO sliceup;

--
-- Name: analized_units_id_seq; Type: SEQUENCE; Schema: public; Owner: sliceup
--

CREATE SEQUENCE public.analized_units_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.analized_units_id_seq OWNER TO sliceup;

--
-- Name: analized_units_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sliceup
--

ALTER SEQUENCE public.analized_units_id_seq OWNED BY public.analized_units.id;


--
-- Name: time_window_templates; Type: TABLE; Schema: public; Owner: sliceup
--

CREATE TABLE public.time_window_templates (
    time_window_id bigint NOT NULL,
    template_id character varying NOT NULL,
    template_version integer NOT NULL,
    count bigint NOT NULL,
    sentiment_contribution numeric NOT NULL
);


ALTER TABLE public.time_window_templates OWNER TO sliceup;

--
-- Name: time_windows; Type: TABLE; Schema: public; Owner: sliceup
--

CREATE TABLE public.time_windows (
    id bigint NOT NULL,
    entity_analyzed_id integer NOT NULL,
    start_time bigint NOT NULL,
    end_time bigint NOT NULL,
    duration integer NOT NULL,
    anomalous boolean DEFAULT true NOT NULL,
    anomalous_score numeric,
    frequency_score numeric,
    sentiment_score numeric,
    total_count integer,
    average numeric,
    deviation numeric,
    data json NOT NULL
);


ALTER TABLE public.time_windows OWNER TO sliceup;

--
-- Name: anom_detail_list; Type: VIEW; Schema: public; Owner: sliceup
--

CREATE VIEW public.anom_detail_list AS
 SELECT a.start_time AS "Anomaly Time",
    a.time_window_id,
    b.template_id,
    b.template_version,
    a.anomalous_score
   FROM (public.time_window_templates b
     JOIN ( SELECT time_window_templates.time_window_id,
            time_windows.start_time,
            time_windows.anomalous_score,
            max(time_window_templates.sentiment_contribution) AS max
           FROM (public.time_window_templates
             JOIN public.time_windows ON ((time_window_templates.time_window_id = time_windows.id)))
          WHERE (time_windows.anomalous = true)
          GROUP BY time_window_templates.time_window_id, time_windows.start_time, time_windows.anomalous_score) a ON (((b.sentiment_contribution = a.max) AND (b.time_window_id = a.time_window_id))));


ALTER TABLE public.anom_detail_list OWNER TO sliceup;

--
-- Name: anom_highest_contrib_template; Type: VIEW; Schema: public; Owner: sliceup
--

CREATE VIEW public.anom_highest_contrib_template AS
 SELECT max(c.start_time) AS max_start_time,
    max(c.anomalous_score) AS max_anomalous_score,
    count(c.time_window_id) AS time_window_count,
    c.template_id,
    c.template_version
   FROM ( SELECT a.time_window_id,
            b.template_id,
            b.template_version,
            a.anomalous_score,
            a.start_time
           FROM (public.time_window_templates b
             JOIN ( SELECT time_window_templates.time_window_id,
                    time_windows.start_time,
                    time_windows.anomalous_score,
                    max(time_window_templates.sentiment_contribution) AS max
                   FROM (public.time_window_templates
                     JOIN public.time_windows ON ((time_window_templates.time_window_id = time_windows.id)))
                  WHERE (time_windows.anomalous = true)
                  GROUP BY time_window_templates.time_window_id, time_windows.start_time, time_windows.anomalous_score
                  ORDER BY time_window_templates.time_window_id) a ON (((b.sentiment_contribution = a.max) AND (b.time_window_id = a.time_window_id))))) c
  GROUP BY c.template_id, c.template_version;


ALTER TABLE public.anom_highest_contrib_template OWNER TO sliceup;

--
-- Name: anomalies_by_host; Type: VIEW; Schema: public; Owner: sliceup
--

CREATE VIEW public.anomalies_by_host AS
 SELECT time_windows.start_time,
    analized_units.unit_name,
    (time_windows.anomalous)::integer AS anomalous
   FROM (public.time_windows
     JOIN public.analized_units ON ((time_windows.entity_analyzed_id = analized_units.id)))
  ORDER BY time_windows.start_time;


ALTER TABLE public.anomalies_by_host OWNER TO sliceup;

--
-- Name: anomalies_over_time; Type: VIEW; Schema: public; Owner: sliceup
--

CREATE VIEW public.anomalies_over_time AS
 SELECT time_windows.start_time,
    sum((time_windows.anomalous)::integer) AS sum
   FROM public.time_windows
  GROUP BY time_windows.start_time;


ALTER TABLE public.anomalies_over_time OWNER TO sliceup;

--
-- Name: templates; Type: TABLE; Schema: public; Owner: sliceup
--

CREATE TABLE public.templates (
    id character varying NOT NULL,
    version smallint NOT NULL,
    template character varying NOT NULL,
    table_name character varying NOT NULL,
    params json NOT NULL
);


ALTER TABLE public.templates OWNER TO sliceup;

--
-- Name: anomaly_detail; Type: VIEW; Schema: public; Owner: sliceup
--

CREATE VIEW public.anomaly_detail AS
 SELECT time_window_templates.time_window_id,
    time_window_templates.count,
    time_window_templates.sentiment_contribution,
    templates.template,
    templates.id,
    templates.version,
    templates.table_name
   FROM (public.time_window_templates
     JOIN public.templates ON ((((templates.id)::text = (time_window_templates.template_id)::text) AND (templates.version = time_window_templates.template_version))))
  ORDER BY time_window_templates.count DESC;


ALTER TABLE public.anomaly_detail OWNER TO sliceup;

--
-- Name: anomaly_evolution; Type: VIEW; Schema: public; Owner: sliceup
--

CREATE VIEW public.anomaly_evolution AS
 SELECT time_windows.id,
    time_windows.start_time,
    analized_units.unit_name,
    time_windows.anomalous,
    time_windows.anomalous_score,
    time_windows.frequency_score,
    time_windows.sentiment_score,
    time_windows.total_count
   FROM (public.time_windows
     JOIN public.analized_units ON ((time_windows.entity_analyzed_id = analized_units.id)))
  WHERE (time_windows.anomalous_score IS NOT NULL)
  ORDER BY time_windows.start_time;


ALTER TABLE public.anomaly_evolution OWNER TO sliceup;

--
-- Name: anomaly_host_detail; Type: VIEW; Schema: public; Owner: sliceup
--

CREATE VIEW public.anomaly_host_detail AS
 SELECT time_windows.id,
    time_windows.start_time,
    analized_units.unit_name,
    time_windows.anomalous,
    time_windows.anomalous_score,
    time_windows.frequency_score,
    time_windows.sentiment_score,
    time_windows.total_count
   FROM (public.time_windows
     JOIN public.analized_units ON ((time_windows.entity_analyzed_id = analized_units.id)))
  WHERE ((time_windows.anomalous = true) AND (time_windows.anomalous_score IS NOT NULL))
  ORDER BY time_windows.start_time;


ALTER TABLE public.anomaly_host_detail OWNER TO sliceup;

--
-- Name: templates_example; Type: TABLE; Schema: public; Owner: sliceup
--

CREATE TABLE public.templates_example (
    template_id character varying,
    template_version integer,
    record character varying NOT NULL
);


ALTER TABLE public.templates_example OWNER TO sliceup;

--
-- Name: log_examples; Type: VIEW; Schema: public; Owner: sliceup
--

CREATE VIEW public.log_examples AS
 SELECT templates_example.template_id,
    templates_example.template_version,
    templates.table_name,
    templates_example.record
   FROM (public.templates_example
     JOIN public.templates ON (((templates_example.template_id)::text = (templates.id)::text)));


ALTER TABLE public.log_examples OWNER TO sliceup;

--
-- Name: logs_by_host; Type: VIEW; Schema: public; Owner: sliceup
--

CREATE VIEW public.logs_by_host AS
 SELECT time_windows.start_time,
    analized_units.unit_name,
    time_windows.total_count
   FROM (public.time_windows
     JOIN public.analized_units ON ((time_windows.entity_analyzed_id = analized_units.id)));


ALTER TABLE public.logs_by_host OWNER TO sliceup;

--
-- Name: logs_over_time; Type: VIEW; Schema: public; Owner: sliceup
--

CREATE VIEW public.logs_over_time AS
 SELECT time_windows.start_time,
    sum(time_windows.total_count) AS sum
   FROM public.time_windows
  GROUP BY time_windows.start_time
  ORDER BY time_windows.start_time;


ALTER TABLE public.logs_over_time OWNER TO sliceup;

--
-- Name: max_anomaly_host; Type: VIEW; Schema: public; Owner: sliceup
--

CREATE VIEW public.max_anomaly_host AS
 SELECT time_windows.start_time,
    analized_units.unit_name,
    time_windows.anomalous_score
   FROM (public.time_windows
     JOIN public.analized_units ON ((time_windows.entity_analyzed_id = analized_units.id)))
  WHERE ((time_windows.anomalous = true) AND (time_windows.anomalous_score IS NOT NULL));


ALTER TABLE public.max_anomaly_host OWNER TO sliceup;

--
-- Name: max_anomaly_host_with_id; Type: VIEW; Schema: public; Owner: sliceup
--

CREATE VIEW public.max_anomaly_host_with_id AS
 SELECT time_windows.start_time,
    analized_units.unit_name,
    time_windows.anomalous_score,
    time_windows.id
   FROM (public.time_windows
     JOIN public.analized_units ON ((time_windows.entity_analyzed_id = analized_units.id)))
  WHERE ((time_windows.anomalous = true) AND (time_windows.anomalous_score IS NOT NULL));


ALTER TABLE public.max_anomaly_host_with_id OWNER TO sliceup;

--
-- Name: record_scores; Type: TABLE; Schema: public; Owner: sliceup
--

CREATE TABLE public.record_scores (
    record_id character varying NOT NULL,
    time_window_id bigint NOT NULL,
    template_id character varying NOT NULL,
    template_version integer NOT NULL,
    record_score numeric NOT NULL,
    synthetic_record character varying NOT NULL
);


ALTER TABLE public.record_scores OWNER TO sliceup;

--
-- Name: salient_records; Type: VIEW; Schema: public; Owner: sliceup
--

CREATE VIEW public.salient_records AS
 SELECT time_windows.start_time,
    record_scores.time_window_id,
    record_scores.record_id,
    templates.table_name,
    record_scores.synthetic_record,
    record_scores.record_score
   FROM ((public.record_scores
     JOIN public.templates ON ((((record_scores.template_id)::text = (templates.id)::text) AND (record_scores.template_version = templates.version))))
     JOIN public.time_windows ON ((record_scores.time_window_id = time_windows.id)))
  ORDER BY record_scores.time_window_id, record_scores.record_score DESC;


ALTER TABLE public.salient_records OWNER TO sliceup;

--
-- Name: template_count; Type: VIEW; Schema: public; Owner: sliceup
--

CREATE VIEW public.template_count AS
 SELECT time_windows.start_time,
    templates.table_name,
    sum(time_window_templates.count) AS sum
   FROM ((public.time_window_templates
     JOIN public.templates ON ((((templates.id)::text = (time_window_templates.template_id)::text) AND (templates.version = time_window_templates.template_version))))
     JOIN public.time_windows ON ((time_window_templates.time_window_id = time_windows.id)))
  GROUP BY templates.table_name, time_window_templates.template_id, time_window_templates.template_version, time_windows.start_time
  ORDER BY time_window_templates.template_id, time_window_templates.template_version;


ALTER TABLE public.template_count OWNER TO sliceup;

--
-- Name: template_counts_host; Type: VIEW; Schema: public; Owner: sliceup
--

CREATE VIEW public.template_counts_host AS
 SELECT time_windows.start_time,
    analized_units.unit_name,
    templates.table_name,
    time_window_templates.count
   FROM (((public.time_window_templates
     JOIN public.templates ON ((((templates.id)::text = (time_window_templates.template_id)::text) AND (templates.version = time_window_templates.template_version))))
     JOIN public.time_windows ON ((time_windows.id = time_window_templates.time_window_id)))
     JOIN public.analized_units ON ((time_windows.entity_analyzed_id = analized_units.id)));


ALTER TABLE public.template_counts_host OWNER TO sliceup;

--
-- Name: time_windows_id_seq; Type: SEQUENCE; Schema: public; Owner: sliceup
--

CREATE SEQUENCE public.time_windows_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.time_windows_id_seq OWNER TO sliceup;

--
-- Name: time_windows_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: sliceup
--

ALTER SEQUENCE public.time_windows_id_seq OWNED BY public.time_windows.id;


--
-- Name: word_dictionary; Type: TABLE; Schema: public; Owner: sliceup
--

CREATE TABLE public.word_dictionary (
    word character varying NOT NULL,
    score numeric NOT NULL
);


ALTER TABLE public.word_dictionary OWNER TO sliceup;

--
-- Name: word_scores; Type: TABLE; Schema: public; Owner: sliceup
--

CREATE TABLE public.word_scores (
    record_id character varying NOT NULL,
    word_sentiment character varying NOT NULL,
    time_window_id bigint NOT NULL,
    word_count integer NOT NULL,
    word_score numeric NOT NULL
);


ALTER TABLE public.word_scores OWNER TO sliceup;

--
-- Name: word_scores_by_time_window; Type: VIEW; Schema: public; Owner: sliceup
--

CREATE VIEW public.word_scores_by_time_window AS
 SELECT word_scores.word_sentiment,
    sum(word_scores.word_score) AS word_contribution,
    word_scores.time_window_id
   FROM public.word_scores
  GROUP BY word_scores.time_window_id, word_scores.word_sentiment
  ORDER BY word_scores.time_window_id, (sum(word_scores.word_score)) DESC;


ALTER TABLE public.word_scores_by_time_window OWNER TO sliceup;

--
-- Name: word_scores_by_time_window_and_template; Type: MATERIALIZED VIEW; Schema: public; Owner: sliceup
--

CREATE MATERIALIZED VIEW public.word_scores_by_time_window_and_template AS
 SELECT record_scores.template_id,
    record_scores.template_version,
    word_scores.word_sentiment,
    sum(word_scores.word_score) AS word_contribution,
    word_scores.time_window_id
   FROM (public.word_scores
     JOIN public.record_scores ON (((word_scores.record_id)::text = (record_scores.record_id)::text)))
  GROUP BY word_scores.time_window_id, word_scores.word_sentiment, record_scores.template_id, record_scores.template_version
  WITH NO DATA;


ALTER TABLE public.word_scores_by_time_window_and_template OWNER TO sliceup;

--
-- Name: analized_units id; Type: DEFAULT; Schema: public; Owner: sliceup
--

ALTER TABLE ONLY public.analized_units ALTER COLUMN id SET DEFAULT nextval('public.analized_units_id_seq'::regclass);


--
-- Name: time_windows id; Type: DEFAULT; Schema: public; Owner: sliceup
--

ALTER TABLE ONLY public.time_windows ALTER COLUMN id SET DEFAULT nextval('public.time_windows_id_seq'::regclass);


--
-- Data for Name: analized_units; Type: TABLE DATA; Schema: public; Owner: sliceup
--

COPY public.analized_units (id, unit_name) FROM stdin;
\.


--
-- Data for Name: record_scores; Type: TABLE DATA; Schema: public; Owner: sliceup
--

COPY public.record_scores (record_id, time_window_id, template_id, template_version, record_score, synthetic_record) FROM stdin;
\.


--
-- Data for Name: templates; Type: TABLE DATA; Schema: public; Owner: sliceup
--

COPY public.templates (id, version, template, table_name, params) FROM stdin;
\.


--
-- Data for Name: templates_example; Type: TABLE DATA; Schema: public; Owner: sliceup
--

COPY public.templates_example (template_id, template_version, record) FROM stdin;
\.


--
-- Data for Name: time_window_templates; Type: TABLE DATA; Schema: public; Owner: sliceup
--

COPY public.time_window_templates (time_window_id, template_id, template_version, count, sentiment_contribution) FROM stdin;
\.


--
-- Data for Name: time_windows; Type: TABLE DATA; Schema: public; Owner: sliceup
--

COPY public.time_windows (id, entity_analyzed_id, start_time, end_time, duration, anomalous, anomalous_score, frequency_score, sentiment_score, total_count, average, deviation, data) FROM stdin;
\.


--
-- Data for Name: word_dictionary; Type: TABLE DATA; Schema: public; Owner: sliceup
--

COPY public.word_dictionary (word, score) FROM stdin;
\.


--
-- Data for Name: word_scores; Type: TABLE DATA; Schema: public; Owner: sliceup
--

COPY public.word_scores (record_id, word_sentiment, time_window_id, word_count, word_score) FROM stdin;
\.


--
-- Name: analized_units_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sliceup
--

SELECT pg_catalog.setval('public.analized_units_id_seq', 1, false);


--
-- Name: time_windows_id_seq; Type: SEQUENCE SET; Schema: public; Owner: sliceup
--

SELECT pg_catalog.setval('public.time_windows_id_seq', 1, false);


--
-- Name: analized_units analized_units_pkey; Type: CONSTRAINT; Schema: public; Owner: sliceup
--

ALTER TABLE ONLY public.analized_units
    ADD CONSTRAINT analized_units_pkey PRIMARY KEY (id);


--
-- Name: analized_units analized_units_unit_name_key; Type: CONSTRAINT; Schema: public; Owner: sliceup
--

ALTER TABLE ONLY public.analized_units
    ADD CONSTRAINT analized_units_unit_name_key UNIQUE (unit_name);


--
-- Name: record_scores record_scores_pkey; Type: CONSTRAINT; Schema: public; Owner: sliceup
--

ALTER TABLE ONLY public.record_scores
    ADD CONSTRAINT record_scores_pkey PRIMARY KEY (record_id);


--
-- Name: templates templates_pkey; Type: CONSTRAINT; Schema: public; Owner: sliceup
--

ALTER TABLE ONLY public.templates
    ADD CONSTRAINT templates_pkey PRIMARY KEY (id, version);


--
-- Name: templates templates_table_name_key; Type: CONSTRAINT; Schema: public; Owner: sliceup
--

ALTER TABLE ONLY public.templates
    ADD CONSTRAINT templates_table_name_key UNIQUE (table_name);


--
-- Name: time_window_templates time_window_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: sliceup
--

ALTER TABLE ONLY public.time_window_templates
    ADD CONSTRAINT time_window_templates_pkey PRIMARY KEY (time_window_id, template_id, template_version);


--
-- Name: time_windows time_windows_pkey; Type: CONSTRAINT; Schema: public; Owner: sliceup
--

ALTER TABLE ONLY public.time_windows
    ADD CONSTRAINT time_windows_pkey PRIMARY KEY (id);


--
-- Name: time_windows time_windows_start_time_end_time_entity_analyzed_id_key; Type: CONSTRAINT; Schema: public; Owner: sliceup
--

ALTER TABLE ONLY public.time_windows
    ADD CONSTRAINT time_windows_start_time_end_time_entity_analyzed_id_key UNIQUE (start_time, end_time, entity_analyzed_id);


--
-- Name: word_dictionary word_dictionary_pkey; Type: CONSTRAINT; Schema: public; Owner: sliceup
--

ALTER TABLE ONLY public.word_dictionary
    ADD CONSTRAINT word_dictionary_pkey PRIMARY KEY (word);


--
-- Name: record_scores record_scores_template_id_template_version_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sliceup
--

ALTER TABLE ONLY public.record_scores
    ADD CONSTRAINT record_scores_template_id_template_version_fkey FOREIGN KEY (template_id, template_version) REFERENCES public.templates(id, version);


--
-- Name: record_scores record_scores_time_window_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sliceup
--

ALTER TABLE ONLY public.record_scores
    ADD CONSTRAINT record_scores_time_window_id_fkey FOREIGN KEY (time_window_id) REFERENCES public.time_windows(id) ON DELETE CASCADE;


--
-- Name: templates_example templates_example_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sliceup
--

ALTER TABLE ONLY public.templates_example
    ADD CONSTRAINT templates_example_template_id_fkey FOREIGN KEY (template_id, template_version) REFERENCES public.templates(id, version) ON DELETE CASCADE;


--
-- Name: time_window_templates time_window_templates_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sliceup
--

ALTER TABLE ONLY public.time_window_templates
    ADD CONSTRAINT time_window_templates_template_id_fkey FOREIGN KEY (template_id, template_version) REFERENCES public.templates(id, version);


--
-- Name: time_window_templates time_window_templates_time_window_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sliceup
--

ALTER TABLE ONLY public.time_window_templates
    ADD CONSTRAINT time_window_templates_time_window_id_fkey FOREIGN KEY (time_window_id) REFERENCES public.time_windows(id) ON DELETE CASCADE;


--
-- Name: time_windows time_windows_entity_analyzed_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sliceup
--

ALTER TABLE ONLY public.time_windows
    ADD CONSTRAINT time_windows_entity_analyzed_id_fkey FOREIGN KEY (entity_analyzed_id) REFERENCES public.analized_units(id);


--
-- Name: word_scores word_scores_record_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sliceup
--

ALTER TABLE ONLY public.word_scores
    ADD CONSTRAINT word_scores_record_id_fkey FOREIGN KEY (record_id) REFERENCES public.record_scores(record_id);


--
-- Name: word_scores word_scores_time_window_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: sliceup
--

ALTER TABLE ONLY public.word_scores
    ADD CONSTRAINT word_scores_time_window_id_fkey FOREIGN KEY (time_window_id) REFERENCES public.time_windows(id) ON DELETE CASCADE;


--
-- Name: word_scores_by_time_window_and_template; Type: MATERIALIZED VIEW DATA; Schema: public; Owner: sliceup
--

REFRESH MATERIALIZED VIEW public.word_scores_by_time_window_and_template;


--
-- PostgreSQL database dump complete
--

