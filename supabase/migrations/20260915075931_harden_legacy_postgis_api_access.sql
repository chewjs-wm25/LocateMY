begin;

-- PostGIS was created in public by the imported legacy schema. Its catalogue
-- and privileged extent helpers are implementation details, not Data API
-- resources. Revoke inherited and direct frontend privileges without moving
-- the non-relocatable extension or disturbing existing geometry columns.
revoke all on table public.spatial_ref_sys from public, anon, authenticated;

revoke execute on function public.st_estimatedextent(text, text)
  from public, anon, authenticated;
revoke execute on function public.st_estimatedextent(text, text, text)
  from public, anon, authenticated;
revoke execute on function public.st_estimatedextent(text, text, text, boolean)
  from public, anon, authenticated;

commit;
