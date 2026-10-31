from pathlib import Path

b = Path('audit-results/hardening/h1-architecture')
o = Path('audit-results/hardening/h3-performance')
s = (b / 'run-windows.ps1').read_text().replace('h1-architecture', 'h3-performance').replace('termr-h1-validation', 'termr-h3-validation')
start = s.index('& $h1script audit-results/hardening/h3-performance/probe-contracts.R')
end = s.index('& $h1script -e', start)
s = s[:start] + s[end:]
s = s.replace("filter='h1-contracts|", "filter='h3-performance-contracts|h2-|h1-contracts|")
(o / 'run-windows.ps1').write_text(s)
s = (b / 'run-wsl-final.sh').read_text().replace('h1-architecture', 'h3-performance').replace('termr-h1', 'termr-h3')
start = s.index('Rscript "$out/inventory.R"')
end = s.index('Rscript -e', start)
s = s[:start] + s[end:]
s = s.replace('filter="h1-contracts|', 'filter="h3-performance-contracts|h2-|h1-contracts|')
s = s.replace('cat "$out/probes-wsl-final.log"', '')
(o / 'run-wsl-final.sh').write_text(s)

# Recover the two tiny H3 expectation changes in a separate snapshot only.
# Verify against the immutable initial hash manifest before using them.
import csv, hashlib
hashes = {r['Path']: r['SHA256'] for r in csv.DictReader((o / 'baseline-files.csv').open(encoding='utf-8-sig'))}
(o / 'baseline/tests').mkdir(exist_ok=True)
for name in ['test-chart-streams.R', 'test-h2-contracts.R']:
    path = Path('tests/testthat') / name
    raw = path.read_bytes()
    ending = b'\r\n' if b'\r\n' in raw else b'\n'
    raw = raw.replace(b'\r\n', b'\n')
    if name == 'test-chart-streams.R':
        raw = raw.replace(b'expect_false(state$pending_render)\n  expect_length(chart$.__enclos_env__$private$.spec$data$x, 16L)',
                          b'expect_true(state$pending_render)\n  expect_length(chart$.__enclos_env__$private$.spec$data$x, 0L)')
    else:
        raw = raw.replace(b'expect_false(state$pending_render)\n  expect_length(chart$.__enclos_env__$private$.spec$data$x, 16L)',
                          b'expect_true(state$pending_render)')
    raw = raw.replace(b'\n', ending)
    # apply_patch may have normalized line endings in the working file.
    expected = hashes[path.as_posix()]
    if hashlib.sha256(raw).hexdigest().upper() != expected:
        alternative = raw.replace(b'\r\n', b'\n').replace(b'\n', b'\r\n')
        assert hashlib.sha256(alternative).hexdigest().upper() == expected, name
        raw = alternative
    (o / 'baseline/tests' / name).write_bytes(raw)
