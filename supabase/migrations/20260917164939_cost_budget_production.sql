-- Forward-only business API. Government mirror business columns are untouched.
alter table public.user_budget_scenarios drop constraint user_budget_scenarios_user_id_fkey;
alter table public.user_budget_scenarios add constraint user_budget_scenarios_user_id_fkey foreign key(user_id) references auth.users(id) on delete cascade;
-- Legacy source columns retained without client grants until archival removal.
revoke all on public.user_budget_scenarios from anon;
revoke insert,update on public.user_budget_scenarios from authenticated;
grant insert(user_id,scenario_name,basket_adjustment,housing_expense,transport_expense,monthly_net_income,household_monthly_gross_income_rm),update(scenario_name,basket_adjustment,housing_expense,transport_expense,monthly_net_income,household_monthly_gross_income_rm,is_current) on public.user_budget_scenarios to authenticated;
create or replace function public.select_current_budget(scenario_id uuid) returns jsonb language plpgsql security invoker set search_path='' as $$
declare result jsonb;
begin
 if auth.uid() is null then raise insufficient_privilege; end if;
 perform pg_advisory_xact_lock(hashtextextended(auth.uid()::text,15));
 if not exists(select 1 from public.user_budget_scenarios where id=scenario_id and user_id=auth.uid()) then return null; end if;
 update public.user_budget_scenarios set is_current=false where user_id=auth.uid() and is_current;
 update public.user_budget_scenarios set is_current=true where id=scenario_id and user_id=auth.uid();
 select to_jsonb(s) into result from public.user_budget_scenarios s where id=scenario_id and user_id=auth.uid();
 return result;
end $$;
revoke all on function public.select_current_budget(uuid) from public,anon;
grant execute on function public.select_current_budget(uuid) to authenticated;

-- Freeze two-stage monthly representative prices for this fixed import snapshot.
create table public.cost_basket_baseline as
with quantities(item_code,quantity,expected_unit) as (values
 (1,2::numeric,'1kg'),(16,2,'1kg'),(118,3,'10 biji'),(224,4,'1 liter'),(272,4,'400 g'),(904,0.5,'10 kg'),(918,2,'1kg'),(1589,1,'1kg'),(1605,1,'±350g'),(1645,1,'180 g'),(1541,1,'1000 ml')),
end_date as (select max(date) d from public.pricecatcher),
premise_month as (select p.item_code,date_trunc('month',p.date)::date as month,p.premise_code,percentile_cont(0.5) within group(order by price) price from public.pricecatcher p,end_date where p.date>=(date_trunc('month',d)-interval '11 months')::date and p.price>=0 and p.price<'Infinity'::float4 group by 1,2,3),
national_month as (select item_code,month,percentile_cont(0.5) within group(order by price) price from premise_month group by 1,2),
representative as (select item_code,avg(price) price from national_month group by 1)
select 'cost-basket-v1'::text basket_version,q.item_code,q.quantity,i.item name,i.unit,q.expected_unit,r.price national_price,(select d from end_date) source_date from quantities q left join public.lookup_item i using(item_code) left join representative r using(item_code);
alter table public.cost_basket_baseline add primary key(basket_version,item_code);
alter table public.cost_basket_baseline enable row level security;
create policy "authenticated frozen cost baseline" on public.cost_basket_baseline for select to authenticated using(true);
revoke all on public.cost_basket_baseline from anon,authenticated;
grant select on public.cost_basket_baseline to authenticated;

create or replace function public.read_cost_inputs(input_state text,input_district text) returns jsonb language sql stable security invoker set search_path='' as $$
with end_date as (select max(source_date) d from public.cost_basket_baseline),
premise_month as (
 select p.item_code,date_trunc('month',p.date)::date as month,p.premise_code,percentile_cont(0.5) within group(order by p.price) price,count(*) records
 from public.pricecatcher p join public.lookup_premise l using(premise_code) join public.cost_basket_baseline b using(item_code),end_date
 where l.state=input_state and l.district=input_district and p.date >= (date_trunc('month',d)-interval '11 months')::date and p.date<=d and p.price>=0 and p.price<'Infinity'::float4 and replace(b.unit,'+-','±')=b.expected_unit group by 1,2,3),
local_month as (select item_code,month,percentile_cont(0.5) within group(order by price) price,count(*) premises,sum(records) records from premise_month group by 1,2),
common_cpi as (select s.date,s.index state_index,n.index national_index from public.cpi_state s join public.cpi_state n on s.date=n.date and n.state='Malaysia' and n.division='overall' where s.state=input_state and s.division='overall' and s.index>0 and n.index>0 order by s.date desc limit 1)
select jsonb_build_object('basket_version','cost-basket-v1','source_date',(select d from end_date),'baseline',(select jsonb_agg(to_jsonb(b) order by item_code) from public.cost_basket_baseline b),'months',coalesce((select jsonb_agg(to_jsonb(m) order by month,item_code) from local_month m),'[]'::jsonb),'district_income',(select income_median from public.hh_income_district where state=input_state and district=input_district order by date desc limit 1),'cpi',(select to_jsonb(c) from common_cpi c));
$$;
revoke all on function public.read_cost_inputs(text,text) from public,anon;
grant execute on function public.read_cost_inputs(text,text) to authenticated;
