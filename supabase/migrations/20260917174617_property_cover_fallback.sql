begin;
create function public.property_photo_cover_fallback() returns trigger language plpgsql security invoker set search_path='' as $$
begin
 if old.is_cover then
  perform 1 from public.property_inspections where id=old.inspection_id for update;
  update public.property_inspection_photos set is_cover=true where id=(select id from public.property_inspection_photos where inspection_id=old.inspection_id and upload_complete order by created_at,id limit 1) and not exists(select 1 from public.property_inspection_photos where inspection_id=old.inspection_id and is_cover);
 end if;
 return old;
end;$$;
revoke all on function public.property_photo_cover_fallback() from public,anon,authenticated;
create trigger property_photo_cover_fallback after delete on public.property_inspection_photos for each row execute function public.property_photo_cover_fallback();
commit;
