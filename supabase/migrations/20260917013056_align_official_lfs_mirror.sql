begin;
-- Add-migrate only: retain the legacy mirror, including every historical field.
-- The canonical mirror matches the six official seasonally adjusted columns.
alter table public.lfs_month_sa rename to lfs_month_sa_legacy;
create table public.lfs_month_sa (
 date date primary key, lf double precision, lf_employed double precision,
 lf_unemployed double precision, p_rate double precision, u_rate double precision
);
insert into public.lfs_month_sa (date,lf,lf_employed,lf_unemployed,p_rate,u_rate)
select date,lf,lf_employed,lf_unemployed,p_rate,u_rate from public.lfs_month_sa_legacy;
alter table public.lfs_month_sa enable row level security;
revoke all on public.lfs_month_sa_legacy, public.lfs_month_sa from anon,authenticated;
grant select on public.lfs_month_sa to authenticated;
grant select,insert,update on public.lfs_month_sa to service_role;
create policy "authenticated read canonical lfs month sa" on public.lfs_month_sa
for select to authenticated using (true);
comment on table public.lfs_month_sa is 'Official lfs_month_sa mirror: date, lf, lf_employed, lf_unemployed, p_rate, u_rate. Legacy extension columns retained separately, never used by Home.';
notify pgrst, 'reload schema';
commit;
