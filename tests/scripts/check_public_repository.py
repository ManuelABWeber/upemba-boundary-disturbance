"""Check the submission code tree without reading ignored files or Git history."""
from pathlib import Path
import hashlib
import json
import re
import shutil
import subprocess
from collections import defaultdict

ROOT = Path(__file__).resolve().parents[2]
git = shutil.which('git')
manifest_path = ROOT/'RELEASE_MANIFEST.json'
if (ROOT/'.git').exists() and git:
    names = subprocess.check_output([git,'ls-files'],cwd=ROOT,text=True).splitlines()
else:
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    names = [item['path'] for item in manifest['files']] + ['RELEASE_MANIFEST.json']

failures=[]
groups=defaultdict(list)
for name in names:
    file=ROOT/name
    if not file.is_file():
        failures.append('Missing tracked/released file: '+name)
        continue
    base=file.name.lower()
    if file.suffix.lower() in {'.doc','.docx','.docm','.odt','.rtf'}:
        failures.append('Paper document: '+name)
    if any(name.startswith(p) for p in ('submission/','outputs/submission_review/','outputs/publication/')):
        failures.append('Retired submission/presentation artifact: '+name)
    if file.suffix.lower() in {'.pdf','.md','.html','.htm','.json'} and re.search(r'manuscript|cover[_ -]?letter|review_text|highlights|supplement.*(?:material|review|final)',base):
        failures.append('Paper or editorial file: '+name)
    groups[hashlib.sha256(file.read_bytes()).hexdigest()].append(name)
    if file.suffix.lower()=='.md':
        for target in re.findall(r'\]\(([^)]+)\)',file.read_text(encoding='utf-8',errors='replace')):
            link=target.split('#')[0].strip('<>')
            if not link or re.match(r'^[a-zA-Z]+:',link) or link.startswith('/'):
                continue
            if not (file.parent/link).exists():
                failures.append('Broken local link: '+name+' -> '+target)

for paths in groups.values():
    if len(paths)>1:
        failures.append('Exact duplicate files: '+'; '.join(paths))

if manifest_path.exists():
    manifest=json.loads(manifest_path.read_text(encoding='utf-8'))
    expected={item['path'] for item in manifest['files']}|{'RELEASE_MANIFEST.json'}
    if set(names)!=expected:
        failures.append('Release manifest and tracked file inventory differ')
    for item in manifest['files']:
        file=ROOT/item['path']
        if file.is_file() and (file.stat().st_size!=item['bytes'] or hashlib.sha256(file.read_bytes()).hexdigest()!=item['sha256']):
            failures.append('Release hash mismatch: '+item['path'])
else:
    failures.append('Missing RELEASE_MANIFEST.json')

if failures:
    print('\n'.join(failures))
    raise SystemExit(1)
print(f'PASS: {len(names)} public files; no paper documents, retired layouts, exact duplicates, broken local links or release hash failures.')
