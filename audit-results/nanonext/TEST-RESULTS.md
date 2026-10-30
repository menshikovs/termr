# Phase 3 validation results

Executed 2026-10-29 against the current local checkout. Windows R 4.6.1 UCRT,
WSL Ubuntu R 4.5.2, optional nanonext 1.10.3. No claims below are inferred from
previous phases or CI. Logs and reproductions remain in this directory.

## Full regression

Command: `Rscript --vanilla audit-results/nanonext/run-tests.R .` runs
testthat::test_local with NOT_CRAN=true and returns failure status on any
error/failure. It includes existing terminal/widget/worker/property suites,
the 100000-publication Stream core test and file transport tests.

| Host | Expectations | Failures / errors | Skips |
| --- | ---: | --- | ---: |
| Windows | 13803 | 0 / 0 | 19: optional DBI/RSQLite/Shiny and POSIX |
| WSL | 13928 | 0 / 0 | 0 |

Logs: full-windows.log, full-wsl.log. No expected snapshots were changed or
accepted. No old tests were edited. Final focused command (same driver without
filter argument) reports 57 expectations, 0 failures/errors/skips on both
hosts: tests-windows-final.log and tests-wsl-final.log.

New tests cover bounded JSON/schema/depth/size failures, executable/reference
object rejection, optional API validation, numeric loopback endpoints, native
port-0 ownership, constructor failure cleanup, latest state before subscription,
history=0 seed, snapshot/live deduplication and monotone sequences, connect
before publisher, source restart, slow-reader gaps, final-event snapshot
recovery after live unsubscribe, topic delimiter isolation, corrupt packets,
callback close/cancellation and a real processx subscriber. Each wait has a
deadline and polls a predicate; process/socket cleanup is registered on exit.

## Package validation

Command: `Rscript --vanilla audit-results/nanonext/check.R`. It stages source
entries allowed by .Rbuildignore, runs R CMD build --no-manual and R CMD check
--no-manual --no-build-vignettes, with NOT_CRAN=true and optional suggestions
not forced. Tar listing assertions exclude audit reports, scratch libraries,
pending snapshot files and testthat temporary artifacts.

- Windows: **Status: OK**, no errors/warnings/notes. Installed test result
  `[FAIL 0 | WARN 0 | SKIP 23 | PASS 13773]`.
- WSL: **Status: OK**, no errors/warnings/notes. Installed test result
  `[FAIL 0 | WARN 0 | SKIP 4 | PASS 13917]`.

Logs: check-windows.log/check-wsl.log and check-{windows,wsl}/termr.Rcheck/.
Four extra skips are existing recipe-Markdown checks because docs are excluded
from package builds; those ran in the full source suite. Windows additionally
lacks optional DB packages/Shiny. PDF manual/TeX and CRAN incoming were not run.

Final source/fixture/tool names were brought to snake_case and help regenerated
with tools/dev.R doc. Packaging/static/help/example checks plus the 57 new
nanonext assertions were rerun on both platforms with
`Rscript audit-results/nanonext/check.R final nanonext`: **Status: OK on both**,
`[FAIL 0 | WARN 0 | SKIP 0 | PASS 57]`. Logs: check-windows-final.log and
check-wsl-final.log. The preceding check runs above exercised the full suite.

## Independent owners, transport and recovery

- Fan-out to **1, 10 and 50 independent installed R subscribers** PASS on
  Windows and WSL, including one deliberately slow client in 10/50 scenarios.
  All reach current final state, keep history<=16 and AIO slots<=2. SUMMARY.json
  contains all per-client delivered counts, gaps, latencies and RSS. Raw-only
  20000-message separate-process controls also PASS on both hosts.
- `monitor-integration.R`: one collector publishes **both file and nano**;
  TUI, Shiny (WSL) and an independent R subscriber consume the same source.
  Client close/restart leaves collector running; stopped collector becomes
  stale; source restart is accepted without restarting clients. All child
  exits are clean. Logs: monitor-windows-bounded.log, monitor-wsl-final.log.
  Windows Shiny is explicitly skipped because the package is absent.
- `shiny-live.R` in WSL: PASS live CPU/RAM rendering and actual renderPlot
  history, stale state after publisher stop, source-restart resync and session
  close with zero pending AIO. Log: shiny-live-final.log. This uses real loopback
  sockets and Shiny testServer; no manual browser/HTTP-host certification.
- WSL publisher -> Windows subscriber loopback forwarding PASS, including
  actual publisher restart on the same endpoints. cross-restart/RESULT.json
  records source change and p50/p95/p99 latency. Windows publisher -> WSL
  localhost did not connect during a bounded attempt; no success is claimed.
- `minimal.R` on each host: install/load current termr in a separate library
  **without nanonext**, emit/read a local stream, render a TUI, then assert a
  clear optional-dependency error on adapter creation. Both PASS.

## Findings and corrections

- A new assertion initially expected a double sequence rather than JSON's
  decoded integer; corrected the test to compare numeric value.
- Missing readiness files initially produced test warnings; readiness now
  checks file existence and retries parse races before reading.
- Windows pkgload-loaded peers received data but exited with native access
  violation. Minimal raw-only nanonext control exited cleanly. Installed
  termr peers then repeatedly exited 0 without added GC/traces/sleeps. The
  harness now tests installed runtime; underlying native/dev-loader cause is
  not claimed solved. Original failure logs are retained.
- Full ps::ps metadata scans stalled Windows collection about 4.6 s and
  starved snapshot polling. Collector now queries only PID/name/RSS for a
  bounded 100-PID sample, and uses 3-second snapshot timeout. Windows
  monitor/restart then PASS. The sampling limitation is documented.
- An audit Shiny probe used a 0.2-second stale threshold, shorter than first
  plot initialization; the probe now uses the production five-second threshold
  and emits a fresh measurement before testing restart. No product behavior
  was weakened to make the probe pass.

Final checks: preservation.log confirms **446 initial files byte-for-byte
unchanged**, including Stream core, signals, App, widgets, workers and all old
tests. Only the 12 authorized existing documentation/config/demo paths changed.
New Phase-3 files are listed in IMPLEMENTATION.md. `git diff --check` PASS.
No commit/push/merge/release or system software installation was performed.
