SET local check_function_bodies = off;
CREATE EXTENSION "pg_cron";
CREATE EXTENSION "pg_net" SCHEMA "extensions";
CREATE EXTENSION "postgis" SCHEMA "public";
CREATE TABLE "public"."cpi_core" (
  "date"     date NOT NULL,
  "division" text NOT NULL,
  "index"    real NOT NULL,
  CONSTRAINT "cpi_core_pkey" PRIMARY KEY (date, division, INDEX)
);
ALTER TABLE "public"."cpi_core"
  ENABLE ROW LEVEL SECURITY;
CREATE TABLE "public"."cpi_state" (
  "state"    text NOT NULL,
  "date"     date NOT NULL,
  "division" text NOT NULL,
  "index"    real NOT NULL,
  CONSTRAINT "cpi_state_pkey" PRIMARY KEY (state, date, division)
);
ALTER TABLE "public"."cpi_state"
  ENABLE ROW LEVEL SECURITY;
CREATE TABLE "public"."crime_stats" (
  "date"     date    NOT NULL,
  "state"    text    NOT NULL,
  "district" text    NOT NULL,
  "category" text    NOT NULL,
  "type"     text    NOT NULL,
  "crimes"   integer NOT NULL,
  CONSTRAINT "crime_stats_pkey" PRIMARY KEY (date, state, district, category, TYPE)
);
ALTER TABLE "public"."crime_stats"
  ENABLE ROW LEVEL SECURITY;
CREATE TABLE "public"."crowdsourced_hazards" (
  "id"          uuid                        NOT NULL DEFAULT gen_random_uuid(),
  "user_id"     uuid,
  "hazard_type" text                        NOT NULL,
  "title"       text,
  "description" text,
  "district"    text,
  "location"    public.geometry(Point,4326) NOT NULL,
  "status"      text                        DEFAULT 'pending'::text,
  "report_time" timestamp with time zone    DEFAULT now(),
  CONSTRAINT "crowdsourced_hazards_pkey" PRIMARY KEY (id),
  CONSTRAINT "crowdsourced_hazards_status_check" CHECK ((status = ANY (ARRAY['pending'::text, 'verified'::text, 'resolved'::text, 'rejected'::text])))
);
ALTER TABLE "public"."crowdsourced_hazards"
  ENABLE ROW LEVEL SECURITY;
CREATE TABLE "public"."district_population" (
  "date"       date    NOT NULL,
  "state"      text    NOT NULL,
  "district"   text    NOT NULL,
  "population" integer NOT NULL,
  CONSTRAINT "district_population_pkey" PRIMARY KEY (date, state, district)
);
ALTER TABLE "public"."district_population"
  ENABLE ROW LEVEL SECURITY;
CREATE TABLE "public"."enrolment_school_district" (
  "date"     date   NOT NULL,
  "state"    text   NOT NULL,
  "district" text   NOT NULL,
  "stage"    text   NOT NULL,
  "sex"      text   NOT NULL,
  "students" bigint NOT NULL,
  CONSTRAINT "enrolment_school_district_pkey" PRIMARY KEY (date, state, district, stage, sex)
);
ALTER TABLE "public"."enrolment_school_district"
  ENABLE ROW LEVEL SECURITY;
CREATE TABLE "public"."gdp_gni_annual_real" (
  "series"     text             NOT NULL,
  "date"       date             NOT NULL,
  "gdp"        double precision NOT NULL,
  "gni"        double precision NOT NULL,
  "gdp_capita" double precision NOT NULL,
  "gni_capita" double precision NOT NULL,
  CONSTRAINT "gdp_gni_annual_real_pkey" PRIMARY KEY (series, date)
);
ALTER TABLE "public"."gdp_gni_annual_real"
  ENABLE ROW LEVEL SECURITY;
CREATE TABLE "public"."hh_access_amenities" (
  "state"       text NOT NULL,
  "district"    text NOT NULL,
  "date"        date NOT NULL,
  "piped_water" real NOT NULL,
  "sanitation"  real NOT NULL,
  "electricity" real NOT NULL,
  CONSTRAINT "hh_access_amenities_pkey" PRIMARY KEY (state, district, date)
);
ALTER TABLE "public"."hh_access_amenities"
  ENABLE ROW LEVEL SECURITY;
CREATE TABLE "public"."hh_income_district" (
  "state"         text    NOT NULL,
  "district"      text    NOT NULL,
  "date"          date    NOT NULL,
  "income_mean"   integer NOT NULL,
  "income_median" integer NOT NULL,
  CONSTRAINT "hh_income_district_pkey" PRIMARY KEY (state, district, date)
);
ALTER TABLE "public"."hh_income_district"
  ENABLE ROW LEVEL SECURITY;
CREATE TABLE "public"."hh_income" (
  "date"          date    NOT NULL,
  "income_mean"   integer NOT NULL,
  "income_median" integer NOT NULL,
  CONSTRAINT "hh_income_pkey" PRIMARY KEY (date)
);
ALTER TABLE "public"."hh_income"
  ENABLE ROW LEVEL SECURITY;
CREATE TABLE "public"."hh_inequality_district" (
  "state"    text NOT NULL,
  "district" text NOT NULL,
  "date"     date NOT NULL,
  "gini"     real NOT NULL,
  CONSTRAINT "hh_inequality_district_pkey" PRIMARY KEY (state, district, date)
);
ALTER TABLE "public"."hh_inequality_district"
  ENABLE ROW LEVEL SECURITY;
CREATE TABLE "public"."hh_inequality" (
  "date" date NOT NULL,
  "gini" real NOT NULL,
  CONSTRAINT "hh_inequality_pkey" PRIMARY KEY (date)
);
ALTER TABLE "public"."hh_inequality"
  ENABLE ROW LEVEL SECURITY;
CREATE TABLE "public"."hies_malaysia_percentile" (
  "date"       date     NOT NULL,
  "percentile" smallint NOT NULL,
  "variable"   text     NOT NULL,
  "income"     integer  NOT NULL,
  CONSTRAINT "hies_malaysia_percentile_pkey" PRIMARY KEY (date, percentile, variable)
);
ALTER TABLE "public"."hies_malaysia_percentile"
  ENABLE ROW LEVEL SECURITY;
CREATE TABLE "public"."hies_state" (
  "date"             date    NOT NULL,
  "state"            text    NOT NULL,
  "income_mean"      integer NOT NULL,
  "income_median"    integer NOT NULL,
  "expenditure_mean" integer NOT NULL,
  "gini"             real    NOT NULL,
  "poverty"          real    NOT NULL,
  CONSTRAINT "hies_state_pkey" PRIMARY KEY (date, state)
);
ALTER TABLE "public"."hies_state"
  ENABLE ROW LEVEL SECURITY;
CREATE TABLE "public"."hospital_beds" (
  "date"     date    NOT NULL,
  "state"    text    NOT NULL,
  "district" text    NOT NULL,
  "type"     text    NOT NULL,
  "beds"     integer NOT NULL,
  CONSTRAINT "hospital_beds_pkey" PRIMARY KEY (date, state, district, TYPE)
);
ALTER TABLE "public"."hospital_beds"
  ENABLE ROW LEVEL SECURITY;
CREATE TABLE "public"."lfs_month" (
  "date"          date NOT NULL,
  "lf"            real NOT NULL,
  "lf_employed"   real NOT NULL,
  "lf_unemployed" real NOT NULL,
  "lf_outside"    real NOT NULL,
  "u_rate"        real NOT NULL,
  "p_rate"        real NOT NULL,
  "ep_ratio"      real NOT NULL,
  CONSTRAINT "lfs_month_pkey" PRIMARY KEY (date)
);
ALTER TABLE "public"."lfs_month"
  ENABLE ROW LEVEL SECURITY;
CREATE TABLE "public"."lookup_item" (
  "item_code"     smallint GENERATED BY DEFAULT AS IDENTITY NOT NULL,
  "item"          text     NOT NULL,
  "unit"          text     NOT NULL,
  "item_group"    text     NOT NULL,
  "item_category" text     NOT NULL,
  CONSTRAINT "lookup_item_pkey" PRIMARY KEY (item_code)
);
ALTER TABLE "public"."lookup_item"
  ENABLE ROW LEVEL SECURITY;
CREATE TABLE "public"."lookup_premise" (
  "premise_code" smallint GENERATED BY DEFAULT AS IDENTITY NOT NULL,
  "premise"      text     NOT NULL,
  "address"      text     NOT NULL,
  "premise_type" text     NOT NULL,
  "state"        text     NOT NULL,
  "district"     text     NOT NULL,
  CONSTRAINT "lookup_premise_pkey" PRIMARY KEY (premise_code)
);
ALTER TABLE "public"."lookup_premise"
  ENABLE ROW LEVEL SECURITY;
CREATE TABLE "public"."police_districts_boundary" (
  "id"            text                               NOT NULL,
  "name"          text                               NOT NULL,
  "state"         text                               NOT NULL,
  "boundary_geom" public.geometry(MultiPolygon,4326),
  CONSTRAINT "police_districts_boundary_pkey" PRIMARY KEY (id)
);
ALTER TABLE "public"."police_districts_boundary"
  ENABLE ROW LEVEL SECURITY;
CREATE TABLE "public"."price_catcher" (
  "date"         date     NOT NULL,
  "premise_code" smallint NOT NULL,
  "item_code"    smallint NOT NULL,
  "price"        real     NOT NULL,
  CONSTRAINT "price_catcher_pkey" PRIMARY KEY (date, premise_code, item_code)
);
ALTER TABLE "public"."price_catcher"
  ENABLE ROW LEVEL SECURITY;
CREATE TABLE "public"."profiles" (
  "id"         uuid                     NOT NULL,
  "username"   text,
  "avatar_url" text,
  "bio"        text,
  "updated_at" timestamp with time zone DEFAULT now(),
  CONSTRAINT "profiles_pkey" PRIMARY KEY (id),
  CONSTRAINT "profiles_username_allowed_chars_chk" CHECK (((username ~ '^[A-Za-z0-9 ]+$'::text) AND (btrim(username) <> ''::text))),
  CONSTRAINT "profiles_username_key" UNIQUE (username),
  CONSTRAINT "profiles_username_min_alnum_chk" CHECK ((length(regexp_replace(username, '[^A-Za-z0-9]'::text, ''::text, 'g'::text)) >= 3)),
  CONSTRAINT "username_length" CHECK ((char_length(username) >= 3))
);
ALTER TABLE "public"."profiles"
  ENABLE ROW LEVEL SECURITY;
CREATE TABLE "public"."teachers_district" (
  "date"     date   NOT NULL,
  "state"    text   NOT NULL,
  "district" text   NOT NULL,
  "stage"    text   NOT NULL,
  "sex"      text   NOT NULL,
  "teachers" bigint NOT NULL,
  CONSTRAINT "teachers_district_pkey" PRIMARY KEY (date, state, district, stage, sex)
);
ALTER TABLE "public"."teachers_district"
  ENABLE ROW LEVEL SECURITY;
CREATE TABLE "public"."transit_stops" (
  "stop_id"      text                        NOT NULL,
  "stop_name"    text                        NOT NULL,
  "transit_type" text                        NOT NULL,
  "latitude"     double precision            NOT NULL,
  "longitude"    double precision            NOT NULL,
  "geom"         public.geometry(Point,4326),
  CONSTRAINT "transit_stops_pkey" PRIMARY KEY (stop_id)
);
ALTER TABLE "public"."transit_stops"
  ENABLE ROW LEVEL SECURITY;
CREATE TABLE "public"."user_budget_scenarios" (
  "id"                  uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "user_id"             uuid                     NOT NULL,
  "scenario_name"       text                     NOT NULL,
  "max_rent"            numeric(12,2)            DEFAULT 0,
  "living_expenses"     numeric(12,2)            DEFAULT 0,
  "transport_allowance" numeric(12,2)            DEFAULT 0,
  "created_at"          timestamp with time zone DEFAULT now(),
  "updated_at"          timestamp with time zone DEFAULT now(),
  CONSTRAINT "user_budget_scenarios_pkey" PRIMARY KEY (id)
);
ALTER TABLE "public"."user_budget_scenarios"
  ENABLE ROW LEVEL SECURITY;
CREATE TABLE "public"."user_ici_preferences" (
  "user_id"          uuid                     NOT NULL,
  "weight_safety"    numeric(3,2)             DEFAULT 0.2,
  "weight_transit"   numeric(3,2)             DEFAULT 0.2,
  "weight_education" numeric(3,2)             DEFAULT 0.2,
  "weight_health"    numeric(3,2)             DEFAULT 0.2,
  "weight_amenity"   numeric(3,2)             DEFAULT 0.2,
  "updated_at"       timestamp with time zone DEFAULT now(),
  CONSTRAINT "user_ici_preferences_pkey" PRIMARY KEY (user_id)
);
ALTER TABLE "public"."user_ici_preferences"
  ENABLE ROW LEVEL SECURITY;
CREATE TABLE "public"."user_property_inspections" (
  "id"              uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "user_id"         uuid                     NOT NULL,
  "property_name"   text                     NOT NULL,
  "address"         text,
  "rating"          integer,
  "inspection_data" jsonb                    DEFAULT '{}'::jsonb,
  "image_urls"      text[]                   DEFAULT '{}'::text[],
  "created_at"      timestamp with time zone DEFAULT now(),
  CONSTRAINT "user_property_inspections_pkey" PRIMARY KEY (id),
  CONSTRAINT "user_property_inspections_rating_check" CHECK (((rating >= 1) AND (rating <= 5)))
);
ALTER TABLE "public"."user_property_inspections"
  ENABLE ROW LEVEL SECURITY;
CREATE TABLE "public"."user_saved_regions" (
  "id"          uuid                     NOT NULL DEFAULT gen_random_uuid(),
  "user_id"     uuid                     NOT NULL,
  "district_id" text                     NOT NULL,
  "alias"       text,
  "created_at"  timestamp with time zone DEFAULT now(),
  CONSTRAINT "user_saved_regions_pkey" PRIMARY KEY (id),
  CONSTRAINT "user_saved_regions_user_id_district_id_key" UNIQUE (user_id, district_id)
);
ALTER TABLE "public"."user_saved_regions"
  ENABLE ROW LEVEL SECURITY;
CREATE TYPE "public"."ingestion_status" AS ENUM (
  'pending',
  'running',
  'success',
  'failed',
  'cancelled'
);
CREATE OR REPLACE FUNCTION public.get_district_income_rank (
  district_name text
)
  RETURNS TABLE (
    rank  bigint,
    total bigint
  )
  LANGUAGE sql
  STABLE
  SET search_path TO 'public', 'extensions'
  AS $function$
    WITH ranked_districts AS (
        SELECT h.district,
               RANK() OVER (ORDER BY h.income_median DESC) AS district_rank,
               COUNT(*) OVER () AS district_total
        FROM public.hh_income_district AS h
    )
    SELECT rd.district_rank, rd.district_total
    FROM ranked_districts AS rd
    WHERE rd.district = district_name;
$function$;
CREATE OR REPLACE FUNCTION public.get_district_prices (
  district_name text
)
  RETURNS TABLE (
    item_name text,
    price     real
  )
  LANGUAGE sql
  STABLE
  SET search_path TO 'public', 'extensions'
  AS $function$
    SELECT li.item AS item_name, AVG(pc.price)::real AS price
    FROM public.price_catcher AS pc
    JOIN public.lookup_premise AS lp
      ON pc.premise_code = lp.premise_code
    JOIN public.lookup_item AS li
      ON pc.item_code = li.item_code
    WHERE lp.district = district_name
    GROUP BY li.item
    ORDER BY li.item;
$function$;
CREATE OR REPLACE FUNCTION public.get_transit_density (
  district_name text
)
  RETURNS double precision
  LANGUAGE sql
  STABLE
  SET search_path TO 'public', 'extensions'
  AS $function$
    SELECT LEAST(COUNT(ts.stop_id)::float8, 100.0)
    FROM public.transit_stops AS ts
    WHERE ts.geom IS NOT NULL
      AND ST_Contains(
          (
              SELECT ST_Union(pdb.boundary_geom)
              FROM public.police_districts_boundary AS pdb
              WHERE pdb.name = district_name
                AND pdb.boundary_geom IS NOT NULL
          ),
          ts.geom
      );
$function$;
CREATE OR REPLACE FUNCTION public.match_police_district (
  lat double precision,
  lng double precision
)
  RETURNS TABLE (
    id    text,
    name  text,
    state text
  )
  LANGUAGE sql
  STABLE
  SET search_path TO 'public', 'extensions'
  AS $function$
    SELECT p.id, p.name, p.state
    FROM public.police_districts_boundary AS p
    WHERE p.boundary_geom IS NOT NULL
      AND ST_Covers(
          p.boundary_geom,
          ST_SetSRID(ST_MakePoint(lng, lat), 4326)
      )
    LIMIT 1;
$function$;
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
  RETURNS TRIGGER
  LANGUAGE plpgsql
  SET search_path TO 'public'
  AS $function$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$;
ALTER TABLE "public"."profiles"
  ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE "public"."crowdsourced_hazards"
  ADD CONSTRAINT "crowdsourced_hazards_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE SET NULL;
ALTER TABLE "public"."user_budget_scenarios"
  ADD CONSTRAINT "user_budget_scenarios_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE "public"."user_ici_preferences"
  ADD CONSTRAINT "user_ici_preferences_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE "public"."user_property_inspections"
  ADD CONSTRAINT "user_property_inspections_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE "public"."user_saved_regions"
  ADD CONSTRAINT "user_saved_regions_user_id_fkey" FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
CREATE INDEX idx_hazards_location ON public.crowdsourced_hazards USING gist (location);
CREATE INDEX idx_police_boundary_geom ON public.police_districts_boundary USING gist (boundary_geom);
CREATE INDEX idx_transit_stops_geom ON public.transit_stops USING gist (geom);
CREATE POLICY "authenticated_select" ON "public"."cpi_core"
  FOR SELECT
  TO "authenticated"
  USING (true);
CREATE POLICY "authenticated_select" ON "public"."cpi_state"
  FOR SELECT
  TO "authenticated"
  USING (true);
CREATE POLICY "authenticated_select" ON "public"."crime_stats"
  FOR SELECT
  TO "authenticated"
  USING (true);
CREATE POLICY "crowdsourced_hazards_delete_own" ON "public"."crowdsourced_hazards"
  FOR DELETE
  TO "authenticated"
  USING ((( SELECT auth.uid() AS uid) = user_id));
CREATE POLICY "crowdsourced_hazards_insert_own" ON "public"."crowdsourced_hazards"
  FOR INSERT
  TO "authenticated"
  WITH CHECK ((( SELECT auth.uid() AS uid) = user_id));
CREATE POLICY "crowdsourced_hazards_select_own" ON "public"."crowdsourced_hazards"
  FOR SELECT
  TO "authenticated"
  USING ((( SELECT auth.uid() AS uid) = user_id));
CREATE POLICY "crowdsourced_hazards_update_own" ON "public"."crowdsourced_hazards"
  FOR UPDATE
  TO "authenticated"
  USING ((( SELECT auth.uid() AS uid) = user_id))
  WITH CHECK ((( SELECT auth.uid() AS uid) = user_id));
CREATE POLICY "authenticated_select" ON "public"."district_population"
  FOR SELECT
  TO "authenticated"
  USING (true);
CREATE POLICY "authenticated_select" ON "public"."enrolment_school_district"
  FOR SELECT
  TO "authenticated"
  USING (true);
CREATE POLICY "authenticated_read_gdp_gni_annual_real" ON "public"."gdp_gni_annual_real"
  FOR SELECT
  TO "authenticated"
  USING (true);
CREATE POLICY "authenticated_select" ON "public"."hh_access_amenities"
  FOR SELECT
  TO "authenticated"
  USING (true);
CREATE POLICY "authenticated_select" ON "public"."hh_income"
  FOR SELECT
  TO "authenticated"
  USING (true);
CREATE POLICY "authenticated_select" ON "public"."hh_income_district"
  FOR SELECT
  TO "authenticated"
  USING (true);
CREATE POLICY "authenticated_select" ON "public"."hh_inequality"
  FOR SELECT
  TO "authenticated"
  USING (true);
CREATE POLICY "authenticated_select" ON "public"."hh_inequality_district"
  FOR SELECT
  TO "authenticated"
  USING (true);
CREATE POLICY "authenticated_select" ON "public"."hies_malaysia_percentile"
  FOR SELECT
  TO "authenticated"
  USING (true);
CREATE POLICY "authenticated_select" ON "public"."hies_state"
  FOR SELECT
  TO "authenticated"
  USING (true);
CREATE POLICY "authenticated_select" ON "public"."hospital_beds"
  FOR SELECT
  TO "authenticated"
  USING (true);
CREATE POLICY "authenticated_read_lfs_month" ON "public"."lfs_month"
  FOR SELECT
  TO "authenticated"
  USING (true);
CREATE POLICY "authenticated_select" ON "public"."lookup_item"
  FOR SELECT
  TO "authenticated"
  USING (true);
CREATE POLICY "authenticated_select" ON "public"."lookup_premise"
  FOR SELECT
  TO "authenticated"
  USING (true);
CREATE POLICY "authenticated_select" ON "public"."police_districts_boundary"
  FOR SELECT
  TO "authenticated"
  USING (true);
CREATE POLICY "authenticated_select" ON "public"."price_catcher"
  FOR SELECT
  TO "authenticated"
  USING (true);
CREATE POLICY "Users can insert their own profile" ON "public"."profiles"
  FOR INSERT
  TO PUBLIC
  WITH CHECK ((auth.uid() = id));
CREATE POLICY "Users can update their own profile" ON "public"."profiles"
  FOR UPDATE
  TO PUBLIC
  USING ((auth.uid() = id));
CREATE POLICY "profiles_delete_own" ON "public"."profiles"
  FOR DELETE
  TO "authenticated"
  USING ((( SELECT auth.uid() AS uid) = id));
CREATE POLICY "profiles_insert_own" ON "public"."profiles"
  FOR INSERT
  TO "authenticated"
  WITH CHECK ((( SELECT auth.uid() AS uid) = id));
CREATE POLICY "profiles_select_own" ON "public"."profiles"
  FOR SELECT
  TO "authenticated"
  USING ((( SELECT auth.uid() AS uid) = id));
CREATE POLICY "profiles_update_own" ON "public"."profiles"
  FOR UPDATE
  TO "authenticated"
  USING ((( SELECT auth.uid() AS uid) = id))
  WITH CHECK ((( SELECT auth.uid() AS uid) = id));
CREATE POLICY "authenticated_select" ON "public"."teachers_district"
  FOR SELECT
  TO "authenticated"
  USING (true);
CREATE POLICY "authenticated_select" ON "public"."transit_stops"
  FOR SELECT
  TO "authenticated"
  USING (true);
CREATE POLICY "Users can manage their own scenarios" ON "public"."user_budget_scenarios"
  FOR ALL
  TO PUBLIC
  USING ((auth.uid() = user_id));
CREATE POLICY "user_budget_scenarios_delete_own" ON "public"."user_budget_scenarios"
  FOR DELETE
  TO "authenticated"
  USING ((( SELECT auth.uid() AS uid) = user_id));
CREATE POLICY "user_budget_scenarios_insert_own" ON "public"."user_budget_scenarios"
  FOR INSERT
  TO "authenticated"
  WITH CHECK ((( SELECT auth.uid() AS uid) = user_id));
CREATE POLICY "user_budget_scenarios_select_own" ON "public"."user_budget_scenarios"
  FOR SELECT
  TO "authenticated"
  USING ((( SELECT auth.uid() AS uid) = user_id));
CREATE POLICY "user_budget_scenarios_update_own" ON "public"."user_budget_scenarios"
  FOR UPDATE
  TO "authenticated"
  USING ((( SELECT auth.uid() AS uid) = user_id))
  WITH CHECK ((( SELECT auth.uid() AS uid) = user_id));
CREATE POLICY "Users can manage their own preferences" ON "public"."user_ici_preferences"
  FOR ALL
  TO PUBLIC
  USING ((auth.uid() = user_id));
CREATE POLICY "user_ici_preferences_delete_own" ON "public"."user_ici_preferences"
  FOR DELETE
  TO "authenticated"
  USING ((( SELECT auth.uid() AS uid) = user_id));
CREATE POLICY "user_ici_preferences_insert_own" ON "public"."user_ici_preferences"
  FOR INSERT
  TO "authenticated"
  WITH CHECK ((( SELECT auth.uid() AS uid) = user_id));
CREATE POLICY "user_ici_preferences_select_own" ON "public"."user_ici_preferences"
  FOR SELECT
  TO "authenticated"
  USING ((( SELECT auth.uid() AS uid) = user_id));
CREATE POLICY "user_ici_preferences_update_own" ON "public"."user_ici_preferences"
  FOR UPDATE
  TO "authenticated"
  USING ((( SELECT auth.uid() AS uid) = user_id))
  WITH CHECK ((( SELECT auth.uid() AS uid) = user_id));
CREATE POLICY "Users can manage their own inspections" ON "public"."user_property_inspections"
  FOR ALL
  TO PUBLIC
  USING ((auth.uid() = user_id));
CREATE POLICY "user_property_inspections_delete_own" ON "public"."user_property_inspections"
  FOR DELETE
  TO "authenticated"
  USING ((( SELECT auth.uid() AS uid) = user_id));
CREATE POLICY "user_property_inspections_insert_own" ON "public"."user_property_inspections"
  FOR INSERT
  TO "authenticated"
  WITH CHECK ((( SELECT auth.uid() AS uid) = user_id));
CREATE POLICY "user_property_inspections_select_own" ON "public"."user_property_inspections"
  FOR SELECT
  TO "authenticated"
  USING ((( SELECT auth.uid() AS uid) = user_id));
CREATE POLICY "user_property_inspections_update_own" ON "public"."user_property_inspections"
  FOR UPDATE
  TO "authenticated"
  USING ((( SELECT auth.uid() AS uid) = user_id))
  WITH CHECK ((( SELECT auth.uid() AS uid) = user_id));
CREATE POLICY "Users can manage their own saved regions" ON "public"."user_saved_regions"
  FOR ALL
  TO PUBLIC
  USING ((auth.uid() = user_id));
CREATE POLICY "user_saved_regions_delete_own" ON "public"."user_saved_regions"
  FOR DELETE
  TO "authenticated"
  USING ((( SELECT auth.uid() AS uid) = user_id));
CREATE POLICY "user_saved_regions_insert_own" ON "public"."user_saved_regions"
  FOR INSERT
  TO "authenticated"
  WITH CHECK ((( SELECT auth.uid() AS uid) = user_id));
CREATE POLICY "user_saved_regions_select_own" ON "public"."user_saved_regions"
  FOR SELECT
  TO "authenticated"
  USING ((( SELECT auth.uid() AS uid) = user_id));
CREATE POLICY "user_saved_regions_update_own" ON "public"."user_saved_regions"
  FOR UPDATE
  TO "authenticated"
  USING ((( SELECT auth.uid() AS uid) = user_id))
  WITH CHECK ((( SELECT auth.uid() AS uid) = user_id));
COMMENT ON EXTENSION "pg_cron" IS 'Job scheduler for PostgreSQL';
COMMENT ON EXTENSION "pg_net" IS 'Async HTTP';
COMMENT ON EXTENSION "postgis" IS 'PostGIS geometry and geography spatial types and functions';
COMMENT ON TABLE "public"."cpi_core" IS '核心消费物价指数 (Core CPI)';
COMMENT ON TABLE "public"."cpi_state" IS '州级消费物价指数 (CPI by State)';
COMMENT ON TABLE "public"."enrolment_school_district" IS '学校在校生人数 (School enrolment)';
COMMENT ON TABLE "public"."gdp_gni_annual_real" IS 'Long time series of annual real gross domestic product (GDP) and gross national income (GNI), including per capita values.';
COMMENT ON TABLE "public"."hh_access_amenities" IS '基础设施普及率 (Water, Electricity, Sanitation)';
COMMENT ON TABLE "public"."hh_income" IS 'Mean and median monthly gross household income in Malaysia';
COMMENT ON TABLE "public"."hh_income_district" IS '县级家庭中位数收入与基尼系数 (Household income)';
COMMENT ON TABLE "public"."hh_inequality" IS 'Gini coefficient for Malaysia';
COMMENT ON TABLE "public"."hh_inequality_district" IS 'Inequality by District';
COMMENT ON TABLE "public"."hies_malaysia_percentile" IS 'Percentile-resolution household income data at national level.';
COMMENT ON TABLE "public"."hies_state" IS 'household-level income, expenditure, poverty, and income inequality at state level. It is based on the Household Income & Expenditure Surveys (HIES)';
COMMENT ON TABLE "public"."hospital_beds" IS '医疗床位数据 (Healthcare capacity)';
COMMENT ON TABLE "public"."lfs_month" IS 'Monthly principal labour force statistics, including unemployment and participation rates.';
COMMENT ON TABLE "public"."lookup_item" IS '商品信息查找表 (Item lookup table)';
COMMENT ON TABLE "public"."lookup_premise" IS '零售场所查找表 (Premise lookup table)';
COMMENT ON TABLE "public"."price_catcher" IS '每日微观物价数据 (Daily price data)';
COMMENT ON TABLE "public"."teachers_district" IS '教师人数统计 (Teachers stats)';
GRANT EXECUTE ON FUNCTION "public"."get_district_income_rank"(text) TO PUBLIC, "anon", "authenticated", "postgres", "service_role";
GRANT EXECUTE ON FUNCTION "public"."get_district_prices"(text) TO PUBLIC, "anon", "authenticated", "postgres", "service_role";
GRANT EXECUTE ON FUNCTION "public"."get_transit_density"(text) TO PUBLIC, "anon", "authenticated", "postgres", "service_role";
GRANT EXECUTE ON FUNCTION "public"."match_police_district"(double precision, double precision) TO PUBLIC, "anon", "authenticated", "postgres", "service_role";
GRANT EXECUTE ON FUNCTION "public"."update_updated_at_column"() TO PUBLIC, "anon", "authenticated", "postgres", "service_role";
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."cpi_core" TO "anon", "authenticated", "postgres", "service_role";
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."cpi_state" TO "anon", "authenticated", "postgres", "service_role";
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."crime_stats" TO "anon", "authenticated", "postgres", "service_role";
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."crowdsourced_hazards" TO "anon", "authenticated", "postgres", "service_role";
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."district_population" TO "anon", "authenticated", "postgres", "service_role";
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."enrolment_school_district" TO "anon", "authenticated", "postgres", "service_role";
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."gdp_gni_annual_real" TO "anon", "authenticated", "postgres", "service_role";
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."hh_access_amenities" TO "anon", "authenticated", "postgres", "service_role";
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."hh_income" TO "anon", "authenticated", "postgres", "service_role";
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."hh_income_district" TO "anon", "authenticated", "postgres", "service_role";
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."hh_inequality" TO "anon", "authenticated", "postgres", "service_role";
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."hh_inequality_district" TO "anon", "authenticated", "postgres", "service_role";
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."hies_malaysia_percentile" TO "anon", "authenticated", "postgres", "service_role";
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."hies_state" TO "anon", "authenticated", "postgres", "service_role";
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."hospital_beds" TO "anon", "authenticated", "postgres", "service_role";
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."lfs_month" TO "anon", "authenticated", "postgres", "service_role";
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."lookup_item" TO "anon", "authenticated", "postgres", "service_role";
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."lookup_premise" TO "anon", "authenticated", "postgres", "service_role";
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."police_districts_boundary" TO "anon", "authenticated", "postgres", "service_role";
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."price_catcher" TO "anon", "authenticated", "postgres", "service_role";
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."profiles" TO "anon", "authenticated", "postgres", "service_role";
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."teachers_district" TO "anon", "authenticated", "postgres", "service_role";
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."transit_stops" TO "anon", "authenticated", "postgres", "service_role";
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."user_budget_scenarios" TO "anon", "authenticated", "postgres", "service_role";
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."user_ici_preferences" TO "anon", "authenticated", "postgres", "service_role";
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."user_property_inspections" TO "anon", "authenticated", "postgres", "service_role";
GRANT DELETE, INSERT, MAINTAIN, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE ON TABLE "public"."user_saved_regions" TO "anon", "authenticated", "postgres", "service_role";
GRANT USAGE ON TYPE "public"."ingestion_status" TO "postgres";
SELECT cron.schedule_in_database('official-data-sync-dispatch', '30 seconds', '
  select net.http_post(
    url := (
      select decrypted_secret
      from vault.decrypted_secrets
      where name = ''project_url''
    ) || ''/functions/v1/official-data-sync'',
    headers := jsonb_build_object(
      ''Content-Type'', ''application/json'',
      ''Authorization'', ''Bearer '' || (
        select decrypted_secret
        from vault.decrypted_secrets
        where name = ''publishable_key''
      ),
      ''apikey'', (
        select decrypted_secret
        from vault.decrypted_secrets
        where name = ''publishable_key''
      )
    ),
    body := jsonb_build_object(''triggered_at'', now()),
    timeout_milliseconds := 10000
  );
  ', 'postgres', NULL, true);
