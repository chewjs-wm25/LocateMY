-- Expose the same canonical RPC facts, rather than mislabeling grid baselines as results.
-- Flutter continues to use the parameterized RPC, not this maintainer inspection view.
create or replace view public.transit_analysis_results with(security_invoker=true) as
select g.snapshot_id,g.reference_grid_version,g.analysis_date,g.grid_id,g.latitude,g.longitude,
 (a.result->>'stop_density_per_km2')::double precision as stop_density_per_km2,
 (a.result->>'unique_route_count')::integer as unique_route_count,a.result as canonical_result
from public.transit_reference_grid g
join (select snapshot_id,reference_grid_version from public.transit_evaluation_batches
 order by promoted_at desc,snapshot_id desc limit 1) b using(snapshot_id,reference_grid_version)
cross join lateral (select public.read_transit_analysis(g.latitude,g.longitude,g.analysis_date,false) as result) a;
revoke all on public.transit_analysis_results from public,anon;
grant select on public.transit_analysis_results to authenticated;
