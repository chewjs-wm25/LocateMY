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
EVIDENCE = ROOT / 'build/property-wave6-evidence'
PACKAGE = 'com.locatemy.propertyqa'
parser = argparse.ArgumentParser()
parser.add_argument('--devices', nargs='+', required=True)
parser.add_argument('--presentation-only',action='store_true')
parser.add_argument('--resume-files',action='store_true')
parser.add_argument('--files-only',action='store_true')
parser.add_argument('--port',type=int,required=True)
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
        if parts[:2] in [['GET','/offline'],['GET','/online']]:
            network['offline']=parts[1]=='/offline'
            if network['offline']:
                with lock:
                    for connection in tuple(active):
                        try:connection.shutdown(socket.SHUT_RDWR)
                        except OSError:pass
            self.request.sendall(b'HTTP/1.1 200 OK\r\nContent-Length: 0\r\nConnection: close\r\n\r\n');return
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
    allow_reuse_address = True
for attempt in range(360):
    try:
        server=Server(('127.0.0.1',args.port),Tunnel);break
    except OSError as error:
        if attempt==0:print('Fixture bind retry errno',error.errno,flush=True)
        time.sleep(1)
else:raise RuntimeError('Fixture port still in use')
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
for device in args.devices:run(['adb','-s',device,'reverse','tcp:'+port,'tcp:'+port])
print('PROPERTY_QA_FIXTURE ready',port,flush=True)
try:
    while True:time.sleep(30)
finally:
    server.shutdown();server.server_close();fixture.clear()
