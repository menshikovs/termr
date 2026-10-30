from pathlib import Path
import hashlib, json
root = Path(__file__).resolve().parents[2]
manifest = json.loads((root/'audit-results/nanonext/initial-hashes.json').read_text())
expected = {
    'DESCRIPTION', 'NAMESPACE', 'NEWS.md', 'README.md', 'docs/api-inventory.md',
    'docs/stability.md', 'docs/data-streams.md',
    'inst/examples/system-monitor-live/common.R',
    'inst/examples/system-monitor-live/collector.R',
    'inst/examples/system-monitor-live/tui.R',
    'inst/examples/system-monitor-live/shiny-app.R',
    'inst/examples/system-monitor-live/README.md',
}
unchanged = []
changed = []
for path, digest in manifest.items():
    data = (root/path).read_bytes()
    if hashlib.sha256(data).hexdigest() == digest:
        unchanged.append(path)
    else:
        if path not in expected: raise RuntimeError(f'Unexpected change: {path}')
        changed.append(path)
for path in ['R/streams.R', 'R/signals.R', 'R/app.R', 'tests/testthat/test-streams.R', 'tests/testthat/test-monitor-live.R']:
    assert path in unchanged, path
print(f'PASS: {len(unchanged)} initial files are byte-for-byte unchanged.')
print('Authorized Phase-3 modifications:')
print('\n'.join(changed))
