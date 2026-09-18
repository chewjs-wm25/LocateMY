#!/usr/bin/env python3
"""Home device acceptance with disposable fixtures and a scoped TLS tunnel."""
import argparse,hashlib,json,os,re,secrets,select,socket,socketserver,subprocess,tempfile,threading,time,urllib.request,zipfile
import xml.etree.ElementTree as ET
from pathlib import Path
from urllib.parse import urlparse
from import_home_datasets import read_values
parser=argparse.ArgumentParser();parser.add_argument('--devices',nargs='+',required=True);args=parser.parse_args()
values=read_values('.env');credentials=read_values('test_credentials.local.md')
evidence=Path('build/home-wave4-evidence');evidence.mkdir(parents=True,exist_ok=True)
redactions=[*values.values(),*credentials.values()]
def clean(text):
 for value in redactions:
  if value:text=text.replace(value,'<REDACTED>')
 return re.sub(r'eyJ[A-Za-z0-9_.-]+','<TOKEN>',text)
def run(command,name=None):
 result=subprocess.run(command,capture_output=True,text=True)
 output=clean(result.stdout+result.stderr)
 if name:(evidence/name).write_text(output)
 if result.returncode:raise RuntimeError('Command failed; see sanitized evidence: '+(name or command[0]))
 return output

def stamp():
 digest=hashlib.sha256()
 for path in sorted([*Path('lib').rglob('*.dart'),*Path('lib').rglob('*.arb'),*Path('test').rglob('*.dart'),*Path('tool').glob('*.dart'),*Path('assets').rglob('*.*'),Path('pubspec.yaml'),Path('pubspec.lock')]):digest.update(str(path).encode()+b'\0'+path.read_bytes())
 return {'base_head':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),'source_sha256':digest.hexdigest()}
def build(extra,name,harness=False):
 original=Path('.env').read_bytes();before=stamp()
 try:
  Path('.env').write_text('\n'.join(k+'='+values[k] for k in ['SUPABASE_URL','SUPABASE_PUBLISHABLE_KEY'])+'\n')
  run(['flutter','build','apk','--debug',*extra],name)
  forbidden=[values['SUPABASE_SECRET_KEY'],*credentials.values()]+([] if harness else fixture_values)
  with zipfile.ZipFile('build/app/outputs/flutter-apk/app-debug.apk') as apk:
   if any(value.encode() in apk.read(n) for n in apk.namelist() for value in forbidden if value):raise RuntimeError('Sensitive credential in APK')
  if before!=stamp():raise RuntimeError('Source changed during build')
  (evidence/(name+'.source.json')).write_text(json.dumps({**before,'apk_sha256':hashlib.sha256(Path('build/app/outputs/flutter-apk/app-debug.apk').read_bytes()).hexdigest(),'secret_scan':'PASS'},indent=2)+'\n')
 finally:Path('.env').write_bytes(original)
def admin(path,method,body=None):
 req=urllib.request.Request(values['SUPABASE_URL']+'/auth/v1/admin/'+path,method=method,data=None if body is None else json.dumps(body).encode(),headers={'apikey':values['SUPABASE_SECRET_KEY'],'Authorization':'Bearer '+values['SUPABASE_SECRET_KEY'],'Content-Type':'application/json'})
 try:
  with urllib.request.urlopen(req,timeout=30) as r:return json.loads(r.read())
 except Exception:raise RuntimeError('Fixture administration failed; details redacted') from None
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
class Server(socketserver.ThreadingTCPServer):daemon_threads=True
server=Server(('127.0.0.1',0),Tunnel);threading.Thread(target=server.serve_forever,daemon=True).start()
port=str(server.server_address[1]);ids=[];fixture_values=[];installed=[];timeouts={}
try:
 email='locatemy.qa.home.'+secrets.token_hex(12)+'@gmail.com';password='Home!'+secrets.token_hex(24)
 redactions.extend([email,password]);fixture_values.extend([email,password]);ids.append(admin('users','POST',{'email':email,'password':password,'email_confirm':True})['id'])
 with tempfile.TemporaryDirectory(prefix='locatemy-home-') as temporary:
  config=Path(temporary)/'fixture.json';config.write_text(json.dumps({**{k:values[k] for k in ['SUPABASE_URL','SUPABASE_PUBLISHABLE_KEY']},'LOCATEMY_EMAIL':email,'LOCATEMY_PASSWORD':password,'LOCATEMY_PRIVACY_PROXY_PORT':port}));config.chmod(0o600)
  print('Building isolated Home device harness',flush=True);build(['--target','tool/home_outlook_device.dart','--dart-define-from-file',str(config)],'device-build.log',True)
 for device in args.devices:
  tag='owner-b-emulator' if device.startswith('emulator-') else 'owner-a-device';adb=['adb','-s',device]
  installed.append(device)
  timeouts[device]=run(adb+['shell','settings','get','system','screen_off_timeout']).strip();run(adb+['shell','settings','put','system','screen_off_timeout','600000'])
  run(adb+['reverse','tcp:'+port,'tcp:'+port]);run(adb+['install','-r','build/app/outputs/flutter-apk/app-debug.apk'],tag+'-install.log')
  run(adb+['shell','run-as','com.locatemy.app','rm','-rf','files/home-wave4-harness'])
  def launch():
   run(adb+['shell','am','force-stop','com.locatemy.app']);run(adb+['logcat','-c']);run(adb+['shell','am','start','-n','com.locatemy.app/.MainActivity'])
  def capture(stage):
   xml=run(adb+['exec-out','uiautomator','dump','/dev/tty']);xml=xml[xml.index('<?xml'):xml.rindex('</hierarchy>')+12]
   (evidence/(tag+'-'+stage+'.xml')).write_text(clean(xml))
   with (evidence/(tag+'-'+stage+'.png')).open('wb') as target:subprocess.run(adb+['exec-out','screencap','-p'],stdout=target,check=True)
   return ET.fromstring(xml)
  def wait(marker,stage):
   deadline=time.monotonic()+60
   while time.monotonic()<deadline:
    log=run(adb+['logcat','-d','-s','flutter:I']);filtered='\n'.join(line for line in log.splitlines() if 'HOME_DEVICE:' in line)
    if 'FAILED' in filtered:raise RuntimeError(clean(filtered))
    if marker in filtered:
     (evidence/(tag+'-'+stage+'.log')).write_text(clean(filtered));print(tag,marker,flush=True);time.sleep(1);capture(stage);return
    time.sleep(1)
   (evidence/(tag+'-'+stage+'.log')).write_text(clean(log));raise RuntimeError(tag+' marker timed out: '+marker)
  def tap(labels,stage):
   if isinstance(labels,str):labels=[labels]
   for attempt in range(12):
    root=capture(stage+'-before');nodes=[n for n in root.iter('node') if n.attrib.get('text','').split('\n')[0] in labels or n.attrib.get('content-desc','').split('\n')[0] in labels]
    if nodes:
     bounds=list(map(int,re.findall(r'\d+',nodes[0].attrib['bounds'])));run(adb+['shell','input','tap',str((bounds[0]+bounds[2])//2),str((bounds[1]+bounds[3])//2)]);time.sleep(1);capture(stage);return
    scrolls=[n for n in root.iter('node') if n.attrib.get('scrollable')=='true']
    if not scrolls:raise RuntimeError('No scrollable page for target '+str(labels))
    bounds=list(map(int,re.findall(r'\d+',scrolls[0].attrib['bounds'])))
    x=(bounds[0]+bounds[2])//2; top= bounds[1];height=bounds[3]-top
    run(adb+['shell','input','swipe',str(x),str(top+int(height*.8)),str(x),str(top+int(height*.2)),'400']);time.sleep(.3)
   raise RuntimeError('UI target missing: '+str(labels))
  launch();wait('FRESH_READY','fresh-zh')
  root=capture('pull-refresh-before')
  scroll=next(n for n in root.iter('node') if n.attrib.get('scrollable')=='true')
  bounds=list(map(int,re.findall(r'\d+',scroll.attrib['bounds'])))
  x=(bounds[0]+bounds[2])//2;top=bounds[1];height=bounds[3]-top
  run(adb+['shell','input','swipe',str(x),str(top+int(height*.2)),str(x),str(top+int(height*.8)),'600'])
  time.sleep(3);root=capture('pull-refresh')
  visible=' '.join(n.attrib.get('text','')+' '+n.attrib.get('content-desc','') for n in root.iter('node'))
  if '秒后可再次刷新' not in visible and 'Refresh available in' not in visible:raise RuntimeError('Pull refresh did not present cooldown')
  print(tag,'PULL_REFRESH_READY',flush=True)
  tap(['刷新','Refresh'],'button-refresh');tap('QA Cooldown','cooldown');wait('COOLDOWN_READY','cooldown-result')
  tap(['语言','Language'],'language');capture('fresh-en')
  tap('QA Offline','offline');wait('STALE_READY','stale')
  launch();wait('RESTART_STALE_READY','restart-stale')
  tap('QA Recover','recover');wait('RECOVERED_READY','recovered')
  # Explore uses actual page/Shell; scrolling coordinates come from current tree.
  tap(['Explore map','探索地图'],'explore');capture('map-tab')
  tap(['Home','首页'],'back-home');capture('return-home')
  tap('QA Close','close');wait('CLOSED_READY','closed')
  (evidence/(tag+'-verification.source.json')).write_text(json.dumps(stamp(),indent=2)+'\n')
finally:
 print('Restoring scanned production APK and removing disposable fixtures',flush=True)
 try:
  build([],'production-build.log')
  for device in installed:
   run(['adb','-s',device,'install','-r','build/app/outputs/flutter-apk/app-debug.apk'])
   run(['adb','-s',device,'shell','run-as','com.locatemy.app','rm','-rf','files/home-wave4-harness'])
 finally:
  for device in installed:
   run(['adb','-s',device,'reverse','--remove','tcp:'+port])
   if device in timeouts:run(['adb','-s',device,'shell','settings','put','system','screen_off_timeout',timeouts[device]])
  for user in ids:admin('users/'+user,'DELETE')
  server.shutdown();server.server_close()
