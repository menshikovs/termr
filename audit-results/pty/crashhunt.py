import pexpect, os, time, random, tempfile, sys, json
ROOT=os.path.expanduser("~/audit/src")
env=dict(os.environ, R_LIBS=os.path.expanduser("~/audit/lib"), TERM="xterm-256color")
script="/mnt/c/programming_pj/r_textualize/audit-results/pty/uni-app.R"
keys=[b"\t",b"\x1b[Z",b"\r",b"\x1b",b"\x1b[A",b"\x1b[B",b"\x1b[C",b"\x1b[D",b"\x7f",b"\x1b[3~",b"\x1b[H",b"\x1b[F",b"a",b"\xd0\x96",b"\xe4\xbd\xa0",b"\xf0\x9f\x98\x80",b" ",b"\x1b[200~paste\x1b[201~",b"\x1b[<0;5;3M",b"\x1b[<0;5;3m",b"\x1b[1;5C",b"\x1bO",b"\x1b[",b"\x1b[99999999999999999999~"]
sizes=[(1,1),(5,10),(10,20),(15,40),(24,80),(40,120),(60,200)]
for attempt in range(int(sys.argv[1])):
    seed=attempt; rnd=random.Random(seed)
    rows,cols=sizes[rnd.randrange(len(sizes))]
    log=tempfile.mktemp(); env["TERMR_PTY_LOG"]=log
    c=pexpect.spawn("Rscript",[script],env=env,dimensions=(rows,cols),encoding=None,timeout=60,cwd=ROOT)
    buf=b""
    def pump(t=0.2):
        global buf
        try:
            while True: buf+=c.read_nonblocking(65536,timeout=t)
        except (pexpect.TIMEOUT,pexpect.EOF): pass
    for _ in range(100):
        pump(0.3)
        if os.path.exists(log) and "ready" in open(log).read(): break
    steps=[]
    for i in range(80):
        n=rnd.choice([1,1,1,3,8]); b=b"".join(rnd.choice(keys) for _ in range(n))
        if not c.isalive(): break
        steps.append(("k",b.hex())); 
        try: c.send(b)
        except OSError: break
        if i%15==7:
            r2,c2=rnd.choice(sizes); c.setwinsize(r2,c2); steps.append(("r",r2,c2))
        pump(0.02)
    pump(0.8)
    if not c.isalive() and b"Execution halted" in buf:
        err=buf[buf.rfind(b"Error"):][:200]
        print("CRASH seed",seed,rows,cols,err)
        json.dump({"rows":rows,"cols":cols,"steps":steps},open(f"crash-{seed}.json","w"))
    else:
        c.send(b"\x03"); pump(1.5)
    if c.isalive(): c.terminate(force=True)
print("done")
