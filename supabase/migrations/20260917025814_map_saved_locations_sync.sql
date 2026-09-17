begin;
alter table public.user_saved_locations add column if not exists client_key text;
update public.user_saved_locations set client_key = id::text where client_key is null;
alter table public.user_saved_locations alter column client_key set not null;
alter table public.user_saved_locations add column if not exists deleted_at timestamptz;
alter table public.user_saved_locations add column if not exists version bigint not null default 1;
create unique index if not exists user_saved_locations_client_key on public.user_saved_locations(user_id, client_key);
alter table public.user_saved_locations add constraint saved_location_name_valid check (length(btrim(name)) between 1 and 120);
create function public.enforce_saved_location_version() returns trigger language plpgsql set search_path = '' as $$
begin
  if new.user_id is distinct from old.user_id or new.client_key is distinct from old.client_key then
    raise exception 'immutable owner or client key' using errcode = '42501';
  end if;
  if old.deleted_at is not null then raise exception 'deleted location is immutable' using errcode = '40001'; end if;
  new.version := old.version + 1;
  return new;
end; $$;
create trigger saved_location_version before update on public.user_saved_locations for each row execute function public.enforce_saved_location_version();
revoke delete on public.user_saved_locations from authenticated;
revoke all on public.user_saved_locations from anon;
create function public.read_saved_locations() returns table (
  id uuid, client_key text, name text, latitude double precision, longitude double precision,
  created_at timestamptz, deleted_at timestamptz, version bigint
) language sql stable security invoker set search_path = '' as $$
  select s.id, s.client_key, s.name, public.st_y(s.location), public.st_x(s.location), s.created_at, s.deleted_at, s.version
  from public.user_saved_locations s where s.user_id = (select auth.uid());
$$;
revoke all on function public.read_saved_locations() from public, anon;
grant execute on function public.read_saved_locations() to authenticated;
commit;
