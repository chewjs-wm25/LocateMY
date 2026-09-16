#!/usr/bin/env python3
"""Build an Auth verification APK with only public .env values; restore .env afterward."""
from pathlib import Path
import subprocess
import zipfile
p=Path('.env'); original=p.read_bytes()
values={}
for line in original.decode().splitlines():
 if '=' in line and not line.lstrip().startswith('#'):
  k,v=line.split('=',1); values[k.strip()]=v.strip().strip('\"\'')
try:
 p.write_text('\n'.join(k+'='+values[k] for k in ['SUPABASE_URL','SUPABASE_PUBLISHABLE_KEY'])+'\n')
 result=subprocess.run(['flutter','build','apk','--debug'])
 if result.returncode: raise SystemExit(result.returncode)
 apk=Path('build/app/outputs/flutter-apk/app-debug.apk')
 with zipfile.ZipFile(apk) as z:
  for name in z.namelist():
   if values.get('SUPABASE_SECRET_KEY') and values['SUPABASE_SECRET_KEY'].encode() in z.read(name):
    raise SystemExit('FAIL: secret key in APK')
 print('PASS: APK does not contain the local secret key')
finally:
 p.write_bytes(original)
