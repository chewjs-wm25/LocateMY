-- CPI equivalent-budget conversion is no longer a Cost feature. Keep the
-- public RPC limited to inputs consumed by the core market basket model.
create or replace function public.read_cost_inputs(
  input_state text,
  input_district text
) returns jsonb language sql stable security invoker set search_path='' as $$
with end_date as (
  select max(source_date) d from public.cost_basket_baseline
),
premise_month as (
  select
    p.item_code,
    date_trunc('month', p.date)::date as month,
    p.premise_code,
    percentile_cont(0.5) within group(order by p.price) price,
    count(*) records
  from public.pricecatcher p
  join public.lookup_premise l using(premise_code)
  join public.cost_basket_baseline b using(item_code), end_date
  where l.state = input_state
    and l.district = input_district
    and p.date >= (date_trunc('month', d) - interval '11 months')::date
    and p.date <= d
    and p.price >= 0
    and p.price < 'Infinity'::float4
    and replace(b.unit, '+-', '±') = b.expected_unit
  group by 1, 2, 3
),
local_month as (
  select
    item_code,
    month,
    percentile_cont(0.5) within group(order by price) price,
    count(*) premises,
    sum(records) records
  from premise_month
  group by 1, 2
)
select jsonb_build_object(
  'basket_version', 'cost-basket-v1',
  'source_date', (select d from end_date),
  'baseline', (
    select jsonb_agg(to_jsonb(b) order by item_code)
    from public.cost_basket_baseline b
  ),
  'months', coalesce(
    (select jsonb_agg(to_jsonb(m) order by month, item_code) from local_month m),
    '[]'::jsonb
  ),
  'district_income', (
    select income_median
    from public.hh_income_district
    where state = input_state and district = input_district
    order by date desc
    limit 1
  )
);
$$;
