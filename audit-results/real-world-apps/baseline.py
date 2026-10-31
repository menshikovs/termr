from pathlib import Path
import subprocess, hashlib, json
out = Path('audit-results/real-world-apps')
out.mkdir(parents=True, exist_ok=True)
assert not (out/'baseline-files.json').exists(), 'Baseline already exists; preserve it.'
files = subprocess.check_output(['git','ls-files','--cached','--others','--exclude-standard','-z']).decode().split('\0')
manifest = {}
for name in sorted(set(files)):
    p = Path(name)
    if name and not name.startswith('audit-results/') and p.is_file():
        manifest[name] = hashlib.sha256(p.read_bytes()).hexdigest()
(out/'baseline-files.json').write_text(json.dumps(manifest,indent=2))
for command,name in [(['git','status','--short'],'git-status-before.txt'),(['git','rev-parse','HEAD'],'head-before.txt'),(['git','branch','--show-current'],'branch-before.txt')]:
    (out/name).write_bytes(subprocess.check_output(command))
print('Preserved',len(manifest),'initial source hashes')
