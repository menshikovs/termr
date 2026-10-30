import pexpect, os, time, tempfile, sys
ROOT=os.path.expanduser("~/audit/src")
base=dict(os.environ, R_LIBS=os.path.expanduser("~/audit/lib"), TERM="xterm-256color")
script="/mnt/c/programming_pj/r_textualize/audit-results/phase-3/pty/exc-app.R"
def run(mode, keys=b"", wait=4):
    log=tempfile.mktemp(); env=dict(base, EXC_MODE=mode, TERMR_PTY_LOG=log)
    c=pexpect.spawn("Rscript",[script],env=env,dimensions=(24,80),encoding=None,timeout=30,cwd=ROOT)
    buf=b""; t0=time.time()
    def pump(t=0.3):
        nonlocal buf
        try:
            while True: buf+=c.read_nonblocking(65536,timeout=t)
        except (pexpect.TIMEOUT,pexpect.EOF): pass
    pump(3.0)
    if keys: c.send(keys); pump(1.0)
    while c.isalive() and time.time()-t0<wait+8: pump(0.3)
    alive=c.isalive()
    if alive: c.send(b"\x03"); pump(1.5)
    if c.isalive(): c.terminate(force=True)
    pump(0.5); c.close(); st=c.exitstatus if c.exitstatus is not None else c.signalstatus

    lg=open(log).read().replace("\n","|") if os.path.exists(log) else "NOLOG"
    restored = buf.rfind(b"\x1b[?1049l")>buf.rfind(b"\x1b[?1049h")>=0 and buf.rfind(b"\x1b[?25h")>buf.rfind(b"\x1b[?25l")
    errtxt=buf[buf.rfind(b"Error"):][:90] if b"Error" in buf else b""
    print(f"{mode:12s} hung_until_ctrlc={alive} status={st} modes_restored={restored} log={lg} err={errtxt!r}")
for m in ["render","layout","timer","worker","stopfail"]:
    run(m, keys=b"q" if m=="stopfail" else b"")
