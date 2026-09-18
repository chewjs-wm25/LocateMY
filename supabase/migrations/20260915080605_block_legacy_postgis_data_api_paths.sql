begin;

-- The imported PostGIS extension is owned by supabase_admin in public and its
-- catalogue ACL cannot be changed by ordinary project migrations. Block only
-- those legacy extension endpoints at the supported PostgREST pre-request
-- seam while leaving LocateMY's explicit tables and RPCs untouched.
create or replace function public.reject_legacy_postgis_data_api_paths()
returns void
language plpgsql
set search_path = ''
as $$
declare
  request_path text := trim(both '/' from coalesce(
    current_setting('request.path', true),
    ''
  ));
begin
  if request_path = 'spatial_ref_sys'
     or request_path = 'st_estimatedextent'
     or request_path like '%/st_estimatedextent'
     or position('graphql' in request_path) > 0 then
    raise sqlstate '42501' using
      message = 'This Data API path is not available.';
  end if;
end;
$$;

revoke all on function public.reject_legacy_postgis_data_api_paths()
  from public, anon, authenticated;
grant execute on function public.reject_legacy_postgis_data_api_paths()
  to anon, authenticated;

alter role authenticator
  set pgrst.db_pre_request = 'public.reject_legacy_postgis_data_api_paths';

notify pgrst, 'reload config';

commit;
