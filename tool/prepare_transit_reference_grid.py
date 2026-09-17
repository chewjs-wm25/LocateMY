#!/usr/bin/env python3
"""Manual fixed-grid preparation from a validated snapshot; never runs in Flutter."""
import argparse,csv,datetime,hashlib,io,json,math,subprocess,urllib.parse,urllib.request
from pathlib import Path
from import_home_datasets import read_values

ROOT=Path('build/transit-wave5-evidence')
VERSION='utm-wgs84-1km-stopcatchment-v1'
TABLES={
 'gtfs_feed_snapshots':['snapshot_id','feed_id','source_id','source_url','captured_at','parse_status','failure_reason','service_start','service_end','source_sha256'],
 'gtfs_stops':['snapshot_id','feed_id','stop_id','name','latitude','longitude','location_type','parent_station','station_type'],
 'gtfs_routes':['snapshot_id','feed_id','route_id','short_name','route_type'],
 'gtfs_service_dates':['snapshot_id','feed_id','service_id','service_date','active'],
 'gtfs_stop_service_links':['snapshot_id','feed_id','stop_id','route_id','service_id'],
}

def local(sql):
    result=subprocess.run(['docker','exec','-i','supabase_db_LocateMY','psql','-qAt','-U','postgres','-d','postgres','-v','ON_ERROR_STOP=1'],input=sql,text=True,capture_output=True)
    if result.returncode:raise RuntimeError('Local preparation failed: '+result.stderr[-1500:])
    return result.stdout.strip()

def prepare(snapshot,day):
    normalized=json.loads((ROOT/'normalized-snapshot.json').read_text())
    if any(row['snapshot_id']!=snapshot for records in normalized.values() for row in records):
        raise RuntimeError('Normalized input must match the requested immutable snapshot')
    audit=json.loads((ROOT/'official-download-audit.json').read_text())
    for item in audit:
        if 'failure' not in item:
            actual=hashlib.sha256((ROOT/'official-feeds'/(item['feed_id']+'.zip')).read_bytes()).hexdigest()
            if actual!=item['sha256']:raise RuntimeError('Source ZIP hash mismatch')
    if local("select count(*) from public.gtfs_feed_snapshots where snapshot_id='"+snapshot+"';")=='0':
        sql='begin;\n'
        for table,columns in TABLES.items():
            data=io.StringIO();writer=csv.writer(data,lineterminator='\n')
            for row in normalized[table]:writer.writerow(['\\N' if row.get(key) is None else row[key] for key in columns])
            sql+='COPY public.'+table+' ('+','.join(columns)+") FROM STDIN WITH (FORMAT csv, NULL '\\N');\n"+data.getvalue()+'\\.\n'
        sql+='commit;'
        local(sql)
    # Never prepare from a silently truncated or different local snapshot.
    for table,columns in TABLES.items():
        projection=','.join(columns)
        actual=json.loads(local("select coalesce(jsonb_agg(t),'[]'::jsonb) from (select "+projection+" from public."+table+" where snapshot_id='"+snapshot+"') t;"))
        def ordered(records):
            return sorted(records,key=lambda row:json.dumps({key:row.get(key) for key in columns if key not in ('latitude','longitude')},sort_keys=True))
        left=ordered(actual);right=ordered(normalized[table])
        matches=len(left)==len(right)
        for a,b in zip(left,right):
            for key in columns:
                if key in ('latitude','longitude'):
                    matches=matches and math.isclose(a[key],b[key],rel_tol=0,abs_tol=1e-11)
                else:matches=matches and a.get(key)==b.get(key)
        if not matches:
            raise RuntimeError('Local immutable snapshot differs from normalized input: '+table)
    # IDs are restricted before SQL interpolation; date is parsed to ISO first.
    sql=f"""begin;
 create temporary table grid_usable_stops on commit drop as
 select s.* from public.gtfs_stops s join public.gtfs_feed_snapshots f using(snapshot_id,feed_id)
 where s.snapshot_id='{snapshot}' and s.location_type=0 and f.parse_status='usable'
 and '{day}'::date between f.service_start and f.service_end;
 create index on grid_usable_stops using gist(geom);
 analyze grid_usable_stops;
 create temporary table grid_active_routes on commit drop as
 select distinct l.feed_id,l.stop_id,l.route_id from public.gtfs_stop_service_links l
 join public.gtfs_service_dates d using(snapshot_id,feed_id,service_id)
 where l.snapshot_id='{snapshot}' and d.service_date='{day}' and d.active;
 create index on grid_active_routes(feed_id,stop_id);
 analyze grid_active_routes;
 create temporary table grid_candidates on commit drop as
 with cells as (
 select distinct zone,g.i,g.j from grid_usable_stops s
 cross join generate_series(47,51) zone
 cross join lateral public.st_squaregrid(1000,
   public.st_expand(public.st_transform(s.geom::public.geometry,32600+zone),1600)) g
 where s.longitude between (zone*6-186)-0.03 and (zone*6-180)+0.03
 ), centers as (
 select zone,i,j,public.st_transform(public.st_setsrid(
   public.st_makepoint((i+0.5)*1000,(j+0.5)*1000),32600+zone),4326) as point from cells
 ) select zone,i,j,point,point::public.geography as geo from centers
 where floor((public.st_x(point)+180)/6)+1=zone;
 insert into public.transit_reference_grid(snapshot_id,reference_grid_version,analysis_date,grid_id,
   latitude,longitude,stop_density_per_km2,unique_route_count)
 select '{snapshot}','{VERSION}','{day}',zone||':'||i||':'||j,
   public.st_y(point),public.st_x(point),facts.stops/(pi()*2.25),facts.routes
 from grid_candidates g
 cross join lateral (
 select count(distinct (s.feed_id,s.stop_id))::integer as stops,
 count(distinct (r.feed_id,r.route_id)) filter(where r.route_id is not null)::integer as routes
 from grid_usable_stops s left join grid_active_routes r using(feed_id,stop_id)
 where public.st_dwithin(s.geom,g.geo,1500)
 ) facts where facts.stops>0
 on conflict(snapshot_id,analysis_date,grid_id) do nothing;
 commit;
 select coalesce(jsonb_agg(g order by grid_id),'[]'::jsonb) from public.transit_reference_grid g
 where snapshot_id='{snapshot}' and analysis_date='{day}' and reference_grid_version='{VERSION}';
 """
    rows=json.loads(local(sql))
    if not rows:raise RuntimeError('No usable service coverage grid points')
    integrity=json.loads(local(f"""select jsonb_build_object(
      'outside_service_area',count(*) filter(where not exists(
        select 1 from public.gtfs_stops s join public.gtfs_feed_snapshots f using(snapshot_id,feed_id)
        where s.snapshot_id=g.snapshot_id and s.location_type=0 and f.parse_status='usable'
          and g.analysis_date between f.service_start and f.service_end
          and public.st_dwithin(s.geom,public.st_setsrid(public.st_makepoint(g.longitude,g.latitude),4326)::public.geography,1500))),
      'nonpositive_density',count(*) filter(where stop_density_per_km2<=0),
      'negative_routes',count(*) filter(where unique_route_count<0))
      from public.transit_reference_grid g where snapshot_id='{snapshot}' and analysis_date='{day}';"""))
    if any(integrity.values()):raise RuntimeError('Prepared grid integrity check failed')
    zones={}
    for row in rows:
        zone=row['grid_id'].split(':')[0];zones[zone]=zones.get(zone,0)+1
    raw=json.dumps(rows,sort_keys=True,separators=(',',':')).encode()
    (ROOT/'reference-grid.json').write_bytes(raw)
    facts={'snapshot_id':snapshot,'analysis_date':day,'reference_grid_version':VERSION,
        'method':'UTM EPSG:32647–32651 fixed origin (0,0), 1000m cells, centers zone-clipped; geography radius 1500m',
        'integrity':integrity,'zone_distribution':zones,
        'grid_count':len(rows),'grid_sha256':hashlib.sha256(raw).hexdigest(),
        'input_sha256':hashlib.sha256((ROOT/'normalized-snapshot.json').read_bytes()).hexdigest(),
        'usable_feed_ids':sorted(row['feed_id'] for row in normalized['gtfs_feed_snapshots']
            if row['parse_status']=='usable' and row['service_start']<=day<=row['service_end']),
        'prepared_at':datetime.datetime.now(datetime.timezone.utc).isoformat()}
    (ROOT/'reference-grid-audit.json').write_text(json.dumps(facts,indent=2)+'\n')
    print('Prepared',len(rows),'fixed grid points',flush=True)

def apply(snapshot,day):
    config=read_values('.env');rows=json.loads((ROOT/'reference-grid.json').read_text())
    if not rows or any(row['snapshot_id']!=snapshot or row['analysis_date']!=day or row['reference_grid_version']!=VERSION for row in rows):
        raise RuntimeError('Prepared grid does not match requested snapshot/date/method')
    audit=json.loads((ROOT/'reference-grid-audit.json').read_text())
    if audit['grid_count']!=len(rows) or hashlib.sha256((ROOT/'reference-grid.json').read_bytes()).hexdigest()!=audit['grid_sha256']:
        raise RuntimeError('Prepared grid differs from its audit')
    if any(audit[key]!=value for key,value in {'snapshot_id':snapshot,'analysis_date':day,'reference_grid_version':VERSION}.items()):
        raise RuntimeError('Grid audit does not match requested immutable group')
    headers={'apikey':config['SUPABASE_SECRET_KEY'],'Authorization':'Bearer '+config['SUPABASE_SECRET_KEY'],'Content-Type':'application/json'}
    expected={row['grid_id']:row for row in rows}
    if len(expected)!=len(rows):raise RuntimeError('Duplicate prepared grid identity')
    existing={}
    offset=0
    while True:
        query=urllib.parse.urlencode({'snapshot_id':'eq.'+snapshot,'analysis_date':'eq.'+day,
            'select':','.join(rows[0]),'order':'grid_id.asc','offset':str(offset),'limit':'1000'})
        try:
            with urllib.request.urlopen(urllib.request.Request(config['SUPABASE_URL']+'/rest/v1/transit_reference_grid?'+query,headers=headers),timeout=40) as response:
                page=json.load(response)
        except Exception:raise RuntimeError('Grid read failed; sensitive HTTP details redacted') from None
        for row in page:
            if row['grid_id'] not in expected or row!=expected[row['grid_id']]:
                raise RuntimeError('Existing grid differs; immutable snapshot cannot be replaced')
            existing[row['grid_id']]=row
        if not page:break
        offset+=len(page)
    missing=[row for row in rows if row['grid_id'] not in existing]
    for start in range(0,len(missing),400):
        request=urllib.request.Request(config['SUPABASE_URL']+'/rest/v1/transit_reference_grid',method='POST',
            headers={**headers,'Prefer':'return=minimal'},data=json.dumps(missing[start:start+400]).encode())
        try:
            with urllib.request.urlopen(request,timeout=40):pass
        except Exception:raise RuntimeError('Grid upload interrupted; rerun to verify existing rows and resume') from None
    print('Verified',len(rows),'immutable grid points; uploaded',len(missing),'missing rows; batch promotion remains explicit',flush=True)

if __name__=='__main__':
    import re
    parser=argparse.ArgumentParser();parser.add_argument('--snapshot',default='official-2026-09-17');parser.add_argument('--date',required=True);parser.add_argument('--apply',action='store_true');parser.add_argument('--root',type=Path,default=ROOT);args=parser.parse_args()
    ROOT=args.root
    if not re.fullmatch(r'[A-Za-z0-9_-]+',args.snapshot):parser.error('Invalid snapshot identity')
    day=datetime.date.fromisoformat(args.date).isoformat()
    if args.apply:apply(args.snapshot,day)
    else:prepare(args.snapshot,day)
