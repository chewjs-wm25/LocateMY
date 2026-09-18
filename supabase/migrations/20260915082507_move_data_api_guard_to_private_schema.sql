begin;

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to anon, authenticated;

create or replace function private.reject_legacy_postgis_data_api_paths()
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

revoke all on function private.reject_legacy_postgis_data_api_paths()
  from public, anon, authenticated;
grant execute on function private.reject_legacy_postgis_data_api_paths()
  to anon, authenticated;

alter role authenticator
  set pgrst.db_pre_request = 'private.reject_legacy_postgis_data_api_paths';

drop function public.reject_legacy_postgis_data_api_paths();

notify pgrst, 'reload config';

commit;
