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
EVIDENCE = ROOT / 'build/integration-evidence'
PACKAGE = 'com.locatemy.integrationqa'
parser = argparse.ArgumentParser()
parser.add_argument('--devices', nargs='+', required=True)
args = parser.parse_args()
EVIDENCE.mkdir(parents=True, exist_ok=True)
values = read_values(ROOT / '.env')
credentials = read_values(ROOT / 'test_credentials.local.md')
fixture = {key: credentials[key] for key in ['LOCATEMY_EMAIL', 'LOCATEMY_PASSWORD']}
redactions = [*values.values(), *credentials.values()]

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
    with tempfile.TemporaryDirectory(prefix='locatemy-property-device-') as temporary:
        build = Path(temporary)
        for name in ['lib', 'tool', 'assets', 'android']:
            shutil.copytree(ROOT / name, build / name, ignore=shutil.ignore_patterns('build', '.gradle', '__pycache__'))
        for name in ['pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml', 'l10n.yaml']:
            if (ROOT / name).exists():
                shutil.copy2(ROOT / name, build / name)
        (build / '.env').write_text('\n'.join(key + '=' + values[key] for key in ['SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY', 'GEOAPIFY_API_KEY'] if values.get(key)) + '\n')
        gradle = build / 'android/app/build.gradle.kts'
        gradle.write_text(gradle.read_text().replace('applicationId = "com.locatemy.app"', 'applicationId = "' + PACKAGE + '"'))
        print('Building isolated real production integration QA app', flush=True)
        result = subprocess.run(['flutter', 'build', 'apk', '--debug', '--target', 'tool/property_device.dart', '--dart-define=LOCATEMY_PROPERTY_FIXTURE_PORT=' + port], cwd=build, capture_output=True, text=True)
        (EVIDENCE / 'device-build.log').write_text(clean(result.stdout + result.stderr))
        if result.returncode:
            raise RuntimeError('QA build failed; sanitized log retained')
        apk = build / 'build/app/outputs/flutter-apk/app-debug.apk'
        with zipfile.ZipFile(apk) as archive:
            if any(secret.encode() in archive.read(name) for name in archive.namelist() for secret in [values.get('SUPABASE_SECRET_KEY', ''), *credentials.values()] if secret):
                raise RuntimeError('QA APK secret scan failed')
        target = EVIDENCE / 'integration-device-debug.apk'
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
            b = list(map(int, re.findall(r'\d+', nodes[-1].attrib['bounds'])))
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
                before = [(text(node), node.attrib.get('bounds')) for node in tree().iter('node')]
                if not swipe(-1):
                    return
                after = [(text(node), node.attrib.get('bounds')) for node in tree().iter('node')]
                if before == after:
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
        try:
            offline(False)
            run(adb+['shell','pm','clear',PACKAGE])
            run(adb+['shell','settings','put','system','font_scale','1.0'])
            run(adb+['shell','settings','put','system','screen_off_timeout','600000'])
            run(adb+['shell','input','keyevent','224']);run(adb+['shell','wm','dismiss-keyguard']);run(adb+['logcat','-c'])
            run(adb+['shell','am','start','-n',PACKAGE+'/com.locatemy.app.MainActivity'])
            wait('探索地图')
            tap('账户')
            capture('account-zh-redacted')
            tap('我的隐患')
            wait('我的隐患')
            capture('my-hazards-zh')
            back()
            top()
            tap('房产实勘')
            wait('新增房产实勘')
            capture('portfolio-zh')
            back()
            top()
            for attempt in range(12):
                current_nodes = [node for node in tree().iter('node') if text(node).startswith('当前评估预案:')]
                if current_nodes:
                    tap_node(current_nodes[0])
                    break
                swipe()
            else:
                raise RuntimeError('Current budget entry unavailable')
            wait('预算预案')
            capture('budget-zh')
            back()
            back()
            tap('探索地图')
            choose('3.0738', '101.6077')
            tap('展开摘要')
            time.sleep(20)
            capture('location-summary-zh')
            summary_text = ''
            for index in range(5):
                summary_text += '\n'.join(text(node) for node in tree().iter('node'))
                swipe()
                capture('location-summary-' + str(index))
            if '全国基准 100' not in summary_text or 'ICI' not in summary_text:
                raise RuntimeError('Real cost and neutral infrastructure summary were not displayed')
            top()
            tap('收起摘要')
            tap('查看完整分析')
            wait('地点分析')
            capture('analysis-menu-zh')
            for label in ['生活成本', '治安与犯罪', '社会经济', '基础设施', '周边设施', '公共交通']:
                top()
                tap(label)
                time.sleep(3)
                capture('analysis-' + str(['生活成本', '治安与犯罪', '社会经济', '基础设施', '周边设施', '公共交通'].index(label)))
                back()
                wait('地点分析')
            back()
            back()
            wait('探索地图')
            print('INTEGRATION_DEVICE: account budget property hazards six analysis routes PASS', flush=True)
        except Exception:
            capture('failure')
            raise
        finally:
            offline(False)
            run(adb+['shell','settings','put','system','font_scale',old_scale])
            run(adb+['shell','settings','put','system','screen_off_timeout',old_timeout])
            # Keep the QA install on failed/adaptive runs for ordinary recovery.
            run(adb+['reverse','--remove','tcp:'+port])
finally:
    server.shutdown();server.server_close();fixture.clear()
