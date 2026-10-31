# Test results

## Focused tests

- Windows focused DataTable source/type/custom/blob tests passed; optional integrations absent on Windows were skipped.
- WSL focused source/type test run passed, including actual units, haven, sf, blob, integer64, SQLite/DBI, dbplyr and Arrow cases. One optional-absence test skipped because haven is installed.
- WSL grouped_df/rowwise edit probe confirmed updated group metadata is retained.
- Direct dbplyr and Arrow objects are rejected without implicit `collect()`; this ran in WSL.
- WSL PTY binary smoke test passed all four checks: raw control/invalid UTF-8 bytes render as hex, Unicode column label reaches the PTY, output contains no terminal control bytes, and the app exits normally.
- A Windows direct probe confirmed missing/non-finite/fractional/over-limit row counts are rejected and a 10M-row source edit reads one projected column page.

## Full suites

| Platform | Command | Result |
|---|---|---|
| Windows 11 / R 4.6.1 | `Rscript --vanilla tools/dev.R test` with `NOT_CRAN=true` | 15,109 tests: 15,020 pass, 0 fail, 0 errors, 89 skip, 0 warnings; exit 0 |
| WSL Ubuntu / R 4.5.2 | `Rscript --vanilla tools/dev.R test` with `NOT_CRAN=true`, UTF-8 locale | 16,584 tests: 16,555 pass, 0 fail, 0 errors, 29 skip, 0 warnings; exit 0 |

The prior restricted baseline invocation of `tools/dev.R test` printed 17 processx child-process access-denied errors but returned exit code 0 because the developer runner summarized results without propagating errors. The later authorized full Windows run passed. `tools/dev.R` now exits nonzero when test failures or errors exist. The current full suites returned zero with no failures/errors.

## Package checks

- Windows `R CMD build` passed; Windows `R CMD check` completed with `Status: OK`.
- WSL `R CMD build` passed; WSL `R CMD check` completed with `Status: OK`.
- Check ran with force-suggests disabled because optional packages are not installed in the audit environments. R CMD check static code, loading, namespace, documentation, examples and tests were executed where available.
- Neither current check reported a warning or note; each reported INFO for optional Suggests unavailable in that environment. Older phase audit artifacts were not used as current validation evidence.
