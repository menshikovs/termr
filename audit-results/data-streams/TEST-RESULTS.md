# Test results

Date: 2026-10-29. All claims below refer to commands run in this environment.
No interactive key input is required by the automated drivers.

## Local testthat

`Rscript --vanilla audit-results/data-streams/full-suite.R` calls
`testthat::test_local('.', reporter='summary')` with NOT_CRAN=true and exits
nonzero on failures/errors (unlike tools/dev.R test's reporting-only wrapper).

- Windows corrected environment: **13740 expectations, 0 failures, 0 errors,
  19 skips, 0 warnings**. Log: full-windows-corrected.log. Skips are optional
  DBI/RSQLite/Shiny and a POSIX test. Locale and sandbox restrictions in the
  initial run were resolved before this successful rerun.
- WSL: **13865 expectations, 0 failures, 0 errors, 0 skips, 0 warnings**.
  Log: full-wsl.log.

Final focused command: `Rscript --vanilla audit-results/data-streams/focused.R`
uses `filter='streams|monitor-live'` and NOT_CRAN=true.

- Windows: **5133 expectations, 0 failures/errors, 1 skip (Shiny absent)**.
  Log: focused-windows-verified.log.
- WSL: **5142 expectations, 0 failures/errors/skips**.
  Log: focused-wsl-verified.log.

The final focused run includes the later interrupt/no-extra-frame checks and
snapshot prune-access-failure checks. No expected snapshots were changed or
accepted. Temporary `.new.md` snapshots from the initial invalid Windows
locale are excluded from package builds, as are testthat `_problems` files.

## Invariants exercised

- Empty/null/repeated events, zero/small capacities, wraparound, clear and
  reference-object semantics.
- Seeded model: five capacities x 500 mixed emit/clear operations, comparing
  chronological history/latest with a reference after every operation.
- Dispatch registration order, self/other unsubscribe, new registration during
  dispatch, callback errors, nested emit rejection, close during callback,
  repeated close/unsubscribe, post-close errors and independent instances.
- Signal bridge, identical-write suppression and untracked callback reads.
- GC finalizers establish callback/event release on unsubscribe/clear/close.
- 100000 sequential emissions to ten subscribers with exact checksum, bounded
  64-slot ring, 1000 additional subscribe/unsubscribe cycles with no entries.
- Interrupt unwind restores dispatch. Emitting to an unbound stream creates
  no additional App frame/layout passes.
- Snapshot validation/corruption, missing data, stale clocks, sequence
  gaps/rollback/source restart, write rate, version retention, ignored pending
  files, writer lock, prune failure bound and graceful STOP cleanup.
- Real ps CPU/RAM/process sampling, TUI normal headless rendering/polling,
  and Shiny testServer polling, rendering, stale/recovery and session cleanup.

## Separate processes and Shiny HTTP

`Rscript tools/data-streams-integration.R`, with R_LIBS pointing to the scratch
installation, launches real collector and consumer R processes. Windows PASS
for collector/TUI restart/stop/stale and 300 concurrent schema-valid reads;
Shiny is explicitly skipped there. WSL PASS for the complete collector + TUI
+ Shiny lifecycle, independent restart of each consumer, collector survival,
300 reads, bounded files and stale state after collector stop. Logs:
integration-windows-corrected.log and integration-wsl.log (later final runs
also use the latest checked installation).

`Rscript audit-results/data-streams/http-smoke.R` in WSL launches actual
Shiny runApp, obtains dashboard HTML from 127.0.0.1:3838, asserts title/plot
elements, and cleans up the child. PASS (http-smoke.log, http-page.html).
Startup connection retries produce expected warnings in the initial log;
the final request succeeded. No external network interface was opened.

## Package checks

`Rscript audit-results/data-streams/check-local.R` stages entries allowed by
.Rbuildignore, runs `R CMD build --no-build-vignettes --no-manual`, inspects
the tar listing, then runs `R CMD check --no-manual --no-build-vignettes` with
NOT_CRAN=true and _R_CHECK_FORCE_SUGGESTS_=false. All build runs assert that
audit reports, scratch libraries, `.pending-*`, `.new.md` and `_problems`
artifacts do not enter the tarball.

Full installed-package checks: **Status: OK on both Windows and WSL**,
check-windows-verified.log and check-wsl-verified.log. Both finish with no
errors, warnings or notes. Windows lists unavailable optional suggestions as
dependency INFO, and skips their tests.

The full installed checks report Windows `[FAIL 0 | WARN 0 | SKIP 23 | PASS
13714]` and WSL `[FAIL 0 | WARN 0 | SKIP 4 | PASS 13858]`. The four additional
skips on each platform are existing recipe-Markdown tests: docs are excluded
from the built package, and those tests were exercised from the source
checkout in the full local runs above.

Latest targeted checks: **Status: OK on Windows and WSL**,
check-windows-latest.log and check-wsl-latest.log. Installed tests report
Windows `[FAIL 0 | WARN 0 | SKIP 1 | PASS 5132]`, WSL
`[FAIL 0 | WARN 0 | SKIP 0 | PASS 5142]`. No errors, warnings or notes.

Final separate-process reruns against those latest checked installations also
PASS: integration-windows-final.log (Shiny skip) and integration-wsl-final.log
(collector, TUI and Shiny). Both recheck all 300 concurrent reads and cleanup.

Preservation: verify-preservation.py reconstructs the initial tracked tree
from HEAD plus INITIAL-CHANGES.patch and confirms unchanged Git content in
all 34 initially modified tracked files outside the intentionally additive
NEWS entry. preservation.log records PASS. `git diff --check` is clean.

The latest check uses the repository's TERMR_TEST_FILTER mechanism to repeat
`streams|monitor-live` after the final prune-limit change; the preceding
installed-package check runs the entire suite. Both include ordinary static,
dependency, help, examples, install/load and namespace checks. PDF manuals,
CRAN incoming checks and manual terminal/browser certification were not run.

Earlier check attempts exposed and fixed an unsubscribe closure analysis
NOTE and a test helper that assumed source-tree inst paths. Those attempts
were interrupted, then replaced by fresh successful validation runs; they
are not counted as passes.
