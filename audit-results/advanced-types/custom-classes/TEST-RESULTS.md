# A2.6 Test Results

## Focused regression tests

- Windows: `testthat::test_local('.', filter = 'datatable-', reporter = 'summary')` completed with no failures in the typed DataTable regression set.
- WSL: the same focused regression selection completed with no failures. Optional integrations present in WSL (including `haven`, `sf`, and `units`) ran as available.
- The dedicated `test-datatable-custom-classes.R` test file passed on Windows.

The A2.6 tests cover ordinary S3 classes, inherited methods, custom vctrs classes, compact type summaries, pillar and base formatting, bounded output, Unicode/control characters, safe and rejected casts, attribute restoration, atomic failures, missing values, sorting/filtering, and bounded formatting of a 100,000-row classed vector.

## Full testthat suite

| Environment | Result | Skips | Process status |
|---|---:|---:|---|
| Windows 11, R 4.6.1 | 14,829 passed; 0 failed; 0 errors; 0 warnings | 87 | `Rscript tools/dev.R test` returned exit 1 after printing the clean summary |
| WSL Ubuntu 26.04, R 4.5.2 | 16,357 passed; 0 failed; 0 errors; 0 warnings | 29 | `Rscript tools/dev.R test` returned exit 1 after printing the clean summary |

The skips were dependency/platform-gated. Windows lacked optional packages including `mirai`, `nanonext`, `sf`, `units`, `haven`, and database/plot integrations; WSL lacked `mirai` and `nanonext`. The test summaries themselves report zero failures, errors, and warnings. Because both launcher processes returned exit 1 after those summaries, that process-level discrepancy is recorded instead of treating the launcher status as success.

## R CMD check

Checks were run against the same source tarball built from a staging copy of the current package. Both omit manuals and vignettes and set `_R_CHECK_FORCE_SUGGESTS_=false`, since CRAN/Bioconductor indexes are inaccessible and several Suggests packages are unavailable.

- Windows 11, R 4.6.1: `R CMD check` completed with `Status: OK`; package test run reported 11,022 passed, 0 failed, 0 warnings, and 121 skipped.
- WSL Ubuntu 26.04, R 4.5.2: `R CMD check` completed with `Status: OK`; package test run reported 12,550 passed, 0 failed, 0 warnings, and 63 skipped.

The Windows check needed inherited `C.UTF-8` locale variables cleared. Its first sandboxed test run also had 17 errors because `processx` could not create child-process pipes (`system error 5, Access is denied`); the same check passed when rerun with permission for those child processes. These were environment restrictions, not failures in the A2.6 tests. Build and check console logs plus the source tarball are retained under `r-cmd-check-a26-20261030/`.

## Scope

The A2.6 change adds no exports and no `NAMESPACE` entries. Generated `man/` files were not edited for this phase. No commit, push, or release was performed.
