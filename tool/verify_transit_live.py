#!/usr/bin/env python3
"""Run real Transit reads using local credentials; save redacted evidence."""
import os,re,subprocess,json,hashlib
from pathlib import Path
from import_home_datasets import read_values
values=read_values('.env');credentials=read_values('test_credentials.local.md')
env={**os.environ,**{k:values[k] for k in ['SUPABASE_URL','SUPABASE_PUBLISHABLE_KEY']},**credentials,'LOCATEMY_TRANSIT_LIVE':'1'}
result=subprocess.run(['flutter','test','test/live/public_transportation_live_test.dart','--reporter','expanded'],env=env,capture_output=True,text=True)
output=result.stdout+result.stderr
for value in [*values.values(),*credentials.values()]:
 if value:output=output.replace(value,'<REDACTED>')
output=re.sub(r'eyJ[A-Za-z0-9_.-]+','<TOKEN>',output)
root=Path('build/transit-wave5-evidence');root.mkdir(parents=True,exist_ok=True)
(root/'live-test.log').write_text(output)
digest=hashlib.sha256()
for path in sorted([*Path('lib/features/public_transportation').rglob('*.dart'),*Path('test/features/public_transportation').rglob('*.*'),Path('test/live/public_transportation_live_test.dart'),*Path('supabase/migrations').glob('*transit*.sql'),Path('supabase/migrations/20260917051623_public_transportation_analysis.sql')]):digest.update(str(path).encode()+b'\0'+path.read_bytes())
(root/'live-test.source.json').write_text(json.dumps({'base_head':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),'source_sha256':digest.hexdigest(),'exit_code':result.returncode},indent=2)+'\n')
print(output);raise SystemExit(result.returncode)
