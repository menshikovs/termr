from pathlib import Path
root = Path(__file__).resolve().parents[2]
for src in (root/'audit-results/nanonext/baseline/man').glob('*.Rd'):
    (root/'man'/src.name).write_bytes(src.read_bytes())
p = root/'DESCRIPTION'
data = p.read_bytes()
p.write_bytes(b'\n'.join(line for line in data.split(b'\n') if not line.startswith(b'RoxygenNote:')))
print('Restored initial generated help, retained new nanonext topic/exports.')
