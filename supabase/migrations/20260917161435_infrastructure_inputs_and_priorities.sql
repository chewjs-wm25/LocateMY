begin;
-- Add target levels; historical five 0–1 weights remain untouched and unused.
alter table public.user_ici_preferences
 add column health integer not null default 5 check (health between 1 and 10),
 add column education integer not null default 5 check (education between 1 and 10),
 add column transit integer not null default 5 check (transit between 1 and 10);
alter table public.user_ici_preferences drop constraint user_ici_preferences_user_id_fkey;
alter table public.user_ici_preferences add constraint user_ici_preferences_user_id_fkey foreign key(user_id) references auth.users(id) on delete cascade;
revoke all on public.user_ici_preferences from anon,authenticated;
grant select(user_id,health,education,transit,updated_at),insert(user_id,health,education,transit),update(health,education,transit,updated_at),delete on public.user_ici_preferences to authenticated;
create or replace function public.read_infrastructure_inputs(p_state text,p_district text)
returns jsonb language plpgsql stable security invoker set search_path = '' as $$
begin
 if auth.uid() is null then raise insufficient_privilege using message='Authentication required'; end if;
 if p_state is null or btrim(p_state)='' or p_district is null or btrim(p_district)='' then raise invalid_parameter_value using message='District required'; end if;
 return jsonb_build_object('version',1,'state',p_state,'district',p_district,
 'amenities',coalesce((select jsonb_agg(to_jsonb(x)) from (select state,district,date,piped_water,electricity from public.hh_access_amenities where state=p_state and district=p_district order by date,state,district) x),'[]'::jsonb),
 'beds',coalesce((select jsonb_agg(to_jsonb(x)) from (select state,district,date,type,beds from public.hospital_beds where district not in ('All Districts','All') order by date,state,district) x),'[]'::jsonb),
 'population',coalesce((select jsonb_agg(to_jsonb(x)) from (select state,district,date,sex,age,ethnicity,population from public.population_district where sex='both' and age='overall' and ethnicity='overall' and district not in ('All Districts','All') order by date,state,district) x),'[]'::jsonb),
 'schools',coalesce((select jsonb_agg(to_jsonb(x)) from (select state,district,date,stage,type,schools from public.schools_district where district not in ('All Districts','All') order by date,state,district) x),'[]'::jsonb),
 'teachers',coalesce((select jsonb_agg(to_jsonb(x)) from (select state,district,date,stage,sex,teachers from public.teachers_district where sex='both' and district not in ('All Districts','All') order by date,state,district) x),'[]'::jsonb),
 'enrolment',coalesce((select jsonb_agg(to_jsonb(x)) from (select state,district,date,stage,sex,students from public.enrolment_school_district where sex='both' and district not in ('All Districts','All') order by date,state,district) x),'[]'::jsonb)
 );
end;
$$;
revoke all on function public.read_infrastructure_inputs(text,text) from public,anon;
grant execute on function public.read_infrastructure_inputs(text,text) to authenticated;
notify pgrst,'reload schema';
commit;
