create or replace function public.hazard_pending_count(p_latitude double precision, p_longitude double precision)
returns jsonb language plpgsql security invoker set search_path = '' as $$
declare n integer;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='PT401'; end if;
  if p_latitude is null or p_longitude is null or p_latitude not between -90 and 90 or p_longitude not between -180 and 180 then
    raise exception 'Invalid coordinate' using errcode='22023'; end if;
  if not exists (select 1 from public.read_administrative_boundary_candidates(p_latitude,p_longitude)) then
    raise exception 'Outside Malaysia' using errcode='22023'; end if;
  -- Product Haversine convention: spherical Earth radius 6,371,000 metres.
  select count(*)::integer into n from public.crowdsourced_hazards h where status='pending'
    and 2*6371000*asin(sqrt(least(1.0,
      power(sin(radians(public.st_y(h.location)-p_latitude)/2),2) +
      cos(radians(p_latitude))*cos(radians(public.st_y(h.location))) *
      power(sin(radians(public.st_x(h.location)-p_longitude)/2),2)))) <= 2000;
  return jsonb_build_object('count',n,'radius_meters',2000,'counted_at',now(),'complete',true);
end;
$$;
