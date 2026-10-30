from pathlib import Path
import re
import subprocess

root = Path(__file__).resolve().parents[2]
scratch = root / 'audit-results/data-streams/initial-tracked-tree'
scratch.mkdir(exist_ok=True)
patch_file = root / 'audit-results/data-streams/INITIAL-CHANGES.patch'
paths = re.findall(rb'^diff --git a/(.+) b/\1$', patch_file.read_bytes(), re.M)
for value in paths:
    path = value.decode()
    dest = scratch / path
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(subprocess.check_output(['git', 'show', f'HEAD:{path}'], cwd=root))
subprocess.run(['git', 'apply', '--directory=audit-results/data-streams/initial-tracked-tree',
                str(patch_file)], cwd=root, check=True)
intentional = {'NEWS.md'}
preserved = []
for value in paths:
    path = value.decode()
    if path in intentional:
        continue
    before = (scratch / path).read_bytes().replace(b'\r\n', b'\n')
    after = (root / path).read_bytes().replace(b'\r\n', b'\n')
    if before != after:
        raise RuntimeError(f'Unexpected change to initially modified file: {path}')
    preserved.append(path)
print(f'PASS: {len(preserved)} initially modified tracked files retain original Git content.')
print('NEWS.md has the intentional additive data-streams entry.')
