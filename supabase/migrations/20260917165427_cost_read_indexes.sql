create index if not exists lookup_premise_cost_district_idx on public.lookup_premise(state,district,premise_code);
create index if not exists pricecatcher_cost_premise_idx on public.pricecatcher(premise_code,item_code,date) include(price);
analyze public.pricecatcher;
analyze public.lookup_premise;
