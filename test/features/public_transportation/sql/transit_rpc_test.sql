begin;
delete from public.transit_evaluation_batches;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
do $$ declare result jsonb; begin
 result=public.read_transit_analysis(3.0738,101.6077,'2026-09-17',true);
 if result->>'availability_status'<>'unavailable' or jsonb_array_length(result->'feeds')<>16 then
 raise exception 'No promoted batch must preserve all expected missing feeds'; end if;
end $$;
reset role;
insert into public.transit_evaluation_batches values('test-transit-rpc','test-grid',now()+interval '1 day',16);
insert into public.gtfs_feed_snapshots(snapshot_id,feed_id,source_id,source_url,captured_at,parse_status,service_start,service_end)
select 'test-transit-rpc',feed_id,feed_id,source_url,now(),'usable','2026-09-01','2026-09-30' from (values
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
('gtfs_static_mybas_kuching','https://api.data.gov.my/gtfs-static/mybas-kuching')) expected(feed_id,source_url);
insert into public.gtfs_stops(snapshot_id,feed_id,stop_id,name,latitude,longitude,station_type)
values('test-transit-rpc','gtfs_static_ktmb','stop-1','Test station',3.0738,101.6077,'bus');
insert into public.gtfs_routes values('test-transit-rpc','gtfs_static_ktmb','route-1','R1',3);
insert into public.gtfs_stop_service_links values('test-transit-rpc','gtfs_static_ktmb','stop-1','route-1','weekday');
insert into public.gtfs_service_dates values('test-transit-rpc','gtfs_static_ktmb','weekday','2026-09-17',true);
insert into public.transit_reference_grid values
('test-transit-rpc','test-grid','2026-09-17','g1',3,101,0,0),
('test-transit-rpc','test-grid','2026-09-17','g2',3,101,0,1),
('test-transit-rpc','test-grid','2026-09-17','g3',3,101,1,2),
('test-transit-rpc','test-grid','2026-09-17','g4',3,101,2,3);
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
do $$ declare result jsonb; begin
 result=public.read_transit_analysis(3.0738,101.6077,'2026-09-17',true);
 if result->>'availability_status'<>'available' or result->>'transit_score'<>'75' or
 result->>'unique_stop_count'<>'1' or result->>'unique_route_count'<>'1' then
 raise exception 'Public served facts differ from independently worked scoring example: %',result;
 end if;
end $$;
reset role;
-- Failed expected feed retains successful stations and suppresses scoring.
update public.gtfs_feed_snapshots set parse_status='failed',failure_reason='test parse failure'
where snapshot_id='test-transit-rpc' and feed_id='gtfs_static_mybas_kuching';
set local role authenticated;
do $$ declare result jsonb; begin
 result=public.read_transit_analysis(3.0738,101.6077,'2026-09-17',true);
 if result->>'availability_status'<>'incomplete' or result->>'transit_score' is not null or
 result->>'unique_stop_count'<>'1' then raise exception 'Partial feed matrix violated'; end if;
end $$;
reset role;
update public.gtfs_feed_snapshots set parse_status='usable',failure_reason=null where snapshot_id='test-transit-rpc';
-- A exactly 30 day old snapshot remains usable, then becomes stale after the boundary.
update public.gtfs_feed_snapshots set captured_at=now()-interval '30 days' where snapshot_id='test-transit-rpc';
set local role authenticated;
do $$ declare result jsonb; begin
 result=public.read_transit_analysis(3.0738,101.6077,'2026-09-17',true);
 if exists(select 1 from jsonb_array_elements(result->'feeds')f where f->>'availability'<>'usable') then
 raise exception 'Exactly 30 days should be usable'; end if;
end $$;
reset role;
update public.gtfs_feed_snapshots set captured_at=now()-interval '30 days 1 second' where snapshot_id='test-transit-rpc';
set local role authenticated;
do $$ declare result jsonb; begin
 result=public.read_transit_analysis(3.0738,101.6077,'2026-09-17',true);
 if result->>'availability_status'<>'available' or result->>'transit_score'<>'75' or
 exists(select 1 from jsonb_array_elements(result->'feeds')f where f->>'availability'<>'stale') then
 raise exception 'Stale remains scoreable and explicitly marked'; end if;
 result=public.read_transit_analysis(3.2,101.7,'2026-09-17',true);
 if result->>'service_outcome'<>'no_stops' or result->>'transit_score' is not null or
 result->>'unique_stop_count'<>'0' then raise exception 'Known zero stops must not become score zero'; end if;
 result=public.read_transit_analysis(3.0738,101.6077,'2040-01-01',true);
 if result->>'availability_status'<>'unavailable' or result->>'unavailable_reason'<>'analysis_date_outside_service_range' then
 raise exception 'Date range failure must not become a service observation'; end if;
end $$;
reset role;
update public.gtfs_service_dates set active=false where snapshot_id='test-transit-rpc';
set local role authenticated;
do $$ declare result jsonb; begin
 result=public.read_transit_analysis(3.0738,101.6077,'2026-09-17',true);
 if result->>'service_outcome'<>'no_active_routes' or result->>'transit_score' is not null or
 result->>'unique_stop_count'<>'1' then raise exception 'Known zero active routes must retain stops without scoring'; end if;
end $$;
reset role;
delete from public.gtfs_feed_snapshots where snapshot_id='test-transit-rpc' and feed_id='gtfs_static_mybas_kuching';
set local role authenticated;
do $$ declare result jsonb; begin
 result=public.read_transit_analysis(3.0738,101.6077,'2026-09-17',true);
 if jsonb_array_length(result->'feeds')<>16 or not exists
 (select 1 from jsonb_array_elements(result->'feeds') f where f->>'availability'='missing') then
 raise exception 'Every expected feed must retain an individual status'; end if;
 if result#>>'{stations,0,routes,0,route_type}'<>'3' or
 result#>>'{stations,0,routes,0,route_short_name}'<>'R1' or
 result#>>'{stations,0,routes,0,service_active}'<>'false' then
 raise exception 'Raw route facts must remain traceable'; end if;
end $$;
reset role;
update public.gtfs_feed_snapshots set source_url='https://wrong.example.invalid'
 where snapshot_id='test-transit-rpc' and feed_id='gtfs_static_ktmb';
set local role authenticated;
do $$ declare result jsonb; begin
 result=public.read_transit_analysis(3.0738,101.6077,'2026-09-17',true);
 if result->>'availability_status'<>'incomplete' or result->>'unique_stop_count'<>'0' or not exists
 (select 1 from jsonb_array_elements(result->'feeds') f where f->>'feed_id'='gtfs_static_ktmb'
 and f->>'availability'='failed' and f->>'source_url'='https://api.data.gov.my/gtfs-static/ktmb') then
 raise exception 'Incorrect snapshot metadata must not create usable facts or publish incorrect provenance'; end if;
end $$;
reset role;
update public.gtfs_feed_snapshots set parse_status='missing'
 where snapshot_id='test-transit-rpc' and feed_id='gtfs_static_ktmb';
set local role authenticated;
do $$ declare result jsonb; begin
 result=public.read_transit_analysis(3.0738,101.6077,'2026-09-17',true);
 if not exists(select 1 from jsonb_array_elements(result->'feeds') f
 where f->>'feed_id'='gtfs_static_ktmb' and f->>'availability'='failed') then
 raise exception 'Present missing snapshot with incorrect identity must be failed'; end if;
end $$;
rollback;

