-- Immutable, maintainer-prepared snapshots; application roles are read-only.
create table public.gtfs_feed_snapshots (
 snapshot_id text not null, feed_id text not null, source_id text not null,
 source_url text not null, captured_at timestamptz, parse_status text not null
 check (parse_status in ('usable','missing','failed')),
 service_start date, service_end date, failure_reason text, source_sha256 text,
 primary key(snapshot_id,feed_id)
);
create table public.gtfs_stops (
 snapshot_id text not null, feed_id text not null, stop_id text not null,
 name text not null, latitude double precision not null check(latitude between -90 and 90),
 longitude double precision not null check(longitude between -180 and 180),
 location_type smallint not null default 0, parent_station text,
 station_type text not null check(station_type in ('bus','rail','ferry','other')),
 geom public.geography(Point,4326) generated always as
 (public.st_setsrid(public.st_makepoint(longitude,latitude),4326)::public.geography) stored,
 primary key(snapshot_id,feed_id,stop_id),
 foreign key(snapshot_id,feed_id) references public.gtfs_feed_snapshots
);
create index gtfs_stops_geom_idx on public.gtfs_stops using gist(geom);
create table public.gtfs_routes (
 snapshot_id text not null, feed_id text not null, route_id text not null,
 short_name text, route_type integer not null,
 primary key(snapshot_id,feed_id,route_id),
 foreign key(snapshot_id,feed_id) references public.gtfs_feed_snapshots
);
-- Compact linkage and per-service dates avoid duplicating every stop for every day.
create table public.gtfs_service_dates (
 snapshot_id text not null, feed_id text not null, service_id text not null,
 service_date date not null, active boolean not null,
 primary key(snapshot_id,feed_id,service_date,service_id),
 foreign key(snapshot_id,feed_id) references public.gtfs_feed_snapshots
);
create table public.gtfs_stop_service_links (
 snapshot_id text not null, feed_id text not null, stop_id text not null,
 route_id text not null, service_id text not null,
 primary key(snapshot_id,feed_id,stop_id,route_id,service_id),
 foreign key(snapshot_id,feed_id,stop_id) references public.gtfs_stops,
 foreign key(snapshot_id,feed_id,route_id) references public.gtfs_routes
);
create view public.gtfs_stop_services with(security_invoker=true) as
 select l.snapshot_id,l.feed_id,l.stop_id,l.route_id,d.service_date,bool_or(d.active) as active
 from public.gtfs_stop_service_links l join public.gtfs_service_dates d
 using(snapshot_id,feed_id,service_id)
 group by l.snapshot_id,l.feed_id,l.stop_id,l.route_id,d.service_date;
create table public.transit_reference_grid (
 snapshot_id text not null, reference_grid_version text not null, analysis_date date not null,
 grid_id text not null, latitude double precision not null, longitude double precision not null,
 stop_density_per_km2 double precision not null, unique_route_count integer not null,
 primary key(snapshot_id,analysis_date,grid_id)
);
create index transit_reference_grid_lookup_idx on public.transit_reference_grid(snapshot_id,analysis_date,reference_grid_version);
-- One promoted evaluation batch. Switching batches is a maintainer operation.
create table public.transit_evaluation_batches (
 snapshot_id text primary key, reference_grid_version text not null,
 promoted_at timestamptz not null default now(), expected_feed_count integer not null check(expected_feed_count=16)
);
DO $$ declare object_name text; begin
 foreach object_name in array array['gtfs_feed_snapshots','gtfs_stops','gtfs_routes',
 'gtfs_service_dates','gtfs_stop_service_links','transit_reference_grid','transit_evaluation_batches'] loop
 execute format('alter table public.%I enable row level security',object_name);
 execute format('revoke all on public.%I from public,anon,authenticated',object_name);
 execute format('grant select on public.%I to authenticated',object_name);
 execute format('grant all on public.%I to service_role',object_name);
 execute format('create policy transit_authenticated_read on public.%I for select to authenticated using ((select auth.uid()) is not null)',object_name);
 end loop;
end $$;
revoke all on public.gtfs_stop_services from public,anon,authenticated;
grant select on public.gtfs_stop_services to authenticated;
grant all on public.gtfs_stop_services to service_role;

create function public.read_transit_analysis(p_latitude double precision,p_longitude double precision,
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
 return jsonb_build_object('availability_status','unavailable','unavailable_reason','no_usable_feed','feeds','[]'::jsonb);
 end if;
 with feed_status as materialized (
 select f.*,case when parse_status='missing' then 'missing' when parse_status='failed' then 'failed'
 when p_analysis_date not between service_start and service_end then 'out_of_service_range'
 when captured_at < greatest(now(),p_analysis_date::timestamptz)-interval '30 days' then 'stale'
 else 'usable' end as availability
 from public.gtfs_feed_snapshots f where snapshot_id=batch.snapshot_id
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
 when usable_feeds<16 or feeds<>16 then 'incomplete'
 when grid_count=0 then 'unavailable' else 'available' end,
 'unavailable_reason',case when grid_count=0 and usable_feeds=16 then 'source_unverifiable'
 when usable_feeds=0 and exists(select 1 from feed_status where availability='out_of_service_range') then 'analysis_date_outside_service_range'
 else 'no_usable_feed' end,
 'service_outcome',case when stops=0 then 'no_stops' when routes=0 then 'no_active_routes' else 'served' end,
 'unique_stop_count',stops,'nearest_distance_m',round(nearest)::integer,'unique_route_count',routes,
 'stop_density_per_km2',stops/(pi()*2.25),
 'density_percentile',density_percentile,'route_percentile',route_percentile,
 'transit_score',case when usable_feeds=16 and feeds=16 and grid_count>0 and stops>0 and routes>0
 then round(0.5*(100*(1-nearest/1500))+0.25*density_percentile+0.25*route_percentile)::integer else null end,
 'stations',coalesce((select jsonb_agg(jsonb_build_object('feed_id',feed_id,'stop_id',stop_id,'name',name,
 'latitude',latitude,'longitude',longitude,'station_type',station_type,'distance_m',round(distance)::integer,
 'parent_station',parent_station) order by distance,feed_id,stop_id) from scoped_stops),'[]'::jsonb),
 'feeds',coalesce((select jsonb_agg(jsonb_build_object('feed_id',feed_id,'source_id',source_id,'source_url',source_url,
 'captured_at',captured_at,'availability',availability,'reason',case when availability='out_of_service_range'
 then 'Analysis date outside the feed service range' else failure_reason end) order by feed_id) from feed_status),'[]'::jsonb)
 ) into result from metrics cross join percentiles;
 return result;
end $$;
revoke all on function public.read_transit_analysis(double precision,double precision,date,boolean) from public,anon;
grant execute on function public.read_transit_analysis(double precision,double precision,date,boolean) to authenticated;
create view public.transit_analysis_results with(security_invoker=true) as
 select snapshot_id,reference_grid_version,analysis_date,grid_id,latitude,longitude,
 stop_density_per_km2,unique_route_count from public.transit_reference_grid;
revoke all on public.transit_analysis_results from public,anon;
grant select on public.transit_analysis_results to authenticated;
