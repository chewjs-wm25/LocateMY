-- LocateMY government-data table completion.
-- Source schema: docs/old/knowledge_base_pruned_2026-09-11 (captured 2026-09-10).
-- Government mirror tables use the official data.gov.my dataset ID as the physical table name.
-- Mirrors are client read-only; import jobs must use a server-side service role.

-- Preserve data while replacing pre-contract aliases with official dataset IDs.
alter table if exists public.price_catcher rename to pricecatcher;
alter table if exists public.crime_stats rename to crime_district;

-- The older district_population table has a different grain and remains a legacy import.
comment on table public.district_population is
  'Deprecated legacy aggregate; not the data.gov.my population_district mirror. Retained to preserve imported rows.';

create table if not exists public.cpi_state_inflation (
  state text not null,
  date date not null,
  division text not null,
  inflation_yoy double precision,
  inflation_mom double precision,
  primary key (state, date, division)
);

create table if not exists public.hh_income_state (
  state text not null,
  date date not null,
  income_mean bigint not null,
  income_median bigint not null,
  primary key (state, date)
);

create table if not exists public.hies_district (
  date date not null,
  state text not null,
  district text not null,
  income_mean bigint,
  income_median bigint,
  expenditure_mean bigint,
  gini double precision,
  poverty double precision,
  primary key (date, state, district)
);

create table if not exists public.fuelprice (
  series_type text not null,
  date date not null,
  ron95 double precision,
  ron97 double precision,
  diesel double precision,
  diesel_eastmsia double precision,
  ron95_budi95 double precision,
  ron95_skps double precision,
  primary key (series_type, date)
);

create table if not exists public.mcoicop (
  digits bigint not null,
  division text not null,
  "group" text not null,
  class text not null,
  subclass text not null,
  desc_en text,
  desc_bm text,
  primary key (digits, division, "group", class, subclass)
);

create table if not exists public.population_district (
  date date not null,
  state text not null,
  district text not null,
  sex text not null,
  age text not null,
  ethnicity text not null,
  population double precision not null,
  primary key (date, state, district, sex, age, ethnicity)
);

create table if not exists public.schools_district (
  date date not null,
  state text not null,
  district text not null,
  stage text not null,
  type text not null,
  schools bigint not null,
  primary key (date, state, district, stage, type)
);

-- GTFS resources are a family of government dataset IDs rather than one catalogue dataset.
-- Keep the official ID at the centre of every raw normalized record so feed-specific
-- identifiers never collide.
create table if not exists public.gtfs_static_stops (
  feed_id text not null,
  feed_captured_at timestamptz not null,
  stop_id text not null,
  stop_name text not null,
  stop_lat double precision not null,
  stop_lon double precision not null,
  location_type smallint,
  parent_station text,
  geom geometry(Point, 4326),
  primary key (feed_id, stop_id)
);

create table if not exists public.gtfs_static_routes (
  feed_id text not null,
  feed_captured_at timestamptz not null,
  route_id text not null,
  route_short_name text,
  route_long_name text,
  route_type integer not null,
  primary key (feed_id, route_id)
);

create table if not exists public.gtfs_static_trips (
  feed_id text not null,
  feed_captured_at timestamptz not null,
  route_id text not null,
  service_id text not null,
  trip_id text not null,
  direction_id smallint,
  primary key (feed_id, trip_id),
  foreign key (feed_id, route_id) references public.gtfs_static_routes (feed_id, route_id)
);

create table if not exists public.gtfs_static_stop_times (
  feed_id text not null,
  trip_id text not null,
  stop_id text not null,
  stop_sequence integer not null,
  arrival_time text,
  departure_time text,
  primary key (feed_id, trip_id, stop_sequence),
  foreign key (feed_id, trip_id) references public.gtfs_static_trips (feed_id, trip_id),
  foreign key (feed_id, stop_id) references public.gtfs_static_stops (feed_id, stop_id)
);

create index if not exists gtfs_static_stops_geom_idx on public.gtfs_static_stops using gist (geom);
create index if not exists gtfs_static_stop_times_stop_idx on public.gtfs_static_stop_times (feed_id, stop_id);
create index if not exists gtfs_static_trips_route_idx on public.gtfs_static_trips (feed_id, route_id);

comment on table public.pricecatcher is 'data.gov.my dataset ID: pricecatcher. Daily retail price observations.';
comment on table public.lookup_item is 'data.gov.my dataset ID: lookup_item. PriceCatcher item lookup.';
comment on table public.lookup_premise is 'data.gov.my dataset ID: lookup_premise. PriceCatcher premise lookup.';
comment on table public.cpi_state is 'data.gov.my dataset ID: cpi_state. State CPI level panel.';
comment on table public.cpi_state_inflation is 'data.gov.my dataset ID: cpi_state_inflation. State CPI change panel.';
comment on table public.crime_district is 'data.gov.my dataset ID: crime_district. Crimes by district and crime type.';
comment on table public.hh_income is 'data.gov.my dataset ID: hh_income. Malaysia household income.';
comment on table public.hh_income_district is 'data.gov.my dataset ID: hh_income_district. District household income.';
comment on table public.hh_income_state is 'data.gov.my dataset ID: hh_income_state. State household income.';
comment on table public.hies_district is 'data.gov.my dataset ID: hies_district. District household income and expenditure survey.';
comment on table public.hh_access_amenities is 'data.gov.my dataset ID: hh_access_amenities. District household amenity access.';
comment on table public.hospital_beds is 'data.gov.my dataset ID: hospital_beds. Hospital beds by district.';
comment on table public.population_district is 'data.gov.my dataset ID: population_district. Population by district and demographic dimensions.';
comment on table public.schools_district is 'data.gov.my dataset ID: schools_district. Schools by district.';
comment on table public.teachers_district is 'data.gov.my dataset ID: teachers_district. Teachers by district.';
comment on table public.enrolment_school_district is 'data.gov.my dataset ID: enrolment_school_district. Enrolment by district.';
comment on table public.fuelprice is 'data.gov.my dataset ID: fuelprice. Weekly retail fuel prices.';
comment on table public.mcoicop is 'data.gov.my dataset ID: mcoicop. Malaysian COICOP classification.';
comment on table public.gtfs_static_stops is 'Official GTFS Static resource mirror. feed_id is one of the official gtfs_static_* dataset IDs.';
comment on table public.gtfs_static_routes is 'Official GTFS Static resource mirror. feed_id is one of the official gtfs_static_* dataset IDs.';
comment on table public.gtfs_static_trips is 'Official GTFS Static resource mirror. feed_id is one of the official gtfs_static_* dataset IDs.';
comment on table public.gtfs_static_stop_times is 'Official GTFS Static resource mirror. feed_id is one of the official gtfs_static_* dataset IDs.';

-- Enable RLS, remove implicit client DML, then allow signed-in app users only to read
-- public government mirrors. Service-role import jobs retain their server-only path.
alter table public.cpi_state_inflation enable row level security;
alter table public.hh_income_state enable row level security;
alter table public.hies_district enable row level security;
alter table public.fuelprice enable row level security;
alter table public.mcoicop enable row level security;
alter table public.population_district enable row level security;
alter table public.schools_district enable row level security;
alter table public.gtfs_static_stops enable row level security;
alter table public.gtfs_static_routes enable row level security;
alter table public.gtfs_static_trips enable row level security;
alter table public.gtfs_static_stop_times enable row level security;

revoke all on table
  public.pricecatcher, public.lookup_item, public.lookup_premise, public.cpi_state,
  public.cpi_state_inflation, public.crime_district, public.hh_income,
  public.hh_income_district, public.hh_income_state, public.hies_district,
  public.hh_access_amenities, public.hospital_beds, public.population_district,
  public.schools_district, public.teachers_district, public.enrolment_school_district,
  public.fuelprice, public.mcoicop, public.gtfs_static_stops, public.gtfs_static_routes,
  public.gtfs_static_trips, public.gtfs_static_stop_times
from anon, authenticated;

grant select on table
  public.pricecatcher, public.lookup_item, public.lookup_premise, public.cpi_state,
  public.cpi_state_inflation, public.crime_district, public.hh_income,
  public.hh_income_district, public.hh_income_state, public.hies_district,
  public.hh_access_amenities, public.hospital_beds, public.population_district,
  public.schools_district, public.teachers_district, public.enrolment_school_district,
  public.fuelprice, public.mcoicop, public.gtfs_static_stops, public.gtfs_static_routes,
  public.gtfs_static_trips, public.gtfs_static_stop_times
to authenticated;

create policy "authenticated read cpi_state_inflation" on public.cpi_state_inflation for select to authenticated using (true);
create policy "authenticated read hh_income_state" on public.hh_income_state for select to authenticated using (true);
create policy "authenticated read hies_district" on public.hies_district for select to authenticated using (true);
create policy "authenticated read fuelprice" on public.fuelprice for select to authenticated using (true);
create policy "authenticated read mcoicop" on public.mcoicop for select to authenticated using (true);
create policy "authenticated read population_district" on public.population_district for select to authenticated using (true);
create policy "authenticated read schools_district" on public.schools_district for select to authenticated using (true);
create policy "authenticated read gtfs_static_stops" on public.gtfs_static_stops for select to authenticated using (true);
create policy "authenticated read gtfs_static_routes" on public.gtfs_static_routes for select to authenticated using (true);
create policy "authenticated read gtfs_static_trips" on public.gtfs_static_trips for select to authenticated using (true);
create policy "authenticated read gtfs_static_stop_times" on public.gtfs_static_stop_times for select to authenticated using (true);;
