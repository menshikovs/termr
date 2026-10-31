"""Read-only tool inventory; never installs anything or sends telemetry."""
import json,platform,shutil,subprocess,sys
from pathlib import Path
root=Path(__file__).resolve().parents[2]
out=root/'audit-results/real-world-apps'
windows=platform.system()=='Windows'
commands={'python':[sys.executable,'--version'],'Rscript':['Rscript','--version'],
 'hyperfine':['hyperfine','--version'],'tmux':['tmux','-V'],
 'Expect':['expect','-v'],'asciinema':['asciinema','--version']}
rows=[]
for name,args in commands.items():
    path=shutil.which(args[0])
    on_path=bool(path)
    if name=='Rscript' and windows and not path:
        known=Path('C:/Program Files/R/R-4.6.1/bin/Rscript.exe')
        if known.exists():path=str(known)
    row=dict(tool=name,platform=platform.platform(),available=bool(path),path=path,on_path=on_path)
    if path:
        try:
            r=subprocess.run([path,*args[1:]],capture_output=True,text=True,timeout=10)
            row.update(version=(r.stdout+r.stderr).strip(),exit=r.returncode)
        except Exception as e:row['error']=str(e)
    row['installation']='pre-existing executable; no Phase E global installation'
    rows.append(row)
try:
 import pexpect
 rows.append(dict(tool='pexpect',version=pexpect.__version__,path=pexpect.__file__,available=True,
  installation='pre-existing Python package',platform=platform.platform()))
except ImportError:
 rows.append(dict(tool='pexpect',available=False,limitation='POSIX scenarios run in WSL'))
(out/('tools-windows.json' if windows else 'tools-wsl.json')).write_text(json.dumps(rows,indent=2))
print(json.dumps(rows,indent=2))
