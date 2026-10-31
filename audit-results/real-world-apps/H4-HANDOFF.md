# Phase E — H4 Handoff

The three applications, final runners, real PTY/browser evidence, exact rtop
baseline comparison and both Status:OK package checks provide an executable
starting point. Do not replace these finite runs with claims of long-duration
stability. Start with the highest-signal open items:

| Priority | Next experiment | Retained evidence |
| --- | --- | --- |
| P2 | Isolate retained Windows handles across repeated named mirai compute profiles; compare native versions/long-lived profile reuse and native handle types | resource-probe.R, resource-probes/*.csv, lifecycle samples; direct mirai reproduces |
| P2 | Native Windows Console/ConPTY manual/automated keyboard/resize/error-restoration run | Existing docs/platform-testing.md; WSL PTY is not certification |
| P2 | Longer sustained UI/chart/input plus worker/reconnect soak, idle-machine latency distribution | lifecycle.R; bounded histories; final recordings |
| P2 | Review provenance of observed H2 test rewrite before merging | preservation-baseline/ and preservation-results.json; current file deliberately retained |
| P3 | Reduce new application/tool style debt without mass-formatting user core changes | final lintr CSVs grouped by scope |
| P3 | Extend missing Windows optional type packages and coverage scope; capture remote worker instrumentation separately if feasible | package inventories; current coverage limitations |
| P3 | Repeat rtop hyperfine with more idle-machine samples; watch recorder errno61 | raw baseline/candidate JSON and earlier failed recording |

```sh
Rscript tools/integration/run-all.R --mode=unit,headless,process --timeout=180
Rscript tools/integration/run-all.R --mode=lifecycle,profile,benchmark --timeout=600
Rscript tools/integration/run-all.R --mode=pty,expect,tmux,recording --timeout=300
python3 tools/integration/verify-preservation.py
```

Use Ubuntu for POSIX modes, native Windows R for its platform checks. Existing
project dependency libraries are controlled but ignored by Git; a fresh machine
must install matching optional packages and exact baseline/candidate libraries.
The runner reports absent POSIX tools/platforms as skips and failed jobs as
nonzero. Install instructions and app controls are in integration-apps/README.md.

No core API/version changes or releases were made. Preserve the already dirty
A1–H3 tree and archived initial hashes. `.Rbuildignore` intentionally excludes
the applications and pre-existing terminal recording from package builds.
Do not silently discard the observed H2 differences or call them a verified
Phase E core fix. No additional manual repair is required to launch the apps.
