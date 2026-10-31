#!/usr/bin/env python3
"""Real POSIX PTY scenarios. Install pexpect only if absent; no terminal mocks."""
import argparse, json, os, shlex, time, sys, signal, traceback
from pathlib import Path
import pexpect
from event_log import read_events

ROOT = Path(__file__).resolve().parents[2]
def events(path):
    return read_events(path)
def until(predicate, timeout=20, pump=lambda:None):
    deadline=time.monotonic()+timeout
    while time.monotonic()<deadline:
        pump()
        if predicate(): return
        time.sleep(.01)
    raise AssertionError('semantic state timeout')
def scenario(app,out,record=False,legacy_library='candidate',crash=False,interrupt=False):
    out.mkdir(parents=True,exist_ok=True)
    marker=out/f'{app}-events.jsonl'
    if marker.exists(): marker.unlink()
    env=os.environ.copy()
    env.update(TERM='xterm-256color',LANG='C.UTF-8',LC_ALL='C.UTF-8',
        TERMR_PROJECT_ROOT=str(ROOT),TERMR_USE_INSTALLED='1',TERMR_E_EVENTS=str(marker))
    if app=='rtop':
        command=['Rscript','integration-apps/legacy-rtop/run.R',f'--library={legacy_library}','--mode=terminal','--fixtures=true']
    else:
        command=['Rscript','integration-apps/run.R',f'--app={app}','--mode=terminal']
        if crash: command.append('--scenario=crash')
    cast=out/f'{app}.cast'
    command_text=shlex.join(command)
    if record:
        # Record only deterministic fixture data. No upload command exists here.
        command_text='asciinema rec --overwrite --quiet --command '+shlex.quote(command_text)+' '+shlex.quote(str(cast))
    shell='before=$(stty -g); '+command_text+'; code=$?; after=$(stty -g); if [ "$before" = "$after" ]; then printf "\nTERMINAL_RESTORED\n"; else printf "\nTERMINAL_BROKEN\n"; fi; exit "$code"'
    child=pexpect.spawn('/bin/bash',['-c',shell],cwd=str(ROOT),env=env,
        encoding='utf-8',codec_errors='replace',dimensions=(30,100),timeout=30)
    transcript=[]
    class Log:
        def write(self,text): transcript.append(text)
        def flush(self): pass
    child.logfile_read=Log()
    def pump():
        try: child.read_nonblocking(65536, timeout=.001)
        except (pexpect.TIMEOUT, pexpect.EOF): pass
    def wait(predicate,timeout=20): return until(predicate,timeout,pump)
    started=time.monotonic()
    def seen(name,**expected):
        return any(e.get('event')==name and all(e.get(k)==v for k,v in expected.items()) for e in events(marker))
    try:
        wait(lambda: seen('rtop-ready') if app=='rtop' else seen('ready',app=app),30)
        ready_ms=(time.monotonic()-started)*1000
        if crash:
            child.sendcontrol('e')
        elif interrupt:
            # DataTable reserves Ctrl+C for copy. Focus the chart before testing
            # the application's normal interrupt binding.
            child.send('\x1bc')
            wait(lambda:seen('key',key='alt+c'))
            child.sendcontrol('c')
        elif app=='showcase':
            child.send('\x1b[B'); child.send('\t\x1b[Z\r')
            child.send('\x1b'); time.sleep(.005); child.send('['); time.sleep(.005); child.send('B')
            sample_before=len([e for e in events(marker) if e.get('event')=='sample'])
            child.send('\x1b')
            wait(lambda:len([e for e in events(marker) if e.get('event')=='sample'])>=sample_before+2)
            old_escape=len([e for e in events(marker) if e.get('event')=='key' and e.get('key')=='escape'])
            child.send('\x1b')
            wait(lambda:len([e for e in events(marker) if e.get('event')=='key' and e.get('key')=='escape'])>old_escape)
            child.sendcontrol('f'); child.send('東京')
            wait(lambda:'東京' in ''.join(transcript))
            sample_before=len([e for e in events(marker) if e.get('event')=='sample'])
            child.send('\x1b')
            wait(lambda:len([e for e in events(marker) if e.get('event')=='sample'])>=sample_before+2)
            child.send('\x1bOQ'); wait(lambda:seen('source',dataset='iris'))
            child.send('\x1bs'); wait(lambda:seen('source',lazy=True))
            child.send('\x1bs'); wait(lambda:seen('source',lazy=False,dataset='cars'))
            child.send('\x1bOS'); wait(lambda:seen('theme',theme='light'))
            child.send('\x1b[18~'); child.send('\x1b[19~'); wait(lambda:seen('copy',kind='value'))
            sample_before=len([e for e in events(marker) if e.get('event')=='sample'])
            child.send('\x1b')
            wait(lambda:len([e for e in events(marker) if e.get('event')=='sample'])>=sample_before+2)
            child.send('\x1bc'); child.send('\x1b[C\r')
            wait(lambda:seen('chart-selection'))
            child.setwinsize(18,42); pump(); child.setwinsize(32,120)
            child.send('q')
        elif app=='analytics':
            child.send('\x1bOQ'); wait(lambda:seen('analytics',sequence=2))
            child.send('\x1bs'); wait(lambda:seen('analytics',source='beta'))
            child.send('\x1bOS'); wait(lambda:seen('analytics',empty=True))
            child.send('\x1bOS'); child.send('\x1b[15~')
            child.setwinsize(18,42); child.send('q')
        elif app=='monitor':
            child.send('n'); wait(lambda:seen('task-event',type='task_completed'),30)
            child.send('e'); wait(lambda:seen('task-event',type='task_failed'),30)
            child.send('l'); wait(lambda:len([e for e in events(marker) if e.get('event')=='submit'])>=3)
            child.send('c'); wait(lambda:seen('task-event',type='task_cancelled'),15)
            child.send('d'); wait(lambda:seen('disconnect'))
            child.send('r'); wait(lambda:seen('reconnect'))
            wait(lambda:seen('monitor',connection='live'))
            child.setwinsize(20,50); child.send('\t\x1b[Z\x1b[B\r'); child.send('q')
        else:
            child.send('m'); child.send('/'); child.send('alpha'); wait(lambda:seen('filter',value='alpha'))
            child.send('\x1b'); child.send('\x1b[B\r'); wait(lambda:seen('selection'))
            child.setwinsize(18,42); wait(lambda:seen('resize',width=42))
            child.setwinsize(32,100); child.send('h+-p'); child.send('q')
        child.expect('TERMINAL_RESTORED')
        child.expect(pexpect.EOF)
        child.close()
        if crash:
            assert child.exitstatus != 0, child.exitstatus
        else:
            assert child.exitstatus == 0, child.exitstatus
            assert seen('stopped') if app=='rtop' else seen('stopped',app=app)
        # All recorded rtop values are fixtures; still check for accidental paths.
        if record:
            text=cast.read_text(encoding='utf-8',errors='replace')
            for private in ['User001','user001','C:\\Users\\','/home/user001','Bearer ','password=','token=']:
                assert private not in text, private
        return dict(app=app,status='PASS',ready_ms=ready_ms,exit_status=child.exitstatus,
            terminal_restored=True,events=len(events(marker)),recording=str(cast.relative_to(ROOT)) if record else None)
    finally:
        if child.isalive():
            # pexpect owns this fresh process group; try normal R interrupt and
            # cleanup before terminating only that group on a failed scenario.
            try: os.killpg(os.getpgid(child.pid),signal.SIGINT)
            except ProcessLookupError: pass
            deadline=time.monotonic()+5
            while child.isalive() and time.monotonic()<deadline:
                pump(); time.sleep(.01)
            if child.isalive():
                try: os.killpg(os.getpgid(child.pid),signal.SIGKILL)
                except ProcessLookupError: pass
            child.close(force=True)
        # Store only our fixture application output; never use this for live /proc.
        (out/f'{app}-pty.log').write_text(''.join(transcript),encoding='utf-8')

def main():
    p=argparse.ArgumentParser(); p.add_argument('--app',default='all',choices=['all','showcase','analytics','monitor','rtop'])
    p.add_argument('--out',default='audit-results/real-world-apps/pty'); p.add_argument('--record',action='store_true')
    p.add_argument('--legacy-library',default='candidate'); p.add_argument('--crash',action='store_true')
    p.add_argument('--interrupt',action='store_true')
    args=p.parse_args(); out=ROOT/args.out
    results=[]
    try:
        for app in (['showcase','analytics','monitor','rtop'] if args.app=='all' else [args.app]):
            result=scenario(app,out,args.record,args.legacy_library,args.crash,args.interrupt);results.append(result);print(json.dumps(result),flush=True)
    except Exception as error:
        (out/'failure-traceback.txt').write_text(traceback.format_exc())
        results.append(dict(app=app,status='FAIL',error=str(error))); print(json.dumps(results[-1]),flush=True)
        out.mkdir(parents=True,exist_ok=True);(out/'results.json').write_text(json.dumps(results,indent=2));return 1
    (out/'results.json').write_text(json.dumps(results,indent=2));return 0
if __name__=='__main__': sys.exit(main())
