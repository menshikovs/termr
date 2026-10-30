import pexpect, os, sys, time, random, re, termios, struct, fcntl, signal, tempfile
ROOT=os.path.expanduser("~/audit/src")
env=dict(os.environ, R_LIBS=os.path.expanduser("~/audit/lib"), TERM="xterm-256color")
sizes=[(1,1),(5,10),(10,20),(15,40),(24,80),(40,120),(60,200)]
fails=[]
def check(n,c,d=""):
    print(("PASS " if c else "FAIL ")+n, d if not c else ""); 
    if not c: fails.append((n,d))
def run(rows,cols,script,seq=None,seed=0,kill=None):
    log=tempfile.mktemp(); env["TERMR_PTY_LOG"]=log
    c=pexpect.spawn("Rscript",[script],env=env,dimensions=(rows,cols),encoding=None,timeout=60,cwd=ROOT)
    t0=time.time(); buf=b""
    def pump(t=0.3):
        nonlocal buf
        try:
            while True: buf+=c.read_nonblocking(65536,timeout=t)
        except (pexpect.TIMEOUT,pexpect.EOF): pass
    # wait ready
    ok=False
    for _ in range(200):
        pump(0.3)
        if os.path.exists(log) and "ready" in open(log).read(): ok=True;break
        if not c.isalive(): break
    return c,log,pump,lambda:buf,ok
app=os.path.join(ROOT,"..","..","..")  # unused
script=os.path.join(os.path.dirname(os.path.abspath(__file__)),"uni-app.R")
script=script.replace("/mnt/c/programming_pj/r_textualize/audit-results/pty","/mnt/c/programming_pj/r_textualize/audit-results/pty")
rnd=random.Random(42)
keys=[b"\t",b"\x1b[Z",b"\r",b"\x1b",b"\x1b[A",b"\x1b[B",b"\x1b[C",b"\x1b[D",b"\x7f",b"\x1b[3~",b"\x1b[H",b"\x1b[F",b"a",b"\xd0\x96",b"\xe4\xbd\xa0",b"\xf0\x9f\x98\x80",b" ",b"\x1b[200~paste\x1b[201~",b"\x1b[<0;5;3M",b"\x1b[<0;5;3m",b"\x1b[1;5C",b"\x1bO",b"\x1b[",b"\x1b[99999999999999999999~"]
for rows,cols in sizes:
    c,log,pump,getbuf,ok=run(rows,cols,script)
    check(f"{cols}x{rows} starts",ok)
    if not ok:
        c.terminate(force=True); continue
    pump(0.5)
    # random fuzz keys, some batched
    for i in range(60):
        n=rnd.choice([1,1,1,3,8])
        c.send(b"".join(rnd.choice(keys) for _ in range(n)))
        if i%15==7:
            r2,c2=rnd.choice(sizes); c.setwinsize(r2,c2)
        time.sleep(0.01)
    pump(1.0)
    alive=c.isalive()
    check(f"{cols}x{rows} alive after fuzz",alive)
    if alive:
        c.send(b"\x03"); 
        t0=time.time()
        while c.isalive() and time.time()-t0<15: pump(0.3)
        check(f"{cols}x{rows} exits on ctrl+c", not c.isalive(), "still alive")
        if c.isalive(): c.terminate(force=True)
    pump(0.3); b=getbuf()
    check(f"{cols}x{rows} leaves alt screen", b.rfind(b"\x1b[?1049l")>b.rfind(b"\x1b[?1049h")>=0)
    check(f"{cols}x{rows} cursor shown at end", b.rfind(b"\x1b[?25h")>b.rfind(b"\x1b[?25l"))
    check(f"{cols}x{rows} mouse off", b.rfind(b"\x1b[?1000l")>b.rfind(b"\x1b[?1000h") or b"\x1b[?1000h" not in b)
    log_t=open(log).read() if os.path.exists(log) else ""
    check(f"{cols}x{rows} exited logged","exited" in log_t, log_t[-200:])
    check(f"{cols}x{rows} no R error output", b"Error" not in b.replace(b"\x1b",b""), b[-300:])
# signals
for sig,name in [(signal.SIGTERM,"SIGTERM"),(signal.SIGINT,"SIGINT"),(signal.SIGHUP,"SIGHUP")]:
    c,log,pump,getbuf,ok=run(24,80,script)
    pump(0.5)
    c.kill(sig)
    t0=time.time()
    while c.isalive() and time.time()-t0<10: pump(0.3)
    pump(0.3); b=getbuf()
    check(f"{name}: process ends",not c.isalive())
    check(f"{name}: terminal modes restored", b.rfind(b"\x1b[?1049l")>b.rfind(b"\x1b[?1049h")>=0 and b.rfind(b"\x1b[?25h")>b.rfind(b"\x1b[?25l"), repr(b[-120:]))
    if c.isalive(): c.terminate(force=True)
# Ctrl+D
c,log,pump,getbuf,ok=run(24,80,script); pump(0.5); c.send(b"\x04"); time.sleep(1); pump(0.5)
print("ctrl+d: alive=",c.isalive(), "log:",(open(log).read() if os.path.exists(log) else "NOLOG").replace("\n","|")[-100:]); c.terminate(force=True)
# key hold flood
c,log,pump,getbuf,ok=run(24,80,script); pump(0.5)
t0=time.time()
for i in range(3000): c.send(b"\x1b[B" if i%2 else b"a")
pump(2.0); print("flood ok alive",c.isalive(), "t=%.1f"%(time.time()-t0))
c.send(b"\x03"); time.sleep(3); pump(0.3); check("flood exit",not c.isalive())
if c.isalive(): c.terminate(force=True)
print("FAILS:",len(fails)); [print(f) for f in fails]
