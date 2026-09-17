#!/usr/bin/env python3
"""Adaptive adb controls: coordinates always come from the current UI tree."""
import re,subprocess,time,xml.etree.ElementTree as ET
from pathlib import Path
from import_home_datasets import read_values
ADB=['adb','-s','emulator-5554'];ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'build/property-wave6-evidence'
SENSITIVE=[*read_values(ROOT/'.env').values(),*read_values(ROOT/'test_credentials.local.md').values()]
def run(command):
 r=subprocess.run(command,capture_output=True)
 if r.returncode:raise RuntimeError('adb command failed')
 return r.stdout
def tree():
 s=run(ADB+['exec-out','uiautomator','dump','/dev/tty']).decode(errors='replace');return ET.fromstring(s[s.index('<?xml'):s.rindex('</hierarchy>')+12])
def text(n):return n.get('text') or n.get('content-desc') or n.get('hint') or ''
def tap_node(n):
 b=list(map(int,re.findall(r'\d+',n.get('bounds'))));run(ADB+['shell','input','tap',str((b[0]+b[2])//2),str((b[1]+b[3])//2)]);time.sleep(.8)
def swipe(direction=1):
 n=next((n for n in tree().iter('node') if n.get('scrollable')=='true'),None)
 if n is None:return False
 b=list(map(int,re.findall(r'\d+',n.get('bounds'))));start,end=b[3]-100,b[1]+70
 if direction<0:start,end=end,start
 run(ADB+['shell','input','swipe',str((b[0]+b[2])//2),str(start),str((b[0]+b[2])//2),str(end),'350']);time.sleep(.5);return True
def tap(label):
 for i in range(12):
  n=next((n for n in tree().iter('node') if text(n)==label or text(n).split('\n')[0]==label),None)
  if n is not None:tap_node(n);return
  if not swipe():time.sleep(.5)
 raise RuntimeError('missing action '+label)
def wait(label,seconds=45):
 end=time.monotonic()+seconds
 while time.monotonic()<end:
  if any(label in text(n) for n in tree().iter('node')):return
  time.sleep(.8)
 raise RuntimeError('missing content '+label)
def capture(stage):
 r=tree();s=ET.tostring(r,encoding='unicode')
 for v in SENSITIVE:
  if v:s=s.replace(v,'<REDACTED>')
 (OUT/('owner-b-emulator-'+stage+'.xml')).write_text(s)
 if not any(v and v in ET.tostring(r,encoding='unicode') for v in SENSITIVE):
  (OUT/('owner-b-emulator-'+stage+'.png')).write_bytes(run(ADB+['exec-out','screencap','-p']))
 print(stage,flush=True)
 return r
def back():run(ADB+['shell','input','keyevent','4']);time.sleep(.8)
def summary():
 for n in tree().iter('node'):
  t=text(n)
  if t and not any(v and v in t for v in SENSITIVE):print(t[:180])
if __name__=='__main__':summary()
