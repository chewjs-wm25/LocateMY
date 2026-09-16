#!/usr/bin/env python3
"""Opt-in live/device GEO acceptance; ephemeral confirmed user is always deleted.

Credentials stay in process environment or a mode-0600 temporary define file.
Only public client configuration and disposable fixture credentials reach APK.
Device install replaces the development app; the normal APK is restored afterward.
"""
import argparse
import json
import os
from pathlib import Path
import re
import secrets
import subprocess
import tempfile
import time
import urllib.request
import zipfile

parser = argparse.ArgumentParser()
parser.add_argument('--devices', nargs='*', default=[])
parser.add_argument('--evidence-dir', default='docs/human/evidence/geographic-context-wave1-2026-09-16')
args = parser.parse_args()
values = {}
for line in Path('.env').read_text().splitlines():
    if '=' in line and not line.lstrip().startswith('#'):
        key, value = line.split('=', 1)
        values[key.strip()] = value.strip().strip('\"\'')
required = ['SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY', 'SUPABASE_SECRET_KEY']
if not all(values.get(k) for k in required):
    raise SystemExit('Missing live configuration')
email = f'locatemy.qa.geo.{secrets.token_hex(10)}@gmail.com'
password = f'Geo!{secrets.token_hex(24)}'
redactions = [*values.values(), email, password]
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

def safe_build(command, log_name, production=False):
    env_path = Path('.env')
    original_env = env_path.read_bytes()
    try:
        env_path.write_text('\n'.join(k + '=' + values[k] for k in required[:2]) + '\n')
        run(command, log_name)
        forbidden = [values['SUPABASE_SECRET_KEY']]
        if production:
            forbidden.extend([email, password])
        with zipfile.ZipFile('build/app/outputs/flutter-apk/app-debug.apk') as archive:
            if any(value.encode() in archive.read(n) for n in archive.namelist() for value in forbidden):
                raise RuntimeError('Forbidden credential found in APK')
        message = 'PASS: APK credential scan (no high-privilege key' + (', no disposable credentials)' if production else ')')
        print(message, flush=True)
        with (evidence / log_name).open('a') as log:
            log.write('\n' + message + '\n')
    finally:
        env_path.write_bytes(original_env)

def admin(path, method, body=None):
    request = urllib.request.Request(values['SUPABASE_URL'] + '/auth/v1/admin/' + path,
        method=method, data=json.dumps(body).encode() if body is not None else None,
        headers={'apikey': values['SUPABASE_SECRET_KEY'],
                 'Authorization': 'Bearer ' + values['SUPABASE_SECRET_KEY'],
                 'Content-Type': 'application/json'})
    with urllib.request.urlopen(request, timeout=30) as response:
        data = response.read()
        return json.loads(data) if data else {}

fixture_id = None
installed = []
try:
    fixture_id = admin('users', 'POST', {'email': email, 'password': password, 'email_confirm': True})['id']
    public = {k: values[k] for k in required[:2]}
    public.update(LOCATEMY_GEO_EMAIL=email, LOCATEMY_GEO_PASSWORD=password)
    run(['flutter', 'test', 'test/live/geographic_context_live_test.dart', '--reporter', 'expanded'],
        'live-test.txt', {**os.environ, **public, 'LOCATEMY_GEO_LIVE': '1'})
    if args.devices:
        with tempfile.TemporaryDirectory(prefix='locatemy-geo-') as temporary:
            config = Path(temporary) / 'fixture.json'
            config.write_text(json.dumps(public))
            config.chmod(0o600)
            safe_build(['flutter', 'build', 'apk', '--debug', '--target', 'tool/geographic_context_device.dart',
                        '--dart-define-from-file', str(config)], 'device-build.txt')
        apk = str(Path('build/app/outputs/flutter-apk/app-debug.apk').resolve())
        for index, device in enumerate(args.devices):
            tag = 'owner-b-emulator' if device.startswith('emulator-') else 'owner-a-device'
            adb = ['adb', '-s', device]
            run(adb + ['install', '-r', apk], f'{tag}-install.txt')
            installed.append(device)
            for stage in ['launch', 'restart']:
                run(adb + ['shell', 'am', 'force-stop', 'com.locatemy.app'])
                run(adb + ['logcat', '-c'])
                run(adb + ['shell', 'am', 'start', '-n', 'com.locatemy.app/.MainActivity'])
                deadline = time.monotonic() + 75
                while time.monotonic() < deadline:
                    logs = subprocess.run(adb + ['logcat', '-d', '-s', 'flutter:I'], capture_output=True, text=True).stdout
                    filtered = '\n'.join(line for line in logs.splitlines() if 'GEO_DEVICE:' in line)
                    if 'ALL PASS' in filtered or 'FAILED:' in filtered:
                        break
                    time.sleep(1)
                (evidence / f'{tag}-{stage}.txt').write_text(sanitize(filtered))
                with (evidence / f'{tag}-{stage}.png').open('wb') as target:
                    subprocess.run(adb + ['exec-out', 'screencap', '-p'], stdout=target, check=True)
                if 'ALL PASS' not in filtered or 'FAILED:' in filtered:
                    raise RuntimeError(f'Device acceptance failed: {tag} {stage}')
                print(f'{tag} {stage}: ALL PASS', flush=True)
finally:
    try:
        if installed:
            # Restore the normal app; never leave the disposable harness installed.
            safe_build(['flutter', 'build', 'apk', '--debug'], 'production-build.txt', production=True)
            apk = str(Path('build/app/outputs/flutter-apk/app-debug.apk').resolve())
            for device in installed:
                run(['adb', '-s', device, 'shell', 'am', 'force-stop', 'com.locatemy.app'])
                run(['adb', '-s', device, 'install', '-r', apk])
    finally:
        if fixture_id:
            admin('users/' + fixture_id, 'DELETE')
            print('Disposable fixture deleted', flush=True)
