from pathlib import Path
import hashlib,json,subprocess
root=Path(__file__).resolve().parents[2]
base=root/'audit-results/mirai'
paths=set(subprocess.check_output(['git','ls-files'],cwd=root).decode().splitlines())
for folder in ['R','man','tests','inst','docs']:
    paths.update(str(p.relative_to(root)).replace('\\','/') for p in (root/folder).rglob('*') if p.is_file() and '.new.md' not in p.name and '_problems' not in p.parts)
paths.update(['tools/nanonext_integration.R','tools/data-streams-integration.R','tools/data-streams-integration-child.R'])
manifest={}
for name in sorted(paths):
    src=root/name
    if not src.is_file():continue
    data=src.read_bytes();manifest[name]=hashlib.sha256(data).hexdigest()
    dest=base/'baseline'/name;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(data)
(base/'initial-hashes.json').write_text(json.dumps(manifest,indent=2))
(base/'INITIAL-STATUS.txt').write_bytes(subprocess.check_output(['git','status','--short'],cwd=root))
print('Saved',len(manifest),'initial files')
