# Test Results

Validation date: 2026-10-30. Source was built from an isolated staging copy of the current worktree; the staging copy omitted ignored developer tooling that Windows `R CMD build` cannot read in-place. No repository files were reset or staged.

## Focused checks

| Check | Result |
| --- | --- |
| `Rscript tools/dev.R doc` | Completed. Generated chart documentation and exports. It printed pre-existing roxygen warnings for undocumented `Pilot` R6 methods/fields in `R/testing.R`. |
| `testthat::test_local('.', filter = 'native-charts|chart-streams|^examples$', reporter = 'summary')` on Windows R 4.6.1 | PASS, including the 90-event multi-turn queue regression and all three chart examples. |
| `git diff --check` | PASS after final source and report updates. |
| Windows `R CMD check --no-manual`, R 4.6.1, `_R_CHECK_FORCE_SUGGESTS_=false` | PASS, `Status: OK`; package examples and complete `testthat.R` passed. |
| WSL Ubuntu 26.04 `R CMD check --no-manual`, R 4.5.2, `C.utf8`, `_R_CHECK_FORCE_SUGGESTS_=false` | PASS, `Status: OK`; package examples and complete `testthat.R` passed. |
| WSL `tools/pty/test-fixture.R` and `tools/pty/pty-check-ci.py`, with the final tarball installed into a temporary library | PASS, all PTY checks passed on rerun. One earlier run of the same harness had two combined Tab+Enter timing failures; the immediate complete rerun passed. |

The initial WSL attempt deliberately unset every locale variable and therefore ran R in the C locale. It produced Unicode parse warnings and 58 failures across existing widgets/data/docs whose expected glyphs were rendered through ASCII fallback. That run is not treated as a code regression or a passing check. The final `C.utf8` run passed.

Both R CMD checks allowed unavailable optional Suggested packages. On Windows the missing optional packages were `bit64`, `blob`, `DBI`, `dplyr`, `ggplot2`, `haven`, `hms`, `mirai`, `nanonext`, `plotly`, `promises`, `RSQLite`, `sf`, `shiny`, and `units`. On WSL only `mirai` and `nanonext` were unavailable. `termrcharts` was absent on both platforms.

## Scope covered

The feature-branch native chart suite and new stream suite cover chart constructors and rendering, coordinates and scales, keyboard/mouse selection, update behavior, dirty/partial repaint, resize, empty/tiny layouts, bounded stream history, gaps/restarts, errors, subscriber cleanup, and queued bursts. `R CMD check` adds the full package regression suite. Chart implementation tests pass independently of `termrcharts`.

## Not run / limits

- No native macOS runner was available; do not infer macOS validation from WSL.
- No separate `tools/dev.R test` run is claimed; the complete package testthat suite ran under both R CMD checks.
- Reproducible benchmark figures and their limitations are in [PERFORMANCE.md](PERFORMANCE.md).
