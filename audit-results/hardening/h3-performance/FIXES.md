# H3 code changes

1. R/app.R: guard inkr tree release/cache reset in widget_unmounting and
   screen_leaving by presence of an active inkr stylesheet. Root cause and
   allocations: redundant 4,096-slot resets without the integration enabled.
   Resource ownership, hooks, tree order and App lifecycle are unchanged.
2. R/inkr-integration.R: add epoch-scoped public element and path-prefix
   reuse; avoid rebuilding an ancestor signature list on style-cache hits;
   explicitly release both new entries during tree/sheet cleanup. Preserve the
   existing bounded App cache, public inkr engine and typed style mapping.
3. R/event-queue.R: replace copy-on-modify list storage with per-instance
   reusable ring hash bindings; remove consumed references and release expanded
   empty tables. Preserve FIFO, clear, empty/NULL behavior and integer size.
   Bounded slot indices prevent lifetime overflow and interned-symbol growth.
4. R/chart-widget.R: publish the first chunk and final drain immediately and
   coalesce intermediate publication to 60 Hz while backlog remains. Previously
   empty-queue-only publication starved continuous streams. The initial eager
   candidate published every chunk at 473 MB in the fixture; the coalesced final
   candidate uses about 104 MB while retaining freshness. This is an intentional
   freshness repair with additional redraw work relative to a stale display.
5. tests/testthat/test-h3-performance-contracts.R: new correctness/allocation
   contracts. test-chart-streams.R and test-h2-contracts.R: update only the
   intermediate publication expectation, preserving the original drain checks.

The baseline includes substantial prior user work. h3-only.patch is the review
diff against that baseline, not git diff against HEAD. preservation.json checks
all 567 initial non-audit files and permits only the eight existing files listed
above including docs/charts.md and docs/inkr-integration.md; the new test and audit
artifacts are additive. No unrelated changes were
staged, reset or overwritten. See benchmark tables for costs and residuals.

docs/charts.md documents coalesced live publication; docs/inkr-integration.md
documents epoch-scoped parent/path reuse. No public function formals, exports,
DESCRIPTION dependencies, NAMESPACE or generated man files changed.
