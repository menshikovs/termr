# E-FIX — Real Execution

| App | Start | Render | Interact | Integration | Shutdown |
| --- | --- | --- | --- | --- | --- |
| Showcase | PASS | PASS | PASS | PASS | PASS |
| Analytics TUI | PASS | PASS | PASS | PASS | PASS |
| Analytics Web | PASS | PASS | PASS | PASS | PASS |
| Task Monitor | PASS | PASS | PASS | PASS | PASS |


All five mandatory gates pass for the tested Windows/WSL execution paths. This
matrix is derived from new entrypoint results, not test-count inference or old
Phase E reports. Normal processes exit0; controlled fatal callback tests exit1
and count as separate expected-failure recovery tests.

```powershell
$R = 'C:/Program Files/R/R-4.6.1/bin/Rscript.exe'
& $R integration-apps/run.R --app=showcase --mode=terminal
& $R integration-apps/run.R --app=analytics --mode=terminal
& $R integration-apps/run.R --app=analytics --mode=web
& $R integration-apps/run.R --app=monitor --mode=terminal
```
Run from the checkout root in VS Code **Terminal → New Terminal**. A TUI paints
that terminal rather than opening a separate window. Web mode prints its URL;
open that URL in a browser (automatic browser launch is intentionally disabled).
From any working directory on Windows:
`& 'C:/programming_pj/r_textualize/integration-apps/launch.ps1' -App showcase`.
The launcher was itself run in a native Windows PTY from the system Temp directory;
the interface rendered and q exited0 (`launcher-real-pty.json`).

| Evidence | What actually ran |
| --- | --- |
| proof-windows/terminal-gates/ | Actual run.R in native Windows ConPTY, installed current-windows package |
| proof-wsl/terminal-gates/ | Actual run.R in POSIX PTYs, installed current-linux package, stty restored |
| proof-windows/browser-gates/ | Actual web command + Windows Chrome; shared values and live Plotly traces |
| proof-web-wsl/ | Actual WSL R web command + Windows Chrome through loopback forwarding |
| active-crash-windows/ and active-crash-wsl/ | Real long task submitted, callback failure, owner closed, observed owned PIDs stopped |

Every terminal case retains stdout.log, stderr.log, result.json, events.jsonl and
runtime.json with R/package versions and namespace paths. Error cases additionally
retain traceback.txt. Normal cases have no traceback because no error occurred.
The Windows wrapper redirects stderr while leaving real console I/O attached.

Workbench native actions include dataset/source/theme, filter, native modal edit
to12.5, A4 value/pipeline, chart selection, all five chart tabs, resize and quit.
Analytics performs sample/source/empty operations with visible changes. Monitor
performs real completion/result/failure/cancel/disconnect/reconnect and shutdown.
`owned-cleanup.*.log` verifies creation-time-aware descendant PIDs after process
exit; pool/source/transport closure is independently asserted. Final global R
process snapshots complement those scoped checks; no unrelated process is killed.
