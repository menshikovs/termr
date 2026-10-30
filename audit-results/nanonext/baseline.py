from pathlib import Path
import hashlib, json, shutil, subprocess
root = Path(__file__).resolve().parents[2]
paths = subprocess.check_output(['git', 'ls-files'], cwd=root).decode().splitlines()
paths += ['R/streams.R', 'man/termr_stream.Rd', 'docs/data-streams.md',
          'tests/testthat/test-streams.R', 'tests/testthat/test-monitor-live.R',
          'tools/data-streams-integration.R', 'tools/data-streams-integration-child.R']
paths += [str(p.relative_to(root)).replace('\\','/') for p in (root/'inst/examples/system-monitor-live').rglob('*') if p.is_file()]
out = root/'audit-results/nanonext/baseline'
manifest = {}
for path in sorted(set(paths)):
    src = root/path
    if not src.is_file(): continue
    data = src.read_bytes()
    manifest[path] = hashlib.sha256(data).hexdigest()
    dest = out/path
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(data)
(out.parent/'initial-hashes.json').write_text(json.dumps(manifest, indent=2))
print(f'Saved {len(manifest)} initial files and hashes.')
