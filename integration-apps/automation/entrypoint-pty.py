"""Exercise the actual documented entrypoint, without changing its loader mode."""
import argparse,json,os,shlex,signal,subprocess,sys,threading,time,traceback
from pathlib import Path
from event_log import read_events,READ_RETRIES
ROOT=Path(__file__).resolve().parents[2]
if os.name=='nt':
    sys.path.insert(0,str(ROOT/'integration-apps/.deps/python-windows'))
    from winpty import PtyProcess
else:
    import pexpect

def scenario(app,out,exercise=True,crash=False):
    out.mkdir(parents=True,exist_ok=True)
    marker=out/'events.jsonl'
    if marker.exists():marker.unlink()
    env=os.environ.copy()
    env.pop('TERMR_USE_INSTALLED',None)
    env.update(TERMR_PROJECT_ROOT=str(ROOT),TERMR_E_EVENTS=str(marker),
        R_PROFILE_USER=str(ROOT/'integration-apps/automation/entrypoint-profile.R'),
        TERMR_E_RUNTIME=str(out/'runtime.json'))
    chunks=[];reader_errors=[]
    if os.name=='nt':
        command=['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',
            str(ROOT/'integration-apps/automation/entrypoint-native.ps1'),'-App',app,'-Out',str(out),
            '-Scenario','crash' if crash else 'normal']
        child=PtyProcess.spawn(command,cwd=str(ROOT),env=env,dimensions=(32,110),backend=0)
        def reader():
            try:
                while True:chunks.append(child.read(65536))
            except EOFError:pass
            except Exception as error:reader_errors.append(str(error))
        thread=threading.Thread(target=reader,daemon=True);thread.start()
        send=child.write
        def pump():time.sleep(.005)
    else:
        env.update(TERM='xterm-256color',LANG='C.UTF-8',LC_ALL='C.UTF-8')
        text=shlex.join(['Rscript','integration-apps/run.R',f'--app={app}','--mode=terminal',
            '--scenario=crash' if crash else '--scenario=normal'])
        command=['bash','-c','before=$(stty -g); '+text+' 2>'+shlex.quote(str(out/'stderr.log'))+
            '; code=$?; test "$(stty -g)" = "$before" && printf "\\nEFIX_TERMINAL_RESTORED\\n"; exit "$code"']
        child=pexpect.spawn(command[0],command[1:],cwd=str(ROOT),env=env,encoding='utf-8',
            codec_errors='strict',dimensions=(32,110),timeout=30)
        send=child.send
        def pump():
            try:chunks.append(child.read_nonblocking(65536,timeout=.005))
            except (pexpect.EOF,pexpect.TIMEOUT):pass
    def seen(event,**fields):
        return any(item.get('event')==event and all(item.get(key)==value for key,value in fields.items()) for item in read_events(marker))
    def wait(predicate,seconds=30):
        deadline=time.monotonic()+seconds
        while time.monotonic()<deadline:
            pump()
            if predicate():return
            if not child.isalive():raise AssertionError('Entrypoint exited before required state')
        raise AssertionError('Timed out waiting for required application state')
    result=dict(app=app,command=f'Rscript integration-apps/run.R --app={app} --mode=terminal',
        loader_environment='TERMR_USE_INSTALLED unset',platform=sys.platform)
    try:
        wait(lambda:seen('ready',app=app))
        title={'showcase':'Termr Data Workbench','analytics':'Shiny Visual Analytics Bridge','monitor':'Distributed Task & Stream Monitor'}[app]
        wait(lambda:title in ''.join(chunks))
        if app=='analytics':wait(lambda:'\u6771\u4eac' in ''.join(chunks))
        result.update(start=True,render=True)
        if crash:
            if app=='monitor':
                send('l');wait(lambda:seen('submit',kind='long'))
            send('\x05')
        elif exercise:
            if app=='showcase':
                send('\x1bOQ');wait(lambda:seen('source',dataset='iris'))
                send('\x1b[23~');wait(lambda:seen('source',lazy=True,rows=10000))
                send('\x1bOS');wait(lambda:seen('theme',theme='light'))
                wait(lambda:'Theme: light' in ''.join(chunks))
                send('\x1b[23~');wait(lambda:seen('source',lazy=False,dataset='cars'))
                send('\x1b[15~');wait(lambda:seen('filter'))
                send('\x1b[17~');wait(lambda:'Edit value' in ''.join(chunks))
                send('\x15'+'12.5'+'\r');wait(lambda:seen('cell-changed',value=12.5))
                send('\x1b[18~'+'\x1b[19~');wait(lambda:seen('copy',kind='value'))
                # Escape belongs to the modal, then a second action opens pipeline.
                send('\x1b');time.sleep(.15);send('\x1b[20~')
                wait(lambda:seen('copy',kind='pipeline'))
                send('\x1b');time.sleep(.15);send('\x1b[24~')
                send('\x1b[C\r');wait(lambda:seen('chart-selection'))
                send('\x1b[Z')
                for index in range(2,6):
                    send('\x1b[C');wait(lambda:seen('chart-tab',index=index))
            elif app=='analytics':
                send('\x1bOQ');wait(lambda:seen('analytics',sequence=2))
                send('\x1b[23~');wait(lambda:seen('analytics',source='beta'))
                send('\x1bOS');wait(lambda:seen('analytics',empty=True,rows=0))
                wait(lambda:'EMPTY' in ''.join(chunks))
            else:
                send('n');wait(lambda:seen('task-event',type='task_completed'))
                send('\r');wait(lambda:seen('task-details',status='completed'))
                wait(lambda:'chunks' in ''.join(chunks))
                send('\x1b');time.sleep(.15)
                send('e');wait(lambda:seen('task-event',type='task_failed'))
                send('l');wait(lambda:len([x for x in read_events(marker) if x.get('event')=='submit'])==3)
                send('c');wait(lambda:seen('task-event',type='task_cancelled'))
                send('d');wait(lambda:seen('disconnect'))
                send('r');wait(lambda:seen('reconnect'))
                wait(lambda:seen('monitor',connection='live'))
            result['interact']=True
        if not crash:
            child.setwinsize(20,65);pump();child.setwinsize(32,110)
            send('q')
        deadline=time.monotonic()+20
        while child.isalive() and time.monotonic()<deadline:pump()
        assert not child.isalive(),'Entrypoint did not shut down'
        if os.name=='nt':
            thread.join(5);code=child.exitstatus
        else:
            for _ in range(4):pump()
            child.close();code=child.exitstatus
            assert 'EFIX_TERMINAL_RESTORED' in ''.join(chunks)
        assert code!=0 if crash else code==0,code
        assert seen('stopped',app=app),'Missing owner-cleanup marker'
        if app=='monitor':
            stopped=[x for x in read_events(marker) if x.get('event')=='stopped'][-1]
            assert all(stopped.get(key) is True for key in ['closed','pool_closed','transport_closed','source_closed'])
            owned=[x for x in read_events(marker) if x.get('event')=='owned-processes'][-1]['processes']
            owned_path=out/'owned-processes.json';owned_path.write_text(json.dumps(owned))
            rscript=r'C:\Program Files\R\R-4.6.1\bin\Rscript.exe' if os.name=='nt' else 'Rscript'
            check=subprocess.run([rscript,'integration-apps/automation/verify-owned.R',str(owned_path)],
                cwd=ROOT,capture_output=True,text=True,timeout=12)
            (out/'owned-cleanup.stdout.log').write_text(check.stdout)
            (out/'owned-cleanup.stderr.log').write_text(check.stderr)
            assert check.returncode==0,check.stderr
            result['owned_processes_verified']=len(owned)
        result.update(status='PASS',shutdown=True,exit_code=code,expected_failure=crash,reader_errors=reader_errors)
    except Exception as error:
        result.update(status='FAIL',error=str(error),traceback=traceback.format_exc())
    finally:
        if child.isalive():
            if os.name=='nt':
                subprocess.run(['taskkill','/PID',str(child.pid),'/T','/F'],capture_output=True,timeout=10)
            else:
                os.killpg(os.getpgid(child.pid),signal.SIGINT)
                deadline=time.monotonic()+3
                while child.isalive() and time.monotonic()<deadline:pump()
                if child.isalive():os.killpg(os.getpgid(child.pid),signal.SIGKILL)
        (out/'stdout.log').write_text(''.join(chunks),encoding='utf-8')
        result['event_log_read_retries']=list(READ_RETRIES)
        (out/'result.json').write_text(json.dumps(result,indent=2))
    return result

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--app',default='all')
    parser.add_argument('--out',required=True);parser.add_argument('--startup-only',action='store_true')
    parser.add_argument('--crash',action='store_true')
    args=parser.parse_args();out=(ROOT/args.out).resolve()
    results=[scenario(app,out/app,not args.startup_only,args.crash) for app in
        (['showcase','analytics','monitor'] if args.app=='all' else [args.app])]
    (out/'results.json').write_text(json.dumps(results,indent=2))
    print(json.dumps(results,indent=2));sys.exit(int(any(x['status']!='PASS' for x in results)))
