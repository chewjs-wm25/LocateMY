-- Align the initial import with the canonical LocateMY knowledge base.
-- Government mirror rows are imported once by a trusted maintainer. Clients have
-- read-only access; no scheduled ingestion is configured.

begin;

-- The initial import accidentally scheduled an automatic refresh. This project
-- deliberately uses a one-time, maintainer-run data import.
do $$
declare job_id bigint;
begin
  for job_id in
    select jobid from cron.job where jobname = 'official-data-sync-dispatch'
  loop
    perform cron.unschedule(job_id);
  end loop;
end;
$$;

-- Public mirror data: authenticated clients may read it, but cannot change it.
revoke all on table
  public.cpi_core, public.cpi_state, public.crime_stats,
  public.district_population, public.enrolment_school_district,
  public.gdp_gni_annual_real, public.hh_access_amenities,
  public.hh_income, public.hh_income_district, public.hh_inequality,
  public.hh_inequality_district, public.hies_malaysia_percentile,
  public.hies_state, public.hospital_beds, public.lfs_month,
  public.lookup_item, public.lookup_premise, public.police_districts_boundary,
  public.price_catcher, public.teachers_district, public.transit_stops
from anon, authenticated;

grant select on table
  public.cpi_core, public.cpi_state, public.crime_stats,
  public.district_population, public.enrolment_school_district,
  public.gdp_gni_annual_real, public.hh_access_amenities,
  public.hh_income, public.hh_income_district, public.hh_inequality,
  public.hh_inequality_district, public.hies_malaysia_percentile,
  public.hies_state, public.hospital_beds, public.lfs_month,
  public.lookup_item, public.lookup_premise, public.police_districts_boundary,
  public.price_catcher, public.teachers_district, public.transit_stops
to authenticated;

-- Never expose broad helper access through PUBLIC/anon. Their underlying data
-- remains RLS-protected and calls are only useful to signed-in app users.
revoke all on function public.get_district_income_rank(text) from public, anon;
revoke all on function public.get_district_prices(text) from public, anon;
revoke all on function public.get_transit_density(text) from public, anon;
revoke all on function public.match_police_district(double precision, double precision) from public, anon;
revoke all on function public.update_updated_at_column() from public, anon, authenticated;
grant execute on function public.get_district_income_rank(text),
  public.get_district_prices(text), public.get_transit_density(text),
  public.match_police_district(double precision, double precision)
to authenticated;

-- A semantic, coordinate-based replacement for the obsolete saved-regions
-- interface. Legacy user_saved_regions stays untouched for any later explicit
-- migration because district identifiers cannot safely be converted to points.
create table if not exists public.user_saved_locations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 120),
  location public.geometry(Point, 4326) not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists user_saved_locations_user_created_idx
  on public.user_saved_locations (user_id, created_at desc);
alter table public.user_saved_locations enable row level security;
grant select, insert, update, delete on public.user_saved_locations to authenticated;
create policy "saved locations are private" on public.user_saved_locations
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "users insert own saved locations" on public.user_saved_locations
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "users update own saved locations" on public.user_saved_locations
  for update to authenticated using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "users delete own saved locations" on public.user_saved_locations
  for delete to authenticated using ((select auth.uid()) = user_id);

-- Account-level suitability preferences are distinct from the pre-existing ICI
-- page weights, which remain in user_ici_preferences.
create table if not exists public.user_assessment_preferences (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  safety smallint not null default 5 check (safety between 1 and 10),
  cost smallint not null default 5 check (cost between 1 and 10),
  daily_convenience smallint not null default 5 check (daily_convenience between 1 and 10),
  transit_accessibility smallint not null default 5 check (transit_accessibility between 1 and 10),
  infrastructure smallint not null default 5 check (infrastructure between 1 and 10),
  updated_at timestamptz not null default now()
);
alter table public.user_assessment_preferences enable row level security;
grant select, insert, update, delete on public.user_assessment_preferences to authenticated;
create policy "assessment preferences are private" on public.user_assessment_preferences
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "users insert own assessment preferences" on public.user_assessment_preferences
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "users update own assessment preferences" on public.user_assessment_preferences
  for update to authenticated using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "users delete own assessment preferences" on public.user_assessment_preferences
  for delete to authenticated using ((select auth.uid()) = user_id);

-- Complete the budget-scenario contract. Existing values retain their previous
-- meaning: max_rent -> housing_expense; living_expenses -> basket_adjustment;
-- transport_allowance -> transport_expense.
alter table public.user_budget_scenarios
  add column if not exists basket_adjustment numeric(12,2),
  add column if not exists housing_expense numeric(12,2),
  add column if not exists transport_expense numeric(12,2),
  add column if not exists monthly_net_income numeric(12,2),
  add column if not exists is_current boolean not null default false;
update public.user_budget_scenarios
set basket_adjustment = living_expenses,
    housing_expense = max_rent,
    transport_expense = transport_allowance
where basket_adjustment is null or housing_expense is null or transport_expense is null;
update public.user_budget_scenarios
set scenario_name = 'Imported budget scenario ' || id::text
where btrim(scenario_name) = '';
alter table public.user_budget_scenarios
  alter column scenario_name type text,
  alter column basket_adjustment drop default,
  alter column housing_expense drop default,
  alter column transport_expense drop default,
  add constraint user_budget_scenarios_name_nonblank
    check (char_length(btrim(scenario_name)) between 1 and 120),
  add constraint user_budget_scenarios_basket_nonnegative
    check (basket_adjustment is null or basket_adjustment >= 0),
  add constraint user_budget_scenarios_housing_nonnegative
    check (housing_expense is null or housing_expense >= 0),
  add constraint user_budget_scenarios_transport_nonnegative
    check (transport_expense is null or transport_expense >= 0),
  add constraint user_budget_scenarios_income_nonnegative
    check (monthly_net_income is null or monthly_net_income >= 0);
create unique index if not exists user_budget_scenarios_one_current_per_user
  on public.user_budget_scenarios (user_id) where is_current;

-- Replace overlapping ALL/public policies on private tables with explicit
-- authenticated policies. UPDATE has both USING and WITH CHECK.
do $$
declare target_table text;
declare policy_name text;
begin
  foreach target_table in array array[
    'profiles', 'user_budget_scenarios', 'user_ici_preferences',
    'user_property_inspections', 'user_saved_regions'
  ] loop
    for policy_name in
      select policyname from pg_policies
      where schemaname = 'public' and tablename = target_table
    loop
      execute format('drop policy %I on public.%I', policy_name, target_table);
    end loop;
  end loop;
end;
$$;
revoke all on table public.profiles, public.user_budget_scenarios,
  public.user_ici_preferences, public.user_property_inspections,
  public.user_saved_regions from anon, authenticated;
grant select, insert, update, delete on table public.profiles,
  public.user_budget_scenarios, public.user_ici_preferences,
  public.user_saved_regions to authenticated;

create policy "profiles are private" on public.profiles for select to authenticated
  using ((select auth.uid()) = id);
create policy "users insert own profile" on public.profiles for insert to authenticated
  with check ((select auth.uid()) = id);
create policy "users update own profile" on public.profiles for update to authenticated
  using ((select auth.uid()) = id) with check ((select auth.uid()) = id);
create policy "users delete own profile" on public.profiles for delete to authenticated
  using ((select auth.uid()) = id);

create policy "budget scenarios are private" on public.user_budget_scenarios for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "users insert own budget scenarios" on public.user_budget_scenarios for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "users update own budget scenarios" on public.user_budget_scenarios for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "users delete own budget scenarios" on public.user_budget_scenarios for delete to authenticated
  using ((select auth.uid()) = user_id);

create policy "ici preferences are private" on public.user_ici_preferences for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "users insert own ici preferences" on public.user_ici_preferences for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "users update own ici preferences" on public.user_ici_preferences for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "users delete own ici preferences" on public.user_ici_preferences for delete to authenticated
  using ((select auth.uid()) = user_id);

-- The earlier JSON/image-url property table is retained only as an inaccessible
-- legacy artifact. The normalized property_inspections table below is the API.

create policy "legacy saved regions are private" on public.user_saved_regions for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "users insert own legacy saved regions" on public.user_saved_regions for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "users update own legacy saved regions" on public.user_saved_regions for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "users delete own legacy saved regions" on public.user_saved_regions for delete to authenticated
  using ((select auth.uid()) = user_id);

-- Public-to-authenticated hazard layer, with author-only modification.
alter table public.crowdsourced_hazards
  alter column user_id set not null,
  alter column title set not null,
  alter column status set not null,
  alter column report_time set not null,
  alter column status set default 'pending';
alter table public.crowdsourced_hazards
  drop constraint if exists crowdsourced_hazards_status_check,
  add constraint crowdsourced_hazards_type_check
    check (hazard_type in ('flood', 'crime', 'traffic', 'infrastructure', 'other')),
  add constraint crowdsourced_hazards_status_check
    check (status in ('pending', 'resolved')),
  add constraint crowdsourced_hazards_title_check
    check (char_length(btrim(title)) between 1 and 120),
  add constraint crowdsourced_hazards_description_check
    check (description is null or char_length(description) <= 2000);
do $$
declare policy_name text;
begin
  for policy_name in
    select policyname from pg_policies
    where schemaname = 'public' and tablename = 'crowdsourced_hazards'
  loop
    execute format('drop policy %I on public.crowdsourced_hazards', policy_name);
  end loop;
end;
$$;
revoke all on public.crowdsourced_hazards from anon, authenticated;
grant select, insert, update, delete on public.crowdsourced_hazards to authenticated;
create policy "authenticated users read hazards" on public.crowdsourced_hazards
  for select to authenticated using (true);
create policy "users create own hazards" on public.crowdsourced_hazards
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "authors update own hazards" on public.crowdsourced_hazards
  for update to authenticated using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "authors delete own hazards" on public.crowdsourced_hazards
  for delete to authenticated using ((select auth.uid()) = user_id);
create index if not exists crowdsourced_hazards_report_time_idx
  on public.crowdsourced_hazards (report_time desc);

create table if not exists public.crowdsourced_hazard_votes (
  hazard_id uuid not null references public.crowdsourced_hazards(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  vote smallint not null check (vote in (-1, 1)),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (hazard_id, user_id)
);
alter table public.crowdsourced_hazard_votes enable row level security;
grant select, insert, update, delete on public.crowdsourced_hazard_votes to authenticated;
create policy "users read own hazard votes" on public.crowdsourced_hazard_votes
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "users insert own hazard votes" on public.crowdsourced_hazard_votes
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "users update own hazard votes" on public.crowdsourced_hazard_votes
  for update to authenticated using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "users delete own hazard votes" on public.crowdsourced_hazard_votes
  for delete to authenticated using ((select auth.uid()) = user_id);

create or replace view public.hazard_vote_counts with (security_invoker = true) as
select hazard_id,
       count(*) filter (where vote = 1)::integer as upvotes,
       count(*) filter (where vote = -1)::integer as downvotes
from public.crowdsourced_hazard_votes
group by hazard_id;
grant select on public.hazard_vote_counts to authenticated;

-- Normalized private property inspection records; the old JSON/image-url table
-- stays available only for a deliberate future migration (it currently has no rows).
create table if not exists public.property_inspections (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  property_name text not null check (char_length(btrim(property_name)) between 1 and 200),
  address text,
  saved_location_id uuid references public.user_saved_locations(id) on delete set null,
  location public.geometry(Point, 4326),
  price numeric(14,2) not null check (price >= 0),
  drainage_rating smallint not null default 3 check (drainage_rating between 1 and 5),
  waterproofing_rating smallint not null default 3 check (waterproofing_rating between 1 and 5),
  humidity_rating smallint not null default 3 check (humidity_rating between 1 and 5),
  lighting_rating smallint not null default 3 check (lighting_rating between 1 and 5),
  flood_evidence boolean not null default false,
  notes text,
  risk_police_district text,
  risk_safety_score numeric(5,2) check (risk_safety_score between 0 and 100),
  risk_nearby_hazard_count integer check (risk_nearby_hazard_count >= 0),
  risk_captured_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists property_inspections_user_active_idx
  on public.property_inspections (user_id, updated_at desc) where deleted_at is null;
create index if not exists property_inspections_user_deleted_idx
  on public.property_inspections (user_id, deleted_at desc) where deleted_at is not null;
alter table public.property_inspections enable row level security;
grant select, insert, update, delete on public.property_inspections to authenticated;
create policy "property inspections are private" on public.property_inspections
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "users insert own property inspections" on public.property_inspections
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "users update own property inspections" on public.property_inspections
  for update to authenticated using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "users delete own property inspections" on public.property_inspections
  for delete to authenticated using ((select auth.uid()) = user_id);

create table if not exists public.property_inspection_photos (
  id uuid primary key default gen_random_uuid(),
  inspection_id uuid not null references public.property_inspections(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  storage_path text not null unique,
  caption text check (caption is null or char_length(caption) <= 1000),
  is_cover boolean not null default false,
  created_at timestamptz not null default now()
);
create unique index if not exists property_inspection_photos_one_cover
  on public.property_inspection_photos (inspection_id) where is_cover;
create index if not exists property_inspection_photos_order_idx
  on public.property_inspection_photos (inspection_id, created_at);
alter table public.property_inspection_photos enable row level security;
grant select, insert, update, delete on public.property_inspection_photos to authenticated;
create policy "property photos are private" on public.property_inspection_photos
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "users insert own property photos" on public.property_inspection_photos
  for insert to authenticated with check (
    (select auth.uid()) = user_id and exists (
      select 1 from public.property_inspections i
      where i.id = inspection_id and i.user_id = (select auth.uid())
    )
  );
create policy "users update own property photos" on public.property_inspection_photos
  for update to authenticated using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);
create policy "users delete own property photos" on public.property_inspection_photos
  for delete to authenticated using ((select auth.uid()) = user_id);

create or replace function public.enforce_property_photo_limit()
returns trigger language plpgsql set search_path = public as $$
begin
  if (select count(*) from public.property_inspection_photos
      where inspection_id = new.inspection_id) >= 20 then
    raise exception 'A property inspection can have at most 20 photos';
  end if;
  return new;
end;
$$;
revoke all on function public.enforce_property_photo_limit() from public, anon, authenticated;
create trigger property_inspection_photo_limit
  before insert on public.property_inspection_photos
  for each row execute function public.enforce_property_photo_limit();

-- Private bucket and ownership path: <user-id>/<inspection-id>/<file>.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('inspection-photos', 'inspection-photos', false, 10485760,
        array['image/jpeg', 'image/png', 'image/webp', 'image/heic'])
on conflict (id) do update set public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;
create policy "users read own inspection files" on storage.objects for select to authenticated
  using (bucket_id = 'inspection-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "users upload own inspection files" on storage.objects for insert to authenticated
  with check (bucket_id = 'inspection-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text
    and exists (select 1 from public.property_inspections i
      where i.id::text = (storage.foldername(name))[2]
        and i.user_id = (select auth.uid())));
create policy "users update own inspection files" on storage.objects for update to authenticated
  using (bucket_id = 'inspection-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'inspection-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "users delete own inspection files" on storage.objects for delete to authenticated
  using (bucket_id = 'inspection-photos'
    and (storage.foldername(name))[1] = (select auth.uid())::text);

-- Keep timestamps reliable for client mutations.
create trigger user_saved_locations_set_updated_at before update on public.user_saved_locations
  for each row execute function public.update_updated_at_column();
create trigger user_assessment_preferences_set_updated_at before update on public.user_assessment_preferences
  for each row execute function public.update_updated_at_column();
create trigger user_budget_scenarios_set_updated_at before update on public.user_budget_scenarios
  for each row execute function public.update_updated_at_column();
create trigger property_inspections_set_updated_at before update on public.property_inspections
  for each row execute function public.update_updated_at_column();
create trigger crowdsourced_hazard_votes_set_updated_at before update on public.crowdsourced_hazard_votes
  for each row execute function public.update_updated_at_column();

commit;
