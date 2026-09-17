#!/usr/bin/env python3
"""Isolated APK builds and real Auth/Privacy/Shell/Map/Overpass device evidence."""
import argparse, hashlib, json, re, select, shutil, socket, socketserver
import subprocess, tempfile, threading, time, urllib.parse, xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / 'docs/human/evidence/nearby-facilities-wave5-2026-09-17'
EVIDENCE.mkdir(parents=True, exist_ok=True)
PACKAGE = 'com.locatemy.facilityqa'

def read(path):
    return {k.strip(): v.strip().strip('\"\'') for line in path.read_text().splitlines()
            if '=' in line and not line.lstrip().startswith('#') for k, v in [line.split('=', 1)]}
values = read(ROOT / '.env')
credentials = read(ROOT / 'test_credentials.local.md')
fixture = {k: values[k] for k in ['SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY']}
fixture.update({k: credentials[k] for k in ['LOCATEMY_EMAIL', 'LOCATEMY_PASSWORD']})
redactions = [*values.values(), *credentials.values()]
def clean(value):
    for secret in redactions:
        if secret:
            value = value.replace(secret, '<REDACTED>')
    return re.sub(r'eyJ[A-Za-z0-9_.-]+', '<TOKEN>', value)

def run(command, **kwargs):
    result = subprocess.run(command, capture_output=True, **kwargs)
    if result.returncode:
        raise RuntimeError(clean((result.stdout + result.stderr).decode(errors='replace')))
    return result.stdout

allowed = {urllib.parse.urlparse(values['SUPABASE_URL']).hostname,
           'overpass-api.de', 'tile.openstreetmap.org'}
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
        if parts[0] != 'CONNECT' or parts[1].split(':')[0] not in allowed or not parts[1].endswith(':443'):
            self.request.sendall(b'HTTP/1.1 403 Forbidden\r\n\r\n')
            return
        with socket.create_connection((parts[1].split(':')[0], 443), timeout=30) as remote:
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
class Server(socketserver.ThreadingTCPServer):
    daemon_threads = True
server = Server(('127.0.0.1', 0), Tunnel)
threading.Thread(target=server.serve_forever, daemon=True).start()
port = str(server.server_address[1])

def stamp():
    digest = hashlib.sha256()
    files = [*ROOT.joinpath('lib/features/nearby_facilities').rglob('*.dart'),
             *ROOT.joinpath('test/features/nearby_facilities').rglob('*.dart'),
             ROOT / 'lib/app/app.dart', ROOT / 'lib/app/src/presentation/shell_host.dart',
             ROOT / 'tool/nearby_facilities_device.dart', ROOT / 'pubspec.yaml', ROOT / 'pubspec.lock']
    for path in sorted(files):
        digest.update(str(path.relative_to(ROOT)).encode() + b'\0' + path.read_bytes())
    return {'base_head': run(['git', 'rev-parse', 'HEAD'], cwd=ROOT).decode().strip(),
            'facility_source_sha256': digest.hexdigest()}

parser = argparse.ArgumentParser()
parser.add_argument('--devices', nargs='+', required=True)
parser.add_argument('--skip-production-build', action='store_true', help='Reuse successful production evidence only when its source fingerprint matches')
args = parser.parse_args()
try:
    with tempfile.TemporaryDirectory(prefix='locatemy-facility-build-') as temporary:
        checkout = Path(temporary)
        for name in ['lib', 'assets', 'android', 'tool']:
            shutil.copytree(ROOT / name, checkout / name, ignore=shutil.ignore_patterns('build', '.gradle', '__pycache__'))
        for name in ['pubspec.yaml', 'pubspec.lock', 'l10n.yaml', 'analysis_options.yaml', '.metadata']:
            if (ROOT / name).exists():
                shutil.copy2(ROOT / name, checkout / name)
        (checkout / '.env').write_text('\n'.join(k + '=' + values[k] for k in ['SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY', 'GEOAPIFY_API_KEY'] if values.get(k)) + '\n')
        build_stamp = stamp()
        def build(extra, label):
            result = subprocess.run(['flutter', 'build', 'apk', '--debug', *extra], cwd=checkout, capture_output=True)
            (EVIDENCE / (label + '.txt')).write_text(clean((result.stdout + result.stderr).decode(errors='replace')))
            if result.returncode:
                raise RuntimeError('Build failed; see ' + label + '.txt')
            apk = checkout / 'build/app/outputs/flutter-apk/app-debug.apk'
            import zipfile
            forbidden = [values.get('SUPABASE_SECRET_KEY', ''), *credentials.values()]
            with zipfile.ZipFile(apk) as archive:
                for member in archive.namelist():
                    content = archive.read(member)
                    if any(secret.encode() in content for secret in forbidden if secret):
                        raise RuntimeError('Sensitive value found in APK')
            (EVIDENCE / (label + '.source.json')).write_text(json.dumps({**build_stamp, 'apk_sha256': hashlib.sha256(apk.read_bytes()).hexdigest(), 'secret_scan': 'PASS'}, indent=2) + '\n')
            print('PASS:', label, flush=True)
            return apk
        if args.skip_production_build:
            previous = json.loads((EVIDENCE / 'production-build.source.json').read_text())
            if previous['facility_source_sha256'] != build_stamp['facility_source_sha256'] or previous['secret_scan'] != 'PASS':
                raise RuntimeError('Production evidence does not match current source')
        else:
            build([], 'production-build')
        gradle = checkout / 'android/app/build.gradle.kts'
        gradle.write_text(gradle.read_text().replace('applicationId = "com.locatemy.app"', 'applicationId = "' + PACKAGE + '"'))
        apk = build(['--target', 'tool/nearby_facilities_device.dart', '--dart-define=FACILITY_QA_PORT=' + port, '--dart-define=LOCATEMY_PRIVACY_PROXY_PORT=' + port], 'device-build')
        for device in args.devices:
            tag = 'owner-b-emulator' if device.startswith('emulator-') else 'owner-a-device'
            adb = ['adb', '-s', device]
            # Other task's device run uses its own application. Wait until its driver finishes.
            if not device.startswith('emulator-'):
                while re.search(r'^python(?:3)? .*verify_(?:hazard|transit)_devices\.py', run(['ps', '-eo', 'args']).decode(), re.M):
                    print('Waiting for the other task device verification to finish', flush=True)
                    time.sleep(10)
            run(adb + ['reverse', 'tcp:' + port, 'tcp:' + port])
            run(adb + ['install', '-r', str(apk)])
            run(adb + ['shell', 'input', 'keyevent', '224'])
            run(adb + ['shell', 'wm', 'dismiss-keyguard'])
            old_scale = run(adb + ['shell', 'settings', 'get', 'system', 'font_scale']).decode().strip()
            run(adb + ['shell', 'am', 'force-stop', PACKAGE])
            run(adb + ['shell', 'am', 'start', '-n', PACKAGE + '/com.locatemy.app.MainActivity'])
            def capture(stage):
                for attempt in range(5):
                    xml = run(adb + ['exec-out', 'uiautomator', 'dump', '/dev/tty']).decode(errors='replace')
                    if '<?xml' in xml and '</hierarchy>' in xml:
                        break
                    time.sleep(1)
                xml = xml[xml.index('<?xml'):xml.rindex('</hierarchy>') + 12]
                (EVIDENCE / (tag + '-' + stage + '.xml')).write_text(clean(xml))
                (EVIDENCE / (tag + '-' + stage + '.png')).write_bytes(run(adb + ['exec-out', 'screencap', '-p']))
                return ET.fromstring(xml)
            def texts(root):
                return '\n'.join(n.attrib.get('text', '') + '\n' + n.attrib.get('content-desc', '') for n in root.iter('node'))
            def wait_text(expected, stage, seconds=90):
                retries = 0
                next_retry = 0.0
                deadline = time.monotonic() + seconds
                while time.monotonic() < deadline:
                    root = capture(stage)
                    if expected in texts(root):
                        print(tag, stage, 'PASS', flush=True)
                        return root
                    # Public retry demonstrates recovery from transient real 504s;
                    # deterministic failure stages deliberately retain their result.
                    if expected in ['范围内覆盖', 'Recorded coverage'] and '重试' in texts(root) and retries < 3 and time.monotonic() >= next_retry:
                        capture(stage + '-transient-unavailable')
                        tap('重试', stage + '-transient-retry')
                        retries += 1
                        next_retry = time.monotonic() + 8
                        print(tag, stage, 'public retry', retries, flush=True)
                    time.sleep(1)
                pid = run(adb + ['shell', 'pidof', '-s', PACKAGE]).decode().strip()
                logs = run(adb + ['logcat', '-d', '--pid', pid]).decode(errors='replace') if pid else 'process absent'
                (EVIDENCE / (tag + '-failure.txt')).write_text(clean(logs))
                raise RuntimeError(tag + ' missing ' + expected + ' at ' + stage)
            markers = []
            def wait_marker(expected, stage):
                deadline = time.monotonic() + 60
                while time.monotonic() < deadline:
                    pid = run(adb + ['shell', 'pidof', '-s', PACKAGE]).decode().strip()
                    log = run(adb + ['logcat', '-d', '--pid', pid]).decode(errors='replace')
                    filtered = '\n'.join(line for line in log.splitlines() if 'FACILITY_DEVICE:' in line)
                    if expected in filtered:
                        markers.append(filtered)
                        capture(stage)
                        return
                    time.sleep(1)
                raise RuntimeError('Missing sanitized device marker ' + expected)
            def tap(label, stage):
                for attempt in range(8):
                    root = capture(stage + '-before')
                    for node in root.iter('node'):
                        if label in [node.attrib.get('text'), node.attrib.get('content-desc')]:
                            bounds = list(map(int, re.findall(r'\d+', node.attrib['bounds'])))
                            run(adb + ['shell', 'input', 'tap', str((bounds[0] + bounds[2]) // 2), str((bounds[1] + bounds[3]) // 2)])
                            time.sleep(.6)
                            return
                    scrolls = [n for n in root.iter('node') if n.attrib.get('scrollable') == 'true']
                    if not scrolls:
                        break
                    b = list(map(int, re.findall(r'\d+', scrolls[0].attrib['bounds'])))
                    run(adb + ['shell', 'input', 'swipe', str((b[0] + b[2]) // 2), str(b[3] - 60), str((b[0] + b[2]) // 2), str(b[1] + 50), '400'])
                raise RuntimeError('Missing tap target ' + label)
            def reveal(expected, stage):
                for attempt in range(12):
                    root = capture(stage)
                    if expected in texts(root):
                        return
                    scrolls = [n for n in root.iter('node') if n.attrib.get('scrollable') == 'true']
                    if not scrolls:
                        break
                    b = list(map(int, re.findall(r'\d+', scrolls[0].attrib['bounds'])))
                    run(adb + ['shell', 'input', 'swipe', str((b[0] + b[2]) // 2), str(b[3] - 60), str((b[0] + b[2]) // 2), str(b[1] + 50), '400'])
                    time.sleep(.4)
                raise RuntimeError('Missing disclosure ' + expected)
            def back():
                run(adb + ['shell', 'input', 'keyevent', '4'])
                time.sleep(.7)
            try:
                wait_text('QA Facilities', 'ready')
                tap('QA Facilities', 'open')
                wait_text('范围内覆盖', 'facilities-zh')
                reveal('未收录不代表现实中不存在', 'facilities-zh-disclosure')
                back()
                tap('QA Offline', 'offline')
                tap('QA Facilities', 'cached-open')
                wait_text('范围内覆盖', 'cached-zh')
                tap('刷新', 'cached-refresh')
                wait_text('范围内覆盖', 'cached-fallback')
                back()
                tap('QA Failure', 'failure')
                wait_text('资料暂不可用', 'failure-zh')
                run(adb + ['shell', "run-as " + PACKAGE + " sh -c 'echo live > files/facility-wave5/network-mode'"])
                tap('重试', 'retry-recovery')
                wait_text('范围内覆盖', 'retry-recovered-zh')
                back()
                tap('QA Recover', 'recover')
                tap('QA Layer', 'layer')
                wait_marker('LAYER_PASS', 'layer-pass')
                tap('QA Failure', 'failure-again')
                wait_text('范围内覆盖', 'rate-limit-cached-fallback')
                back()
                tap('QA Recover', 'online-again')
                tap('语言', 'language')
                tap('QA Facilities', 'english-open')
                wait_text('Recorded coverage', 'facilities-en')
                run(adb + ['shell', 'settings', 'put', 'system', 'font_scale', '2.0'])
                time.sleep(1)
                capture('facilities-en-200')
                reveal('Missing records do not mean', 'facilities-en-200-disclosure')
                back()
                run(adb + ['shell', 'settings', 'put', 'system', 'font_scale', old_scale])
                tap('Language', 'language-zh')
                tap('QA Compare', 'compare')
                wait_text('A/B 可比较', 'compare-zh', seconds=90)
                back()
                run(adb + ['shell', 'am', 'force-stop', PACKAGE])
                run(adb + ['shell', 'am', 'start', '-n', PACKAGE + '/com.locatemy.app.MainActivity'])
                wait_text('QA Facilities', 'restart-ready')
                tap('QA Offline', 'restart-offline')
                tap('QA Facilities', 'restart-cache-open')
                wait_text('范围内覆盖', 'restart-cached')
                back()
                tap('QA Close', 'close')
                wait_marker('CLOSED_PASS', 'closed')
                (EVIDENCE / (tag + '-verification.txt')).write_text(clean('\n'.join(markers)) + '\n')
                (EVIDENCE / (tag + '-verification.source.json')).write_text(json.dumps(build_stamp, indent=2) + '\n')
                print(tag, 'ALL PASS', flush=True)
            finally:
                run(adb + ['shell', 'settings', 'put', 'system', 'font_scale', old_scale])
                run(adb + ['shell', 'am', 'force-stop', PACKAGE])
                run(adb + ['reverse', '--remove', 'tcp:' + port])
                run(adb + ['uninstall', PACKAGE])
finally:
    server.shutdown()
    server.server_close()
    fixture.clear()
