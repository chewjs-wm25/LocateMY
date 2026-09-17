#!/usr/bin/env python3
"""Build with an allowlisted mobile configuration and scan APK for secrets."""
import hashlib,json,re,shutil,subprocess,sys,tempfile,zipfile
from pathlib import Path

def read(path):
 return {k.strip():v.strip().strip('"\'') for line in Path(path).read_text().splitlines() if '=' in line and not line.lstrip().startswith('#') for k,v in [line.split('=',1)]}
def stamp():
 digest=hashlib.sha256()
 for path in sorted([*Path('lib').rglob('*.dart'),*Path('test').rglob('*.dart'),*Path('tool').glob('*.dart'),Path('pubspec.yaml'),Path('pubspec.lock')]):digest.update(str(path).encode()+b'\0'+path.read_bytes())
 scoped=hashlib.sha256()
 paths=[*Path('lib/features/hazard_reporting').rglob('*.dart'),Path('lib/app/app.dart'),Path('lib/app/src/presentation/shell_host.dart'),Path('lib/features/map_location/src/presentation/map_location_page.dart'),*Path('test/features/hazard_reporting').glob('*.dart'),Path('test/live/hazard_reporting_live_test.dart'),Path('tool/hazard_reporting_device.dart'),*Path('supabase/migrations').glob('*hazard*.sql')]
 for path in sorted(paths):scoped.update(str(path).encode()+b'\0'+path.read_bytes())
 return {'hazard_source_sha256':scoped.hexdigest(),'base_head':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),'source_sha256':digest.hexdigest()}
def build(extra=(),name='production-build'):
 values=read('.env');credentials=read('test_credentials.local.md');evidence=Path('docs/human/evidence/hazard-reporting-wave5-2026-09-17');evidence.mkdir(parents=True,exist_ok=True)
 source=stamp();root=Path.cwd();artifact=Path('/tmp/locatemy-hazard-artifacts')/(name+'.apk');artifact.parent.mkdir(parents=True,exist_ok=True)
 with tempfile.TemporaryDirectory(prefix='locatemy-hazard-build-') as temporary:
  snapshot=Path(temporary)
  for folder in ['lib','assets','android','tool']:
   shutil.copytree(root/folder,snapshot/folder,ignore=shutil.ignore_patterns('build','.gradle','.cxx','local.properties','*.local.*','__pycache__'))
  for filename in ['pubspec.yaml','pubspec.lock','analysis_options.yaml']:
   if (root/filename).exists():shutil.copy2(root/filename,snapshot/filename)
  (snapshot/'.env').write_text('\n'.join(k+'='+values[k] for k in ['SUPABASE_URL','SUPABASE_PUBLISHABLE_KEY','GEOAPIFY_API_KEY'] if values.get(k))+'\n')
  if name=='device-build':
   gradle=snapshot/'android/app/build.gradle.kts';gradle.write_text(gradle.read_text().replace('applicationId = "com.locatemy.app"','applicationId = "com.locatemy.hazard.qa"'))
   manifest=snapshot/'android/app/src/main/AndroidManifest.xml';manifest.write_text(manifest.read_text().replace('android:name=".MainActivity"','android:name="com.locatemy.app.MainActivity"').replace('android:label="LocateMY"','android:label="LocateMY Hazard QA"'))
  result=subprocess.run(['flutter','build','apk','--debug',*extra],cwd=snapshot,capture_output=True,text=True)
  output=result.stdout+result.stderr
  for value in [*values.values(),*credentials.values()]:
   if value:output=output.replace(value,'<REDACTED>')
  output=re.sub(r'eyJ[A-Za-z0-9_.-]+','<TOKEN>',output);(evidence/(name+'.txt')).write_text(output)
  if result.returncode:print(output);raise RuntimeError('Build failed')
  apk=snapshot/'build/app/outputs/flutter-apk/app-debug.apk'
  forbidden=[values.get('SUPABASE_SECRET_KEY',''),*credentials.values()]
  with zipfile.ZipFile(apk) as archive:
   if any(value.encode() in archive.read(n) for n in archive.namelist() for value in forbidden if value):raise RuntimeError('Sensitive value in APK')
  shutil.copy2(apk,artifact)
  (evidence/(name+'.source.json')).write_text(json.dumps({**source,'apk_sha256':hashlib.sha256(apk.read_bytes()).hexdigest(),'secret_scan':'PASS','application_id':'com.locatemy.hazard.qa' if name=='device-build' else 'com.locatemy.app'},indent=2)+'\n')
  print('PASS: '+name+'; no high privilege key or local login credentials in APK',flush=True)
 return artifact
if __name__=='__main__':build(sys.argv[1:])
