begin;
alter table public.property_inspections
  add column if not exists snapshot_availability text not null default 'unavailable'
    check (snapshot_availability in ('available', 'unavailable')),
  add column if not exists snapshot_latitude double precision,
  add column if not exists snapshot_longitude double precision,
  add column if not exists reporting_state text,
  add column if not exists safety_index numeric check (safety_index between 0 and 100),
  add column if not exists safety_source_year integer,
  add column if not exists safety_source_id text,
  add column if not exists safety_model_boundary_version text,
  add column if not exists safety_completeness text,
  add column if not exists hazard_pending_count integer check (hazard_pending_count >= 0),
  add column if not exists hazard_radius_m integer check (hazard_radius_m = 2000),
  add column if not exists hazard_counted_at timestamptz,
  add column if not exists snapshot_captured_at timestamptz;

alter table public.property_inspections drop constraint if exists property_snapshot_complete;
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

create or replace function public.invalidate_changed_property_snapshot()
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
drop trigger if exists property_snapshot_coordinate on public.property_inspections;
create trigger property_snapshot_coordinate before update on public.property_inspections
  for each row execute function public.invalidate_changed_property_snapshot();

-- Retain historical nullable-location records, prohibit new invalid records.
alter table public.property_inspections drop constraint if exists property_inspections_user_id_fkey;
alter table public.property_inspections add constraint property_inspections_user_id_fkey foreign key(user_id) references auth.users(id) on delete cascade;
alter table public.property_inspections add constraint property_location_required check(location is not null and public.st_y(location) between -90 and 90 and public.st_x(location) between -180 and 180) not valid;
alter table public.property_inspection_photos drop constraint if exists property_inspection_photos_user_id_fkey;
alter table public.property_inspection_photos add constraint property_inspection_photos_user_id_fkey foreign key(user_id) references auth.users(id) on delete cascade;
alter table public.property_inspection_photos add column if not exists upload_complete boolean not null default true;
-- Immutable photo/parent identity; no path reassignment or orphan Storage.
create function public.property_photo_identity_guard() returns trigger language plpgsql set search_path='' as $$
begin
 if new.id is distinct from old.id or new.inspection_id is distinct from old.inspection_id or new.user_id is distinct from old.user_id or new.storage_path is distinct from old.storage_path or new.created_at is distinct from old.created_at then raise exception 'immutable photo identity';end if;
 return new;
end;$$;
revoke all on function public.property_photo_identity_guard() from public,anon,authenticated;
create trigger property_photo_identity_guard before update on public.property_inspection_photos for each row execute function public.property_photo_identity_guard();
create or replace function public.enforce_property_photo_limit() returns trigger language plpgsql set search_path='' as $$
begin
 perform 1 from public.property_inspections where id=new.inspection_id for update;
 if (select count(*) from public.property_inspection_photos where inspection_id=new.inspection_id)>=20 then raise exception 'photo limit';end if;
 if new.storage_path <> new.user_id::text||'/'||new.inspection_id::text||'/'||new.id::text||'.jpg' then raise exception 'invalid photo path';end if;
 return new;
end;$$;
drop policy if exists "property photos are private" on public.property_inspection_photos;
drop policy if exists "users insert own property photos" on public.property_inspection_photos;
drop policy if exists "users update own property photos" on public.property_inspection_photos;
drop policy if exists "users delete own property photos" on public.property_inspection_photos;
create policy property_photos_owner on public.property_inspection_photos for all to authenticated using(user_id=(select auth.uid()) and exists(select 1 from public.property_inspections i where i.id=inspection_id and i.user_id=(select auth.uid()))) with check(user_id=(select auth.uid()) and exists(select 1 from public.property_inspections i where i.id=inspection_id and i.user_id=(select auth.uid())));
drop policy if exists "users read own inspection files" on storage.objects;
drop policy if exists "users upload own inspection files" on storage.objects;
drop policy if exists "users update own inspection files" on storage.objects;
drop policy if exists "users delete own inspection files" on storage.objects;
create policy inspection_storage_owner on storage.objects for all to authenticated using(bucket_id='inspection-photos' and (storage.foldername(name))[1]=(select auth.uid())::text and exists(select 1 from public.property_inspections i where i.id::text=(storage.foldername(name))[2] and i.user_id=(select auth.uid()))) with check(bucket_id='inspection-photos' and (storage.foldername(name))[1]=(select auth.uid())::text and exists(select 1 from public.property_inspections i join public.property_inspection_photos p on p.inspection_id=i.id where i.id::text=(storage.foldername(name))[2] and i.user_id=(select auth.uid()) and i.deleted_at is null and p.storage_path=name));
create function public.read_property_inspections(p_id uuid default null,p_deleted boolean default false) returns setof jsonb language sql stable security invoker set search_path='' as $$
 select to_jsonb(i)-'location' || jsonb_build_object('latitude',public.st_y(i.location),'longitude',public.st_x(i.location)) from public.property_inspections i where i.user_id=(select auth.uid()) and (p_id is null or i.id=p_id) and (p_deleted is null or (i.deleted_at is not null)=p_deleted) and i.location is not null order by i.updated_at desc,i.id;
$$;
create function public.reserve_property_photo(p_inspection uuid) returns jsonb language plpgsql security invoker set search_path='' as $$
declare new_id uuid:=gen_random_uuid(); result public.property_inspection_photos;
begin
 perform 1 from public.property_inspections where id=p_inspection and user_id=(select auth.uid()) and deleted_at is null for update;
 if not found then raise exception 'inspection unavailable';end if;
 insert into public.property_inspection_photos(id,inspection_id,user_id,storage_path,upload_complete) values(new_id,p_inspection,(select auth.uid()),(select auth.uid())::text||'/'||p_inspection::text||'/'||new_id::text||'.jpg',false) returning * into result;
 return to_jsonb(result);
end;$$;
create function public.finish_property_photo(p_photo uuid) returns void language plpgsql security invoker set search_path='' as $$
declare parent_id uuid;
begin
 select inspection_id into parent_id from public.property_inspection_photos where id=p_photo and user_id=(select auth.uid());
 if parent_id is null then raise exception 'photo unavailable';end if;
 perform 1 from public.property_inspections where id=parent_id and user_id=(select auth.uid()) and deleted_at is null for update;
 if not found then raise exception 'inspection unavailable';end if;
 update public.property_inspection_photos set upload_complete=true,is_cover=not exists(select 1 from public.property_inspection_photos where inspection_id=parent_id and is_cover) where id=p_photo;
end;$$;
create function public.edit_property_photo(p_inspection uuid,p_photo uuid,p_caption text default null,p_cover boolean default false) returns void language plpgsql security invoker set search_path='' as $$
begin
 perform 1 from public.property_inspections where id=p_inspection and user_id=(select auth.uid()) and deleted_at is null for update;
 if not found then raise exception 'inspection unavailable';end if;
 perform 1 from public.property_inspection_photos where id=p_photo and inspection_id=p_inspection and upload_complete;
 if not found then raise exception 'photo unavailable';end if;
 if p_cover then update public.property_inspection_photos set is_cover=false where inspection_id=p_inspection and is_cover;end if;
 update public.property_inspection_photos set caption=coalesce(p_caption,caption),is_cover=case when p_cover then true else is_cover end where id=p_photo and inspection_id=p_inspection;
end;$$;
revoke all on function public.read_property_inspections(uuid,boolean),public.reserve_property_photo(uuid),public.finish_property_photo(uuid),public.edit_property_photo(uuid,uuid,text,boolean) from public,anon;
grant execute on function public.read_property_inspections(uuid,boolean),public.reserve_property_photo(uuid),public.finish_property_photo(uuid),public.edit_property_photo(uuid,uuid,text,boolean) to authenticated;
commit;
