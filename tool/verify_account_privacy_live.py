#!/usr/bin/env python3
"""Wave 2 live/device acceptance. Secrets are read locally and redacted.
Live uses configured test login; device uses disposable fixtures only.
Harness is always replaced by a scanned normal APK; fixtures are deleted.
"""
import argparse
import json
import os
from pathlib import Path
import re
import secrets
import select
import socket
import socketserver
import threading
from urllib.parse import urlparse
import subprocess
import tempfile
import time
import urllib.request
import zipfile

parser = argparse.ArgumentParser()
parser.add_argument('--devices', nargs='*', default=[])
parser.add_argument('--evidence-dir', default='docs/human/evidence/account-privacy-wave2-2026-09-16')
args = parser.parse_args()

def read_values(path):
    result = {}
    for line in Path(path).read_text().splitlines():
        if '=' in line and not line.lstrip().startswith('#'):
            key, value = line.split('=', 1)
            result[key.strip()] = value.strip().strip('\"\'')
    return result

values = read_values('.env')
credentials = read_values('test_credentials.local.md')
required = ['SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY', 'SUPABASE_SECRET_KEY']
if not all(values.get(k) for k in required) or not all(credentials.get(k) for k in ['LOCATEMY_EMAIL', 'LOCATEMY_PASSWORD']):
    raise SystemExit('Missing local live configuration')
redactions = [*values.values(), *credentials.values()]
evidence = Path(args.evidence_dir)
evidence.mkdir(parents=True, exist_ok=True)

def sanitize(output):
    for value in redactions:
        if value:
            output = output.replace(value, '<REDACTED>')
    return re.sub(r'eyJ[A-Za-z0-9_.-]+', '<TOKEN>', output)

def run(command, name=None, env=None):
    result = subprocess.run(command, env=env, capture_output=True, text=True)
    output = sanitize(result.stdout + result.stderr)
    if name:
        (evidence / name).write_text(output)
    print(output, flush=True)
    if result.returncode:
        raise RuntimeError(f'Command failed: {command[0]} ({result.returncode})')
    return output

def safe_build(command, name):
    original = Path('.env').read_bytes()
    try:
        Path('.env').write_text('\n'.join(k + '=' + values[k] for k in required[:2]) + '\n')
        run(command, name)
        forbidden = [values['SUPABASE_SECRET_KEY'], *credentials.values()]
        if '--target' not in command:
            forbidden.extend(value for pair in fixtures for value in pair)
        with zipfile.ZipFile('build/app/outputs/flutter-apk/app-debug.apk') as archive:
            if any(value.encode() in archive.read(n) for n in archive.namelist() for value in forbidden if value):
                raise RuntimeError('Forbidden credential found in APK')
        with (evidence / name).open('a') as log:
            log.write('\nPASS: APK scan excludes high privilege key and configured test login\n')
    finally:
        Path('.env').write_bytes(original)

def admin(path, method, body=None):
    request = urllib.request.Request(values['SUPABASE_URL'] + '/auth/v1/admin/' + path, method=method,
        data=json.dumps(body).encode() if body is not None else None,
        headers={'apikey': values['SUPABASE_SECRET_KEY'], 'Authorization': 'Bearer ' + values['SUPABASE_SECRET_KEY'], 'Content-Type': 'application/json'})
    with urllib.request.urlopen(request, timeout=30) as response:
        data = response.read()
        return json.loads(data) if data else {}

# Opaque CONNECT tunnel for the phone's unavailable direct network route.
# TLS remains end-to-end with Supabase; no header/body/token logging or interception.
allowed_host = urlparse(values['SUPABASE_URL']).hostname
class Tunnel(socketserver.StreamRequestHandler):
    def handle(self):
        line = self.rfile.readline(8192).decode('ascii', errors='replace').split()
        if len(line) != 3 or line[0] != 'CONNECT' or line[1] != allowed_host + ':443':
            self.request.sendall(b'HTTP/1.1 403 Forbidden\r\n\r\n')
            return
        while self.rfile.readline(8192) not in [b'\r\n', b'\n', b'']:
            pass
        with socket.create_connection((allowed_host, 443), timeout=30) as remote:
            self.request.sendall(b'HTTP/1.1 200 Connection Established\r\n\r\n')
            streams = [self.request, remote]
            while True:
                ready, _, _ = select.select(streams, [], [], 30)
                if not ready:
                    return
                for source in ready:
                    data = source.recv(65536)
                    if not data:
                        return
                    destination = remote if source is self.request else self.request
                    destination.sendall(data)
class TunnelServer(socketserver.ThreadingTCPServer):
    daemon_threads = True
proxy = TunnelServer(('127.0.0.1', 0), Tunnel) if args.devices else None
if proxy:
    threading.Thread(target=proxy.serve_forever, daemon=True).start()
    (evidence / 'device-transport.txt').write_text('adb reverse to host CONNECT tunnel, Supabase host only; end-to-end TLS; no interception; device Dart/SDK and file storage remain real. Direct phone route returned ClientSocketException.\n')

fixture_ids = []
installed = []
screen_timeouts = {}
try:
    public = {k: values[k] for k in required[:2]}
    fixtures = []
    for suffix in ['a', 'b']:
        email = f'locatemy.qa.privacy.{secrets.token_hex(10)}.{suffix}@gmail.com'
        password = 'Privacy!' + secrets.token_hex(24)
        redactions.extend([email, password])
        fixture_ids.append(admin('users', 'POST', {'email': email, 'password': password, 'email_confirm': True})['id'])
        fixtures.append((email, password))
    second = {'LOCATEMY_PRIVACY_B_EMAIL': fixtures[1][0], 'LOCATEMY_PRIVACY_B_PASSWORD': fixtures[1][1]}
    run(['flutter', 'test', 'test/live/account_privacy_live_test.dart', '--reporter', 'expanded'], 'live-test.txt',
        {**os.environ, **public, **credentials, **second, 'LOCATEMY_PRIVACY_LIVE': '1'})
    if args.devices:
        defines = {**public, **second, 'LOCATEMY_EMAIL': fixtures[0][0], 'LOCATEMY_PASSWORD': fixtures[0][1], 'LOCATEMY_PRIVACY_PROXY_PORT': str(proxy.server_address[1])}
        with tempfile.TemporaryDirectory(prefix='locatemy-privacy-') as temporary:
            config = Path(temporary) / 'fixture.json'
            config.write_text(json.dumps(defines))
            config.chmod(0o600)
            safe_build(['flutter', 'build', 'apk', '--debug', '--target', 'tool/account_privacy_device.dart', '--dart-define-from-file', str(config)], 'device-build.txt')
        apk = str(Path('build/app/outputs/flutter-apk/app-debug.apk').resolve())
        for device in args.devices:
            tag = 'owner-b-emulator' if device.startswith('emulator-') else 'owner-a-device'
            adb = ['adb', '-s', device]
            screen_timeouts[device] = subprocess.check_output(adb + ['shell', 'settings', 'get', 'system', 'screen_off_timeout'], text=True).strip()
            run(adb + ['shell', 'settings', 'put', 'system', 'screen_off_timeout', '600000'])
            run(adb + ['reverse', 'tcp:' + str(proxy.server_address[1]), 'tcp:' + str(proxy.server_address[1])])
            run(adb + ['install', '-r', apk], tag + '-install.txt')
            installed.append(device)
            # Only the harness namespace is reset. No production/user state is read.
            run(adb + ['shell', 'run-as', 'com.locatemy.app', 'rm', '-rf', 'files/privacy-wave2-harness'])
            for stage in ['launch', 'restart']:
                run(adb + ['shell', 'input', 'keyevent', 'KEYCODE_WAKEUP'])
                run(adb + ['shell', 'wm', 'dismiss-keyguard'])
                run(adb + ['shell', 'am', 'force-stop', 'com.locatemy.app'])
                run(adb + ['logcat', '-c'])
                run(adb + ['shell', 'am', 'start', '-n', 'com.locatemy.app/.MainActivity'])
                deadline = time.monotonic() + 90
                filtered = ''
                expected = 'READY_RESTART' if stage == 'launch' else 'ALL PASS'
                while time.monotonic() < deadline:
                    logs = subprocess.run(adb + ['logcat', '-d', '-s', 'flutter:I'], capture_output=True, text=True).stdout
                    filtered = '\n'.join(line for line in logs.splitlines() if 'PRIVACY_DEVICE:' in line)
                    if expected in filtered or 'FAILED:' in filtered:
                        break
                    time.sleep(1)
                (evidence / f'{tag}-{stage}.txt').write_text(sanitize(filtered))
                with (evidence / f'{tag}-{stage}.png').open('wb') as target:
                    subprocess.run(adb + ['exec-out', 'screencap', '-p'], stdout=target, check=True)
                if expected not in filtered or 'FAILED:' in filtered:
                    print(sanitize(filtered), flush=True)
                    raise RuntimeError(f'Device acceptance failed: {tag} {stage}')
                print(f'{tag} {stage}: {expected}', flush=True)
finally:
    try:
        safe_build(['flutter', 'build', 'apk', '--debug'], 'production-build.txt')
        apk = str(Path('build/app/outputs/flutter-apk/app-debug.apk').resolve())
        restoration = []
        for device in installed:
            for command in [ ['adb', '-s', device, 'shell', 'am', 'force-stop', 'com.locatemy.app'], ['adb', '-s', device, 'install', '-r', apk] ]:
                result = subprocess.run(command, capture_output=True, text=True)
                restoration.append(sanitize(result.stdout + result.stderr))
                if result.returncode:
                    print('Restoration failed for unavailable device; remaining devices still attempted', flush=True)
        (evidence / 'restoration.txt').write_text('\n'.join(restoration))
    finally:
        for device, timeout in screen_timeouts.items():
            operation = ['delete', 'system', 'screen_off_timeout'] if timeout == 'null' else ['put', 'system', 'screen_off_timeout', timeout]
            subprocess.run(['adb', '-s', device, 'shell', 'settings', *operation], capture_output=True)
        for fixture_id in fixture_ids:
            admin('users/' + fixture_id, 'DELETE')
        if proxy:
            for device in args.devices:
                subprocess.run(['adb', '-s', device, 'reverse', '--remove', 'tcp:' + str(proxy.server_address[1])], capture_output=True)
            proxy.shutdown()
            proxy.server_close()
        print('Disposable fixtures deleted; tunnel removed', flush=True)
