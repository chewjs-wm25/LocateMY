#!/usr/bin/env python3
"""Read local test credentials, run live acceptance, redact all sensitive values."""
import os,re,subprocess,hashlib,json
from pathlib import Path
from import_home_datasets import read_values
values=read_values('.env');credentials=read_values('test_credentials.local.md')
env={**os.environ,**{k:values[k] for k in ['SUPABASE_URL','SUPABASE_PUBLISHABLE_KEY']},**credentials,'LOCATEMY_HOME_LIVE':'1'}
digest=hashlib.sha256()
for path in sorted([*Path('lib').rglob('*.dart'),*Path('lib').rglob('*.arb'),*Path('test').rglob('*.dart'),*Path('tool').glob('*.dart'),*Path('assets').rglob('*.*'),Path('pubspec.yaml'),Path('pubspec.lock')]):
 digest.update(str(path).encode()+b'\0'+path.read_bytes())
source={'base_head':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),'source_sha256':digest.hexdigest()}
result=subprocess.run(['flutter','test','test/live/home_relocation_outlook_live_test.dart','--reporter','expanded'],env=env,capture_output=True,text=True)
output=result.stdout+result.stderr
for value in [*values.values(),*credentials.values()]:
 if value:output=output.replace(value,'<REDACTED>')
output=re.sub(r'eyJ[A-Za-z0-9_.-]+','<TOKEN>',output)
p=Path('build/home-wave4-evidence/live-test.log');p.parent.mkdir(parents=True,exist_ok=True);p.write_text(output)
(p.parent/'live-test.source.json').write_text(json.dumps({**source,'exit_code':result.returncode},indent=2)+'\n')
print(output);raise SystemExit(result.returncode)
