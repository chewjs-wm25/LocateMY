begin;

create table public.cpi_headline_inflation (
  date date not null, division text not null,
  inflation_yoy double precision, inflation_mom double precision,
  primary key (date, division)
);
comment on table public.cpi_headline_inflation is 'data.gov.my dataset ID: cpi_headline_inflation. National CPI inflation by division.';

create table public.lfs_month_sa (
  date date primary key, lf double precision, lf_employed double precision,
  lf_unemployed double precision, lf_outside double precision,
  u_rate double precision, p_rate double precision, ep_ratio double precision
);
comment on table public.lfs_month_sa is 'data.gov.my dataset ID: lfs_month_sa. Seasonally adjusted monthly labour force statistics.';

create table public.economic_indicators (
  date date primary key, "leading" double precision, coincident double precision,
  lagging double precision, leading_diffusion double precision,
  coincident_diffusion double precision
);
comment on table public.economic_indicators is 'data.gov.my dataset ID: economic_indicators. Malaysian economic indicator indices.';

create table public.gdp_qtr_real_sa (
  series text not null, date date not null, value double precision,
  primary key (series, date)
);
comment on table public.gdp_qtr_real_sa is 'data.gov.my dataset ID: gdp_qtr_real_sa. Seasonally adjusted quarterly real GDP.';

create table public.hh_inequality_state (
  state text not null, date date not null, gini double precision,
  primary key (state, date)
);
comment on table public.hh_inequality_state is 'data.gov.my dataset ID: hh_inequality_state. State household income inequality.';

create table public.hies_state_percentile (
  date date not null, state text not null, percentile smallint not null,
  variable text not null, income bigint,
  primary key (date, state, percentile, variable)
);
comment on table public.hies_state_percentile is 'data.gov.my dataset ID: hies_state_percentile. State household income percentile distribution.';

create table public.gtfs_static_calendar (
  feed_id text not null, feed_captured_at timestamptz not null,
  service_id text not null, monday boolean not null, tuesday boolean not null,
  wednesday boolean not null, thursday boolean not null, friday boolean not null,
  saturday boolean not null, sunday boolean not null, start_date date not null,
  end_date date not null, primary key (feed_id, service_id)
);
comment on table public.gtfs_static_calendar is 'Official GTFS Static calendar.txt mirror.';

create table public.gtfs_static_calendar_dates (
  feed_id text not null, feed_captured_at timestamptz not null,
  service_id text not null, date date not null,
  exception_type smallint not null check (exception_type in (1, 2)),
  primary key (feed_id, service_id, date)
);
comment on table public.gtfs_static_calendar_dates is 'Official GTFS Static calendar_dates.txt mirror.';

alter table public.cpi_headline_inflation enable row level security;
alter table public.lfs_month_sa enable row level security;
alter table public.economic_indicators enable row level security;
alter table public.gdp_qtr_real_sa enable row level security;
alter table public.hh_inequality_state enable row level security;
alter table public.hies_state_percentile enable row level security;
alter table public.gtfs_static_calendar enable row level security;
alter table public.gtfs_static_calendar_dates enable row level security;

grant select on table public.cpi_headline_inflation, public.lfs_month_sa,
  public.economic_indicators, public.gdp_qtr_real_sa,
  public.hh_inequality_state, public.hies_state_percentile,
  public.gtfs_static_calendar, public.gtfs_static_calendar_dates
  to authenticated;

create policy "authenticated read cpi headline inflation" on public.cpi_headline_inflation for select to authenticated using (true);
create policy "authenticated read lfs month sa" on public.lfs_month_sa for select to authenticated using (true);
create policy "authenticated read economic indicators" on public.economic_indicators for select to authenticated using (true);
create policy "authenticated read gdp qtr real sa" on public.gdp_qtr_real_sa for select to authenticated using (true);
create policy "authenticated read hh inequality state" on public.hh_inequality_state for select to authenticated using (true);
create policy "authenticated read hies state percentile" on public.hies_state_percentile for select to authenticated using (true);
create policy "authenticated read gtfs static calendar" on public.gtfs_static_calendar for select to authenticated using (true);
create policy "authenticated read gtfs static calendar dates" on public.gtfs_static_calendar_dates for select to authenticated using (true);

create index gtfs_static_calendar_service_dates_idx on public.gtfs_static_calendar (feed_id, service_id, start_date, end_date);
create index gtfs_static_calendar_dates_service_idx on public.gtfs_static_calendar_dates (feed_id, service_id, date);

commit;;
