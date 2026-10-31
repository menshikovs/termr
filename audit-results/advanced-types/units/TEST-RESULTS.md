# Test and check results

## Environments

| Environment | R | units | Locale/encoding |
| --- | --- | --- | --- |
| Windows 11 x64 | 4.6.1 (ucrt) | 1.0.1, isolated task library | R CMD check reports UTF-8 session charset |
| WSL Ubuntu | 4.5.2 | 1.0.0, system UDUNITS-2 | `C.UTF-8` |

## Focused and full tests

- `tests/testthat/test-datatable-units.R`: all tests passed on Windows and WSL.
  This covers `m/km/cm`, `kg/g`, `m/s` and `km/h`, area, volume, dimensionless
  units, offset temperatures, a registered custom unit, special values,
  incompatible/unknown units, precision/range rejection, and Unicode `°C`.
- The seeded conversion property test exercises 140 compatible conversions
  across length, mass, speed, area, volume, temperature and dimensionless unit
  groups, with a `1e-10` absolute comparison tolerance for those values. The
  edit conversion guard independently uses a relative 32-epsilon round-trip
  bound.
- Final full local testthat with `NOT_CRAN=true`:
  - Windows: **14,777 expectations**, 0 failed, 0 errors, 58 skipped,
    0 warnings.
  - WSL: **14,985 expectations**, 0 failed, 0 errors, 28 skipped,
    0 warnings.
- Windows skipped optional DBI, hms, bit64, dplyr, mirai, nanonext, ggplot2,
  plotly and Shiny tests, plus POSIX-only tests. WSL skipped unavailable mirai
  and nanonext tests. Units tests themselves were not skipped on either OS.
- A Windows run with the optional units library removed verified that base
  DataTable creation and editing still work without `units`.

The initial failing-first run failed for the intended A2.1 gaps: units columns
were read-only, unit strings appeared in generic formatted cells, and parsing
reported the class as unsupported. After implementation, the focused tests
pass on both R versions. A range probe also established that units 1.0.0/1.0.1
can return `Inf` or zero for finite overflow/underflow without a warning; the
final tests verify those edits are rejected atomically.

## R CMD build and check

The same final source archive was checked on both systems with
`--no-manual --no-build-vignettes` and `_R_CHECK_FORCE_SUGGESTS_=false`:

- Windows R 4.6.1: **Status: OK**.
- WSL R 4.5.2: **Status: OK**.

Both checks report `OK` for syntax, package/namespace loading, dependency use in
R code, S3 consistency, static code analysis, Rd files, missing documentation,
usage and code/documentation matching. The check test files passed on the final
source: Windows 10,912 passed / 92 skipped; WSL 11,150 passed / 62 skipped.
Those counts use the package's CRAN-bounded workload; the `NOT_CRAN=true`
counts above run the extended local workload. Missing optional Suggests are
reported as check `INFO`, not WARNING/NOTE; `units` was available in both
checks.

An initial in-sandbox Windows run could not create processx child pipes
(Windows system error 5). The full suite and final R CMD check were rerun
outside the sandbox and completed successfully. This was an execution
environment restriction, not a test failure in termr.

## Documentation, namespace and diff

- `NAMESPACE` has no A2.1 changes and no exported symbol was added.
- No `man/` file was changed for A2.1; final R CMD check reports all Rd and
  documentation checks `OK`.
- Unicode `°C` rendered in `column_info()` and the headless terminal screen on
  Windows and WSL.
- `git diff --check` passed.
