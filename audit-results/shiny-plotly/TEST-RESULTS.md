# Validation results

Run date: 2026-10-29, Windows R 4.6.1 / WSL R 4.5.2. NOT_CRAN=true for full
source tests and checks. No mandatory dependency added. Raw logs remain here.

- `full-windows-unsandboxed.log`: TOTAL 13927 expectations; 0 failures; 0 errors; 18 skips; 0 warnings.
- `full-wsl.log`: TOTAL 14035 expectations; 0 failures; 0 errors; 0 skips; 0 warnings.
- `focused-ack-windows.log`: TOTAL 113 expectations; 0 failures; 0 errors; 0 skips; 0 warnings.
- `focused-final-wsl.log`: TOTAL 105 expectations; 0 failures; 0 errors; 0 skips; 0 warnings.
- `focused-ack-wsl.log`: TOTAL 53 expectations; 0 failures; 0 errors; 0 skips; 0 warnings.
- Final batched R CMD check windows: Status: OK; `check-batched-windows.log`.
  Package testthat windows: [ FAIL 0 | WARN 0 | SKIP 22 | PASS 13899 ].
- Final batched R CMD check wsl: Status: OK; `check-batched-wsl.log`.
  Package testthat wsl: [ FAIL 0 | WARN 0 | SKIP 4 | PASS 14033 ].

The earlier pre-batching full R CMD checks also completed with Status: OK on
both platforms (check-final-*.log). The final checks include the selected 500 ms
example interval and full testthat suite from the final tarball. Build excludes
audit reports, local browser artifacts and temporary snapshots. No manual PDFs
or built vignettes were requested (`--no-manual --no-build-vignettes`).

Commands:

```text
Rscript audit-results/shiny-plotly/run_tests.R .
Rscript audit-results/shiny-plotly/run_tests.R shiny-process
Rscript audit-results/shiny-plotly/check.R batched
Rscript audit-results/shiny-plotly/minimal.R
Rscript audit-results/shiny-plotly/performance_shared.R
Rscript audit-results/shiny-plotly/plot_benchmark.R
WSL: bash audit-results/shiny-plotly/pty.sh
python audit-results/shiny-plotly/preservation.py
```

Focused Shiny suite covers lifecycle/coalescing, bounded history, invalid/stale
status, metadata dedupe/order/source restart (including empty snapshot), 20
shared leases and implicit cleanup. testServer validates independent processx
publisher delivery and dashboard cursor/proxy/acknowledgement behavior. Nano
suite covers raw malformed JSON/schema, exact topics, snapshots/gaps/reconnect,
callback close and bounded ready-queue drain. Frame tests cover typed empty,
NA/NaN/Inf, bad timestamps, nesting/extractors and discontinuity segments.
Stream suite covers callback errors. These are layer-specific tests; not every
corrupt-packet case was also driven through a browser.

Minimal isolated libraries on BOTH hosts contain only mandatory dependencies:
TUI/core/frame work without Shiny/ggplot2/Plotly/nanonext, and Shiny constructor
reports a clear optional-package error. Existing WSL PTY suite: all checks passed,
including raw mode, focus/input batching, resize, Ctrl+C/error restoration.
Windows terminal behavior is unit-tested; no interactive ConPTY automation or
macOS host was available.

Windows 18 source-suite skips concern unavailable DBI/RSQLite/knitr or POSIX-only
tests; see raw reasons. Initial sandbox run failed processx pipe creation, then
approved unrestricted run passed. Early readiness-file test warnings were a
harness race and were fixed; clean focused runs and final checks supersede them.

`preservation.json` verifies 455 of 467 initial files byte-for-byte; the 12
changed baseline files are explicitly authorized scope. Unrelated initial user
changes, old stream/signal/TUI implementations and existing help are preserved.
Index remains unstaged. `git diff --check` passed; Git only warned about existing
CRLF normalization in initial geometry/style files. See IMPLEMENTATION.md for
the maintained change list and BROWSER-VALIDATION.md for actual browser evidence.
