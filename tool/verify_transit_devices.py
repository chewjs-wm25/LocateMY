#!/usr/bin/env python3
"""Build an isolated credential-safe source snapshot and verify both Android targets."""
import urllib.error
import argparse,hashlib,json,os,re,secrets,select,shutil,socket,socketserver,subprocess,tempfile,threading,time,urllib.request,zipfile
import xml.etree.ElementTree as ET
from pathlib import Path
from urllib.parse import urlparse
from import_home_datasets import read_values
parser=argparse.ArgumentParser();parser.add_argument('--devices',nargs='+',required=True);args=parser.parse_args()
for attempt in range(240):
 values=read_values('.env')
 if values.get('SUPABASE_SECRET_KEY'):break
 time.sleep(1)
else:raise RuntimeError('Local sensitive configuration is temporarily owned by another build')
credentials=read_values('test_credentials.local.md')
root=Path.cwd();evidence=root/'build/transit-wave5-evidence';evidence.mkdir(parents=True,exist_ok=True)
redactions=[*values.values(),*credentials.values()]
def clean(s):
 for v in redactions:
  if v:s=s.replace(v,'<REDACTED>')
 return re.sub(r'eyJ[A-Za-z0-9_.-]+','<TOKEN>',s)
def run(cmd,name=None,cwd=None):
 r=subprocess.run(cmd,capture_output=True,text=True,cwd=cwd);output=clean(r.stdout+r.stderr)
 if name:(evidence/name).write_text(output)
 if r.returncode:raise RuntimeError('Command failed; sanitized evidence '+(name or cmd[0]))
 return output
allowed=urlparse(values['SUPABASE_URL']).hostname
class Tunnel(socketserver.StreamRequestHandler):
 def handle(self):
  line=self.rfile.readline(8192).decode('ascii','replace').strip()
  if not line.startswith('CONNECT '+allowed+':443 '):self.request.sendall(b'HTTP/1.1 403 Forbidden\r\n\r\n');return
  while self.rfile.readline(8192) not in [b'\r\n',b'\n',b'']:pass
  with socket.create_connection((allowed,443),timeout=30) as remote:
   self.request.sendall(b'HTTP/1.1 200 Connection Established\r\n\r\n')
   while True:
    ready,_,_=select.select([self.request,remote],[],[],30)
    if not ready:return
    for source in ready:
     data=source.recv(65536)
     if not data:return
     (remote if source is self.request else self.request).sendall(data)
def admin(path,method,body=None):
 request=urllib.request.Request(values['SUPABASE_URL']+'/auth/v1/admin/'+path,method=method,data=None if body is None else json.dumps(body).encode(),headers={'apikey':values['SUPABASE_SECRET_KEY'],'Authorization':'Bearer '+values['SUPABASE_SECRET_KEY'],'Content-Type':'application/json'})
 try:
  with urllib.request.urlopen(request,timeout=30) as r:return json.loads(r.read())
 except urllib.error.HTTPError as error:
  body=json.loads(error.read());print('Fixture HTTP',error.code,clean(str(body.get('msg') or body.get('message') or body.get('code'))),flush=True)
  raise RuntimeError('Fixture administration failed; sensitive details redacted') from None
 except Exception as error:
  print('Fixture failure type',type(error).__name__,flush=True)
  raise RuntimeError('Fixture administration failed; sensitive details redacted') from None
server=socketserver.ThreadingTCPServer(('127.0.0.1',0),Tunnel);server.daemon_threads=True
threading.Thread(target=server.serve_forever,daemon=True).start();port=str(server.server_address[1]);fixture=None
try:
 email='transit-qa-'+secrets.token_hex(8)+'@gmail.com';password='Transit!'+secrets.token_hex(24);redactions.extend([email,password])
 fixture=admin('users','POST',{'email':email,'password':password,'email_confirm':True})['id']
 with tempfile.TemporaryDirectory(prefix='locatemy-transit-source-') as tmp:
  build=Path(tmp)
  for name in ['lib','tool','assets','android']:
   shutil.copytree(root/name,build/name,ignore=shutil.ignore_patterns('build','.gradle','__pycache__'))
  for name in ['pubspec.yaml','pubspec.lock','analysis_options.yaml','l10n.yaml']:
   if (root/name).exists():shutil.copy2(root/name,build/name)
  (build/'.env').write_text('\n'.join(k+'='+values[k] for k in ['SUPABASE_URL','SUPABASE_PUBLISHABLE_KEY'])+'\n')
  config=build/'fixture.json';config.write_text(json.dumps({**{k:values[k] for k in ['SUPABASE_URL','SUPABASE_PUBLISHABLE_KEY']},'LOCATEMY_EMAIL':email,'LOCATEMY_PASSWORD':password,'LOCATEMY_PRIVACY_PROXY_PORT':port}));config.chmod(0o600)
  print('Building isolated real Transit harness',flush=True)
  run(['flutter','build','apk','--debug','--target','tool/public_transportation_device.dart','--dart-define-from-file',str(config)],'device-build.log',build)
  apk=build/'build/app/outputs/flutter-apk/app-debug.apk';dest=evidence/'transit-device-debug.apk';shutil.copy2(apk,dest)
  with zipfile.ZipFile(dest) as z:
   if any(v.encode() in z.read(n) for n in z.namelist() for v in [values['SUPABASE_SECRET_KEY'],*credentials.values()] if v):raise RuntimeError('Forbidden secret in QA APK')
  digest=hashlib.sha256()
  for p in sorted((build/'lib').rglob('*.dart')):digest.update(str(p.relative_to(build)).encode()+b'\0'+p.read_bytes())
  (evidence/'device-build.source.json').write_text(json.dumps({'base_head':run(['git','rev-parse','HEAD']).strip(),'source_sha256':digest.hexdigest(),'apk_sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'secret_scan':'PASS'},indent=2)+'\n')
 print('Waiting for the other device verification to release the shared app',flush=True)
 for attempt in range(240):
  processes=subprocess.check_output(['ps','-eo','args'],text=True)
  busy=any((re.search(r'python(?:3)? tool/verify_',line) and '_devices.py' in line and 'verify_transit_devices.py' not in line) for line in processes.splitlines())
  if not busy:break
  time.sleep(1)
 else:raise RuntimeError('Other verification still owns shared devices; build retained')
 for device in args.devices:
  tag='owner-b-emulator' if device.startswith('emulator-') else 'owner-a-device';adb=['adb','-s',device]
  run(adb+['reverse','tcp:'+port,'tcp:'+port]);run(adb+['install','-r',str(dest)],tag+'-install.log')
  def launch():
   run(adb+['shell','am','force-stop','com.locatemy.app']);run(adb+['logcat','-c']);run(adb+['shell','am','start','-n','com.locatemy.app/.MainActivity'])
  def capture(stage):
   xml=run(adb+['exec-out','uiautomator','dump','/dev/tty']);xml=xml[xml.index('<?xml'):xml.rindex('</hierarchy>')+12];(evidence/(tag+'-'+stage+'.xml')).write_text(clean(xml))
   with (evidence/(tag+'-'+stage+'.png')).open('wb') as f:subprocess.run(adb+['exec-out','screencap','-p'],stdout=f,check=True)
   return ET.fromstring(xml)
  def tap(label,stage):
   tree=capture(stage+'-before');nodes=[n for n in tree.iter('node') if n.attrib.get('text')==label or n.attrib.get('content-desc')==label]
   if not nodes:raise RuntimeError('UI target missing '+label)
   b=list(map(int,re.findall(r'\d+',nodes[0].attrib['bounds'])));run(adb+['shell','input','tap',str((b[0]+b[2])//2),str((b[1]+b[3])//2)]);time.sleep(3);return capture(stage)
  original_font=run(adb+['shell','settings','get','system','font_scale']).strip()
  launch()
  for attempt in range(30):
   log=run(adb+['logcat','-d','-s','flutter:I'])
   if 'TRANSIT_DEVICE: FAILED' in log:
    (evidence/(tag+'-failure.log')).write_text(clean(log))
    raise RuntimeError('Device fixture failed; sanitized logs')
   if 'TRANSIT_DEVICE: READY' in log:break
   time.sleep(1)
  else:raise RuntimeError('Device launch timed out')
  time.sleep(2);tap('QA Open transportation','partial-zh')
  time.sleep(8);capture('partial-zh-settled')
  run(adb+['shell','input','keyevent','4']);time.sleep(1);capture('return-home')
  tap('QA Controlled served','controlled-served');time.sleep(12);capture('controlled-served-settled')
  run(adb+['shell','input','keyevent','4']);time.sleep(1)
  tap('QA Controlled offline cache','controlled-offline-cache');time.sleep(5);capture('controlled-offline-cache-settled')
  run(adb+['shell','input','keyevent','4']);time.sleep(1)
  tap('QA Outside service range','date-unavailable');time.sleep(5);capture('date-unavailable-settled')
  run(adb+['shell','input','keyevent','4']);time.sleep(1)
  tap('QA Transportation comparison','comparison-zh');time.sleep(8);capture('comparison-zh-settled')
  run(adb+['shell','input','keyevent','4']);time.sleep(1)
  tap('QA English transportation','partial-en');time.sleep(8);capture('partial-en-settled')
  run(adb+['shell','input','keyevent','4']);time.sleep(1)
  run(adb+['shell','settings','put','system','font_scale','2.0'])
  tap('QA Open transportation','large-font-en');time.sleep(8);capture('large-font-en-settled')
  run(adb+['shell','settings','put','system','font_scale',original_font])
  run(adb+['shell','input','keyevent','4']);time.sleep(1)
  launch();time.sleep(12);tap('QA Open transportation','restart-partial');time.sleep(8);capture('restart-partial-settled')
  device_log=clean(run(adb+['logcat','-d','-s','flutter:I']))
  (evidence/(tag+'-device.log')).write_text(device_log)
  if any(error in device_log for error in ['A RenderFlex overflowed','EXCEPTION CAUGHT','ListTile background color']):
   raise RuntimeError('Flutter UI error found; sanitized device log retained')
  run(adb+['reverse','--remove','tcp:'+port]);print(tag,'real production task: partial/date/comparison/bilingual/large-font/return/restart PASS',flush=True)
finally:
 if fixture:admin('users/'+fixture,'DELETE')
 server.shutdown();server.server_close()
