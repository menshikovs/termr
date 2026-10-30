"""Restore pre-task generated docs after a different roxygen version ran.

Reconstruct only original man/ files in scratch from HEAD plus the saved
pre-task diff. Leave new termr_stream.Rd and the new NAMESPACE export intact.
"""
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[2]
scratch = root / 'audit-results/data-streams/original-docs'
scratch.mkdir(exist_ok=True)
paths = subprocess.check_output(['git', 'ls-files', 'man'], cwd=root).decode().splitlines()
for path in paths:
    dest = scratch / path
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(subprocess.check_output(['git', 'show', f'HEAD:{path}'], cwd=root))
patch = (root / 'audit-results/data-streams/INITIAL-CHANGES.patch').read_bytes()
parts = patch.split(b'diff --git ')
selected = b''.join(b'diff --git ' + p for p in parts[1:] if p.startswith(b'a/man/'))
patch_file = root / 'audit-results/data-streams/original-man.patch'
patch_file.write_bytes(selected)
subprocess.run(['git', 'apply', '--directory=audit-results/data-streams/original-docs',
                str(patch_file)], cwd=root, check=True)
for path in paths:
    (root / path).write_bytes((scratch / path).read_bytes())
print(f'Restored {len(paths)} original help files, including pre-existing edits.')
