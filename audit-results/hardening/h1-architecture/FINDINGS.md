# H1 findings

Defect/documentation counts: P0 0, P1 3, P2 3, P3 1. This is six confirmed
runtime defects plus one documentation mismatch. F05/F06/F07 are fixed; F01/F02/
F08/F09 remain open. Design limitation F03 and policy risk F04 are separate.
Passing package checks do not negate the reproducible failures below.

## H1-F01 — P1 — DataTable source replacement

- Category/status: confirmed defect — open.
- Location: R/widget-datatable.R: DataTable$set_data.
- Description: A rejected source replacement commits .source and clears state before count/schema validation.
- Reproduction: Construct a local x=1:3 table; replace it with table_source(function() NA_real_, 'x', ...).
- Expected: Replacement errors and the previous usable table remains active.
- Observed: The error occurs, but source_changed is TRUE and subsequent row_data also errors on the invalid source.
- Evidence: probe-contracts.R / failed-source-switch; Windows elevated and WSL current/final logs.
- Confidence: High: deterministic on Windows and WSL.
- Fix: Build candidate state before commit or restore every affected UI/cache/provenance field on failure. Define callback-side rollback separately.
- Regression: regressions-open.R F01; extend to seed errors, schema mismatch, refresh and previous edit ledger.
- Target: H2, priority 1.

## H1-F02 — P1 — DataTable / A4 view contract

- Category/status: confirmed defect — open.
- Location: R/widget-datatable.R: set_cell and reproducible_code; R/reproducible-code.R: termr_r_pipeline_ast.
- Description: An exact pipeline re-sorts edited data while DataTable retains the old row-index order.
- Reproduction: Sort x=1:3; set_cell(1,'x','10'); evaluate pipeline with data equal to table$data.
- Expected: An exact result equals the displayed current view under the explicitly supplied binding.
- Observed: Display is 10,2,3; generated result is 2,3,10; status remains exact.
- Evidence: edited-sort-pipeline-consistency in fresh Windows/WSL probes.
- Confidence: High: binding ambiguity was removed by using the current table$data.
- Fix: Choose edit/view semantics; reapply sort/filter or encode actual view state/fail closed. Do not silently claim exactness.
- Regression: regressions-open.R F02; add edited filter keys, selection, hidden sort keys and source replacement.
- Target: H2, priority 1.

## H1-F08 — P1 — Owned DBI lifecycle

- Category/status: confirmed defect — open.
- Location: R/sql.R: SQLEditor$on_app_shutdown; R/app.R: shutdown tree walk.
- Description: Unmount removes the only automatically traversed owner of an owned connection.
- Reproduction: Create SQLite connection and owned wrapper; mount SQLEditor; remove editor; stop App.
- Expected: The owned connection is released by disposal or eventual App cleanup; borrowed connections stay open.
- Observed: DBI::dbIsValid(con) remains TRUE after both unmount and App stop. Probe explicitly disconnects it afterwards.
- Evidence: owned-sql-editor-unmount, probes-wsl-current.log and final WSL log.
- Confidence: High observation; supported by existing automatic shutdown hook/ownership contract.
- Fix: Register one ownership-aware disposal routine for both unmount and shutdown, preserving same-App moves and shared borrowed wrappers.
- Regression: regressions-open.R F08; add owned/borrowed, repeated close, same-App reparent and DatabaseExplorer composition.
- Target: H2, priority 1.

## H1-F05 — P2 — Headless startup lifecycle

- Category/status: confirmed defect — fixed.
- Location: R/testing.R: Pilot$initialize.
- Description: A mount callback error before a Pilot is returned leaves its App running and globally registered.
- Reproduction: Mount a widget whose mount handler stops; call test_app().
- Expected: Startup failure unwinds App/driver registration without requiring an unavailable Pilot handle.
- Observed: Before: running TRUE, retained driver, active-App delta 1. After: FALSE/NULL/0.
- Evidence: regressions-failing-first.log; regressions-after.log; test-h1-contracts.R and final probes.
- Confidence: High: failing-first and passing-after regression.
- Fix: H1 added startup-completion guarded on.exit shutdown, preserving the original error.
- Regression: tests/testthat/test-h1-contracts.R: failed pilot startup releases its registered app and driver.
- Target: Fixed in H1; H4 repeated failure cycles.

## H1-F06 — P2 — Source projection cache

- Category/status: confirmed defect — fixed.
- Location: R/widget-datatable.R: get_source_page.
- Description: CR-delimited column-name concatenation aliases a two-column projection with one legal CR-containing name.
- Reproduction: At source row 101 render columns a,b; then show only the column named a-CR-b.
- Expected: Cache selects the correct projected data and renders value 501.
- Observed: Before: undefined columns selected; after: correct bounded viewport renders.
- Evidence: source-projection-cache-key; failing-first and after regression logs.
- Confidence: High: deterministic public operations reproduce and verify the fix.
- Fix: H1 replaced delimiter-only projection encoding with byte-length-prefixed tokens.
- Regression: tests/testthat/test-h1-contracts.R: source projection cache keys distinguish control characters in names.
- Target: Fixed in H1.

## H1-F09 — P2 — Count validation / logging

- Category/status: confirmed defect — open.
- Location: R/style.R: check_count; R/app.R: App$log_events.
- Description: Non-finite capacity is accepted and coerced to NA, producing a downstream startup error.
- Reproduction: Call app(label('x'))$log_events(size=Inf), then test_app on that App.
- Expected: Reject invalid capacity immediately with an actionable size error.
- Observed: No validation error; integer coercion warning; startup errors in tail with invalid n.
- Evidence: nonfinite-log-capacity in probes-wsl-current/final; regressed earlier S-1.
- Confidence: High: deterministic local invalid-input probe.
- Fix: Audit callers of check_count and apply finite/whole/range validation where counts must be bounded; distinguish cell-size clamping policy.
- Regression: regressions-open.R F09; NULL/0/fractional/NA/Inf/2^31 boundary matrix.
- Target: H2 validation sweep.

## H1-F07 — P3 — Roxygen internal class documentation

- Category/status: documentation mismatch — fixed.
- Location: R/testing.R: Pilot class definition.
- Description: The undocumented internal R6 class was processed as a help topic and emitted R6 field/method diagnostics.
- Reproduction: Run diagnose-roxygen.R on the same internal class with and without a noRd block.
- Expected: Internal class does not create a public topic or spurious public-method diagnostics.
- Observed: Without block: diagnostics plus skipped nameless Pilot topic; with noRd: zero diagnostics/topics.
- Evidence: roxygen-diagnostics.log; regenerated doc-windows.log.
- Confidence: High: isolated same-source comparison, roxygen2 8.1.1.
- Fix: H1 added an explicit internal noRd block; public test_app/Pilot method prose remains.
- Regression: diagnose-roxygen.R and tools/dev.R doc; NAMESPACE/man preservation hashes.
- Target: Fixed in H1.


## H1-F03 — P2 — confirmed documented design limitation

- Component/location: ChartWidget$flush_stream_queue in R/chart-widget.R.
- Reproduce: max_points=100; emit 64 records; before each of eight 1 ms flush
  advances emit another 16. Probe uses controlled headless scheduling, not sleeps.
- Expected H2 responsiveness goal: displayed data advances while backlog remains
  bounded. Current documented contract only catches up after the queue drains.
- Observed: 9 flushes, 48 pending, 100 processed retained points, 0 displayed points.
- Evidence/confidence: sustained-chart-backlog on both platforms; high.
- Suggested work: choose a bounded render cadence without removing 16-record
  processing limits or overflow gaps; measure cost in H3.
- Regression/target: F03 in regressions-open.R is a proposed H2 liveness invariant,
  not evidence that current documentation promises continuous rendering. H2/H3.

## H1-F04 — P2 — unverified contract risk, confirmed behavior

- Component/location: App$dispatch snapshots target$ancestors once.
- Reproduce: child handler removes its parent; parent also has a handler.
- Observed: parent$app is NULL, but its snapshotted handler runs once.
- Evidence/confidence: detached-ancestor-dispatch; high observation confidence,
  medium contract interpretation because detach is not destruction of the R6
  object and the public mid-dispatch rule is unspecified.
- Proposed invariant: inactive ordinary ancestors should not receive further
  delivery; lifecycle events may need different treatment.
- Suggested work/target: decide and document semantics in H2 before changing the
  dispatch loop. F04 in regressions-open.R records the candidate policy.

## Other confirmed limitations and coverage risks

| ID / category | Severity | Evidence and reproduction | Current boundary / next action |
|---|---|---|---|
| L01 specialized lubridate absent | P2 limitation | WSL creates Period/Duration/Interval: all choose extension/read-only; three value exports round-trip | No dedicated calendar parsing, DST editing or A2.3 suite; plan a separate type phase |
| L02 backend adapters absent | P2 limitation | Source inventory + dbplyr/Arrow rejection tests | SQLite built-ins; other DBI callbacks need caller code; no automatic DuckDB/dbplyr/Arrow support |
| L03 inkr conversion errors are late | P2 limitation | Valid alpha sheet replaces old sheet; matching computed_style then errors | Compile transaction does not validate all future termr mappings; H2 decide eager validation/fail-closed contract |
| L04 inkr overhead | P2 limitation | INKR.md: unique paths, element-conversion microprofile and optional-free unmount allocation | Bound counts are real; optimize measured conversion/cache-reset work in H3 |
| L05 global selector cache unbounded | P2 design risk | R/selectors.R parse_selector assigns every successful unique selector with no eviction | Static bound absence confirmed, no retained-heap soak measured; H3/H4 measure distinct-query churn |
| U01 native telemetry/task runtime untested | P1 validation risk, not defect | packages manifests show mirai/nanonext absent; guarded runtime tests skip | Install/pin optional test jobs and exercise races/cleanup before release |
| E01 Windows child pipes denied in sandbox | Environment issue | Same processx probe fails restricted and succeeds elevated with unchanged package | Use authorized subprocess-capable environment; no termr worker fix justified |

Open regression script exits nonzero intentionally for unresolved defects/design/
policy candidates. It is outside the package suite. It must never be summarized
as an unexpected package-check failure or hidden by blanket skips.
