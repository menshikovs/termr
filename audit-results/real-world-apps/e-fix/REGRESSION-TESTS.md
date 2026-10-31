# E-FIX — Regression Tests

New `integration-apps/tests/test-e-fix.R` covers cwd-independent startup, clearing
an empty chart, Enter/result details, strict missing/stale/tampered installation
rejection, portable source/chart keys, real sorted row values and five distinct
painted chart bodies with numeric data. The verified failing-first run exits1
with six failed expectations. Current full app suites have115 passing
expectations on each OS, no fail/error/skip/warn. Their files and summaries are
`proof-windows/app-test-summary-windows.json` and `proof-wsl/app-test-summary-unix.json`.

`entrypoint-pty.py` launches the real CLI with TERMR_USE_INSTALLED unset, under
Windows ConPTY or POSIX PTY, captures first-frame bytes, performs real keyboard
operations and checks semantic/data events, exits and ownership cleanup. It
never substitutes a miniature independent app. `entrypoint-browser.R` launches
the actual web mode and asserts the live browser. Controlled error cases expect
exit1, so a falsely successful returning error hook fails the harness.

Fresh additional tools:

| Tool | E-FIX evidence/scope |
| --- | --- |
| processx |Ten cases on both OS, including actual headless app entrypoints, failure/timeout/owned child cleanup |
| Expect |Two independent real terminal smokes, keyboard and terminal restoration |
| tmux |Fresh isolated namespace; showcase/monitor pane capture, input and resize (legacy third case kept separately) |
| covr |91.9192% of the three current app source files; HTML/XML/CSV/RDS in proof-coverage/ |
| lintr |Fresh scans,0 error diagnostics; substantial style debt retained; counts in proof-windows/ and proof-wsl/ |
| Rprof/profvis |Fresh actual startup/table/chart/Shiny/native workloads after functional gates, raw/summary/HTML artifacts |
| hyperfine |Fresh process startup/render/shutdown runs, warmup1/runs5; JSON in proof-windows/ and proof-wsl/ |
| asciinema |New real recordings below; no upload |

| Application | Fresh recording |
| --- | --- |
| showcase | proof-wsl/recording/showcase.cast |
| analytics | proof-wsl/recording/analytics.cast |
| monitor | proof-wsl/recording/monitor.cast |


Coverage includes real controller/native operations; the identical worker body
runs uninstrumented in its separate R process and remains uncovered. Branch
coverage and fresh core covr are not claimed. Public API/source provenance and
real gates are separate from coverage percentage. Profiling preserves raw
Shiny profiles and a disclosed derived normalization for multiline debug labels.
Benchmark timings include setup/render/cleanup and overlapping validation load;
they are not a steady-state latency or performance-improvement claim.

Default lintr is not clean: Windows5396 findings and WSL5388,
mostly style; existing core diagnostics are separately labelled. Known ggplot
NSE names cpu/segment were checked against real browser rendering rather than
silenced with global-variable declarations.
