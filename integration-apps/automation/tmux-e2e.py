import os,sys,json,time,subprocess,uuid,argparse,shlex
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
def main(out):
    out=ROOT/out;out.mkdir(parents=True,exist_ok=True)
    socket='termr-phase-e-'+uuid.uuid4().hex[:12]
    prefix=['tmux','-L',socket]
    def tmux(*args,check=True): return subprocess.run(prefix+list(args),check=check,text=True,capture_output=True)
    def wait(fn,timeout=30):
        deadline=time.monotonic()+timeout
        while time.monotonic()<deadline:
            if fn():return
            time.sleep(.02)
        raise AssertionError('tmux semantic timeout')
    results=[]
    try:
        for app in ['showcase','monitor','rtop']:
            done=out/f'{app}-restored.txt'
            if done.exists():done.unlink()
            cmd=['Rscript','integration-apps/legacy-rtop/run.R','--mode=terminal','--fixtures=true'] if app=='rtop' else ['Rscript','integration-apps/run.R',f'--app={app}','--mode=terminal']
            shell='cd '+shlex.quote(str(ROOT))+'; export TERM=xterm-256color LC_ALL=C.UTF-8 TERMR_USE_INSTALLED=1; before=$(stty -g); '+shlex.join(cmd)+'; rc=$?; after=$(stty -g); if [ "$before" = "$after" ] && [ "$rc" = 0 ]; then echo PASS > '+shlex.quote(str(done))+'; else echo FAIL > '+shlex.quote(str(done))+'; fi'
            tmux('new-session','-d','-s',app,'-x','100','-y','30','/bin/bash -c '+shlex.quote(shell))
            def capture():return tmux('capture-pane','-p','-t',app,check=False).stdout
            title={'showcase':'Termr Data Workbench','monitor':'Distributed Task','rtop':'CPU'}[app]
            wait(lambda:title in capture())
            tmux('send-keys','-t',app,'Tab','BTab')
            tmux('send-keys','-t',app,'F4' if app=='showcase' else 'n' if app=='monitor' else 'm')
            if app=='showcase':wait(lambda:'Theme: light' in capture())
            tmux('resize-window','-t',app,'-x','42','-y','18')
            wait(lambda:tmux('display-message','-p','-t',app,'#{pane_width}x#{pane_height}').stdout.strip()=='42x18')
            (out/f'{app}-screen.txt').write_text(capture(),encoding='utf-8')
            tmux('resize-window','-t',app,'-x','100','-y','30')
            tmux('send-keys','-t',app,'q')
            wait(lambda:done.exists())
            assert done.read_text().strip()=='PASS'
            results.append(dict(app=app,status='PASS',resize='42x18',terminal_restored=True))
    finally:
        tmux('kill-server',check=False) # Only this fresh -L namespace.
    (out/'results.json').write_text(json.dumps(dict(socket=socket,cases=results,cleanup=True),indent=2))
    print(json.dumps(results))
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--out',default='audit-results/real-world-apps/tmux');a=p.parse_args();main(a.out)
