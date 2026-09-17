#!/usr/bin/env python3
"""Build with an allowlisted mobile configuration and scan APK for secrets."""
import hashlib,json,re,subprocess,sys,zipfile
from pathlib import Path

def read(path):
 return {k.strip():v.strip().strip('"\'') for line in Path(path).read_text().splitlines() if '=' in line and not line.lstrip().startswith('#') for k,v in [line.split('=',1)]}
def stamp():
 digest=hashlib.sha256()
 for path in sorted([*Path('lib').rglob('*.dart'),*Path('test').rglob('*.dart'),*Path('tool').glob('*.dart'),Path('pubspec.yaml'),Path('pubspec.lock')]):digest.update(str(path).encode()+b'\0'+path.read_bytes())
 return {'base_head':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),'source_sha256':digest.hexdigest()}
def build(extra=(),name='production-build'):
 values=read('.env');credentials=read('test_credentials.local.md');original=Path('.env').read_bytes();evidence=Path('docs/human/evidence/map-location-wave4-2026-09-17');evidence.mkdir(parents=True,exist_ok=True)
 try:
  Path('.env').write_text('\n'.join(k+'='+values[k] for k in ['SUPABASE_URL','SUPABASE_PUBLISHABLE_KEY','GEOAPIFY_API_KEY'] if values.get(k))+'\n')
  result=subprocess.run(['flutter','build','apk','--debug',*extra],capture_output=True,text=True)
  output=result.stdout+result.stderr
  for value in [*values.values(),*credentials.values()]:
   if value:output=output.replace(value,'<REDACTED>')
  output=re.sub(r'eyJ[A-Za-z0-9_.-]+','<TOKEN>',output);(evidence/(name+'.txt')).write_text(output)
  if result.returncode:print(output);raise RuntimeError('Build failed')
  apk=Path('build/app/outputs/flutter-apk/app-debug.apk')
  forbidden=[values.get('SUPABASE_SECRET_KEY',''),*credentials.values()]
  with zipfile.ZipFile(apk) as archive:
   if any(value.encode() in archive.read(n) for n in archive.namelist() for value in forbidden if value):raise RuntimeError('Sensitive value in APK')
  (evidence/(name+'.source.json')).write_text(json.dumps({**stamp(),'apk_sha256':hashlib.sha256(apk.read_bytes()).hexdigest(),'secret_scan':'PASS'},indent=2)+'\n')
  print('PASS: '+name+'; no high privilege key or local login credentials in APK',flush=True)
 finally:Path('.env').write_bytes(original)
if __name__=='__main__':build(sys.argv[1:])
