from pathlib import Path
base = Path(__file__).resolve().parent
for p in list(base.glob('*.md')) + list(base.glob('*.R')):
    data = p.read_text(encoding='utf-8')
    data = data.replace('transport-nanonext.R', 'transport_nanonext.R')
    data = data.replace('nano-child.R', 'nano_child.R')
    data = data.replace('nanonext-integration.R', 'nanonext_integration.R')
    p.write_text(data, encoding='utf-8')
