#!/usr/bin/env python3
"""Actual Map page on emulator and Owner A device, using disposable account."""
import argparse,json,re,secrets,select,socket,socketserver,subprocess,tempfile,threading,time,urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path
from urllib.parse import urlparse
from verify_map_build import build,read,stamp
parser=argparse.ArgumentParser();parser.add_argument('--devices',nargs='+',required=True);parser.add_argument('--replay-only',action='store_true');args=parser.parse_args()
values=read('.env');credentials=read('test_credentials.local.md')
evidence=Path('docs/human/evidence/map-location-wave4-2026-09-17');evidence.mkdir(parents=True,exist_ok=True)
redactions=[*values.values(),*credentials.values()]
def clean(text):
 for value in redactions:
  if value:text=text.replace(value,'<REDACTED>')
 return re.sub(r'eyJ[A-Za-z0-9_.-]+','<TOKEN>',text)
def run(command):
 result=subprocess.run(command,capture_output=True,text=True)
 if result.returncode:raise RuntimeError('Device command failed: '+command[0])
 return clean(result.stdout+result.stderr)
def admin(path,method,body=None):
 req=urllib.request.Request(values['SUPABASE_URL']+'/auth/v1/admin/'+path,method=method,data=json.dumps(body).encode() if body is not None else None,headers={'apikey':values['SUPABASE_SECRET_KEY'],'Authorization':'Bearer '+values['SUPABASE_SECRET_KEY'],'Content-Type':'application/json'})
 with urllib.request.urlopen(req,timeout=30) as r:
  body=r.read();return json.loads(body) if body else None
allowed={urlparse(values['SUPABASE_URL']).hostname,'api.geoapify.com','tile.openstreetmap.org'}
class Tunnel(socketserver.StreamRequestHandler):
 def handle(self):
  line=self.rfile.readline(8192).decode('ascii','replace').strip();parts=line.split()
  if len(parts)!=3 or parts[0]!='CONNECT' or parts[1].split(':')[0] not in allowed or not parts[1].endswith(':443'):
   self.request.sendall(b'HTTP/1.1 403 Forbidden\r\n\r\n');return
  while self.rfile.readline(8192) not in [b'\r\n',b'\n',b'']:pass
  with socket.create_connection((parts[1].split(':')[0],443),timeout=30) as remote:
   self.request.sendall(b'HTTP/1.1 200 Connection Established\r\n\r\n')
   while True:
    ready,_,_=select.select([self.request,remote],[],[],30)
    if not ready:return
    for source in ready:
     data=source.recv(65536)
     if not data:return
     (remote if source is self.request else self.request).sendall(data)
class Server(socketserver.ThreadingTCPServer):daemon_threads=True
server=Server(('127.0.0.1',0),Tunnel);threading.Thread(target=server.serve_forever,daemon=True).start();port=str(server.server_address[1]);uid=None;installed=[];timeouts={};font_scales={}
try:
 email='locatemy.qa.map.'+secrets.token_hex(12)+'@gmail.com';password='Map!'+secrets.token_hex(24);redactions.extend([email,password]);uid=admin('users','POST',{'email':email,'password':password,'email_confirm':True})['id']
 with tempfile.TemporaryDirectory(prefix='locatemy-map-') as temporary:
  config=Path(temporary)/'fixture.json';config.write_text(json.dumps({**{k:values[k] for k in ['SUPABASE_URL','SUPABASE_PUBLISHABLE_KEY','GEOAPIFY_API_KEY'] if values.get(k)},'LOCATEMY_EMAIL':email,'LOCATEMY_PASSWORD':password,'LOCATEMY_PRIVACY_PROXY_PORT':port}));config.chmod(0o600)
  build(['--target','tool/map_location_device.dart','--dart-define-from-file',str(config)],'device-build')
 for device in args.devices:
  tag='owner-b-emulator' if device.startswith('emulator-') else 'owner-a-device';adb=['adb','-s',device];installed.append(device)
  (evidence/(tag+'-build.source.json')).write_text((evidence/'device-build.source.json').read_text())
  timeouts[device]=run(adb+['shell','settings','get','system','screen_off_timeout']).strip();run(adb+['shell','settings','put','system','screen_off_timeout','600000']);run(adb+['reverse','tcp:'+port,'tcp:'+port]);run(adb+['install','-r','build/app/outputs/flutter-apk/app-debug.apk']);run(adb+['shell','run-as','com.locatemy.app','rm','-rf','files/map-wave4-harness'])
  font_scale=run(adb+['shell','settings','get','system','font_scale']).strip();font_scales[device]=font_scale
  def launch():
   run(adb+['shell','am','force-stop','com.locatemy.app']);run(adb+['logcat','-c']);run(adb+['shell','am','start','-n','com.locatemy.app/.MainActivity'])
  def capture(stage):
   for attempt in range(5):
    xml=run(adb+['exec-out','uiautomator','dump','/dev/tty'])
    if '<?xml' in xml and '</hierarchy>' in xml:break
    time.sleep(1)
   else:raise RuntimeError('UI hierarchy unavailable: '+stage)
   xml=xml[xml.index('<?xml'):xml.rindex('</hierarchy>')+12]
   (evidence/(tag+'-'+stage+'.xml')).write_text(clean(xml))
   with (evidence/(tag+'-'+stage+'.png')).open('wb') as target:subprocess.run(adb+['exec-out','screencap','-p'],stdout=target,check=True)
   return ET.fromstring(xml)
  def wait(marker,stage):
   deadline=time.monotonic()+60
   while time.monotonic()<deadline:
    log=run(adb+['logcat','-d','-s','flutter:I']);filtered='\n'.join(line for line in log.splitlines() if 'MAP_DEVICE:' in line or 'PRIVACY_DEVICE:' in line)
    if 'FAILED' in filtered:raise RuntimeError(clean(filtered))
    if marker in filtered:
     (evidence/(tag+'-'+stage+'.txt')).write_text(clean(filtered));print(tag,marker,flush=True);time.sleep(.5);capture(stage);return
    time.sleep(1)
   (evidence/(tag+'-'+stage+'.txt')).write_text(clean(log));raise RuntimeError(tag+' timed out '+marker)
  def tap(labels,stage):
   if isinstance(labels,str):labels=[labels]
   for attempt in range(8):
    root=capture(stage+'-before');nodes=[n for n in root.iter('node') if any(label==n.attrib.get('text','').split('\n')[0] or label==n.attrib.get('content-desc','').split('\n')[0] for label in labels)]
    if nodes:
     bounds=list(map(int,re.findall(r'\d+',nodes[0].attrib['bounds'])));run(adb+['shell','input','tap',str((bounds[0]+bounds[2])//2),str((bounds[1]+bounds[3])//2)]);time.sleep(.8);capture(stage);return
    scrolls=[n for n in root.iter('node') if n.attrib.get('scrollable')=='true']
    if not scrolls:raise RuntimeError('No target '+str(labels))
    b=list(map(int,re.findall(r'\d+',scrolls[0].attrib['bounds'])));x=(b[0]+b[2])//2;run(adb+['shell','input','swipe',str(x),str(b[3]-80),str(x),str(b[1]+50),'400']);time.sleep(.3)
   raise RuntimeError('No target '+str(labels))
  run(adb+['shell','input','keyevent','224']);run(adb+['shell','wm','dismiss-keyguard']);time.sleep(2)
  launch();wait('READY','ready');tap('QA Pick','pick');wait('SELECTED_READY','selected')
  if not args.replay_only:
   tap(['地图','Map'],'map-tab');time.sleep(3);capture('map-zh')
   tap(['语言','Language'],'language');capture('map-en')
   try:
    run(adb+['shell','settings','put','system','font_scale','2.0']);time.sleep(2);capture('map-en-200')
    tap(['Language','语言'],'large-language');capture('map-zh-200');tap(['Language','语言'],'large-language-return')
   finally:run(adb+['shell','settings','put','system','font_scale',font_scale]);time.sleep(1)
   tap('View full analysis','analysis');capture('analysis-slot');run(adb+['shell','input','keyevent','4']);time.sleep(1);capture('return-map')
   tap('Enter coordinates','coordinates');capture('coordinate-dialog');run(adb+['shell','input','keyevent','4']);time.sleep(.5)
   tap('Compare locations','compare-mode');capture('comparison-empty');tap('Single','single-mode');tap(['Home','首页'],'home')
  tap('QA Outside','outside');wait('REJECTED_READY','rejected');tap('QA Queue','queue');wait('QUEUED_READY','queued');launch();wait('RESTART_QUEUED_READY','restart-queued')
  if not args.replay_only:
   tap(['Map','地图'],'restart-map');tap(['Saved','收藏'],'saved-queue');capture('queue-visible');run(adb+['shell','input','keyevent','4']);time.sleep(.5);tap(['Home','首页'],'restart-home')
  tap('QA Recover','recover');wait('RECOVERED_READY','recovered');tap('QA Close','close');wait('CLOSED_READY','closed');(evidence/(tag+'-verification.source.json')).write_text(json.dumps(stamp(),indent=2)+'\n')
finally:
 print('Restoring production APK and cleaning disposable fixtures',flush=True)
 cleanup_errors=[]
 try:
  build()
  for device in installed:
   try:
    run(['adb','-s',device,'install','-r','build/app/outputs/flutter-apk/app-debug.apk'])
    run(['adb','-s',device,'shell','run-as','com.locatemy.app','rm','-rf','files/map-wave4-harness'])
   except Exception as error:cleanup_errors.append(str(error))
 finally:
  for device in installed:
   try:
    if device in font_scales:run(['adb','-s',device,'shell','settings','put','system','font_scale',font_scales[device]])
    run(['adb','-s',device,'reverse','--remove','tcp:'+port])
    if device in timeouts:run(['adb','-s',device,'shell','settings','put','system','screen_off_timeout',timeouts[device]])
   except Exception as error:cleanup_errors.append(str(error))
  try:
   if uid:admin('users/'+uid,'DELETE')
  finally:
   server.shutdown();server.server_close()
  if cleanup_errors:print('Cleanup pending for disconnected device: '+', '.join(cleanup_errors),flush=True)
