-- Partial sources retain observed scoring; missing reference components are excluded, never zero-filled.
create or replace function public.read_transit_analysis(p_latitude double precision,p_longitude double precision,
 p_analysis_date date,p_refresh boolean default false) returns jsonb
 language plpgsql stable security invoker set search_path='' as $$
declare batch public.transit_evaluation_batches%rowtype; result jsonb;
begin
 if auth.uid() is null then raise insufficient_privilege; end if;
 if p_latitude is null or p_longitude is null or p_analysis_date is null or
 p_latitude not between -90 and 90 or p_longitude not between -180 and 180 then
 raise exception 'Invalid transit request' using errcode='22023'; end if;
 select * into batch from public.transit_evaluation_batches order by promoted_at desc,snapshot_id desc limit 1;
 if batch.snapshot_id is null then
 return jsonb_build_object('availability_status','unavailable','unavailable_reason','no_usable_feed',
 'feeds',(select jsonb_agg(jsonb_build_object('feed_id',feed_id,'source_id',feed_id,
 'source_url',source_url,'captured_at',null,'availability','missing','reason','No promoted evaluation batch') order by feed_id)
 from (values
('gtfs_static_ktmb','https://api.data.gov.my/gtfs-static/ktmb'),
('gtfs_static_prasarana_rapid_rail_kl','https://api.data.gov.my/gtfs-static/prasarana?category=rapid-rail-kl'),
('gtfs_static_prasarana_rapid_bus_kl','https://api.data.gov.my/gtfs-static/prasarana?category=rapid-bus-kl'),
('gtfs_static_prasarana_rapid_bus_penang','https://api.data.gov.my/gtfs-static/prasarana?category=rapid-bus-penang'),
('gtfs_static_prasarana_rapid_bus_kuantan','https://api.data.gov.my/gtfs-static/prasarana?category=rapid-bus-kuantan'),
('gtfs_static_prasarana_rapid_bus_mrtfeeder','https://api.data.gov.my/gtfs-static/prasarana?category=rapid-bus-mrtfeeder'),
('gtfs_static_mybas_kangar','https://api.data.gov.my/gtfs-static/mybas-kangar'),
('gtfs_static_mybas_alor_setar','https://api.data.gov.my/gtfs-static/mybas-alor-setar'),
('gtfs_static_mybas_kota_bharu','https://api.data.gov.my/gtfs-static/mybas-kota-bharu'),
('gtfs_static_mybas_kuala_terengganu','https://api.data.gov.my/gtfs-static/mybas-kuala-terengganu'),
('gtfs_static_mybas_ipoh','https://api.data.gov.my/gtfs-static/mybas-ipoh'),
('gtfs_static_mybas_seremban_a','https://api.data.gov.my/gtfs-static/mybas-seremban-a'),
('gtfs_static_mybas_seremban_b','https://api.data.gov.my/gtfs-static/mybas-seremban-b'),
('gtfs_static_mybas_melaka','https://api.data.gov.my/gtfs-static/mybas-melaka'),
('gtfs_static_mybas_johor','https://api.data.gov.my/gtfs-static/mybas-johor'),
('gtfs_static_mybas_kuching','https://api.data.gov.my/gtfs-static/mybas-kuching')
 ) expected(feed_id,source_url)));
 end if;
 with expected_feeds(feed_id,source_url) as (values
('gtfs_static_ktmb','https://api.data.gov.my/gtfs-static/ktmb'),
('gtfs_static_prasarana_rapid_rail_kl','https://api.data.gov.my/gtfs-static/prasarana?category=rapid-rail-kl'),
('gtfs_static_prasarana_rapid_bus_kl','https://api.data.gov.my/gtfs-static/prasarana?category=rapid-bus-kl'),
('gtfs_static_prasarana_rapid_bus_penang','https://api.data.gov.my/gtfs-static/prasarana?category=rapid-bus-penang'),
('gtfs_static_prasarana_rapid_bus_kuantan','https://api.data.gov.my/gtfs-static/prasarana?category=rapid-bus-kuantan'),
('gtfs_static_prasarana_rapid_bus_mrtfeeder','https://api.data.gov.my/gtfs-static/prasarana?category=rapid-bus-mrtfeeder'),
('gtfs_static_mybas_kangar','https://api.data.gov.my/gtfs-static/mybas-kangar'),
('gtfs_static_mybas_alor_setar','https://api.data.gov.my/gtfs-static/mybas-alor-setar'),
('gtfs_static_mybas_kota_bharu','https://api.data.gov.my/gtfs-static/mybas-kota-bharu'),
('gtfs_static_mybas_kuala_terengganu','https://api.data.gov.my/gtfs-static/mybas-kuala-terengganu'),
('gtfs_static_mybas_ipoh','https://api.data.gov.my/gtfs-static/mybas-ipoh'),
('gtfs_static_mybas_seremban_a','https://api.data.gov.my/gtfs-static/mybas-seremban-a'),
('gtfs_static_mybas_seremban_b','https://api.data.gov.my/gtfs-static/mybas-seremban-b'),
('gtfs_static_mybas_melaka','https://api.data.gov.my/gtfs-static/mybas-melaka'),
('gtfs_static_mybas_johor','https://api.data.gov.my/gtfs-static/mybas-johor'),
('gtfs_static_mybas_kuching','https://api.data.gov.my/gtfs-static/mybas-kuching')
 ), feed_status as materialized (
 select e.feed_id,e.feed_id as source_id,
 e.source_url as source_url,f.captured_at,
 coalesce(f.failure_reason,case when f.feed_id is null then 'Expected feed snapshot missing'
 when f.source_id<>e.feed_id or f.source_url<>e.source_url then 'Snapshot source metadata does not match the official registry' end) as failure_reason,
 case when f.feed_id is null then 'missing'
 when f.source_id<>e.feed_id or f.source_url<>e.source_url then 'failed'
 when parse_status='missing' then 'missing'
 when parse_status='failed' or captured_at is null or service_start is null or service_end is null then 'failed'
 when p_analysis_date not between service_start and service_end then 'out_of_service_range'
 when captured_at < greatest(now(),p_analysis_date::timestamptz)-interval '30 days' then 'stale'
 else 'usable' end as availability
 from expected_feeds e left join public.gtfs_feed_snapshots f
 on f.feed_id=e.feed_id and f.snapshot_id=batch.snapshot_id
 ), usable as (select feed_id from feed_status where availability in ('usable','stale')),
 scoped_stops as materialized (
 select s.*,public.st_distance(s.geom,public.st_setsrid(public.st_makepoint(p_longitude,p_latitude),4326)::public.geography) as distance
 from public.gtfs_stops s join usable u using(feed_id)
 where s.snapshot_id=batch.snapshot_id and location_type=0
 and public.st_dwithin(s.geom,public.st_setsrid(public.st_makepoint(p_longitude,p_latitude),4326)::public.geography,1500)
 ), active_routes as (
 select distinct l.feed_id,l.route_id from public.gtfs_stop_service_links l
 join scoped_stops s using(snapshot_id,feed_id,stop_id)
 join public.gtfs_service_dates d using(snapshot_id,feed_id,service_id)
 where d.service_date=p_analysis_date and d.active
 ), metrics as (
 select (select count(*) from scoped_stops)::integer as stops,
 (select min(distance) from scoped_stops) as nearest,
 (select count(*) from active_routes)::integer as routes,
 (select count(*) from usable) as usable_feeds,
 (select count(*) from feed_status) as feeds
 ), grid as (
 select * from public.transit_reference_grid where snapshot_id=batch.snapshot_id
 and reference_grid_version=batch.reference_grid_version and analysis_date=p_analysis_date
 ), percentiles as (
 select count(*) as grid_count,
 100.0*count(*) filter(where stop_density_per_km2 <= metrics.stops/(pi()*2.25))/nullif(count(*),0) as density_percentile,
 100.0*count(*) filter(where unique_route_count <= metrics.routes)/nullif(count(*),0) as route_percentile
 from grid cross join metrics
 )
 select jsonb_build_object(
 'snapshot_id',batch.snapshot_id,'reference_grid_version',batch.reference_grid_version,'generated_at',now(),
 'analysis_date',p_analysis_date,'latitude',p_latitude,'longitude',p_longitude,'radius_m',1500,
 'availability_status',case when usable_feeds=0 then 'unavailable'
 when usable_feeds<16 or feeds<>16 or grid_count=0 then 'incomplete' else 'available' end,
 'unavailable_reason',case when grid_count=0 and usable_feeds=16 then 'source_unverifiable'
 when usable_feeds=0 and exists(select 1 from feed_status where availability='out_of_service_range') then 'analysis_date_outside_service_range'
 else 'no_usable_feed' end,
 'service_outcome',case when stops=0 then 'no_stops' when routes=0 then 'no_active_routes' else 'served' end,
 'unique_stop_count',stops,'nearest_distance_m',round(nearest)::integer,'unique_route_count',routes,
 'stop_density_per_km2',stops/(pi()*2.25),
 'density_percentile',density_percentile,'route_percentile',route_percentile,
 'score_basis',case when grid_count=0 then 'distance_only' else 'full_formula' end,
 'transit_score',case when usable_feeds>0 and stops>0 and routes>0
 then case when grid_count>0
 then round(0.5*(100*(1-nearest/1500))+0.25*density_percentile+0.25*route_percentile)::integer
 else round(100*(1-nearest/1500))::integer end else null end,
 'stations',coalesce((select jsonb_agg(jsonb_build_object('feed_id',feed_id,'stop_id',stop_id,'name',name,
 'latitude',latitude,'longitude',longitude,'station_type',station_type,'distance_m',round(distance)::integer,
 'parent_station',parent_station,
 'routes',coalesce((select jsonb_agg(jsonb_build_object('route_id',r.route_id,
 'route_short_name',r.short_name,'route_type',r.route_type,'service_active',coalesce(a.active,false)) order by r.route_id)
 from (select distinct route_id from public.gtfs_stop_service_links l
 where l.snapshot_id=s.snapshot_id and l.feed_id=s.feed_id and l.stop_id=s.stop_id) links
 join public.gtfs_routes r on r.snapshot_id=s.snapshot_id and r.feed_id=s.feed_id and r.route_id=links.route_id
 left join lateral (select bool_or(d.active) as active from public.gtfs_stop_service_links l
 join public.gtfs_service_dates d using(snapshot_id,feed_id,service_id)
 where l.snapshot_id=s.snapshot_id and l.feed_id=s.feed_id and l.stop_id=s.stop_id
 and l.route_id=r.route_id and d.service_date=p_analysis_date) a on true),'[]'::jsonb))
 order by distance,feed_id,stop_id) from scoped_stops s),'[]'::jsonb),
 'feeds',coalesce((select jsonb_agg(jsonb_build_object('feed_id',feed_id,'source_id',source_id,'source_url',source_url,
 'captured_at',captured_at,'availability',availability,'reason',case when availability='out_of_service_range'
 then 'Analysis date outside the feed service range' else failure_reason end) order by feed_id) from feed_status),'[]'::jsonb)
 ) into result from metrics cross join percentiles;
 return result;
end $$;
