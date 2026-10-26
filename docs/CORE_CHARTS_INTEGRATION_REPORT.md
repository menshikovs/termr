# Core Charts Integration Report

**Evidence date:** 2026-10-26

**Status:** implementation and local Windows checks are reviewable; Stage 3B is not yet verified for merge.

## A. Source baseline

- `termr` branch: `feature/core-charts-1.1`, based on `origin/main` at `d6ca75ea3e23c9320146602b9b790b4b91b16e92`.
- Current committed `termr` HEAD: `aec5157752f899a46574c71f6d5052b6e35fb219` (`docs: audit native chart integration`). The implementation and this report are working-tree changes on top of that commit; they have not been committed.
- `termrcharts` source: local `main` at `361556778c7fc6e93a46b485a7cdefd1e5f15231`, package version `0.1.0.9000`. The repository has unrelated untracked `.vscode/` files; it was not changed. The supplied ZIP SHA256 is `CE8ECE977E69EEA63A0543AFEC5AA1B8E3E53F953AD1AABA8F2BCCE20C61A5B5`; the audited local commit is used as source of truth.
- Compatibility baseline: installed CRAN `termr` 1.0.1 at `C:/Users/User001/AppData/Local/R/win-library/4.5/termr`, built with R 4.5.2 on 2026-10-21.
- Local environment: Windows 11 x64, R 4.5.2 (ucrt). Ubuntu and macOS were not available locally.

## B. Architectural changes

Five constructors were added: `line_chart()`, `scatter_chart()`, `bar_chart()`, `histogram()`, and `heatmap_chart()`. They produce a private `ChartWidget` subclass of termr's `Widget`; no chart engine, surface, scale, or hit-test internals are exported. The chart code reuses the selected termrcharts rendering, scale, glyph, layout, hit-test, and data-normalization paths, adapted to termr's widget and style APIs. `ChartWidget$update_data()` updates the existing widget and invalidates its plan and rendered-cell caches.

The implementation is split across the new `R/chart-*.R` modules. `graphics` was added to `Imports` because histogram construction calls `graphics::hist()`. No dependency on `termrcharts` was added. Existing `R/` implementations for the rest of termr were not modified. Pie, violin, density, bubble, area, stacked-area, and box plots remain in termrcharts; box plots were deferred because they require a separate statistical-summary path.

## C. Chart feature matrix

| Chart | Native support | Test evidence |
|---|---|---|
| Line | Numeric, `Date`, and `POSIXct` x values; linear/log axes; gaps for missing data; point labels and reference annotations; keyboard/mouse selection; in-place data replacement | Rendering modes, time/log scales, gaps, selection payloads, callbacks, mouse hit testing, update and resize tests |
| Scatter | Numeric/time coordinates; dense points reduced to visible cells while retaining source indices; selection and updates | 10,000-point render, source-index behavior, callbacks, mouse hit testing, update and resize tests |
| Bar | Vector or category-by-series matrix; grouped/stacked; horizontal/vertical; negative values; value labels and reference lines | Negative, grouped, stacked, orientation, selection, callback, update and resize tests |
| Histogram | `graphics::hist()` bin semantics; non-finite values omitted; bin ranges/counts selectable; data and break updates | Empty/invalid/non-finite inputs, explicit breaks, payloads, updates and rendering tests |
| Heatmap | Numeric matrices, row/column labels, missing-value marks, glyph/color levels, viewport aggregation, source-cell inspection | Missing values, 100x100 aggregation, cell payloads, mouse hit testing, updates and resize tests |

All five constructors are tested in `auto`, ASCII, block, and Braille modes. The dashboard example combines a data table and all five charts, supports keyboard focus/selection, and refreshes chart values with `r`.

## D. API compatibility

The installed CRAN package has 155 exports. The development namespace has 160: the only additions are the five chart constructors; no prior export was removed. A comparison of all common exported functions found **zero changed formal argument lists**. A separate comparison found the five new constructor signatures exactly match those in the audited termrcharts source commit.

Both `library(termr); library(termrcharts)` and the reverse attachment order were smoke-tested. In each order, the later-attached package supplies the unqualified shared chart names; explicit `termr::` and `termrcharts::` calls successfully created and rendered all five shared chart types. The old termrcharts constructors remain untouched. The returned widget implementation is native to the package namespace used for the qualified call. `$update_data()` is additive.

`DESCRIPTION` remains at version **1.0.1**. The only runtime dependency change is the base R `graphics` namespace. `termr` does not depend on `termrcharts`; termrcharts depends on termr, so there is no dependency cycle. No worker lifecycle, terminal input, or Stage 3A API implementation was edited.

## E. Rendering and interaction

Headless tests cover the four rendering modes and verify ASCII output. Automatic mode relies on termr's Unicode width check and falls back to ASCII when required glyph widths are unsupported. The tests use deterministic data and virtual-screen dimensions. They verify chart contents and synthetic pointer coordinates; they do not establish glyph appearance in every physical terminal or mouse delivery through a real terminal driver.

Keyboard navigation uses the chart selection model; Enter posts `selected` followed by `activated`. Tests verify ordering, payload shape, and one invocation per callback. Left-click hit testing is covered for each chart type using headless screen coordinates. A high-contrast themed widget is mounted, resized, and removed in the widget tests. PTY coverage exists in the repository's general CI workflow, but no chart-specific PTY run has been observed.

## F. Performance

The checked-in benchmark was run in separate fresh Rscript processes on Windows 11/R 4.5.2. It used the local termrcharts source commit and the development worktree; the same `test_app()` virtual driver rendered at 80x24, then resized to 100x30. Inputs were 5,000 points for line/scatter/histogram, 100 categories for bars, and a 100x100 heatmap. Values below are medians in milliseconds; memory is R's process-wide `gc()` maximum-used heap in MB.

| Chart | CRAN termr + termrcharts: initial / resize / update / heap | Development termr: initial / resize / update / heap |
|---|---:|---:|
| Line | 560 / 390 / 300 / 110.5 | 610 / 460 / 270 / 129.8 |
| Bar | 280 / 400 / 300 / 110.7 | 330 / 430 / 70 / 129.8 |
| Scatter | 320 / 390 / 290 / 110.1 | 350 / 450 / 275 / 129.4 |
| Histogram | 300 / 365 / 300 / 109.3 | 330 / 405 / 30 / 127.9 |
| Heatmap | 420 / 500 / 390 / 107.1 | 450 / 545 / 125 / 125.8 |

The baseline update measurement is complete widget/app replacement because termrcharts has no in-place update method. Development update measures `$update_data()` plus one Pilot step. Those update timings are therefore a practical comparison of the available operations, not identical code paths. Constructor timings rounded to 0 ms at this clock resolution and are not meaningful. Initial render and resize were about 30–70 ms slower in the development run; bar, histogram, and heatmap updates were faster, with line/scatter update times close to baseline. The heap figures include package and test harness overhead, so they do not establish per-chart memory use. `test_app()` timings include virtual-driver work and are not interactive-terminal guarantees.

## G. Testing

| Command or probe | Result |
|---|---|
| Untouched termrcharts suite: `pkgload::load_all('.', quiet=TRUE, export_all=TRUE); testthat::test_local('.', reporter='summary')` at the audited source commit | Completed with no reported failures or warnings |
| `Rscript -e "testthat::test_local('.', filter = 'native-charts', reporter = 'summary')"` after the deterministic fixture adjustment | **PASS** (`══ DONE ══`) |
| Combined native-chart/example focused run | Native chart tests and dashboard test passed; the overall command stopped at the existing task-runner test when processx could not create a child pipe |
| `R CMD build --no-build-vignettes --no-manual .` | **PASS**; inspected tarball and confirmed `.agents` and `.serena` are excluded |
| Final `R CMD check --no-manual --no-vignettes --output=<temp> termr_1.0.1.tar.gz` | Install, load/unload, static analysis, documentation, examples, and dependency checks passed. Full tests: **4,540 pass, 17 fail, 35 skip, 0 test warnings**. Final status: **1 ERROR**, no package `WARNING` or `NOTE`. |
| Export/signature comparison: installed CRAN termr 1.0.1 vs development termr | **PASS**: 155 common exports retained with matching formals; exactly five added exports |
| termrcharts coexistence smoke tests and constructor-formal comparison | **PASS** in both package attachment orders; all five old and new constructors rendered; signatures match |
| Dependency graph probe | **PASS**: no `termrcharts` dependency from termr; termrcharts depends on termr |
| Workflow YAML validation with PyYAML 6.0.3 | **PASS**: pull-request trigger, feature-branch push trigger, and Ubuntu/Windows/macOS matrix present |

All 17 R CMD check test failures occur before the test's process work can run. `test-posix-driver.R` has one failure (`the processx input pipe preserves UTF-8 independently of locale`). `test-worker-bootstrap.R` has ten failures (probes A, A2, B, C, D, E; payload capture, nested captures, testthat job loading, and timeout diagnostics). `test-workers2.R` has six failures (installed worker helper/hooks, library paths, exited worker cleanup, timeout diagnostics, descendant-held pipe, and output backlog). Each reports processx failing to create a write pipe for `Rscript.exe` or `cmd.exe` with Windows system error 5, “Access is denied.”

The same `termr::test_app(...); pilot$app$run_worker(...)` startup probe against installed CRAN termr 1.0.1 fails with the same processx/system error 5 in this sandbox. This classifies the 17 failures as an environment restriction, not a chart regression or a confirmed CRAN behavior defect. It does **not** demonstrate that worker behavior passes on ordinary Windows; that remains for CI. The 35 skipped expectations follow existing CRAN, OS, optional-dependency, and sandbox guards; no native-chart test was skipped. The installed CRAN binary was available, but its source test suite was not; CRAN index access was unavailable, so a full source-to-source CRAN `R CMD check` comparison remains pending. During check, repository index requests were unavailable and Windows `du` emitted a diagnostic warning during package-size measurement; dependency and package-size checks continued as `OK`.

## H. Platform support and CI

| Platform | Evidence in this worktree | Status |
|---|---|---|
| Windows 11, R 4.5.2 | Native chart tests pass; CRAN/API/termrcharts compatibility probes pass; full `R CMD check` reaches all non-test checks but process tests hit sandbox error 5 | Partially verified; ordinary Windows process behavior and terminal rendering still pending |
| Ubuntu | Workflow matrix configured; no run for this worktree | Pending |
| macOS | Workflow matrix configured; no run for this worktree | Pending |

`.github/workflows/R-CMD-check.yaml` already runs on pull requests and includes Ubuntu release/oldrel-1/R 4.1/devel, macOS release, and Windows release. Its push list now includes `feature/core-charts-1.1`. Workflow YAML and matrix structure were parsed locally. `actionlint` was not installed. No GitHub Actions run URL is available: the feature branch has no local remote-tracking ref, the GitHub PR search returned no PR, and direct `git ls-remote` access failed because this environment cannot connect to github.com. Workflow configuration is not test evidence; all remote platform jobs remain pending.

## I. Known limitations

- No Ubuntu or macOS execution has been observed. No chart-specific real-terminal PTY or cross-terminal Unicode/color appearance result is available.
- Windows process creation is denied by this sandbox, so worker and child-process tests cannot establish their normal platform behavior here. The CRAN baseline exhibits the same sandbox failure.
- Performance numbers are headless, coarse-grained, and include process/package overhead; memory is not chart-isolated.
- Box plots and the excluded termrcharts chart families remain outside this integration.
- This feature worktree has not been committed beyond its audit commit, pushed, or associated with a pull request; CI results are consequently pending.

## J. Release readiness

The five chart widgets, documentation, generated help topics, deterministic tests, and dashboard example are implemented. Local API and termrcharts compatibility evidence is positive, and the package builds without a hidden-directory NOTE. No confirmed chart regression or public API break was found.

**Stage 3B is not complete and is not ready to merge.** The full local check ends in an environment-blocked process-test ERROR, and Ubuntu/macOS plus ordinary Windows GitHub Actions results have not run. Completion requires the feature-branch CI matrix to pass, including R CMD check and the chart tests on supported operating systems, with the worker child-process tests executing in a process-permitting environment.
