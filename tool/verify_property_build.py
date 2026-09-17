#!/usr/bin/env python3
"""Verify the production debug APK from an isolated source copy and safe asset env."""
import hashlib,json,re,shutil,subprocess,tempfile,zipfile
from pathlib import Path
from import_home_datasets import read_values
root=Path.cwd();output=root/'build/property-wave6-evidence';output.mkdir(parents=True,exist_ok=True)
values=read_values('.env');credentials=read_values('test_credentials.local.md')
def clean(text):
    for value in [*values.values(),*credentials.values()]:
        if value:text=text.replace(value,'<REDACTED>')
    return re.sub(r'eyJ[A-Za-z0-9_.-]+','<TOKEN>',text)
with tempfile.TemporaryDirectory(prefix='locatemy-property-production-') as temporary:
    copied=Path(temporary)
    for name in ['lib','assets','android']:
        shutil.copytree(root/name,copied/name,ignore=shutil.ignore_patterns('build','.gradle','__pycache__'))
    for name in ['pubspec.yaml','pubspec.lock','analysis_options.yaml','l10n.yaml']:
        if (root/name).exists():shutil.copy2(root/name,copied/name)
    (copied/'.env').write_text('\n'.join(key+'='+values[key] for key in ['SUPABASE_URL','SUPABASE_PUBLISHABLE_KEY'])+'\n')
    process=subprocess.run(['flutter','build','apk','--debug'],cwd=copied,capture_output=True,text=True)
    (output/'production-build.log').write_text(clean(process.stdout+process.stderr))
    digest=hashlib.sha256()
    for path in sorted((copied/'lib').rglob('*.dart')):
        digest.update(str(path.relative_to(copied)).encode()+b'\0'+path.read_bytes())
    evidence={'base_head':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),
        'source_sha256':digest.hexdigest(),'exit_code':process.returncode}
    if process.returncode==0:
        apk=copied/'build/app/outputs/flutter-apk/app-debug.apk'
        forbidden=[values.get('SUPABASE_SECRET_KEY',''),*credentials.values()]
        with zipfile.ZipFile(apk) as archive:
            for name in archive.namelist():
                content=archive.read(name)
                if any(value.encode() in content for value in forbidden if value):
                    raise RuntimeError('Production APK secret scan failed')
        evidence.update({'apk_sha256':hashlib.sha256(apk.read_bytes()).hexdigest(),'secret_scan':'PASS'})
        shutil.copy2(apk,output/'production-debug.apk')
    (output/'production-build.source.json').write_text(json.dumps(evidence,indent=2)+'\n')
    print('Production debug build exit',process.returncode,flush=True)
    raise SystemExit(process.returncode)
