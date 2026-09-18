-- PostgREST upsert includes all supplied columns in INSERT and ON CONFLICT UPDATE.
-- Ownership remains protected by both existing USING and WITH CHECK predicates.
grant insert(updated_at),update(user_id) on public.user_ici_preferences to authenticated;
notify pgrst,'reload schema';
