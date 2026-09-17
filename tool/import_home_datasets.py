#!/usr/bin/env python3
"""One-time official Home import. Never invoked by Flutter or scheduled."""
import csv, hashlib, io, json, math, urllib.request
from pathlib import Path

SOURCES = {
 'cpi_headline_inflation': ('https://storage.dosm.gov.my/cpi/cpi_2d_inflation.csv', ['date','division']),
 'lfs_month_sa': ('https://storage.dosm.gov.my/labour/lfs_month_sa.csv', ['date']),
 'economic_indicators': ('https://storage.dosm.gov.my/mei/mei.csv', ['date']),
 'gdp_qtr_real_sa': ('https://storage.dosm.gov.my/gdp/gdp_qtr_real_sa.csv', ['series','date']),
}

def read_values(path):
 return dict((k.strip(),v.strip().strip('\"\'')) for line in Path(path).read_text().splitlines() if '=' in line and not line.lstrip().startswith('#') for k,v in [line.split('=',1)])

def main():
 config=read_values('.env'); evidence=[]
 for dataset,(url,keys) in SOURCES.items():
  raw=urllib.request.urlopen(url,timeout=30).read()
  rows=list(csv.DictReader(io.StringIO(raw.decode('utf-8-sig'))))
  if not rows or len({tuple(row[k] for k in keys) for row in rows}) != len(rows):
   raise RuntimeError('Official dataset empty or duplicate business key: '+dataset)
  for row in rows:
   for key,value in row.items():
    if key not in ('date','division','series'):
     row[key]=None if value=='' else float(value)
     if row[key] is not None and not math.isfinite(row[key]): raise ValueError('Nonfinite source')
  for offset in range(0,len(rows),500):
   request=urllib.request.Request(config['SUPABASE_URL']+'/rest/v1/'+dataset+'?on_conflict='+','.join(keys),data=json.dumps(rows[offset:offset+500]).encode(),method='POST',headers={'apikey':config['SUPABASE_SECRET_KEY'],'Authorization':'Bearer '+config['SUPABASE_SECRET_KEY'],'Content-Type':'application/json','Prefer':'resolution=merge-duplicates,return=minimal'})
   try:
    with urllib.request.urlopen(request,timeout=60) as response: pass
   except Exception:
    raise RuntimeError('Import failed; sensitive HTTP details redacted: '+dataset) from None
  evidence.append({'dataset':dataset,'url':url,'sha256':hashlib.sha256(raw).hexdigest(),'rows':len(rows),'max_date':max(r['date'] for r in rows),'columns':list(rows[0]),'business_key':keys})
  print('Imported',dataset,len(rows),'rows')
 target=Path('build/home-wave4-evidence');target.mkdir(parents=True,exist_ok=True)
 (target/'official-import-audit.json').write_text(json.dumps(evidence,indent=2)+'\n')

if __name__=='__main__': main()
