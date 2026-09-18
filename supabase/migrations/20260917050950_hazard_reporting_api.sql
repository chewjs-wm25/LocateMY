-- Author identities are Auth accounts; profile registration is optional.
-- Validate replacement FKs before removing the legacy profile dependency.
do $$ begin
  if not exists(select 1 from pg_constraint where conrelid='public.crowdsourced_hazards'::regclass and conname='crowdsourced_hazards_author_account_fkey') then
    alter table public.crowdsourced_hazards add constraint crowdsourced_hazards_author_account_fkey foreign key(user_id) references auth.users(id) not valid;
  end if;
  if not exists(select 1 from pg_constraint where conrelid='public.crowdsourced_hazard_votes'::regclass and conname='crowdsourced_hazard_votes_account_fkey') then
    alter table public.crowdsourced_hazard_votes add constraint crowdsourced_hazard_votes_account_fkey foreign key(user_id) references auth.users(id) on delete cascade not valid;
  end if;
end $$;
alter table public.crowdsourced_hazards validate constraint crowdsourced_hazards_author_account_fkey;
alter table public.crowdsourced_hazard_votes validate constraint crowdsourced_hazard_votes_account_fkey;
alter table public.crowdsourced_hazards drop constraint if exists crowdsourced_hazards_user_id_fkey;
alter table public.crowdsourced_hazard_votes drop constraint if exists crowdsourced_hazard_votes_user_id_fkey;

-- Wave 5: online-only, authenticated public reports and author-only management.
-- Keep published content/time immutable even when accessed outside the RPCs.
create or replace function public.hazard_prevent_content_mutation()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.user_id is distinct from old.user_id or new.hazard_type is distinct from old.hazard_type
     or new.title is distinct from old.title or new.description is distinct from old.description
     or public.st_asewkb(new.location) is distinct from public.st_asewkb(old.location) or new.report_time is distinct from old.report_time then
    raise exception 'Published hazard content is immutable' using errcode = '42501';
  end if;
  return new;
end;
$$;
drop trigger if exists crowdsourced_hazards_immutable on public.crowdsourced_hazards;
create trigger crowdsourced_hazards_immutable before update on public.crowdsourced_hazards
for each row execute function public.hazard_prevent_content_mutation();
revoke insert, update on public.crowdsourced_hazards from authenticated;
grant insert (user_id, hazard_type, title, description, location) on public.crowdsourced_hazards to authenticated;
grant update (status) on public.crowdsourced_hazards to authenticated;

-- The legacy invoker view could only count the caller's votes. Aggregate RPC
-- reveals counts alone; caller's own choice remains protected by normal RLS.
drop view if exists public.hazard_vote_counts;
create or replace function public.hazard_vote_counts(p_id uuid)
returns jsonb language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='PT401'; end if;
  if not exists(select 1 from public.crowdsourced_hazards where id=p_id) then
    raise exception 'Hazard not found' using errcode='P0002';
  end if;
  return (select jsonb_build_object('upvotes', count(*) filter(where vote=1),
    'downvotes', count(*) filter(where vote=-1)) from public.crowdsourced_hazard_votes where hazard_id=p_id);
end;
$$;

create or replace function public.hazard_detail(p_id uuid)
returns jsonb language plpgsql security invoker set search_path = '' as $$
declare h public.crowdsourced_hazards; counts jsonb; my_vote smallint;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='PT401'; end if;
  select * into h from public.crowdsourced_hazards where id=p_id;
  if not found then raise exception 'Hazard not found' using errcode='P0002'; end if;
  counts := public.hazard_vote_counts(p_id);
  select vote into my_vote from public.crowdsourced_hazard_votes where hazard_id=p_id and user_id=auth.uid();
  return jsonb_build_object('id', h.id, 'type', h.hazard_type, 'title', h.title, 'description', h.description,
    'latitude', public.st_y(h.location), 'longitude', public.st_x(h.location), 'status', h.status,
    'reported_at', h.report_time, 'author', case when h.user_id=auth.uid() then 'mine' else 'other' end,
    'vote', counts || jsonb_build_object('mine', case my_vote when 1 then 'up' when -1 then 'down' else 'none' end));
end;
$$;

create or replace function public.hazard_create(p_type text, p_title text, p_description text,
 p_latitude double precision, p_longitude double precision)
returns jsonb language plpgsql security invoker set search_path = '' as $$
declare new_id uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='PT401'; end if;
  if p_type is null or p_type not in ('flood','crime','traffic','infrastructure','other') then
    raise exception 'Invalid type' using errcode='22023'; end if;
  if p_title is null or char_length(btrim(p_title)) not between 1 and 120 or char_length(p_description)>2000 then
    raise exception 'Invalid content' using errcode='22023'; end if;
  if p_latitude is null or p_longitude is null or p_latitude not between -90 and 90 or p_longitude not between -180 and 180 then
    raise exception 'Invalid coordinate' using errcode='22023'; end if;
  if not exists(select 1 from public.read_administrative_boundary_candidates(p_latitude,p_longitude)) then
    raise exception 'Invalid coordinate outside Malaysia' using errcode='22023'; end if;
  insert into public.crowdsourced_hazards(user_id,hazard_type,title,description,location)
    values(auth.uid(),p_type,btrim(p_title),p_description,public.st_setsrid(public.st_makepoint(p_longitude,p_latitude),4326)) returning id into new_id;
  return public.hazard_detail(new_id);
end;
$$;

create or replace function public.hazard_page(p_mine boolean, p_south double precision, p_west double precision,
 p_north double precision, p_east double precision, p_cursor uuid default null)
returns jsonb language plpgsql security invoker set search_path = '' as $$
declare ids uuid[]; page_ids uuid[]; result jsonb := '[]'; item uuid; cursor_time timestamptz;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='PT401'; end if;
  if p_mine is null or p_south is null or p_west is null or p_north is null or p_east is null
    or p_south not between -90 and 90 or p_north not between -90 and 90
    or p_west not between -180 and 180 or p_east not between -180 and 180 or p_south>p_north or p_west>p_east then
    raise exception 'Invalid viewport' using errcode='22023'; end if;
  if p_cursor is not null then
    select report_time into cursor_time from public.crowdsourced_hazards where id=p_cursor;
    if not found then raise exception 'Expired cursor' using errcode='22023'; end if;
  end if;
  select array_agg(id order by report_time desc,id desc) into ids from (
    select id,report_time from public.crowdsourced_hazards h
    where (not p_mine or h.user_id=auth.uid())
      and public.st_intersects(h.location,public.st_makeenvelope(p_west,p_south,p_east,p_north,4326))
      and (p_cursor is null or (h.report_time,h.id)<(cursor_time,p_cursor))
    order by report_time desc,id desc limit 51) q;
  page_ids := ids[1:50];
  foreach item in array coalesce(page_ids,'{}'::uuid[]) loop
    result := result || jsonb_build_array(public.hazard_detail(item));
  end loop;
  return jsonb_build_object('reports',result,'next_cursor',case when array_length(ids,1)>50 then ids[50] else null end);
end;
$$;

create or replace function public.hazard_status(p_id uuid, p_status text)
returns jsonb language plpgsql security invoker set search_path = '' as $$
declare owner_id uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='PT401'; end if;
  select user_id into owner_id from public.crowdsourced_hazards where id=p_id;
  if not found then raise exception 'Hazard not found' using errcode='P0002'; end if;
  if owner_id<>auth.uid() then raise exception 'Author required' using errcode='42501'; end if;
  if p_status is null or p_status not in ('pending','resolved') then raise exception 'Invalid status' using errcode='22023'; end if;
  update public.crowdsourced_hazards set status=p_status where id=p_id and user_id=auth.uid();
  if not found then raise exception 'Hazard no longer exists' using errcode='P0002'; end if;
  return public.hazard_detail(p_id);
end;
$$;
create or replace function public.hazard_delete(p_id uuid)
returns boolean language plpgsql security invoker set search_path = '' as $$
declare owner_id uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='PT401'; end if;
  select user_id into owner_id from public.crowdsourced_hazards where id=p_id;
  if not found then raise exception 'Hazard not found' using errcode='P0002'; end if;
  if owner_id<>auth.uid() then raise exception 'Author required' using errcode='42501'; end if;
  delete from public.crowdsourced_hazards where id=p_id and user_id=auth.uid();
  if not found then raise exception 'Hazard no longer exists' using errcode='P0002'; end if;
  return true;
end;
$$;
create or replace function public.hazard_vote(p_id uuid, p_vote text)
returns jsonb language plpgsql security invoker set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='PT401'; end if;
  if p_vote is null or p_vote not in ('up','down','none') then raise exception 'Invalid vote' using errcode='22023'; end if;
  perform id from public.crowdsourced_hazards where id=p_id;
  if not found then raise exception 'Hazard not found' using errcode='P0002'; end if;
  if p_vote='none' then delete from public.crowdsourced_hazard_votes where hazard_id=p_id and user_id=auth.uid();
  else insert into public.crowdsourced_hazard_votes(hazard_id,user_id,vote)
    values(p_id,auth.uid(),case p_vote when 'up' then 1 else -1 end)
    on conflict(hazard_id,user_id) do update set vote=excluded.vote; end if;
  return public.hazard_vote_counts(p_id) || jsonb_build_object('mine',p_vote);
end;
$$;
create or replace function public.hazard_pending_count(p_latitude double precision, p_longitude double precision)
returns jsonb language plpgsql security invoker set search_path = '' as $$
declare n integer;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='PT401'; end if;
  if p_latitude is null or p_longitude is null or p_latitude not between -90 and 90 or p_longitude not between -180 and 180 then
    raise exception 'Invalid coordinate' using errcode='22023'; end if;
  -- Product Haversine convention: spherical Earth radius 6,371,000 metres.
  select count(*)::integer into n from public.crowdsourced_hazards h where status='pending'
    and 2*6371000*asin(sqrt(least(1.0,
      power(sin(radians(public.st_y(h.location)-p_latitude)/2),2) +
      cos(radians(p_latitude))*cos(radians(public.st_y(h.location))) *
      power(sin(radians(public.st_x(h.location)-p_longitude)/2),2)))) <= 2000;
  return jsonb_build_object('count',n,'radius_meters',2000,'counted_at',now(),'complete',true);
end;
$$;

-- No default/anonymous EXECUTE, including the trigger helper.
revoke all on function public.hazard_prevent_content_mutation() from public, anon, authenticated;
revoke all on function public.hazard_vote_counts(uuid), public.hazard_detail(uuid),
 public.hazard_create(text,text,text,double precision,double precision),
 public.hazard_page(boolean,double precision,double precision,double precision,double precision,uuid),
 public.hazard_status(uuid,text), public.hazard_delete(uuid), public.hazard_vote(uuid,text),
 public.hazard_pending_count(double precision,double precision) from public, anon;
grant execute on function public.hazard_vote_counts(uuid), public.hazard_detail(uuid),
 public.hazard_create(text,text,text,double precision,double precision),
 public.hazard_page(boolean,double precision,double precision,double precision,double precision,uuid),
 public.hazard_status(uuid,text), public.hazard_delete(uuid), public.hazard_vote(uuid,text),
 public.hazard_pending_count(double precision,double precision) to authenticated;
