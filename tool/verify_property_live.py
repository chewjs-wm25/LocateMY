#!/usr/bin/env python3
"""Run real Infrastructure reads using local credentials; save redacted evidence."""
import os,re,subprocess,json,hashlib,secrets,urllib.request
from pathlib import Path
from import_home_datasets import read_values
values=read_values('.env');credentials=read_values('test_credentials.local.md')
other_email='locatemy.property.'+secrets.token_hex(8)+'@gmail.com'
other_password='Infra!'+secrets.token_hex(20)
def admin(path,method,body=None):
 request=urllib.request.Request(values['SUPABASE_URL']+path,method=method,data=json.dumps(body).encode() if body else None,headers={'apikey':values['SUPABASE_SECRET_KEY'],'Authorization':'Bearer '+values['SUPABASE_SECRET_KEY'],'Content-Type':'application/json'})
 with urllib.request.urlopen(request,timeout=30) as response:
  payload=response.read();return json.loads(payload) if payload else None
uid=None
try:
 uid=admin('/auth/v1/admin/users','POST',{'email':other_email,'password':other_password,'email_confirm':True})['id']
 env={**os.environ,**{k:values[k] for k in ['SUPABASE_URL','SUPABASE_PUBLISHABLE_KEY']},**credentials,'LOCATEMY_OTHER_EMAIL':other_email,'LOCATEMY_OTHER_PASSWORD':other_password,'LOCATEMY_PROPERTY_LIVE':'1'}
 result=subprocess.run(['flutter','test','test/live/property_live_test.dart','--reporter','expanded'],env=env,capture_output=True,text=True)
finally:
 if uid:admin('/auth/v1/admin/users/'+uid,'DELETE')
output=result.stdout+result.stderr
for value in [*values.values(),*credentials.values(),other_email,other_password]:
 if value:output=output.replace(value,'<REDACTED>')
output=re.sub(r'eyJ[A-Za-z0-9_.-]+','<TOKEN>',output)
root=Path('build/property-wave6-evidence');root.mkdir(parents=True,exist_ok=True)
(root/'live-test.log').write_text(output)
digest=hashlib.sha256()
for path in sorted([*Path('lib/features/property_inspection').rglob('*.dart'),*Path('test/features/property_inspection').rglob('*.*'),Path('test/live/property_live_test.dart'),Path('lib/app/app.dart'),*Path('supabase/migrations').glob('*property*.sql')]):digest.update(str(path).encode()+b'\0'+path.read_bytes())
(root/'live-test.source.json').write_text(json.dumps({'base_head':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),'source_sha256':digest.hexdigest(),'exit_code':result.returncode},indent=2)+'\n')
print(output);raise SystemExit(result.returncode)
