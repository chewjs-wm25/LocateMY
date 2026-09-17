#!/usr/bin/env python3
"""Actual Map page on emulator and Owner A device, using disposable account."""
import argparse,json,re,secrets,select,socket,socketserver,subprocess,tempfile,threading,time,urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path
from urllib.parse import urlparse
from verify_hazard_build import build,read,stamp
parser=argparse.ArgumentParser();parser.add_argument('--devices',nargs='+',required=True);parser.add_argument('--replay-only',action='store_true');args=parser.parse_args()
values=read('.env');credentials=read('test_credentials.local.md')
evidence=Path('docs/human/evidence/hazard-reporting-completion-2026-09-17');evidence.mkdir(parents=True,exist_ok=True)
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
def rest(path,method,body=None):
 req=urllib.request.Request(values['SUPABASE_URL']+path,method=method,data=json.dumps(body).encode() if body is not None else None,headers={'apikey':values['SUPABASE_SECRET_KEY'],'Authorization':'Bearer '+values['SUPABASE_SECRET_KEY'],'Content-Type':'application/json'})
 with urllib.request.urlopen(req,timeout=30) as response:return response.read()
try:
 email='locatemy.qa.hazard.'+secrets.token_hex(12)+'@gmail.com';password='Hazard!'+secrets.token_hex(24);redactions.extend([email,password]);uid=admin('users','POST',{'email':email,'password':password,'email_confirm':True})['id']
 with tempfile.TemporaryDirectory(prefix='locatemy-hazard-') as temporary:
  config=Path(temporary)/'fixture.json';config.write_text(json.dumps({**{k:values[k] for k in ['SUPABASE_URL','SUPABASE_PUBLISHABLE_KEY']},'LOCATEMY_EMAIL':email,'LOCATEMY_PASSWORD':password,'LOCATEMY_PRIVACY_PROXY_PORT':port}));config.chmod(0o600)
  harness_apk=build(['--target','tool/hazard_reporting_device.dart','--dart-define-from-file',str(config)],'device-build')
 for device in args.devices:
  tag='owner-b-emulator' if device.startswith('emulator-') else 'owner-a-device';adb=['adb','-s',device];installed.append(device)
  (evidence/(tag+'-build.source.json')).write_text((evidence/'device-build.source.json').read_text())
  timeouts[device]=run(adb+['shell','settings','get','system','screen_off_timeout']).strip();font_scales[device]=run(adb+['shell','settings','get','system','font_scale']).strip()
  run(adb+['shell','settings','put','system','screen_off_timeout','600000']);run(adb+['shell','settings','put','system','font_scale','1.0'])
  run(adb+['reverse','tcp:'+port,'tcp:'+port]);run(adb+['install','-r',str(harness_apk)]);run(adb+['shell','run-as','com.locatemy.hazard.qa','rm','-rf','files/hazard-wave5-harness'])
  def launch():
   run(adb+['shell','am','force-stop','com.locatemy.hazard.qa']);run(adb+['logcat','-c']);run(adb+['shell','am','start','-n','com.locatemy.hazard.qa/com.locatemy.app.MainActivity'])
  def capture(stage):
   xml=''
   for capture_attempt in range(4):
    xml=run(adb+['exec-out','uiautomator','dump','/dev/tty'])
    if '<?xml' in xml and '</hierarchy>' in xml:break
    time.sleep(1)
   if '<?xml' not in xml or '</hierarchy>' not in xml:raise RuntimeError('UI tree unavailable at '+stage)
   xml=xml[xml.index('<?xml'):xml.rindex('</hierarchy>')+12]
   (evidence/(tag+'-'+stage+'.xml')).write_text(clean(xml))
   with (evidence/(tag+'-'+stage+'.png')).open('wb') as output:subprocess.run(adb+['exec-out','screencap','-p'],stdout=output,check=True)
   return ET.fromstring(xml)
  def wait(marker):
   deadline=time.monotonic()+60
   while time.monotonic()<deadline:
    log=run(adb+['logcat','-d','-s','flutter:I'])
    if 'HAZARD_DEVICE: '+marker in log:return
    time.sleep(1)
   raise RuntimeError('Device readiness timed out: '+marker)
  def tap(labels,stage):
   if isinstance(labels,str):labels=[labels]
   for attempt in range(14):
    tree=capture(stage+'-before')
    nodes=[n for n in tree.iter('node') if any(label==n.attrib.get('text','').split('\n')[0] or label==n.attrib.get('content-desc','').split('\n')[0] for label in labels)]
    if nodes:
     if nodes[0].attrib.get('enabled')=='false':
      time.sleep(1);continue
     b=list(map(int,re.findall(r'\d+',nodes[0].attrib['bounds'])));run(adb+['shell','input','tap',str((b[0]+b[2])//2),str((b[1]+b[3])//2)]);time.sleep(1);return
    scrolls=[n for n in tree.iter('node') if n.attrib.get('scrollable')=='true']
    if not scrolls:raise RuntimeError('UI target missing: '+str(labels))
    b=list(map(int,re.findall(r'\d+',scrolls[0].attrib['bounds'])));x=(b[0]+b[2])//2;run(adb+['shell','input','swipe',str(x),str(b[3]-80),str(x),str(b[1]+50),'400']);time.sleep(.4)
   raise RuntimeError('UI target not found after scrolling: '+str(labels))
  def back():run(adb+['shell','input','keyevent','4']);time.sleep(1)
  run(adb+['shell','input','keyevent','224']);run(adb+['shell','wm','dismiss-keyguard'])
  launch();wait('READY');capture('ready')
  tap('QA My Reports','entry-list')
  tap(['＋ 新建隐患报告','+ New hazard report'],'entry-create');tree=capture('entry-select')
  assert any('选择隐患位置' in n.attrib.get('text','') or '选择隐患位置' in n.attrib.get('content-desc','') for n in tree.iter('node')), 'Missing report selection guidance'
  tap(['输入坐标','Enter coordinates'],'entry-coordinates');tree=capture('entry-coordinate-fields')
  fields=[n for n in tree.iter('node') if n.attrib.get('class')=='android.widget.EditText']
  assert len(fields)==2, 'Expected latitude and longitude fields'
  for node,value in zip(fields,['3.0738','101.6072']):
   b=list(map(int,re.findall(r'\d+',node.attrib['bounds'])));run(adb+['shell','input','tap',str((b[0]+b[2])//2),str((b[1]+b[3])//2)])
   time.sleep(1);run(adb+['shell','input','text',value]);time.sleep(.5)
  back();tap(['选择','Select'],'entry-select-point');time.sleep(2)
  tap(['在此位置上报','Report at this location'],'entry-confirm');tree=capture('composer-zh')
  assert any('隐患类型' in n.attrib.get('text','') or '隐患类型' in n.attrib.get('content-desc','') for n in tree.iter('node')), 'Report form did not open'
  tap(['发布隐患报告','Publish hazard report'],'missing-type');capture('validation')
  # Submit scrolls back to the first invalid field.
  tap(['水灾','Flood'],'type')
  tree=capture('title-before');node=next(n for n in tree.iter('node') if n.attrib.get('class')=='android.widget.EditText')
  b=list(map(int,re.findall(r'\d+',node.attrib['bounds'])));run(adb+['shell','input','tap',str((b[0]+b[2])//2),str((b[1]+b[3])//2)])
  run(adb+['shell','input','text','QA-Hazard-'+tag]);back()
  tap(['发布隐患报告','Publish hazard report'],'publish');time.sleep(3);capture('my-reports-zh')
  tap(['查看详情','View details'],'details');capture('detail-zh')
  tap(['赞成  0','Support  0'],'vote');capture('voted')
  tap(['标记为已解决','Mark resolved'],'resolve');capture('resolved')
  tap(['标记为待处理','Mark pending'],'pending');capture('pending')
  tap(['删除','Delete'],'delete-dialog');capture('delete-confirmation');tap(['取消','Cancel'],'cancel-delete');capture('delete-cancelled')
  tap(['语言','Language'],'language');capture('detail-en')
  try:
   run(adb+['shell','settings','put','system','font_scale','2.0']);time.sleep(2);capture('detail-en-200')
   tap(['Withdraw vote','撤回投票'],'retract-200');capture('retracted-200')
  finally:run(adb+['shell','settings','put','system','font_scale','1.0']);time.sleep(1)
  back();capture('return-list');back();tap(['Home','首页'],'return-home-tab');capture('return-home')
  tap('QA Offline','offline');wait('OFFLINE_READY');tap('QA Composer','offline-composer')
  tap(['Flood','水灾'],'offline-type');tree=capture('offline-title');node=next(n for n in tree.iter('node') if n.attrib.get('class')=='android.widget.EditText')
  b=list(map(int,re.findall(r'\d+',node.attrib['bounds'])));run(adb+['shell','input','tap',str((b[0]+b[2])//2),str((b[1]+b[3])//2)])
  run(adb+['shell','input','text','QA-offline-retained']);back();tap(['Publish hazard report','发布隐患报告'],'offline-publish');capture('offline-retained')
  back();tap('QA Recover','recover');wait('ONLINE_READY');launch();wait('READY');tap('QA My Reports','restart-list');capture('restart-persisted')
  tap(['查看详情','View details'],'restart-detail');tap(['地图定位','Locate on map'],'locate');time.sleep(3);capture('map-layer');tap(['Home','首页'],'home')
  tap('QA My Reports','final-list');tap(['查看详情','View details'],'final-detail')
  tap(['删除','Delete'],'final-delete-dialog');tap(['删除','Delete'],'final-delete-confirm');time.sleep(2);tree=capture('deleted-list')
  assert not any('QA-Hazard-' in n.attrib.get('text','') or 'QA-Hazard-' in n.attrib.get('content-desc','') for n in tree.iter('node')), 'Deleted report still visible'
  back()
  tap('QA Close','close');wait('CLOSED_READY');capture('closed')
  (evidence/(tag+'-verification.source.json')).write_text(json.dumps(stamp(),indent=2)+'\n')
  print(tag+' PASS: form, votes, status, confirmation, offline, restart, map and close',flush=True)
finally:
 print('Removing isolated QA APK and cleaning disposable fixtures',flush=True)
 cleanup_errors=[]
 try:
  for device in installed:
   try:
    run(['adb','-s',device,'uninstall','com.locatemy.hazard.qa'])
   except Exception as error:cleanup_errors.append(str(error))
 finally:
  for device in installed:
   try:
    if device in font_scales:run(['adb','-s',device,'shell','settings','put','system','font_scale',font_scales[device]])
    run(['adb','-s',device,'reverse','--remove','tcp:'+port])
    if device in timeouts:run(['adb','-s',device,'shell','settings','put','system','screen_off_timeout',timeouts[device]])
   except Exception as error:cleanup_errors.append(str(error))
  try:
   if uid:
    rest('/rest/v1/crowdsourced_hazards?user_id=eq.'+uid,'DELETE')
    admin('users/'+uid,'DELETE')
  finally:
   server.shutdown();server.server_close()
  if cleanup_errors:print('Cleanup pending for disconnected device: '+', '.join(cleanup_errors),flush=True)
