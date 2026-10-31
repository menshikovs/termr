# Test results

## Full regression suites

| Environment | Command | Result |
|---|---|---|
| Windows 11, R 4.6.1 | `Rscript tools/dev.R test` with `NOT_CRAN=true` | PASS: 14,104 passed, 0 failed, 0 errors, 0 warnings; 58 skipped |
| Ubuntu WSL, R 4.5.2 | `Rscript tools/dev.R test` with `NOT_CRAN=true` | PASS: 14,342 passed, 0 failed, 0 errors, 0 warnings; 28 skipped |
| Windows example focus | `test_local('.', filter = '^examples$')` | PASS, including the new runnable typed-data example |
| Ubuntu WSL DataTable focus | `test_local('.', filter = 'datatable')` | PASS, including installed DBI, dplyr, hms and bit64 adapters |

Windows skips were for unavailable optional packages and the POSIX-only test.
WSL skips were the mirai/nanonext cases; the typed optional adapters ran there.

The first Windows full-suite attempt ran inside the sandbox and could not
create worker subprocess pipes. The same extended suite passed outside the
sandbox. The final suite includes the new runnable example in `run_example()`.

## R CMD checks

Both platforms passed installation, namespace loading, examples and the
package test suite. Each check reported **1 WARNING, 1 NOTE** from existing
mirai items outside this phase:

* `termr_mirai_submit.Rd` has an unresolved cross-reference to `0,1`.
* `mirai_prepare_job()` refers to `removeSource` without a visible global
  definition/import.

No A1 file changed either source. Local agent metadata was excluded from the
check tarball. Windows: R 4.6.1. WSL: R 4.5.2. Full logs are
`check-windows.log` and `check-wsl.log`.

## Optional-free install

PASS on Windows: `R CMD INSTALL` and a typed Date/integer edit succeeded in an
isolated library containing only `Imports` and their recursive dependencies.
The following optional packages were not visible: vctrs, pillar, tibble, dplyr,
hms and bit64. This also exercised the base-R assignment fallback.

## Time zones and terminal integration

The typed DataTable test file passed under both `TZ=UTC` and
`TZ=America/New_York` on Windows and WSL. The existing real-PTY integration
script passed in WSL: all terminal restoration, input, resize, mouse, paste,
and no-TTY assertions passed.

The new example test, focused logs, timezone logs, optional-free install log,
and PTY log are kept in this directory.
