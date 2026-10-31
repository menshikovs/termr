# A2.2 Test results

## Haven API

Inspected installed Haven 2.5.5 on Windows R 4.6.1 and WSL R 4.5.2. Logs:
`haven-api-windows.log` and `haven-api-wsl.log`. `labelled()`,
`labelled_spss()`, `tagged_na()`, `is_tagged_na()`, `na_tag()` and `as_factor()`
were confirmed. The implementation uses the labelled and tagged-NA APIs and
does not use `as_factor()`.

## Focused and full suites

| Check | Result |
| --- | --- |
| Haven-focused tests, Windows R 4.6.1, Haven 2.5.5 | Pass |
| Haven-focused tests, WSL R 4.5.2, Haven 2.5.5 | Pass |
| Haven-absent Windows run (`requireNamespace("haven")` is false) | Pass; all 5 optional-mode assertions passed |
| Full `testthat::test_local()` Windows R 4.6.1 | Pass when run outside the sandbox |
| Full `testthat::test_local()` WSL R 4.5.2 | Pass |
| WSL `R CMD check` | Pass: `Status: OK` |
| Windows `R CMD check` | Pass: `Status: OK` |

The default sandbox denied Windows `processx` child pipes (system error 5).
The full suite was rerun with elevated execution and completed successfully.
The Windows run used UTF-8-compatible default locale variables; WSL used its
UTF-8 locale. Both full runs executed Haven, typed-data, DataTable
virtualization and Unicode tests.

The Haven matrix covers integer, double and character storage; ordinary NA,
tagged NA(a/z), NaN, exact and ranged SPSS missing definitions, duplicate and
unknown labels, raw/label collisions, empty vectors, long and Unicode labels,
malformed metadata and attribute preservation. A seeded 100-edit fuzz loop
checks atomic rejection and class/attribute invariants.

`R CMD check` was configured with `_R_CHECK_FORCE_SUGGESTS_=false`. On WSL,
only missing optional `mirai` and `nanonext` were reported as INFO. The full
test suites also skipped integration tests whose optional packages are not
installed in that platform library.

Windows `R CMD check` reported missing optional `DBI`, `dplyr`, `ggplot2`,
`mirai`, `nanonext`, `plotly`, `promises`, `RSQLite`, `shiny` and `units` as
INFO; Haven was available from the isolated task library. Neither platform
reported a WARNING or NOTE. The Windows and WSL check logs are
`R-CMD-check-windows.log` and `R-CMD-check-wsl.log`.

`Rscript tools/dev.R doc` returned success and regenerated `column.Rd` and
`DataTable-class.Rd` without changing `NAMESPACE`. Roxygen also emitted
unrelated R6 documentation diagnostics for the existing `Pilot` class in
`R/testing.R`; package Rd checks passed on both platforms.

Logs and commands are retained alongside this report. `build-wsl.log` records
the source tarball build. The Haven API probe is in `inspect-haven-api.R` and
the optional-mode test runner is in `run-haven-tests.R`. Final focused output
is in `tests-focused-windows.log` and `tests-focused-wsl.log`; the Haven-absent
run is in `tests-optional-absent-windows.log`.
