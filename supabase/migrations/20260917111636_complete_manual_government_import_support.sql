begin;
-- Existing mirror tables already match the official business columns.
create table if not exists public.hh_inequality_state (
 state text not null,date date not null,gini double precision,
 primary key(state,date)
);
create table if not exists public.hies_state_percentile (
 date date not null,state text not null,percentile smallint not null,
 variable text not null,income bigint,
 primary key(date,state,percentile,variable)
);
alter table public.hh_inequality_state enable row level security;
alter table public.hies_state_percentile enable row level security;
revoke all on public.hh_inequality_state,public.hies_state_percentile from public,anon,authenticated;
grant select on public.hh_inequality_state,public.hies_state_percentile to authenticated;
grant select,insert,update on public.hh_inequality_state,public.hies_state_percentile to service_role;
drop policy if exists "authenticated read hh inequality state" on public.hh_inequality_state;
drop policy if exists "authenticated read hies state percentile" on public.hies_state_percentile;
create policy "authenticated read hh inequality state" on public.hh_inequality_state
 for select to authenticated using ((select auth.uid()) is not null);
create policy "authenticated read hies state percentile" on public.hies_state_percentile
 for select to authenticated using ((select auth.uid()) is not null);
-- Import facts are separate from unmodified government business columns.
create table public.government_data_import_files (
 import_id text not null,dataset_id text not null,source_url text not null,
 source_sha256 text not null check(source_sha256 ~ '^[0-9a-f]{64}$'),
 selection_rule text not null,row_count bigint not null check(row_count>=0),
 rejected_rows jsonb not null default '{}'::jsonb,
 imported_at timestamptz not null default now(),
 primary key(import_id,dataset_id,source_sha256)
);
alter table public.government_data_import_files enable row level security;
revoke all on public.government_data_import_files from public,anon,authenticated;
grant select,insert,update on public.government_data_import_files to service_role;
comment on table public.government_data_import_files is
 'Maintainer-only one-time import provenance, including filtered PriceCatcher and archived GTFS sources.';
notify pgrst,'reload schema';
commit;
