#!/usr/bin/env python3
"""Inspect only task-owned QA records with the ordinary test user's JWT."""
import argparse,hashlib,json,time,urllib.request,urllib.parse
from pathlib import Path
from import_home_datasets import read_values
ROOT=Path(__file__).resolve().parents[1];values=read_values(ROOT/'.env');credentials=read_values(ROOT/'test_credentials.local.md')
parser=argparse.ArgumentParser();parser.add_argument('--stage',required=True);parser.add_argument('--count',type=int);args=parser.parse_args()
token=None
def api(path,method='GET',body=None,binary=False):
 headers={'apikey':values['SUPABASE_PUBLISHABLE_KEY'],'Content-Type':'application/json'}
 if token:headers['Authorization']='Bearer '+token
 req=urllib.request.Request(values['SUPABASE_URL']+path,method=method,data=None if body is None else json.dumps(body).encode(),headers=headers)
 with urllib.request.urlopen(req,timeout=30) as r:
  b=r.read();return b if binary else json.loads(b) if b else None
session=api('/auth/v1/token?grant_type=password','POST',{'email':credentials['LOCATEMY_EMAIL'],'password':credentials['LOCATEMY_PASSWORD']});token=session['access_token']
rows=api('/rest/v1/property_inspections?select=id,property_name,snapshot_availability,snapshot_captured_at,deleted_at&property_name=eq.QAPropertyDevice&order=created_at.desc')
if not rows:raise RuntimeError('Task QA property missing')
row=rows[0];photos=api('/rest/v1/property_inspection_photos?select=id,storage_path,upload_complete,is_cover,caption&inspection_id=eq.'+row['id']+'&order=created_at.asc')
if args.count is not None and len(photos)!=args.count:raise RuntimeError('Expected photo count not yet reached')
proof={'stage':args.stage,'inspection_id':row['id'],'snapshot_availability':row['snapshot_availability'],'snapshot_captured_at':row['snapshot_captured_at'],'deleted_at':row['deleted_at'],'photos':[]}
for p in photos:
 if not p['upload_complete']:raise RuntimeError('Photo not uploaded')
 b=api('/storage/v1/object/authenticated/inspection-photos/'+urllib.parse.quote(p['storage_path'])+'?qa='+str(time.time_ns()),binary=True)
 if b[:3]!=b'\xff\xd8\xff' or len(b)>10*1024*1024:raise RuntimeError('Compressed static JPEG contract failed')
 proof['photos'].append({'photo_id':p['id'],'file_sha256':hashlib.sha256(b).hexdigest(),'byte_length':len(b),'uploaded':p['upload_complete'],'cover':p['is_cover'],'caption':p['caption']})
if photos and sum(1 for p in photos if p['is_cover'])!=1:raise RuntimeError('Single cover contract failed')
out=ROOT/'build/property-wave6-evidence';(out/('device-record-'+args.stage+'.json')).write_text(json.dumps(proof,indent=2)+'\n')
print('PROPERTY_DEVICE_RECORD:',args.stage,'real owner metadata plus JPEG Storage files PASS; photos',len(photos))
