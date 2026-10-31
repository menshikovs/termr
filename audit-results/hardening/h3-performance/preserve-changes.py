from pathlib import Path
import csv, hashlib, difflib, json
out = Path('audit-results/hardening/h3-performance')
allowed = {'R/app.R', 'R/event-queue.R', 'R/inkr-integration.R', 'R/chart-widget.R',
           'tests/testthat/test-chart-streams.R', 'tests/testthat/test-h2-contracts.R',
           'docs/charts.md', 'docs/inkr-integration.md'}
results = []
manifest = list(csv.DictReader((out / 'baseline-files.csv').open(encoding='utf-8-sig')))
initial_hashes = {row['Path']: row['SHA256'] for row in manifest}
for row in manifest:
    p = Path(row['Path'])
    digest = hashlib.sha256(p.read_bytes()).hexdigest().upper() if p.is_file() else 'MISSING'
    results.append(dict(path=p.as_posix(), unchanged=digest == row['SHA256'], allowed=p.as_posix() in allowed))
unexpected = [r for r in results if not r['unchanged'] and not r['allowed']]
assert not unexpected, unexpected
patches = []
for name in sorted(allowed):
    p = Path(name)
    old = out / 'baseline' / ('tests/' + p.name if name.startswith('tests/') else name)
    assert hashlib.sha256(old.read_bytes()).hexdigest().upper() == initial_hashes[name], name
    patches.extend(difflib.unified_diff(old.read_text().splitlines(True), p.read_text().splitlines(True),
                                      fromfile='baseline/' + name, tofile=name))
new_test = Path('tests/testthat/test-h3-performance-contracts.R')
patches.extend(difflib.unified_diff([], new_test.read_text().splitlines(True),
    fromfile='/dev/null', tofile=new_test.as_posix()))
(out / 'h3-only.patch').write_text(''.join(patches))
(out / 'preservation.json').write_text(json.dumps(dict(initial_files=len(results), unchanged=sum(r['unchanged'] for r in results),
    permitted_changes=[r['path'] for r in results if not r['unchanged']], unexpected=unexpected), indent=2))
print((out / 'preservation.json').read_text())
