from pathlib import Path
root=Path(__file__).resolve().parents[2]
for src in (root/'audit-results/mirai/baseline/man').glob('*.Rd'):
    (root/'man'/src.name).write_bytes(src.read_bytes())
p=root/'DESCRIPTION'
p.write_bytes(b'\n'.join(line for line in p.read_bytes().split(b'\n') if not line.startswith(b'RoxygenNote:')))
print('Preserved existing help, retained new mirai topics and exports.')
