import pexpect, os, time, tempfile
ROOT=os.path.expanduser("~/audit/src")
env=dict(os.environ, R_LIBS=os.path.expanduser("~/audit/lib"), TERM="xterm-256color")
script="/mnt/c/programming_pj/r_textualize/audit-results/pty/uni-app.R"
log=tempfile.mktemp(); env["TERMR_PTY_LOG"]=log
c=pexpect.spawn("Rscript",[script],env=env,dimensions=(24,80),encoding=None,timeout=60,cwd=ROOT)
def pump(t=0.01):
    try:
        while True: c.read_nonblocking(65536,timeout=t)
    except (pexpect.TIMEOUT,pexpect.EOF): pass
for _ in range(100):
    pump(0.3)
    if os.path.exists(log) and "ready" in open(log).read(): break
N=3000; t0=time.time()
for i in range(N):
    c.send(b"\x1b[B" if i%2 else b"a")
    if i%50==0: pump(0.001)
sent=time.time()-t0
# wait until processed: all keys logged
t1=time.time()
while time.time()-t1<120:
    pump(0.2)
    if open(log).read().count("key ")>=N: break
n=open(log).read().count("key ")
print(f"sent {N} in {sent:.1f}s, processed {n} after {time.time()-t0:.1f}s")
c.send(b"\x03"); time.sleep(2); pump(0.5); print("exited:", not c.isalive())
if c.isalive(): c.terminate(force=True)
