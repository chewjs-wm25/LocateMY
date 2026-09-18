begin;
-- Maintenance callers must run the same pre-request guard as app clients.
grant usage on schema private to service_role;
grant execute on function private.reject_legacy_postgis_data_api_paths() to service_role;
notify pgrst, 'reload schema';
commit;
