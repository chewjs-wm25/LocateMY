#!/usr/bin/env python3
"""Run opt-in live Auth acceptance without putting credentials in shell arguments."""
import os
from pathlib import Path
import subprocess

values = {}
for line in Path('.env').read_text().splitlines():
    if '=' in line and not line.lstrip().startswith('#'):
        key, value = line.split('=', 1)
        values[key.strip()] = value.strip().strip('\"\'')
required = ('SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY', 'SUPABASE_SECRET_KEY')
if not all(values.get(key) for key in required):
    raise SystemExit('Missing live test configuration in .env')
result = subprocess.run(['flutter', 'test', 'test/live/authentication_session_live_test.dart',
                         '--reporter', 'expanded'],
                        env={**os.environ, **values, 'LOCATEMY_AUTH_LIVE': '1'},
                        capture_output=True, text=True)
output = result.stdout + result.stderr
for value in values.values():
    if value:
        output = output.replace(value, '<REDACTED>')
# SDK debug messages must not expose tokens or fixture identities.
import re
output = re.sub(r'locatemy[.-]qa[.-][^\s\"\']+@(?:example|gmail)\.com', '<TEST_EMAIL>', output)
output = re.sub(r'eyJ[A-Za-z0-9_.-]+', '<TOKEN>', output)
print(output)
raise SystemExit(result.returncode)
