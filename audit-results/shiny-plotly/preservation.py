from pathlib import Path
import hashlib, json, subprocess
root = Path(__file__).resolve().parents[2]
base = root / 'audit-results/shiny-plotly'
initial = json.loads((base / 'initial-hashes.json').read_text())
allowed = {'.Rbuildignore','DESCRIPTION','NAMESPACE','NEWS.md','README.md',
 'docs/api-inventory.md','docs/stability.md','R/transport_nanonext.R',
 'tests/testthat/test-nanonext.R','tools/nanonext_integration.R','tools/data-streams-integration.R',
 'inst/examples/system-monitor-live/README.md'}
changed = []
unexpected = []
for name, digest in initial.items():
    p = root / name
    actual = hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else None
    if actual != digest:
        changed.append(name)
        if name not in allowed: unexpected.append(name)
result = {'initial_files':len(initial),'changed':changed,'unexpected':unexpected,
 'preserved':len(initial)-len(changed),'index_unchanged':subprocess.check_output(
 ['git','diff','--cached','--name-only'],cwd=root).decode().strip()==''}
(base/'preservation.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))
assert not unexpected
