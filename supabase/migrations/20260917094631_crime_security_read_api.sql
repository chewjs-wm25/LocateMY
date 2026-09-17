-- Official CSV audited against the existing canonical mirror (19,152 rows).
-- No data replacement. The pinned digest fails closed after unreviewed imports.
revoke all on public.crime_district from anon;
revoke insert, update, delete, truncate, references, trigger on public.crime_district from authenticated;
grant select on public.crime_district to authenticated;
alter table public.crime_district enable row level security;

create or replace function public.read_safety_inputs()
returns jsonb language sql stable security invoker set search_path = ''
as $$
  with verification as (
    select count(*) = 19152 and
      md5(string_agg(concat_ws('|',date,state,district,category,type,crimes),E'\n'
        order by date,state,district,category,type)) = 'efb060e86024b8bd70eb32fbfd759e74' as verified
    from public.crime_district
  ), leaf_counts as (
    select extract(year from date)::integer as year,state,category,type,
      case when bool_and(crimes >= 0) then sum(crimes) else null end as crimes
    from public.crime_district
    where state <> 'Malaysia' and lower(district) <> 'all' and lower(type) <> 'all'
      and category in ('assault','property')
      and date between '2019-01-01'::date and '2023-01-01'::date
    group by date,state,category,type
  )
  select jsonb_build_object(
    'version',1,'dataset_id','crime_district',
    'source_url','https://storage.data.gov.my/publicsafety/crime_district.csv',
    'source_sha256','800d488b426cd02f068179c626f7b4d2c5ba024f5b4b838fb0986fb7001c31be',
    'verified',(select verified from verification),
    'latest_complete_year',2023,
    'rows',coalesce((select jsonb_agg(to_jsonb(l) order by year,state,category,type) from leaf_counts l),'[]'::jsonb)
  );
$$;
revoke all on function public.read_safety_inputs() from public, anon;
grant execute on function public.read_safety_inputs() to authenticated;
comment on function public.read_safety_inputs() is 'Read-only audited crime_district leaf counts; snapshot 2016-2023; statewide aggregation; no population or police boundaries.';
