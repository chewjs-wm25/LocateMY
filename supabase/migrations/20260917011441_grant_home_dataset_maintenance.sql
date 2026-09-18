begin;
-- Controlled one-time import only; service_role never enters Flutter.
grant select, insert, update on public.cpi_headline_inflation, public.lfs_month_sa, public.economic_indicators, public.gdp_qtr_real_sa to service_role;
commit;
