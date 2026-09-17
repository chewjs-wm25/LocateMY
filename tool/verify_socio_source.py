#!/usr/bin/env python3
"""Compare the real read-only RPC projections with independent official CSVs."""
import csv, hashlib, io, json, urllib.request
from pathlib import Path
from import_home_datasets import read_values

config = read_values('.env')
credentials = read_values('test_credentials.local.md')
token = None

def request(path, payload, authenticated=False):
    headers = {'apikey': config['SUPABASE_PUBLISHABLE_KEY'], 'Content-Type': 'application/json'}
    if authenticated:
        headers['Authorization'] = 'Bearer ' + token
    req = urllib.request.Request(config['SUPABASE_URL'] + path, data=json.dumps(payload).encode(), headers=headers)
    with urllib.request.urlopen(req, timeout=30) as response:
        return json.load(response)

try:
    token = request('/auth/v1/token?grant_type=password', {'email': credentials['LOCATEMY_EMAIL'], 'password': credentials['LOCATEMY_PASSWORD']})['access_token']
    data = request('/rest/v1/rpc/read_socio_inputs', {'p_state': 'Selangor', 'p_district': 'Petaling'}, True)
    sources = {
        'income_district': ('hh_income_district', ['date', 'income_median']),
        'income_state': ('hh_income_state', ['date', 'income_median']),
        'gini_district': ('hh_inequality_district', ['date', 'gini']),
        'gini_state': ('hh_inequality_state', ['date', 'gini']),
        'percentiles': ('hies_state_percentile', ['date', 'percentile', 'variable', 'income']),
    }
    evidence = []
    for projection, (dataset, columns) in sources.items():
        url = 'https://storage.dosm.gov.my/hies/' + dataset + '.csv'
        with urllib.request.urlopen(url, timeout=30) as response:
            raw = response.read()
        rows = list(csv.DictReader(io.StringIO(raw.decode('utf-8-sig'))))
        expected = []
        for row in rows:
            if row['state'] != 'Selangor' or ('district' in row and row['district'] != 'Petaling'):
                continue
            # The old mirror omits income rows whose median is officially null.
            # Compare available readings only; do not invent a median for them.
            if 'income_median' in columns and row['income_median'] == '':
                continue
            projected = {}
            for column in columns:
                value = row[column]
                if value == '':
                    projected[column] = None
                elif column in ['income', 'income_median', 'percentile']:
                    projected[column] = int(float(value))
                elif column == 'gini':
                    projected[column] = float(value)
                else:
                    projected[column] = value
            expected.append(projected)
        key = lambda row: tuple(str(row.get(column)) for column in columns)
        if not expected or sorted(expected, key=key) != sorted(data[projection], key=key):
            raise RuntimeError('Official projection mismatch: ' + dataset)
        evidence.append({'dataset': dataset, 'source_url': url, 'source_sha256': hashlib.sha256(raw).hexdigest(), 'matching_scope_rows': len(expected), 'result': 'PASS'})
        print(dataset, 'official/RPC projection PASS', len(expected), flush=True)
    target = Path('build/socio-wave6-evidence'); target.mkdir(parents=True, exist_ok=True)
    (target / 'official-source-verification.json').write_text(json.dumps(evidence, indent=2) + '\n')
except Exception:
    raise SystemExit('Official source verification failed; sensitive request details redacted') from None
finally:
    if token:
        try:
            request('/auth/v1/logout?scope=local', {}, True)
        except Exception:
            pass
    token = None
    credentials.clear()
