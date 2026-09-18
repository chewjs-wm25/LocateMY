## 一、Public 业务表

### `public.price_catcher`

```sql
CREATE TABLE public.price_catcher (
  date date NOT NULL,
  premise_code smallint NOT NULL,
  item_code smallint NOT NULL,
  price real NOT NULL,
  CONSTRAINT price_catcher_pkey
    PRIMARY KEY (date, premise_code, item_code)
);
```

RLS：

```text
RLS: ENABLED

authenticated_select
  Command: SELECT
  Role: authenticated
  USING: true
```

---

### `public.lookup_item`

```sql
CREATE TABLE public.lookup_item (
  item_code smallint NOT NULL,
  item text NOT NULL,
  unit text NOT NULL,
  item_group text NOT NULL,
  item_category text NOT NULL,
  CONSTRAINT lookup_item_pkey
    PRIMARY KEY (item_code)
);
```

RLS：

```text
RLS: ENABLED

authenticated_select
  Command: SELECT
  Role: authenticated
  USING: true
```

---

### `public.lookup_premise`

```sql
CREATE TABLE public.lookup_premise (
  premise_code smallint NOT NULL,
  premise text NOT NULL,
  address text NOT NULL,
  premise_type text NOT NULL,
  state text NOT NULL,
  district text NOT NULL,
  CONSTRAINT lookup_premise_pkey
    PRIMARY KEY (premise_code)
);
```

RLS：

```text
RLS: ENABLED

authenticated_select
  Command: SELECT
  Role: authenticated
  USING: true
```

---

### `public.cpi_state`

```sql
CREATE TABLE public.cpi_state (
  state text NOT NULL,
  date date NOT NULL,
  division text NOT NULL,
  index real NOT NULL,
  CONSTRAINT cpi_state_pkey
    PRIMARY KEY (state, date, division)
);
```

RLS：

```text
RLS: ENABLED

authenticated_select
  Command: SELECT
  Role: authenticated
  USING: true
```

---

### `public.cpi_core`

```sql
CREATE TABLE public.cpi_core (
  date date NOT NULL,
  division text NOT NULL,
  index real NOT NULL,
  CONSTRAINT cpi_core_pkey
    PRIMARY KEY (date, division, index)
);
```

RLS：

```text
RLS: ENABLED

authenticated_select
  Command: SELECT
  Role: authenticated
  USING: true
```

---

### `public.crime_stats`

```sql
CREATE TABLE public.crime_stats (
  date date NOT NULL,
  state text NOT NULL,
  district text NOT NULL,
  category text NOT NULL,
  type text NOT NULL,
  crimes integer NOT NULL,
  CONSTRAINT crime_stats_pkey
    PRIMARY KEY (date, state, district, category, type)
);
```

RLS：

```text
RLS: ENABLED

authenticated_select
  Command: SELECT
  Role: authenticated
  USING: true
```

---

### `public.hh_income_district`

```sql
CREATE TABLE public.hh_income_district (
  state text NOT NULL,
  district text NOT NULL,
  date date NOT NULL,
  income_mean integer NOT NULL,
  income_median integer NOT NULL,
  CONSTRAINT hh_income_district_pkey
    PRIMARY KEY (state, district, date)
);
```

RLS：

```text
RLS: ENABLED

authenticated_select
  Command: SELECT
  Role: authenticated
  USING: true
```

---

### `public.hh_access_amenities`

```sql
CREATE TABLE public.hh_access_amenities (
  state text NOT NULL,
  district text NOT NULL,
  date date NOT NULL,
  piped_water real NOT NULL,
  sanitation real NOT NULL,
  electricity real NOT NULL,
  CONSTRAINT hh_access_amenities_pkey
    PRIMARY KEY (state, district, date)
);
```

RLS：

```text
RLS: ENABLED

authenticated_select
  Command: SELECT
  Role: authenticated
  USING: true
```

---

### `public.hospital_beds`

```sql
CREATE TABLE public.hospital_beds (
  date date NOT NULL,
  state text NOT NULL,
  district text NOT NULL,
  type text NOT NULL,
  beds integer NOT NULL,
  CONSTRAINT hospital_beds_pkey
    PRIMARY KEY (date, state, district, type)
);
```

RLS：

```text
RLS: ENABLED

authenticated_select
  Command: SELECT
  Role: authenticated
  USING: true
```

---

### `public.enrolment_school_district`

```sql
CREATE TABLE public.enrolment_school_district (
  date date NOT NULL,
  state text NOT NULL,
  district text NOT NULL,
  stage text NOT NULL,
  sex text NOT NULL,
  students bigint NOT NULL,
  CONSTRAINT enrolment_school_district_pkey
    PRIMARY KEY (date, state, district, stage, sex)
);
```

RLS：

```text
RLS: ENABLED

authenticated_select
  Command: SELECT
  Role: authenticated
  USING: true
```

---

### `public.teachers_district`

```sql
CREATE TABLE public.teachers_district (
  date date NOT NULL,
  state text NOT NULL,
  district text NOT NULL,
  stage text NOT NULL,
  sex text NOT NULL,
  teachers bigint NOT NULL,
  CONSTRAINT teachers_district_pkey
    PRIMARY KEY (date, state, district, stage, sex)
);
```

RLS：

```text
RLS: ENABLED

authenticated_select
  Command: SELECT
  Role: authenticated
  USING: true
```

---

### `public.profiles`

```sql
CREATE TABLE public.profiles (
  id uuid NOT NULL,
  username text,
  avatar_url text,
  bio text,
  updated_at timestamptz DEFAULT now(),

  CONSTRAINT profiles_pkey
    PRIMARY KEY (id),

  CONSTRAINT profiles_id_fkey
    FOREIGN KEY (id)
    REFERENCES auth.users(id)
    ON DELETE CASCADE,

  CONSTRAINT profiles_username_key
    UNIQUE (username),

  CONSTRAINT username_length
    CHECK (char_length(username) >= 3),

  CONSTRAINT profiles_username_allowed_chars_chk
    CHECK (
      username ~ '^[A-Za-z0-9 ]+$'
      AND btrim(username) <> ''
    ),

  CONSTRAINT profiles_username_min_alnum_chk
    CHECK (
      length(
        regexp_replace(username, '[^A-Za-z0-9]', '', 'g')
      ) >= 3
    )
);
```

RLS：

```text
RLS: ENABLED

Users can insert their own profile
  Command: INSERT
  Role: public
  WITH CHECK: auth.uid() = id

Users can update their own profile
  Command: UPDATE
  Role: public
  USING: auth.uid() = id

profiles_insert_own
  Command: INSERT
  Role: authenticated
  WITH CHECK: auth.uid() = id

profiles_select_own
  Command: SELECT
  Role: authenticated
  USING: auth.uid() = id

profiles_update_own
  Command: UPDATE
  Role: authenticated
  USING: auth.uid() = id
  WITH CHECK: auth.uid() = id

profiles_delete_own
  Command: DELETE
  Role: authenticated
  USING: auth.uid() = id
```

---

### `public.user_budget_scenarios`

```sql
CREATE TABLE public.user_budget_scenarios (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  scenario_name text NOT NULL,
  max_rent numeric(12,2) DEFAULT 0,
  living_expenses numeric(12,2) DEFAULT 0,
  transport_allowance numeric(12,2) DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),

  CONSTRAINT user_budget_scenarios_pkey
    PRIMARY KEY (id),

  CONSTRAINT user_budget_scenarios_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES profiles(id)
    ON DELETE CASCADE
);
```

RLS：

```text
RLS: ENABLED

Users can manage their own scenarios
  Command: ALL
  Role: public
  USING: auth.uid() = user_id

user_budget_scenarios_insert_own
  Command: INSERT
  Role: authenticated
  WITH CHECK: auth.uid() = user_id

user_budget_scenarios_select_own
  Command: SELECT
  Role: authenticated
  USING: auth.uid() = user_id

user_budget_scenarios_update_own
  Command: UPDATE
  Role: authenticated
  USING: auth.uid() = user_id
  WITH CHECK: auth.uid() = user_id

user_budget_scenarios_delete_own
  Command: DELETE
  Role: authenticated
  USING: auth.uid() = user_id
```

---

### `public.crowdsourced_hazards`

```sql
CREATE TABLE public.crowdsourced_hazards (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  hazard_type text NOT NULL,
  title text,
  description text,
  district text,
  location geometry(Point,4326) NOT NULL,
  status text DEFAULT 'pending',
  report_time timestamptz DEFAULT now(),

  CONSTRAINT crowdsourced_hazards_pkey
    PRIMARY KEY (id),

  CONSTRAINT crowdsourced_hazards_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES profiles(id)
    ON DELETE SET NULL,

  CONSTRAINT crowdsourced_hazards_status_check
    CHECK (
      status IN ('pending', 'verified', 'resolved', 'rejected')
    )
);
```

RLS：

```text
RLS: ENABLED

crowdsourced_hazards_insert_own
  Command: INSERT
  Role: authenticated
  WITH CHECK: auth.uid() = user_id

crowdsourced_hazards_select_own
  Command: SELECT
  Role: authenticated
  USING: auth.uid() = user_id

crowdsourced_hazards_update_own
  Command: UPDATE
  Role: authenticated
  USING: auth.uid() = user_id
  WITH CHECK: auth.uid() = user_id

crowdsourced_hazards_delete_own
  Command: DELETE
  Role: authenticated
  USING: auth.uid() = user_id
```

---

### `public.user_saved_regions`

```sql
CREATE TABLE public.user_saved_regions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  district_id text NOT NULL,
  alias text,
  created_at timestamptz DEFAULT now(),

  CONSTRAINT user_saved_regions_pkey
    PRIMARY KEY (id),

  CONSTRAINT user_saved_regions_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES profiles(id)
    ON DELETE CASCADE,

  CONSTRAINT user_saved_regions_user_id_district_id_key
    UNIQUE (user_id, district_id)
);
```

RLS：

```text
RLS: ENABLED

Users can manage their own saved regions
  Command: ALL
  Role: public
  USING: auth.uid() = user_id

user_saved_regions_insert_own
  Command: INSERT
  Role: authenticated
  WITH CHECK: auth.uid() = user_id

user_saved_regions_select_own
  Command: SELECT
  Role: authenticated
  USING: auth.uid() = user_id

user_saved_regions_update_own
  Command: UPDATE
  Role: authenticated
  USING: auth.uid() = user_id
  WITH CHECK: auth.uid() = user_id

user_saved_regions_delete_own
  Command: DELETE
  Role: authenticated
  USING: auth.uid() = user_id
```

---

### `public.user_ici_preferences`

```sql
CREATE TABLE public.user_ici_preferences (
  user_id uuid NOT NULL,
  weight_safety numeric(3,2) DEFAULT 0.2,
  weight_transit numeric(3,2) DEFAULT 0.2,
  weight_education numeric(3,2) DEFAULT 0.2,
  weight_health numeric(3,2) DEFAULT 0.2,
  weight_amenity numeric(3,2) DEFAULT 0.2,
  updated_at timestamptz DEFAULT now(),

  CONSTRAINT user_ici_preferences_pkey
    PRIMARY KEY (user_id),

  CONSTRAINT user_ici_preferences_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES profiles(id)
    ON DELETE CASCADE
);
```

RLS：

```text
RLS: ENABLED

Users can manage their own preferences
  Command: ALL
  Role: public
  USING: auth.uid() = user_id

user_ici_preferences_insert_own
  Command: INSERT
  Role: authenticated
  WITH CHECK: auth.uid() = user_id

user_ici_preferences_select_own
  Command: SELECT
  Role: authenticated
  USING: auth.uid() = user_id

user_ici_preferences_update_own
  Command: UPDATE
  Role: authenticated
  USING: auth.uid() = user_id
  WITH CHECK: auth.uid() = user_id

user_ici_preferences_delete_own
  Command: DELETE
  Role: authenticated
  USING: auth.uid() = user_id
```

---

### `public.user_property_inspections`

```sql
CREATE TABLE public.user_property_inspections (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  property_name text NOT NULL,
  address text,
  rating integer,
  inspection_data jsonb DEFAULT '{}',
  image_urls text[] DEFAULT '{}',
  created_at timestamptz DEFAULT now(),

  CONSTRAINT user_property_inspections_pkey
    PRIMARY KEY (id),

  CONSTRAINT user_property_inspections_user_id_fkey
    FOREIGN KEY (user_id)
    REFERENCES profiles(id)
    ON DELETE CASCADE,

  CONSTRAINT user_property_inspections_rating_check
    CHECK (rating >= 1 AND rating <= 5)
);
```

RLS：

```text
RLS: ENABLED

Users can manage their own inspections
  Command: ALL
  Role: public
  USING: auth.uid() = user_id

user_property_inspections_insert_own
  Command: INSERT
  Role: authenticated
  WITH CHECK: auth.uid() = user_id

user_property_inspections_select_own
  Command: SELECT
  Role: authenticated
  USING: auth.uid() = user_id

user_property_inspections_update_own
  Command: UPDATE
  Role: authenticated
  USING: auth.uid() = user_id
  WITH CHECK: auth.uid() = user_id

user_property_inspections_delete_own
  Command: DELETE
  Role: authenticated
  USING: auth.uid() = user_id
```

---

### `public.transit_stops`

```sql
CREATE TABLE public.transit_stops (
  stop_id text NOT NULL,
  stop_name text NOT NULL,
  transit_type text NOT NULL,
  latitude double precision NOT NULL,
  longitude double precision NOT NULL,
  geom geometry(Point,4326),

  CONSTRAINT transit_stops_pkey
    PRIMARY KEY (stop_id)
);
```

RLS：

```text
RLS: ENABLED

authenticated_select
  Command: SELECT
  Role: authenticated
  USING: true
```

---

### `public.police_districts_boundary`

```sql
CREATE TABLE public.police_districts_boundary (
  id text NOT NULL,
  name text NOT NULL,
  state text NOT NULL,
  boundary_geom geometry(MultiPolygon,4326),

  CONSTRAINT police_districts_boundary_pkey
    PRIMARY KEY (id)
);
```

RLS：

```text
RLS: ENABLED

authenticated_select
  Command: SELECT
  Role: authenticated
  USING: true
```

---

### `public.gdp_gni_annual_real`

```sql
CREATE TABLE public.gdp_gni_annual_real (
  series text NOT NULL,
  date date NOT NULL,
  gdp double precision NOT NULL,
  gni double precision NOT NULL,
  gdp_capita double precision NOT NULL,
  gni_capita double precision NOT NULL,

  CONSTRAINT gdp_gni_annual_real_pkey
    PRIMARY KEY (series, date)
);
```

RLS：

```text
RLS: ENABLED

authenticated_read_gdp_gni_annual_real
  Command: SELECT
  Role: authenticated
  USING: true
```

---

### `public.lfs_month`

```sql
CREATE TABLE public.lfs_month (
  date date NOT NULL,
  lf real NOT NULL,
  lf_employed real NOT NULL,
  lf_unemployed real NOT NULL,
  lf_outside real NOT NULL,
  u_rate real NOT NULL,
  p_rate real NOT NULL,
  ep_ratio real NOT NULL,

  CONSTRAINT lfs_month_pkey
    PRIMARY KEY (date)
);
```

RLS：

```text
RLS: ENABLED

authenticated_read_lfs_month
  Command: SELECT
  Role: authenticated
  USING: true
```

---

### `public.hh_inequality`

```sql
CREATE TABLE public.hh_inequality (
  date date NOT NULL,
  gini real NOT NULL,

  CONSTRAINT hh_inequality_pkey
    PRIMARY KEY (date)
);
```

RLS：

```text
RLS: ENABLED

当前未发现可用 RLS Policy。
```

---

### `public.hh_inequality_district`

```sql
CREATE TABLE public.hh_inequality_district (
  state text NOT NULL,
  district text NOT NULL,
  date date NOT NULL,
  gini real NOT NULL,

  CONSTRAINT hh_inequality_district_pkey
    PRIMARY KEY (state, district, date)
);
```

RLS：

```text
RLS: ENABLED

当前未发现可用 RLS Policy。
```

---

### `public.hies_malaysia_percentile`

```sql
CREATE TABLE public.hies_malaysia_percentile (
  date date NOT NULL,
  percentile smallint NOT NULL,
  variable text NOT NULL,
  income integer NOT NULL,

  CONSTRAINT hies_malaysia_percentile_pkey
    PRIMARY KEY (date, percentile, variable)
);
```

RLS：

```text
RLS: ENABLED

当前未发现可用 RLS Policy。
```

---

### `public.hies_state`

```sql
CREATE TABLE public.hies_state (
  date date NOT NULL,
  state text NOT NULL,
  income_mean integer NOT NULL,
  income_median integer NOT NULL,
  expenditure_mean integer NOT NULL,
  gini real NOT NULL,
  poverty real NOT NULL,

  CONSTRAINT hies_state_pkey
    PRIMARY KEY (date, state)
);
```

RLS：

```text
RLS: ENABLED

当前未发现可用 RLS Policy。
```

---

### `public.hh_income`

```sql
CREATE TABLE public.hh_income (
  date date NOT NULL,
  income_mean integer NOT NULL,
  income_median integer NOT NULL,

  CONSTRAINT hh_income_pkey
    PRIMARY KEY (date)
);
```

RLS：

```text
RLS: ENABLED

当前未发现可用 RLS Policy。
```

---

## 二、Public Schema 表清单

以下表也已确认存在，并且均启用了 RLS：

```text
public.price_catcher
public.lookup_item
public.lookup_premise
public.cpi_state
public.cpi_core
public.crime_stats
public.hh_income_district
public.hh_access_amenities
public.hospital_beds
public.enrolment_school_district
public.teachers_district
public.profiles
public.user_budget_scenarios
public.crowdsourced_hazards
public.user_saved_regions
public.user_ici_preferences
public.user_property_inspections
public.transit_stops
public.police_districts_boundary
public.gdp_gni_annual_real
public.lfs_month
public.hh_inequality
public.hh_inequality_district
public.hies_malaysia_percentile
public.hies_state
public.hh_income
```

另外还存在：

```text
public.spatial_ref_sys
```

---

## 三、Supabase 系统表

### `auth`

```text
auth.users
auth.identities
auth.instances
auth.sessions
auth.refresh_tokens
auth.audit_log_entries
auth.schema_migrations
auth.mfa_factors
auth.mfa_challenges
auth.mfa_amr_claims
auth.sso_providers
auth.sso_domains
auth.saml_providers
auth.saml_relay_states
auth.flow_state
auth.one_time_tokens
auth.oauth_clients
auth.oauth_authorizations
auth.oauth_consents
auth.oauth_client_states
auth.custom_oauth_providers
auth.webauthn_credentials
auth.webauthn_challenges
```

### `storage`

```text
storage.buckets
storage.objects
storage.migrations
storage.s3_multipart_uploads
storage.s3_multipart_uploads_parts
storage.buckets_analytics
storage.buckets_vectors
storage.vector_indexes
```

### `realtime`

```text
realtime.messages
realtime.schema_migrations
realtime.subscription
```

### `cron`

```text
cron.job
cron.job_run_details
```

### `vault`

```text
vault.secrets
```

### `net`

```text
net.http_request_queue
net._http_response
```