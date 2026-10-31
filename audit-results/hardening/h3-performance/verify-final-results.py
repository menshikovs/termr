from pathlib import Path
from collections import Counter
import csv, json, subprocess

out = Path('audit-results/hardening/h3-performance')
final = out/'final-validation-ring'
def read(path):
    raw = path.read_bytes()
    return raw.decode('utf-16' if raw.startswith((b'\xff\xfe',b'\xfe\xff')) else 'utf-8-sig').strip()
platform = ['focused-windows','focused-wsl','optional-free-windows','optional-free-wsl',
    'full-windows','full-wsl','build-windows','build-wsl','check-windows','check-wsl',
    'inventory-wsl','resource-cycles-wsl','pty-fixture-wsl-final','pty-full-wsl',
    'pty-combined-wsl-repeat-1','pty-combined-wsl-repeat-2','pty-binary-wsl']
helpers = ['h1-h2-baseline','before-core','after-core','before-broad','after-broad',
    'before-events-profile','after-events','before-extra','after-extra','before-components',
    'after-components','before-memory','after-memory','resource-cycles-windows','trace-copies',
    'after-stream','paired-bridge','before-granular','after-granular','queue-lifetime-before-ring','queue-lifetime-after-ring','git-diff-check']
status = {}
for folder, names in [(final,platform),(out,helpers)]:
    for name in names:
        path = folder/(name+'.exit')
        assert path.exists(), path
        value = read(path)
        status[str(path.relative_to(out))] = value
        assert value == '0', (path,value)
for system in ['windows','wsl']:
    text = read(final/f'check-{system}.log')
    assert 'Status: OK' in text, system
    assert '0 failed, 0 errors' in read(final/f'full-{system}.log'), system
datasets = {}
for phase in ['before','after']:
    for group in ['core','broad','events','extra','granular']:
        path = out/f'{phase}-{group}.csv'
        rows = list(csv.DictReader(path.open()))
        counts = Counter((r['id'],r['n']) for r in rows)
        assert set(counts.values()) == {3}, (path,counts)
        datasets[path.name] = dict(rows=len(rows), scenarios=len(counts))
assert subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip() == read(out/'head-before.txt')
assert subprocess.check_output(['git','branch','--show-current'],text=True).strip() == '2.0-termr'
preservation = json.loads((out/'preservation.json').read_text())
assert preservation['unexpected'] == []
archives = json.loads((out/'archive-source-verification.json').read_text())
assert all(r['mismatch'] == [] and r['verified_source_files'] == 222 for r in archives)
(out/'final-verification.json').write_text(json.dumps(dict(status=status,datasets=datasets,
    head_unchanged=True,branch='2.0-termr',archives_verified=True,preservation=preservation),indent=2))
print('All final platform/helper exits zero; dataset repetitions, archives, HEAD and preservation verified.')
