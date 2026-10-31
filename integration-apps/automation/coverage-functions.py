"""Derive function-label hit coverage from covr's public data.frame export."""
import csv,json
from pathlib import Path
root=Path(__file__).resolve().parents[2]
out=root/'audit-results/real-world-apps/coverage'
results={}
for scope in ['core','apps']:
    groups={}
    with (out/f'{scope}-lines.csv').open(newline='') as f:
        for row in csv.DictReader(f):
            key=(row['filename'],row['functions'])
            if not key[1]:continue
            counts=groups.setdefault(key,[])
            counts.append(float(row['value']))
    rows=[dict(file=file,function_label=label,hit=any(x>0 for x in values),
        expressions=len(values),covered_expressions=sum(x>0 for x in values))
        for (file,label),values in groups.items()]
    with (out/f'{scope}-functions.csv').open('w',newline='') as f:
        writer=csv.DictWriter(f,fieldnames=list(rows[0]));writer.writeheader();writer.writerows(rows)
    hit=sum(row['hit'] for row in rows)
    results[scope]=dict(function_labels=len(rows),hit_labels=hit,percent=100*hit/len(rows),
        definition='Any instrumented expression hit per distinct (file, covr function label). Nested/anonymous/R6 labels may be grouped. Not branch or complete-path coverage.')
(out/'function-summary.json').write_text(json.dumps(results,indent=2))
print(json.dumps(results,indent=2))
