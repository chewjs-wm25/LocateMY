#!/usr/bin/env python3
"""Drive the real production Infrastructure routes on Owner A Android and Owner B emulator.

Builds an isolated application id. Local login credentials travel through a
loopback-only runtime fixture; APK assets contain only allowlisted public config.
"""
import argparse
import hashlib
import json
import re
import select
import shutil
import socket
import socketserver
import subprocess
import tempfile
import threading
import time
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path
from import_home_datasets import read_values

ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / 'build/cost_budget-wave6-evidence'
PACKAGE = 'com.locatemy.costbudgetqa'
parser = argparse.ArgumentParser()
parser.add_argument('--devices', nargs='+', required=True)
parser.add_argument('--presentation-only',action='store_true')
parser.add_argument('--resume-files',action='store_true')
parser.add_argument('--files-only',action='store_true')
args = parser.parse_args()
EVIDENCE.mkdir(parents=True, exist_ok=True)
values = read_values(ROOT / '.env')
credentials = read_values(ROOT / 'test_credentials.local.md')
fixture = {key: credentials[key] for key in ['LOCATEMY_EMAIL', 'LOCATEMY_PASSWORD']}
redactions = [*values.values(), *credentials.values()]
# Preserve account budgets around device interactions; JSON copies are local only.
def budget_api(path,method='GET',body=None,token=None):
    headers={'apikey':values['SUPABASE_PUBLISHABLE_KEY'],'Content-Type':'application/json'}
    if token:headers['Authorization']='Bearer '+token
    request=urllib.request.Request(values['SUPABASE_URL']+path,method=method,data=json.dumps(body).encode() if body is not None else None,headers=headers)
    with urllib.request.urlopen(request,timeout=30) as response:
        content=response.read();return json.loads(content) if content else None
qa_session=budget_api('/auth/v1/token?grant_type=password','POST',{'email':credentials['LOCATEMY_EMAIL'],'password':credentials['LOCATEMY_PASSWORD']})
qa_token=qa_session['access_token'];redactions.append(qa_token)
# These reserved QA names were absent before the first device run. Remove only
# our interrupted-run fixtures before backing up the user's untouched selection.
if args.resume_files:
    for row in budget_api('/rest/v1/user_budget_scenarios?select=id,scenario_name',token=qa_token):
        if row['scenario_name'] in ['QABudgetCost','ShouldNotSave']:
            budget_api('/rest/v1/user_budget_scenarios?id=eq.'+row['id'],'DELETE',token=qa_token)
original_budgets=budget_api('/rest/v1/user_budget_scenarios?select=id,is_current',token=qa_token)
original_ids={row['id'] for row in original_budgets}
original_current=next((row['id'] for row in original_budgets if row['is_current']),None)
if args.resume_files:
    budget_api('/rest/v1/user_budget_scenarios','POST',{'user_id':qa_session['user']['id'],'scenario_name':'QABudgetCost','housing_expense':0,'transport_expense':0,'monthly_net_income':3500,'household_monthly_gross_income_rm':8000},token=qa_token)
    resume_row=next(row for row in budget_api('/rest/v1/user_budget_scenarios?select=id,scenario_name',token=qa_token) if row['scenario_name']=='QABudgetCost')
    budget_api('/rest/v1/rpc/select_current_budget','POST',{'scenario_id':resume_row['id']},token=qa_token)
def restore_budgets():
    for row in budget_api('/rest/v1/user_budget_scenarios?select=id,scenario_name',token=qa_token):
        if row['id'] not in original_ids and row['scenario_name'] in ['QABudgetCost','ShouldNotSave']:
            budget_api('/rest/v1/user_budget_scenarios?id=eq.'+row['id'],'DELETE',token=qa_token)
    if original_current:budget_api('/rest/v1/rpc/select_current_budget','POST',{'scenario_id':original_current},token=qa_token)


def clean(text):
    for value in redactions:
        if value:
            text = text.replace(value, '<REDACTED>')
    return re.sub(r'eyJ[A-Za-z0-9_.-]+', '<TOKEN>', text)

def run(command, cwd=None):
    result = subprocess.run(command, cwd=cwd, capture_output=True)
    if result.returncode:
        raise RuntimeError(clean((result.stdout + result.stderr).decode(errors='replace')))
    return result.stdout

allowed = {urllib.parse.urlparse(values['SUPABASE_URL']).hostname,
           'api.geoapify.com', 'tile.openstreetmap.org', 'overpass-api.de'}
active = set()
lock = threading.Lock()
network = {'offline': False}
class Tunnel(socketserver.StreamRequestHandler):
    def handle(self):
        parts = self.rfile.readline(8192).decode('ascii', 'replace').strip().split()
        if len(parts) != 3:
            return
        while self.rfile.readline(8192) not in [b'\r\n', b'\n', b'']:
            pass
        if parts[:2] == ['GET', '/fixture']:
            body = json.dumps(fixture).encode()
            self.request.sendall(b'HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: ' + str(len(body)).encode() + b'\r\nConnection: close\r\n\r\n' + body)
            return
        if network['offline'] or parts[0] != 'CONNECT' or parts[1].split(':')[0] not in allowed or not parts[1].endswith(':443'):
            self.request.sendall(b'HTTP/1.1 503 Service Unavailable\r\nConnection: close\r\n\r\n')
            return
        try:
            with socket.create_connection((parts[1].split(':')[0], 443), timeout=30) as remote:
                with lock:
                    active.add(self.request)
                self.request.sendall(b'HTTP/1.1 200 Connection Established\r\n\r\n')
                while True:
                    ready, _, _ = select.select([self.request, remote], [], [], 30)
                    if not ready:
                        return
                    for source in ready:
                        data = source.recv(65536)
                        if not data:
                            return
                        (remote if source is self.request else self.request).sendall(data)
        except OSError:
            pass
        finally:
            with lock:
                active.discard(self.request)
class Server(socketserver.ThreadingTCPServer):
    daemon_threads = True
server = Server(('127.0.0.1', 0), Tunnel)
threading.Thread(target=server.serve_forever, daemon=True).start()
port = str(server.server_address[1])
def offline(value):
    network['offline'] = value
    if value:
        with lock:
            for connection in tuple(active):
                try:
                    connection.shutdown(socket.SHUT_RDWR)
                except OSError:
                    pass
try:
    with tempfile.TemporaryDirectory(prefix='locatemy-cost_budget-device-') as temporary:
        build = Path(temporary)
        for name in ['lib', 'tool', 'assets', 'android']:
            shutil.copytree(ROOT / name, build / name, ignore=shutil.ignore_patterns('build', '.gradle', '__pycache__'))
        for name in ['pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml', 'l10n.yaml']:
            if (ROOT / name).exists():
                shutil.copy2(ROOT / name, build / name)
        (build / '.env').write_text('\n'.join(key + '=' + values[key] for key in ['SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY', 'GEOAPIFY_API_KEY'] if values.get(key)) + '\n')
        gradle = build / 'android/app/build.gradle.kts'
        gradle.write_text(gradle.read_text().replace('applicationId = "com.locatemy.app"', 'applicationId = "' + PACKAGE + '"'))
        print('Building isolated real production Cost Budget QA app', flush=True)
        result = subprocess.run(['flutter', 'build', 'apk', '--debug', '--target', 'tool/cost_budget_device.dart', '--dart-define=LOCATEMY_COST_FIXTURE_PORT=' + port], cwd=build, capture_output=True, text=True)
        (EVIDENCE / 'device-build.log').write_text(clean(result.stdout + result.stderr))
        if result.returncode:
            raise RuntimeError('QA build failed; sanitized log retained')
        apk = build / 'build/app/outputs/flutter-apk/app-debug.apk'
        with zipfile.ZipFile(apk) as archive:
            if any(secret.encode() in archive.read(name) for name in archive.namelist() for secret in [values.get('SUPABASE_SECRET_KEY', ''), *credentials.values()] if secret):
                raise RuntimeError('QA APK secret scan failed')
        target = EVIDENCE / 'cost_budget-device-debug.apk'
        shutil.copy2(apk, target)
        digest = hashlib.sha256()
        for path in sorted((build / 'lib').rglob('*.dart')):
            digest.update(str(path.relative_to(build)).encode() + b'\0' + path.read_bytes())
        stamp = {'base_head': run(['git', 'rev-parse', 'HEAD']).decode().strip(), 'source_sha256': digest.hexdigest(), 'apk_sha256': hashlib.sha256(apk.read_bytes()).hexdigest(), 'secret_scan': 'PASS'}
        (EVIDENCE / 'device-build.source.json').write_text(json.dumps(stamp, indent=2) + '\n')
    for device in args.devices:
        tag = 'owner-b-emulator' if device.startswith('emulator-') else 'owner-a-device'
        adb = ['adb', '-s', device]
        old_scale = run(adb + ['shell', 'settings', 'get', 'system', 'font_scale']).decode().strip()
        old_timeout = run(adb + ['shell', 'settings', 'get', 'system', 'screen_off_timeout']).decode().strip()
        run(adb + ['reverse', 'tcp:' + port, 'tcp:' + port])
        run(adb + ['install', '-r', str(target)])
        def tree():
            for attempt in range(4):
                xml = run(adb + ['exec-out', 'uiautomator', 'dump', '/dev/tty']).decode(errors='replace')
                if '<?xml' in xml and '</hierarchy>' in xml:
                    return ET.fromstring(xml[xml.index('<?xml'):xml.rindex('</hierarchy>') + 12])
                time.sleep(.7)
            raise RuntimeError('UI tree unavailable after four attempts')
        def text(node):
            return node.attrib.get('text', '') or node.attrib.get('content-desc', '') or node.attrib.get('hint','')
        def center(node):
            b = list(map(int, re.findall(r'\d+', node.attrib['bounds'])))
            return [(b[0] + b[2]) // 2, (b[1] + b[3]) // 2]
        def tap_node(node):
            x, y = center(node)
            run(adb + ['shell', 'input', 'tap', str(x), str(y)])
            time.sleep(.6)
        def swipe(direction=1):
            nodes = [n for n in tree().iter('node') if n.attrib.get('scrollable') == 'true']
            if not nodes:
                return False
            b = list(map(int, re.findall(r'\d+', nodes[0].attrib['bounds'])))
            x = (b[0] + b[2]) // 2
            start, end = b[3] - 90, b[1] + 70
            if direction < 0:
                start, end = end, start
            run(adb + ['shell', 'input', 'swipe', str(x), str(start), str(x), str(end), '350'])
            time.sleep(.5)
            return True
        def tap(label):
            for attempt in range(16):
                nodes = [n for n in tree().iter('node') if label == text(n) or label == text(n).split('\n')[0]]
                if nodes:
                    tap_node(nodes[0])
                    return
                if not swipe():
                    time.sleep(1)
            raise RuntimeError(tag + ': missing action ' + label)
        def wait(label, seconds=60):
            deadline = time.monotonic() + seconds
            while time.monotonic() < deadline:
                if any(label in text(n) for n in tree().iter('node')):
                    return
                time.sleep(1)
            raise RuntimeError(tag + ': missing expected content ' + label)
        def capture(stage):
            print(tag,stage,flush=True)
            root = tree()
            raw = ET.tostring(root, encoding='unicode')
            (EVIDENCE / (tag + '-' + stage + '.xml')).write_text(clean(raw))
            # Never capture the real email/password shown by an account/login view.
            if not any(value and value in raw for value in credentials.values()):
                with (EVIDENCE / (tag + '-' + stage + '.png')).open('wb') as output:
                    subprocess.run(adb + ['exec-out', 'screencap', '-p'], stdout=output, check=True)
            return root
        def back():
            run(adb + ['shell', 'input', 'keyevent', '4'])
            time.sleep(.7)
        def top():
            for attempt in range(8):
                if not swipe(-1):
                    return
        def choose(latitude, longitude):
            tap('输入坐标')
            fields = [n for n in tree().iter('node') if n.attrib.get('class') == 'android.widget.EditText']
            if len(fields) != 2:
                raise RuntimeError('Coordinate form fields missing')
            for field, value in zip(fields, [latitude, longitude]):
                tap_node(field)
                run(adb + ['shell', 'input', 'text', value])
            back()
            tap('选择')
            wait(latitude)
        def fill(label,value):
            for attempt in range(12):
                nodes=[n for n in tree().iter('node') if n.attrib.get('class')=='android.widget.EditText' and label in (n.attrib.get('text','')+' '+n.attrib.get('content-desc','')+' '+n.attrib.get('hint',''))]
                if nodes:
                    tap_node(nodes[0]);run(adb+['shell','input','text',value]);back();return
                if not swipe():time.sleep(.6)
            raise RuntimeError('Missing field '+label)
        def open_cost():
            tap('探索地图');choose('3.0738','101.6077');tap('查看完整分析');tap('生活成本');wait('核心市场篮子估算月支出');wait('覆盖率未知')
        try:
            offline(False)
            run(adb+['shell','pm','clear',PACKAGE])
            run(adb+['shell','settings','put','system','font_scale','1.0'])
            run(adb+['shell','settings','put','system','screen_off_timeout','600000'])
            run(adb+['shell','input','keyevent','224']);run(adb+['shell','wm','dismiss-keyguard']);run(adb+['logcat','-c'])
            run(adb+['shell','am','start','-n',PACKAGE+'/com.locatemy.app.MainActivity'])
            if args.files_only:
                wait('探索地图');open_cost();top();tap('预案');wait('QABudgetCost')
                tap('导出 JSON');wait('导出已保存至本机');tap('打开导出副本');wait('导出副本');capture('json-final-copy-zh');back()
                local_before=run(adb+['shell','run-as',PACKAGE,'find','app_flutter/budget_exports','-name',"'*.json'"]).decode()
                json_paths=sorted(line.strip() for line in local_before.splitlines() if line.strip().endswith('.json'))
                if len(json_paths)!=1:raise RuntimeError('Expected one actual JSON export')
                tap('本机导出文件');wait('.json');capture('json-final-files-zh')
                run(adb+['shell','am','force-stop',PACKAGE]);run(adb+['shell','am','start','-n',PACKAGE+'/com.locatemy.app.MainActivity']);wait('探索地图');open_cost();top();tap('预案');tap('本机导出文件');wait('.json');capture('json-final-restart-zh');back();back();back();back()
                tap('账户');wait('QABudgetCost')
                (EVIDENCE/(tag+'-account-current.xml')).write_text(clean(ET.tostring(tree(),encoding='unicode')))
                tap('退出当前设备');tap('退出');wait('登录');capture('json-final-signed-out')
                local_after=run(adb+['shell','run-as',PACKAGE,'find','app_flutter/budget_exports','-name',"'*.json'"]).decode()
                if sorted(line.strip() for line in local_after.splitlines() if line.strip().endswith('.json'))!=json_paths:raise RuntimeError('Actual JSON file names changed on sign out')
                run(adb+['shell','am','force-stop',PACKAGE]);run(adb+['shell','am','start','-n',PACKAGE+'/com.locatemy.app.MainActivity']);wait('探索地图');open_cost();top();tap('预案');tap('本机导出文件');wait('.json');tap(Path(json_paths[0]).name);wait('导出副本');capture('json-final-relogin-copy-zh')
                (EVIDENCE/(tag+'-json-verification.json')).write_text(json.dumps({**stamp,'actual_json_file_paths':json_paths,'export_visible_feedback_open':'PASS','restart_public_list':'PASS','logout_file_retention':'PASS','relogin_same_copy_open':'PASS','account_shared_current':'PASS'},indent=2)+'\n')
                print(tag,'JSON LIFECYCLE ALL PASS',flush=True)
                continue
            if args.resume_files:
                wait('探索地图');open_cost();top();tap('预案');wait('QABudgetCost')
            else:
                wait('探索地图');open_cost();capture('cost-single-zh')
                tap('语言');wait('Core market basket estimated monthly spending');capture('cost-single-en');tap('Language')
                top();tap('预案');wait('新增预案');tap('新增预案');tap('在线保存');wait('请输入 1–120 个字符');capture('budget-invalid-name-zh')
                fill('名称','QABudgetCost');fill('住房支出','0');fill('交通支出','0');fill('月净收入','3500');fill('家庭月度总收入','8000')
                tap('在线保存');wait('QABudgetCost');tap('选为当前');wait('保存成功');capture('budget-current-zero-zh')
            tap('导出 JSON');wait('导出已保存至本机');tap('打开导出副本');wait('导出副本');capture('json-copy-zh');back()
            tap('本机导出文件');wait('.json');capture('json-files-zh');back()
            offline(True);top();tap('新增预案');fill('名称','ShouldNotSave');tap('在线保存');wait('尚未保存',seconds=35);capture('budget-offline-failed-zh')
            offline(False);tap('在线保存');wait('ShouldNotSave');capture('budget-retry-saved-zh')
            tap('语言');wait('New scenario');capture('budget-en');tap('Language');back()
            # Authenticated routes close on restart; local copies remain on disk.
            local_before=run(adb+['shell','run-as',PACKAGE,'find','app_flutter/budget_exports','-name',"'*.json'"]).decode()
            if not local_before.strip():raise RuntimeError('Real export file absent')
            run(adb+['shell','am','force-stop',PACKAGE]);run(adb+['shell','am','start','-n',PACKAGE+'/com.locatemy.app.MainActivity']);wait('探索地图');open_cost();tap('预案');tap('本机导出文件');wait('.json');capture('json-after-restart-zh');back();back();back();back()
            tap('两地比较');choose('3.0738','101.6077');tap('地点 B');choose('1.4927','103.7414');tap('查看地点比较');tap('生活成本');wait('两地点不可比较');capture('cost-comparison-zh');back();back()
            tap('单点');tap('查看完整分析');tap('生活成本');wait('核心市场篮子估算月支出')
            run(adb+['shell','settings','put','system','font_scale','2.0']);time.sleep(2);capture('cost-small-200-zh');top();tap('语言');capture('cost-small-200-en');top()
            run(adb+['shell','settings','put','system','font_scale','1.0']);back();back();tap('Account');tap('Sign out of this device');tap('Sign out');wait('Sign in');capture('signed-out')
            local_after=run(adb+['shell','run-as',PACKAGE,'find','app_flutter/budget_exports','-name',"'*.json'"]).decode()
            if local_after!=local_before:raise RuntimeError('Export copies changed after sign out')
            pid=run(adb+['shell','pidof','-s',PACKAGE]).decode().strip();logs=clean(run(adb+['logcat','-d','--pid',pid]).decode(errors='replace'));(EVIDENCE/(tag+'-device.log')).write_text(logs)
            if any(m in logs for m in ['A RenderFlex overflowed','EXCEPTION CAUGHT BY','COST_DEVICE: FAILED']):raise RuntimeError('Flutter exception retained')
            (EVIDENCE/(tag+'-verification.json')).write_text(json.dumps({**stamp,'single':'PASS','comparison_partial':'PASS','budget_online_zero_null_current':'PASS','offline_save_retry':'PASS','bilingual':'PASS','small_font_200':'PASS','real_json_export_restart_logout':'PASS','semantics_xml':'PASS'},indent=2)+'\n')
            print(tag,'ALL PASS',flush=True)
        except Exception:
            pid = run(adb + ['shell', 'pidof', '-s', PACKAGE]).decode().strip()
            if pid:
                (EVIDENCE / (tag + '-failure.log')).write_text(clean(run(adb + ['logcat', '-d', '--pid', pid]).decode(errors='replace')))
            capture('failure')
            raise
        finally:
            offline(False)
            run(adb + ['shell', 'settings', 'put', 'system', 'font_scale', old_scale])
            run(adb + ['shell', 'settings', 'put', 'system', 'screen_off_timeout', old_timeout])
            run(adb + ['shell', 'am', 'force-stop', PACKAGE])
            run(adb + ['reverse', '--remove', 'tcp:' + port])
            run(adb + ['uninstall', PACKAGE])
finally:
    restore_budgets()
    server.shutdown()
    server.server_close()
    fixture.clear()
