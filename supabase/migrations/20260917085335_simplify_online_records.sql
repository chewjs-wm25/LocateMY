begin;
-- Retire the excluded five-preference API without deleting historical records.
revoke all on table public.user_assessment_preferences from anon, authenticated;

-- Property is a future Feature. Add its snapshot availability and provenance
-- now; legacy police-district fields do not prove a valid state-level snapshot.
alter table public.property_inspections
  add column snapshot_availability text not null default 'unavailable'
    check (snapshot_availability in ('available', 'unavailable')),
  add column snapshot_latitude double precision,
  add column snapshot_longitude double precision,
  add column reporting_state text,
  add column safety_index numeric check (safety_index between 0 and 100),
  add column safety_source_year integer,
  add column safety_source_id text,
  add column safety_model_boundary_version text,
  add column safety_completeness text,
  add column hazard_pending_count integer check (hazard_pending_count >= 0),
  add column hazard_radius_m integer check (hazard_radius_m = 2000),
  add column hazard_counted_at timestamptz,
  add column snapshot_captured_at timestamptz;

alter table public.property_inspections add constraint property_snapshot_complete check (
  (snapshot_availability = 'unavailable'
    and snapshot_latitude is null and snapshot_longitude is null
    and reporting_state is null and safety_index is null
    and safety_source_year is null and safety_source_id is null
    and safety_model_boundary_version is null and safety_completeness is null
    and hazard_pending_count is null and hazard_radius_m is null
    and hazard_counted_at is null)
  or
  (snapshot_availability = 'available'
    and location is not null
    and snapshot_latitude is not null and snapshot_longitude is not null
    and snapshot_latitude = public.st_y(location)
    and snapshot_longitude = public.st_x(location)
    and nullif(btrim(reporting_state), '') is not null
    and safety_index is not null and safety_source_year is not null
    and nullif(btrim(safety_source_id), '') is not null
    and nullif(btrim(safety_model_boundary_version), '') is not null
    and safety_completeness is not null and safety_completeness = 'complete'
    and hazard_pending_count is not null and hazard_radius_m is not null
    and hazard_counted_at is not null and snapshot_captured_at is not null)
);

create function public.invalidate_changed_property_snapshot()
returns trigger language plpgsql set search_path = '' as $$
begin
  -- A freshly supplied complete group for the new coordinate is accepted.
  -- Otherwise clear the old coordinate's group; this never queries or retries.
  if (public.st_x(new.location) is distinct from public.st_x(old.location)
      or public.st_y(new.location) is distinct from public.st_y(old.location)) and
    (new.location is null or new.snapshot_latitude is distinct from public.st_y(new.location)
      or new.snapshot_longitude is distinct from public.st_x(new.location)) then
    new.snapshot_availability := 'unavailable';
    new.snapshot_latitude := null;
    new.snapshot_longitude := null;
    new.reporting_state := null;
    new.safety_index := null;
    new.safety_source_year := null;
    new.safety_source_id := null;
    new.safety_model_boundary_version := null;
    new.safety_completeness := null;
    new.hazard_pending_count := null;
    new.hazard_radius_m := null;
    new.hazard_counted_at := null;
    new.snapshot_captured_at := null;
    new.risk_police_district := null;
    new.risk_safety_score := null;
    new.risk_nearby_hazard_count := null;
    new.risk_captured_at := null;
  end if;
  return new;
end;
$$;
revoke all on function public.invalidate_changed_property_snapshot() from public, anon, authenticated;
create trigger property_snapshot_coordinate before update on public.property_inspections
  for each row execute function public.invalidate_changed_property_snapshot();

-- Keep the existing saved-location RPC shape for compatibility with the live
-- development app. Version/deleted_at are backend metadata, never a local queue.
create or replace function public.read_saved_locations() returns table (
  id uuid, client_key text, name text, latitude double precision, longitude double precision,
  created_at timestamptz, deleted_at timestamptz, version bigint
) language sql stable security invoker set search_path = '' as $$
  select s.id, s.client_key, s.name, public.st_y(s.location), public.st_x(s.location),
         s.created_at, s.deleted_at, s.version
  from public.user_saved_locations s
  where s.user_id = (select auth.uid()) and s.deleted_at is null;
$$;
revoke all on function public.read_saved_locations() from public, anon;
grant execute on function public.read_saved_locations() to authenticated;
commit;
