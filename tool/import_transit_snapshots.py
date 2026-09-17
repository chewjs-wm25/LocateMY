#!/usr/bin/env python3
"""One-time official GTFS preparation. Never called by Flutter or a scheduler."""
import argparse, csv, datetime as dt, hashlib, io, json, math, urllib.request, urllib.parse, zipfile
from pathlib import Path
from import_home_datasets import read_values

ROOT = Path('build/transit-wave5-evidence')
SNAPSHOT = 'official-2026-09-17'

def prepare():
    download = json.loads((ROOT/'official-download-audit.json').read_text())
    tables = {name: [] for name in ['gtfs_feed_snapshots','gtfs_stops','gtfs_routes','gtfs_service_dates','gtfs_stop_service_links']}
    audit = []
    for item in download:
        feed = item['feed_id']; shared = {'snapshot_id': SNAPSHOT, 'feed_id': feed}
        status = {**shared, 'source_id': feed, 'source_url': item['url'],
                  'captured_at': None, 'parse_status': 'failed', 'failure_reason': item.get('failure'),
                  'service_start': None, 'service_end': None, 'source_sha256': None}
        # Snapshot identity uses the registered producer; the audit retains the
        # actual archive URL and capture time for a verified archived feed.
        status['source_url'] = item.get('official_producer_url',item['url'])
        try:
            if 'failure' in item:
                raise ValueError(item['failure'])
            path = ROOT/'official-feeds'/(feed+'.zip')
            raw = path.read_bytes()
            status['captured_at'] = dt.datetime.fromtimestamp(path.stat().st_mtime,dt.timezone.utc).isoformat()
            status['source_sha256'] = hashlib.sha256(raw).hexdigest()
            z = zipfile.ZipFile(io.BytesIO(raw))
            def rows(name, optional=False):
                matches = [p for p in z.namelist() if p.split('/')[-1] == name]
                if not matches and optional: return []
                if len(matches) != 1: raise ValueError('Missing or ambiguous '+name)
                return list(csv.DictReader(io.StringIO(z.read(matches[0]).decode('utf-8-sig'))))
            routes = {r['route_id']: r for r in rows('routes.txt')}
            trips = {r['trip_id']: r for r in rows('trips.txt')}
            stops = {r['stop_id']: r for r in rows('stops.txt')}
            links = set(); types = {}
            for r in rows('stop_times.txt'):
                trip = trips.get(r['trip_id'])
                if trip is None or r['stop_id'] not in stops or trip['route_id'] not in routes:
                    raise ValueError('Broken routes/trips/stop_times association')
                links.add((r['stop_id'],trip['route_id'],trip['service_id']))
                types.setdefault(r['stop_id'],set()).add(int(routes[trip['route_id']]['route_type']))
            calendars = rows('calendar.txt',True); exceptions = rows('calendar_dates.txt',True)
            dates = {}
            def date(value): return dt.datetime.strptime(value,'%Y%m%d').date()
            weekdays = ['monday','tuesday','wednesday','thursday','friday','saturday','sunday']
            for r in calendars:
                start = date(r['start_date']); end = date(r['end_date'])
                if end < start: raise ValueError('Inverted service range')
                day = start
                while day <= end:
                    dates[(r['service_id'],day)] = r[weekdays[day.weekday()]] == '1'
                    day += dt.timedelta(days=1)
            for r in exceptions:
                if r['exception_type'] not in ('1','2'): raise ValueError('Invalid service exception')
                dates[(r['service_id'],date(r['date']))] = r['exception_type'] == '1'
            if not dates or not stops or not routes: raise ValueError('Empty service calendar, stops or routes')
            known_services = {k[0] for k in dates}
            if any(service not in known_services for _,_,service in links):
                raise ValueError('Linked service has no calendar')
            staged_stops = []
            for stop_id,r in stops.items():
                lat = float(r['stop_lat']); lon = float(r['stop_lon'])
                if not math.isfinite(lat+lon) or not -90 <= lat <= 90 or not -180 <= lon <= 180:
                    raise ValueError('Invalid stop coordinates')
                route_types = types.get(stop_id,set())
                station_type = 'other'
                if route_types.intersection({0,1,2,5,6,7,12}): station_type = 'rail'
                elif 4 in route_types: station_type = 'ferry'
                elif route_types.intersection({3,11}): station_type = 'bus'
                staged_stops.append({**shared,'stop_id':stop_id,'name':r['stop_name'],'latitude':lat,'longitude':lon,
                   'location_type':int(r.get('location_type') or 0),'parent_station':r.get('parent_station') or None,'station_type':station_type})
            tables['gtfs_stops'].extend(staged_stops)
            tables['gtfs_routes'].extend({**shared,'route_id':key,'short_name':r.get('route_short_name'),'route_type':int(r['route_type'])} for key,r in routes.items())
            tables['gtfs_service_dates'].extend({**shared,'service_id':service,'service_date':day.isoformat(),'active':active} for (service,day),active in sorted(dates.items()))
            tables['gtfs_stop_service_links'].extend({**shared,'stop_id':stop,'route_id':route,'service_id':service} for stop,route,service in sorted(links))
            status.update(parse_status='usable',failure_reason=None,service_start=min(k[1] for k in dates).isoformat(),service_end=max(k[1] for k in dates).isoformat())
            audit.append({'feed_id':feed,'status':'usable','stops':len(staged_stops),'routes':len(routes),'links':len(links),'service_dates':len(dates),'sha256':status['source_sha256'],'source_url':item['url']})
        except Exception as e:
            status['failure_reason'] = str(e)
            audit.append({'feed_id':feed,'status':'failed','reason':str(e),'source_url':item['url']})
        tables['gtfs_feed_snapshots'].append(status)
    (ROOT/'normalized-snapshot.json').write_text(json.dumps(tables))
    (ROOT/'official-import-audit.json').write_text(json.dumps(audit,indent=2)+'\n')
    for name,values in tables.items(): print('Prepared',name,len(values))

def rest(config, path, method='GET', records=None):
    request = urllib.request.Request(config['SUPABASE_URL']+'/rest/v1/'+path,
        method=method, data=None if records is None else json.dumps(records).encode(), headers={
        'apikey':config['SUPABASE_SECRET_KEY'],'Authorization':'Bearer '+config['SUPABASE_SECRET_KEY'],
        'Content-Type':'application/json','Prefer':'return=minimal'})
    try:
        with urllib.request.urlopen(request,timeout=40) as response:
            raw=response.read()
            return json.loads(raw) if raw else None
    except Exception:
        raise RuntimeError('Snapshot operation failed; HTTP details redacted') from None

def apply():
    config = read_values('.env')
    tables = json.loads((ROOT/'normalized-snapshot.json').read_text())
    snapshots={row['snapshot_id'] for records in tables.values() for row in records}
    if snapshots != {SNAPSHOT}:
        raise RuntimeError('Prepare this snapshot identity before applying')
    query=urllib.parse.urlencode({'snapshot_id':'eq.'+SNAPSHOT,'select':'snapshot_id'})
    if rest(config,'transit_evaluation_batches?'+query):
        raise RuntimeError('Promoted snapshot is immutable; prepare a new snapshot identity')
    # Staging retries are permitted; a promoted identity is never rewritten.
    keys = {'gtfs_feed_snapshots':'snapshot_id,feed_id','gtfs_stops':'snapshot_id,feed_id,stop_id',
       'gtfs_routes':'snapshot_id,feed_id,route_id','gtfs_service_dates':'snapshot_id,feed_id,service_date,service_id',
       'gtfs_stop_service_links':'snapshot_id,feed_id,stop_id,route_id,service_id'}
    for table,records in tables.items():
        for offset in range(0,len(records),400):
            request = urllib.request.Request(config['SUPABASE_URL']+'/rest/v1/'+table+'?on_conflict='+keys[table],
               data=json.dumps(records[offset:offset+400]).encode(),method='POST',headers={
               'apikey':config['SUPABASE_SECRET_KEY'],'Authorization':'Bearer '+config['SUPABASE_SECRET_KEY'],
               'Content-Type':'application/json','Prefer':'resolution=merge-duplicates,return=minimal'})
            try:
                with urllib.request.urlopen(request,timeout=40): pass
            except Exception:
                raise RuntimeError('Import failed; HTTP details redacted: '+table) from None
        print('Imported',table,len(records),flush=True)

def promote(grid_version, analysis_date):
    config=read_values('.env')
    query=urllib.parse.urlencode({'snapshot_id':'eq.'+SNAPSHOT,'select':'feed_id,parse_status'})
    records=rest(config,'gtfs_feed_snapshots?'+query)
    expected={row['feed_id'] for row in json.loads((ROOT/'official-download-audit.json').read_text())}
    if len(expected)!=16 or len(records)!=16 or {row['feed_id'] for row in records}!=expected:
        raise RuntimeError('Promotion requires an individual row for every expected feed')
    if all(row['parse_status']=='usable' for row in records):
        prepared=json.loads((ROOT/'reference-grid.json').read_text())
        audit=json.loads((ROOT/'reference-grid-audit.json').read_text())
        if audit['snapshot_id']!=SNAPSHOT or audit['analysis_date']!=analysis_date or audit['reference_grid_version']!=grid_version:
            raise RuntimeError('Promotion requires the audited snapshot/date/grid')
        if hashlib.sha256((ROOT/'reference-grid.json').read_bytes()).hexdigest()!=audit['grid_sha256']:
            raise RuntimeError('Prepared reference grid audit mismatch')
        actual=[]
        while True:
            query=urllib.parse.urlencode({'snapshot_id':'eq.'+SNAPSHOT,'analysis_date':'eq.'+analysis_date,
                'select':','.join(prepared[0]),'order':'grid_id.asc','offset':str(len(actual)),'limit':'1000'})
            page=rest(config,'transit_reference_grid?'+query)
            if not page:break
            actual.extend(page)
        if {row['grid_id']:row for row in actual}!={row['grid_id']:row for row in prepared}:
            raise RuntimeError('Complete feed promotion requires the entire immutable audited grid')
    rest(config,'transit_evaluation_batches','POST',[{'snapshot_id':SNAPSHOT,
        'reference_grid_version':grid_version,'expected_feed_count':16}])
    print('Promoted',SNAPSHOT,flush=True)

if __name__ == '__main__':
    parser=argparse.ArgumentParser()
    parser.add_argument('--root',type=Path,default=ROOT)
    parser.add_argument('--snapshot',default=SNAPSHOT)
    parser.add_argument('--apply',action='store_true')
    parser.add_argument('--promote',action='store_true')
    parser.add_argument('--grid-version')
    parser.add_argument('--analysis-date')
    args=parser.parse_args();SNAPSHOT=args.snapshot;ROOT=args.root
    if args.promote:
        if not args.grid_version or not args.analysis_date:
            parser.error('--promote requires --grid-version and --analysis-date')
        promote(args.grid_version,args.analysis_date)
    elif args.apply: apply()
    else: prepare()
