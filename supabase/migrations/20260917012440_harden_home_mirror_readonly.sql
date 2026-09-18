begin;
-- Explicit grants are required even when RLS already denies writes.
revoke all on public.cpi_headline_inflation, public.lfs_month_sa, public.economic_indicators, public.gdp_qtr_real_sa, public.hh_income from anon, authenticated;
grant select on public.cpi_headline_inflation, public.lfs_month_sa, public.economic_indicators, public.gdp_qtr_real_sa, public.hh_income to authenticated;
notify pgrst, 'reload schema';
commit;
