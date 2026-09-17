begin;
alter table public.user_saved_locations add constraint user_saved_locations_account_fkey foreign key (user_id) references auth.users(id) on delete cascade not valid;
alter table public.user_saved_locations validate constraint user_saved_locations_account_fkey;
alter table public.user_saved_locations drop constraint user_saved_locations_user_id_fkey;
commit;
