#!/usr/bin/env python3
"""Read-only official CSV/mirror content audit. Never imports or replaces data."""
import csv
import hashlib
import io
import json
import urllib.request
from collections import defaultdict
from pathlib import Path
from import_home_datasets import read_values

SOURCE = 'https://storage.data.gov.my/publicsafety/crime_district.csv'
FIELDS = ['date', 'state', 'district', 'category', 'type', 'crimes']
KEYS = FIELDS[:-1]

def canonical(rows):
    ordered = sorted(rows, key=lambda row: tuple(row[key] for key in KEYS))
    return '\n'.join('|'.join(str(row[key]) for key in FIELDS) for row in ordered).encode()

def main():
    values = read_values('.env')
    credentials = read_values('test_credentials.local.md')
    token = None
    try:
        raw = urllib.request.urlopen(SOURCE, timeout=30).read()
        official = list(csv.DictReader(io.StringIO(raw.decode('utf-8-sig'))))
        request = urllib.request.Request(values['SUPABASE_URL'] + '/auth/v1/token?grant_type=password', method='POST', data=json.dumps({'email': credentials['LOCATEMY_EMAIL'], 'password': credentials['LOCATEMY_PASSWORD']}).encode(), headers={'apikey': values['SUPABASE_PUBLISHABLE_KEY'], 'Content-Type': 'application/json'})
        with urllib.request.urlopen(request, timeout=30) as response:
            token = json.loads(response.read())['access_token']
        mirror = []
        for offset in range(0, len(official) + 1000, 1000):
            request = urllib.request.Request(values['SUPABASE_URL'] + '/rest/v1/crime_district?select=' + ','.join(FIELDS) + '&order=' + ','.join(KEYS), headers={'apikey': values['SUPABASE_PUBLISHABLE_KEY'], 'Authorization': 'Bearer ' + token, 'Range': str(offset) + '-' + str(offset + 999)})
            with urllib.request.urlopen(request, timeout=30) as response:
                rows = json.loads(response.read())
            mirror.extend(rows)
            if len(rows) < 1000:
                break
        if canonical(official) != canonical(mirror):
            raise RuntimeError('Official CSV and mirror differ')
        latest = max(row['date'] for row in official)
        totals = defaultdict(int)
        for row in official:
            if row['date'] == latest and row['state'] != 'Malaysia' and row['district'].lower() != 'all' and row['type'].lower() != 'all':
                totals[row['state'] + '/' + row['category']] += int(row['crimes'])
        evidence = {'source': SOURCE, 'sha256': hashlib.sha256(raw).hexdigest(), 'canonical_md5': hashlib.md5(canonical(official)).hexdigest(), 'row_count': len(official), 'mirror_matches_all_rows': True, 'latest_complete_year': latest[:4], 'fields': FIELDS, 'business_key': KEYS, 'latest_leaf_totals': dict(totals)}
        output = Path('build/crime-wave5-evidence')
        output.mkdir(parents=True, exist_ok=True)
        (output / 'official-source-audit.json').write_text(json.dumps(evidence, indent=2) + '\n')
        print('PASS: crime_district official CSV/mirror complete content audit;', len(official), 'rows; latest year', latest[:4])
    except Exception:
        raise RuntimeError('Crime source audit failed; sensitive details redacted') from None
    finally:
        if token:
            request = urllib.request.Request(values['SUPABASE_URL'] + '/auth/v1/logout?scope=local', method='POST', headers={'apikey': values['SUPABASE_PUBLISHABLE_KEY'], 'Authorization': 'Bearer ' + token})
            with urllib.request.urlopen(request, timeout=30):
                pass
if __name__ == '__main__':
    main()
