-- Indexes cover ownership FKs used by RLS and parent-row deletion.
create index if not exists crowdsourced_hazard_votes_user_idx
  on public.crowdsourced_hazard_votes (user_id);
create index if not exists crowdsourced_hazards_user_idx
  on public.crowdsourced_hazards (user_id);
create index if not exists property_inspection_photos_user_idx
  on public.property_inspection_photos (user_id);
create index if not exists property_inspections_saved_location_idx
  on public.property_inspections (saved_location_id);

-- The obsolete JSON/image-url table is deliberately denied to every API role.
-- Keeping an explicit deny policy makes this security posture auditable.
create policy "legacy property inspection API disabled"
  on public.user_property_inspections
  as restrictive
  for all
  to anon, authenticated
  using (false)
  with check (false);
