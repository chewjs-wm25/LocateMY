#!/usr/bin/env python3
"""Live Map acceptance. Credentials never printed; fixture rows/users cleaned."""
import json,os,re,secrets,subprocess,urllib.request,urllib.parse
from pathlib import Path

def read_variables(path):
    return {k.strip():v.strip().strip('"\'') for line in Path(path).read_text().splitlines() if '=' in line and not line.lstrip().startswith('#') for k,v in [line.split('=',1)]}
values=read_variables('.env');credentials=read_variables('test_credentials.local.md')
values.update(credentials)
other_email=f'locatemy.map.{secrets.token_hex(8)}@gmail.com';other_password=f'Map!{secrets.token_hex(20)}'
name='locatemy-map-'+secrets.token_hex(12)
redact=[*values.values(),other_email,other_password]
root=Path('docs/human/evidence/map-location-wave4-2026-09-17');root.mkdir(parents=True,exist_ok=True)
def request(path,method,body=None):
    req=urllib.request.Request(values['SUPABASE_URL']+path,method=method,data=json.dumps(body).encode() if body is not None else None,headers={'apikey':values['SUPABASE_SECRET_KEY'],'Authorization':'Bearer '+values['SUPABASE_SECRET_KEY'],'Content-Type':'application/json'})
    with urllib.request.urlopen(req,timeout=30) as response:
        data=response.read();return json.loads(data) if data else None
uid=None
try:
    uid=request('/auth/v1/admin/users','POST',{'email':other_email,'password':other_password,'email_confirm':True})['id']
    env={**os.environ,**{k:v for k,v in values.items() if k!='SUPABASE_SECRET_KEY'},'LOCATEMY_OTHER_EMAIL':other_email,'LOCATEMY_OTHER_PASSWORD':other_password,'LOCATEMY_MAP_FIXTURE':name,'LOCATEMY_MAP_LIVE':'1'}
    result=subprocess.run(['flutter','test','test/live/map_location_live_test.dart','--reporter','expanded'],env=env,capture_output=True,text=True)
    output=result.stdout+result.stderr
    for value in redact:
        if value:output=output.replace(value,'<REDACTED>')
    output=re.sub(r'eyJ[A-Za-z0-9_.-]+','<TOKEN>',output)
    (root/'live-test.txt').write_text(output);print(output)
    raise SystemExit(result.returncode)
finally:
    request('/rest/v1/user_saved_locations?name=like.'+urllib.parse.quote(name+'%'),'DELETE')
    if uid:request('/auth/v1/admin/users/'+uid,'DELETE')
