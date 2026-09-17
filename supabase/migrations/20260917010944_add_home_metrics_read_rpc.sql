begin;
-- Read-only, caller privileges; the source tables retain authenticated-only RLS.
create function public.read_home_metrics() returns jsonb
language sql stable security invoker set search_path = ''
as $$
select jsonb_build_object('version',1,'datasets',jsonb_build_object(
  'cpi_headline_inflation',coalesce((select jsonb_agg(to_jsonb(t) order by t.date,t.division) from (select date,division,inflation_yoy,inflation_mom from public.cpi_headline_inflation where division in ('overall','01','04','07')) t),'[]'::jsonb),
  'lfs_month_sa',coalesce((select jsonb_agg(to_jsonb(t) order by t.date) from (select date,lf_employed,u_rate,p_rate from public.lfs_month_sa) t),'[]'::jsonb),
  'economic_indicators',coalesce((select jsonb_agg(to_jsonb(t) order by t.date) from (select date,"leading",leading_diffusion from public.economic_indicators) t),'[]'::jsonb),
  'gdp_qtr_real_sa',coalesce((select jsonb_agg(to_jsonb(t) order by t.date,t.series) from (select date,series,value from public.gdp_qtr_real_sa where series='growth_qoq') t),'[]'::jsonb),
  'hh_income',coalesce((select jsonb_agg(to_jsonb(t) order by t.date) from (select date,income_median from public.hh_income) t),'[]'::jsonb)
));
$$;
revoke all on function public.read_home_metrics() from public,anon;
grant execute on function public.read_home_metrics() to authenticated;
comment on function public.read_home_metrics() is 'HOME-001 version 1 national datasets; observed date per source, not import time. No account or location fields.';
commit;
