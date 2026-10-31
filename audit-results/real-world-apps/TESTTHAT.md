# Phase E — Testthat

Full checkout suites were run with `Rscript tools/dev.R test`, NOT_CRAN=true,
using platform-appropriate project/normal libraries. Windows: 17,238 PASS,
56 SKIP,0 FAIL/ERROR/WARN (`full-windows.log`, exit 0). WSL: 18,736 PASS,
2 SKIP,0 FAIL/ERROR/WARN (`full-wsl.log`, exit 0). These are current Phase E runs,
not copied H3 totals. Additional final app suites have 83 expectations each,
zero skips/failures/errors/warnings; see `final-*/app-test-summary-*.json`.

Application files: `test-showcase.R`, `test-analytics.R`, `test-monitor.R` under
`integration-apps/tests`. They validate source switching, typed edit/rejection,
unchanged attributes, find/selection/A4, chart selection/resize/history, themes
with and without inkr, Shiny frame agreement/widget reuse/lease cleanup, real
tasks/failure/cancel/socket reconnect and owned worker shutdown.

The saved failing-first showcase run exits1 with three expectations exposing
reserved-key collisions. After Alt+S/Alt+C bindings, focused and final full app
suites pass. The task-shutdown test now compares new children against a captured
baseline; a runner's pre-existing processx supervisor must not be killed by it.

Windows skips include unavailable bit64, units, haven, hms, sf, RSQLite and
dbplyr paths plus POSIX-only testing. WSL skips only opposite absent-package
branches (haven and inkr are installed). Installed-package checks additionally
skip four recipes excluded from the tarball: Windows check 17,227 PASS/60 SKIP;
WSL check 18,725 PASS/6 SKIP. Both check test suites have zero warnings/failures.
Exact skip locations remain in logs; no skipped workload is labelled passed.
