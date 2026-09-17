begin;
-- Nullable additive field: old scenarios have unknown household income.
alter table public.user_budget_scenarios add column if not exists household_monthly_gross_income_rm numeric(12,2)
 check (household_monthly_gross_income_rm is null or household_monthly_gross_income_rm >= 0);
create or replace function public.read_socio_inputs(p_state text,p_district text default null)
returns jsonb language plpgsql stable security invoker set search_path = '' as $$
begin
 if auth.uid() is null then raise insufficient_privilege using message = 'Authentication required'; end if;
 if p_state is null or btrim(p_state) = '' then raise invalid_parameter_value using message = 'State required'; end if;
 return jsonb_build_object(
  'version',1,'state',p_state,'district',p_district,
  'income_district',coalesce((select jsonb_agg(to_jsonb(x)) from (select date,income_median from public.hh_income_district where state=p_state and district=p_district order by date) x),'[]'::jsonb),
  'income_state',coalesce((select jsonb_agg(to_jsonb(x)) from (select date,income_median from public.hh_income_state where state=p_state order by date) x),'[]'::jsonb),
  'gini_district',coalesce((select jsonb_agg(to_jsonb(x)) from (select date,gini from public.hh_inequality_district where state=p_state and district=p_district order by date) x),'[]'::jsonb),
  'gini_state',coalesce((select jsonb_agg(to_jsonb(x)) from (select date,gini from public.hh_inequality_state where state=p_state order by date) x),'[]'::jsonb),
  'percentiles',coalesce((select jsonb_agg(to_jsonb(x)) from (select date,percentile,variable,income from public.hies_state_percentile where state=p_state order by date,percentile,variable) x),'[]'::jsonb)
 );
end;
$$;
revoke all on function public.read_socio_inputs(text,text) from public,anon;
grant execute on function public.read_socio_inputs(text,text) to authenticated;
notify pgrst,'reload schema';
commit;
