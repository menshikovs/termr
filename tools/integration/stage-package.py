"""Stage current package inputs without recursively copying audits/dependencies."""
from pathlib import Path
import re,os,shutil,hashlib,json,argparse
root=Path(__file__).resolve().parents[2]
parser=argparse.ArgumentParser();parser.add_argument('--out',default='audit-results/real-world-apps')
args=parser.parse_args()
out=root/args.out
out.mkdir(parents=True,exist_ok=True)
target=out/'package-source'
target.mkdir(exist_ok=True)
patterns=[re.compile(line.strip()) for line in (root/'.Rbuildignore').read_text().splitlines() if line.strip()]
manifest={}
for current,folders,files in os.walk(root):
    current=Path(current)
    folders[:]=[name for name in folders if not any(p.search((current/name).relative_to(root).as_posix()) for p in patterns)]
    for name in files:
        file=current/name;relative=file.relative_to(root).as_posix()
        if any(p.search(relative) for p in patterns):continue
        dest=target/relative;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(file,dest)
        manifest[relative]=hashlib.sha256(file.read_bytes()).hexdigest()
(out/'package-stage.json').write_text(json.dumps(dict(path=str(target),files=manifest),indent=2))
print(target)
