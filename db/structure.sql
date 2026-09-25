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
-- Name: numeric; Type: COLLATION; Schema: public; Owner: -
--

CREATE COLLATION public."numeric" (provider = icu, locale = 'en-u-kn');


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: active_storage_attachments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_attachments (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    name character varying NOT NULL,
    record_id bigint NOT NULL,
    record_type character varying NOT NULL
);


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_attachments_id_seq OWNED BY public.active_storage_attachments.id;


--
-- Name: active_storage_blobs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_blobs (
    id bigint NOT NULL,
    byte_size bigint NOT NULL,
    checksum character varying,
    content_type character varying,
    created_at timestamp(6) without time zone NOT NULL,
    filename character varying NOT NULL,
    key character varying NOT NULL,
    metadata text,
    service_name character varying NOT NULL
);


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_blobs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_blobs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_blobs_id_seq OWNED BY public.active_storage_blobs.id;


--
-- Name: active_storage_variant_records; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.active_storage_variant_records (
    id bigint NOT NULL,
    blob_id bigint NOT NULL,
    variation_digest character varying NOT NULL
);


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.active_storage_variant_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_storage_variant_records_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.active_storage_variant_records_id_seq OWNED BY public.active_storage_variant_records.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: bulk_actions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bulk_actions (
    id bigint NOT NULL,
    action_type character varying NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    description text,
    druid_count_fail integer DEFAULT 0 NOT NULL,
    druid_count_success integer DEFAULT 0 NOT NULL,
    druid_count_total integer DEFAULT 0 NOT NULL,
    status character varying DEFAULT 'created'::character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: bulk_actions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bulk_actions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bulk_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bulk_actions_id_seq OWNED BY public.bulk_actions.id;


--
-- Name: content_file_binaries; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.content_file_binaries (
    id bigint NOT NULL,
    basename character varying NOT NULL,
    content_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    extname character varying NOT NULL,
    file_location character varying NOT NULL,
    filepath character varying NOT NULL,
    md5_digest character varying,
    mime_type character varying,
    path_parts character varying[] DEFAULT '{}'::character varying[] NOT NULL,
    sha1_digest character varying,
    size bigint,
    updated_at timestamp(6) without time zone NOT NULL,
    mount_path character varying
);


--
-- Name: content_file_binaries_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.content_file_binaries_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: content_file_binaries_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.content_file_binaries_id_seq OWNED BY public.content_file_binaries.id;


--
-- Name: content_file_sets; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.content_file_sets (
    id bigint NOT NULL,
    content_id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    external_identifier character varying,
    file_set_type character varying NOT NULL,
    label character varying NOT NULL,
    "position" integer NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: content_file_sets_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.content_file_sets_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: content_file_sets_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.content_file_sets_id_seq OWNED BY public.content_file_sets.id;


--
-- Name: content_files; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.content_files (
    id bigint NOT NULL,
    content_file_binary_id bigint NOT NULL,
    content_file_set_id bigint NOT NULL,
    corrected_for_accessibility boolean DEFAULT false NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    download character varying NOT NULL,
    external_identifier character varying,
    height integer,
    label character varying NOT NULL,
    language_tag character varying,
    location character varying,
    "position" integer NOT NULL,
    preserve boolean NOT NULL,
    publish boolean NOT NULL,
    sdr_generated_text boolean DEFAULT false NOT NULL,
    shelve boolean NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    use character varying,
    view character varying NOT NULL,
    width integer
);


--
-- Name: content_files_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.content_files_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: content_files_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.content_files_id_seq OWNED BY public.content_files.id;


--
-- Name: contents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.contents (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    druid character varying NOT NULL,
    immutable boolean DEFAULT true NOT NULL,
    lock character varying NOT NULL,
    staging_state character varying DEFAULT 'staging_not_in_progress'::character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    mount_state character varying DEFAULT 'discovery_not_in_progress'::character varying NOT NULL
);


--
-- Name: contents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.contents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contents_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.contents_id_seq OWNED BY public.contents.id;


--
-- Name: form_validation_actions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.form_validation_actions (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    error_data jsonb,
    form_payload jsonb NOT NULL,
    status character varying DEFAULT 'created'::character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: form_validation_actions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.form_validation_actions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: form_validation_actions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.form_validation_actions_id_seq OWNED BY public.form_validation_actions.id;


--
-- Name: permissions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.permissions (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    permission_type character varying NOT NULL,
    target_druid character varying,
    updated_at timestamp(6) without time zone NOT NULL,
    workgroup character varying NOT NULL
);


--
-- Name: permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.permissions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.permissions_id_seq OWNED BY public.permissions.id;


--
-- Name: pinned_objects; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pinned_objects (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    druid character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: pinned_objects_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pinned_objects_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pinned_objects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pinned_objects_id_seq OWNED BY public.pinned_objects.id;


--
-- Name: pinned_searches; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pinned_searches (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    search_form_attributes jsonb NOT NULL,
    search_form_md5 character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: pinned_searches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pinned_searches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pinned_searches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pinned_searches_id_seq OWNED BY public.pinned_searches.id;


--
-- Name: pinned_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pinned_tags (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    tag character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    user_id bigint NOT NULL
);


--
-- Name: pinned_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.pinned_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: pinned_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.pinned_tags_id_seq OWNED BY public.pinned_tags.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    email_address character varying NOT NULL,
    groups character varying[] DEFAULT '{}'::character varying[],
    name character varying NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: active_storage_attachments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments ALTER COLUMN id SET DEFAULT nextval('public.active_storage_attachments_id_seq'::regclass);


--
-- Name: active_storage_blobs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs ALTER COLUMN id SET DEFAULT nextval('public.active_storage_blobs_id_seq'::regclass);


--
-- Name: active_storage_variant_records id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records ALTER COLUMN id SET DEFAULT nextval('public.active_storage_variant_records_id_seq'::regclass);


--
-- Name: bulk_actions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bulk_actions ALTER COLUMN id SET DEFAULT nextval('public.bulk_actions_id_seq'::regclass);


--
-- Name: content_file_binaries id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_file_binaries ALTER COLUMN id SET DEFAULT nextval('public.content_file_binaries_id_seq'::regclass);


--
-- Name: content_file_sets id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_file_sets ALTER COLUMN id SET DEFAULT nextval('public.content_file_sets_id_seq'::regclass);


--
-- Name: content_files id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_files ALTER COLUMN id SET DEFAULT nextval('public.content_files_id_seq'::regclass);


--
-- Name: contents id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contents ALTER COLUMN id SET DEFAULT nextval('public.contents_id_seq'::regclass);


--
-- Name: form_validation_actions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.form_validation_actions ALTER COLUMN id SET DEFAULT nextval('public.form_validation_actions_id_seq'::regclass);


--
-- Name: permissions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permissions ALTER COLUMN id SET DEFAULT nextval('public.permissions_id_seq'::regclass);


--
-- Name: pinned_objects id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pinned_objects ALTER COLUMN id SET DEFAULT nextval('public.pinned_objects_id_seq'::regclass);


--
-- Name: pinned_searches id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pinned_searches ALTER COLUMN id SET DEFAULT nextval('public.pinned_searches_id_seq'::regclass);


--
-- Name: pinned_tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pinned_tags ALTER COLUMN id SET DEFAULT nextval('public.pinned_tags_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: active_storage_attachments active_storage_attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT active_storage_attachments_pkey PRIMARY KEY (id);


--
-- Name: active_storage_blobs active_storage_blobs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_blobs
    ADD CONSTRAINT active_storage_blobs_pkey PRIMARY KEY (id);


--
-- Name: active_storage_variant_records active_storage_variant_records_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT active_storage_variant_records_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: bulk_actions bulk_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bulk_actions
    ADD CONSTRAINT bulk_actions_pkey PRIMARY KEY (id);


--
-- Name: content_file_binaries content_file_binaries_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_file_binaries
    ADD CONSTRAINT content_file_binaries_pkey PRIMARY KEY (id);


--
-- Name: content_file_sets content_file_sets_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_file_sets
    ADD CONSTRAINT content_file_sets_pkey PRIMARY KEY (id);


--
-- Name: content_files content_files_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_files
    ADD CONSTRAINT content_files_pkey PRIMARY KEY (id);


--
-- Name: contents contents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.contents
    ADD CONSTRAINT contents_pkey PRIMARY KEY (id);


--
-- Name: form_validation_actions form_validation_actions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.form_validation_actions
    ADD CONSTRAINT form_validation_actions_pkey PRIMARY KEY (id);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: pinned_objects pinned_objects_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pinned_objects
    ADD CONSTRAINT pinned_objects_pkey PRIMARY KEY (id);


--
-- Name: pinned_searches pinned_searches_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pinned_searches
    ADD CONSTRAINT pinned_searches_pkey PRIMARY KEY (id);


--
-- Name: pinned_tags pinned_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pinned_tags
    ADD CONSTRAINT pinned_tags_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_on_workgroup_permission_type_target_druid_05a2ba0d8f; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_on_workgroup_permission_type_target_druid_05a2ba0d8f ON public.permissions USING btree (workgroup, permission_type, target_druid) NULLS NOT DISTINCT;


--
-- Name: index_active_storage_attachments_on_blob_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_active_storage_attachments_on_blob_id ON public.active_storage_attachments USING btree (blob_id);


--
-- Name: index_active_storage_attachments_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_attachments_uniqueness ON public.active_storage_attachments USING btree (record_type, record_id, name, blob_id);


--
-- Name: index_active_storage_blobs_on_key; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_blobs_on_key ON public.active_storage_blobs USING btree (key);


--
-- Name: index_active_storage_variant_records_uniqueness; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_active_storage_variant_records_uniqueness ON public.active_storage_variant_records USING btree (blob_id, variation_digest);


--
-- Name: index_bulk_actions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_bulk_actions_on_user_id ON public.bulk_actions USING btree (user_id);


--
-- Name: index_content_file_binaries_on_content_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_file_binaries_on_content_id ON public.content_file_binaries USING btree (content_id);


--
-- Name: index_content_file_binaries_on_content_id_and_filepath; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_content_file_binaries_on_content_id_and_filepath ON public.content_file_binaries USING btree (content_id, filepath);


--
-- Name: index_content_file_sets_on_content_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_file_sets_on_content_id ON public.content_file_sets USING btree (content_id);


--
-- Name: index_content_file_sets_on_content_id_and_position; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_content_file_sets_on_content_id_and_position ON public.content_file_sets USING btree (content_id, "position");


--
-- Name: index_content_files_on_content_file_binary_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_files_on_content_file_binary_id ON public.content_files USING btree (content_file_binary_id);


--
-- Name: index_content_files_on_content_file_set_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_content_files_on_content_file_set_id ON public.content_files USING btree (content_file_set_id);


--
-- Name: index_content_files_on_content_file_set_id_and_position; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_content_files_on_content_file_set_id_and_position ON public.content_files USING btree (content_file_set_id, "position");


--
-- Name: index_contents_on_druid_and_lock_and_immutable; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_contents_on_druid_and_lock_and_immutable ON public.contents USING btree (druid, lock, immutable);


--
-- Name: index_form_validation_actions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_form_validation_actions_on_user_id ON public.form_validation_actions USING btree (user_id);


--
-- Name: index_permissions_on_target_druid; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_permissions_on_target_druid ON public.permissions USING btree (target_druid);


--
-- Name: index_pinned_objects_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pinned_objects_on_user_id ON public.pinned_objects USING btree (user_id);


--
-- Name: index_pinned_objects_on_user_id_and_druid; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pinned_objects_on_user_id_and_druid ON public.pinned_objects USING btree (user_id, druid);


--
-- Name: index_pinned_searches_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pinned_searches_on_user_id ON public.pinned_searches USING btree (user_id);


--
-- Name: index_pinned_searches_on_user_id_and_search_form_md5; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pinned_searches_on_user_id_and_search_form_md5 ON public.pinned_searches USING btree (user_id, search_form_md5);


--
-- Name: index_pinned_tags_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_pinned_tags_on_user_id ON public.pinned_tags USING btree (user_id);


--
-- Name: index_pinned_tags_on_user_id_and_tag; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_pinned_tags_on_user_id_and_tag ON public.pinned_tags USING btree (user_id, tag);


--
-- Name: index_users_on_email_address; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email_address ON public.users USING btree (email_address);


--
-- Name: content_file_binaries fk_rails_08676b556d; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_file_binaries
    ADD CONSTRAINT fk_rails_08676b556d FOREIGN KEY (content_id) REFERENCES public.contents(id);


--
-- Name: content_files fk_rails_3148f8bb68; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_files
    ADD CONSTRAINT fk_rails_3148f8bb68 FOREIGN KEY (content_file_binary_id) REFERENCES public.content_file_binaries(id);


--
-- Name: pinned_objects fk_rails_4bde216498; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pinned_objects
    ADD CONSTRAINT fk_rails_4bde216498 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: pinned_tags fk_rails_7ee08fc325; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pinned_tags
    ADD CONSTRAINT fk_rails_7ee08fc325 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: pinned_searches fk_rails_9363851b70; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pinned_searches
    ADD CONSTRAINT fk_rails_9363851b70 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: active_storage_variant_records fk_rails_993965df05; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_variant_records
    ADD CONSTRAINT fk_rails_993965df05 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: content_files fk_rails_9c2751e3c0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_files
    ADD CONSTRAINT fk_rails_9c2751e3c0 FOREIGN KEY (content_file_set_id) REFERENCES public.content_file_sets(id);


--
-- Name: form_validation_actions fk_rails_b84cab4fe2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.form_validation_actions
    ADD CONSTRAINT fk_rails_b84cab4fe2 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: active_storage_attachments fk_rails_c3b3935057; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.active_storage_attachments
    ADD CONSTRAINT fk_rails_c3b3935057 FOREIGN KEY (blob_id) REFERENCES public.active_storage_blobs(id);


--
-- Name: bulk_actions fk_rails_d7e4ed32e0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bulk_actions
    ADD CONSTRAINT fk_rails_d7e4ed32e0 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: content_file_sets fk_rails_d8595a7992; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.content_file_sets
    ADD CONSTRAINT fk_rails_d8595a7992 FOREIGN KEY (content_id) REFERENCES public.contents(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20260925120000'),
('20260924170659'),
('20260924132418'),
('20260922120000'),
('20260916120000'),
('20260911123744'),
('20260820180000'),
('20260820170000'),
('20260818191652'),
('20260814125042'),
('20260813125653'),
('20260813125650'),
('20260813125648'),
('20260813125637'),
('20260809212959'),
('20251218120533'),
('20251216121418'),
('20251212114252'),
('20251212114139');

