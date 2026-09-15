-- The legacy table is inaccessible, but retain an FK index for maintenance.
create index if not exists user_property_inspections_user_idx
  on public.user_property_inspections (user_id);

-- These PostGIS extension functions are not application RPCs. Remove their
-- default API execution grants while keeping PostGIS available to database roles.
revoke execute on function public.st_estimatedextent(text, text) from public, anon, authenticated;
revoke execute on function public.st_estimatedextent(text, text, text) from public, anon, authenticated;
revoke execute on function public.st_estimatedextent(text, text, text, boolean) from public, anon, authenticated;;
