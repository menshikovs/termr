# Windows and WSL validation

| Check | Windows | WSL Ubuntu |
|---|---|---|
| R | 4.6.1, Windows 11 x64, UTF-8 session | 4.5.2, Linux x86_64, `LANG=C.UTF-8`, `LC_ALL=C.UTF-8` |
| Full `Rscript tools/dev.R test` | 15,020 passed; 0 failed/errors/warnings; 89 skipped | 16,555 passed; 0 failed/errors/warnings; 29 skipped |
| `R CMD build --no-manual --no-build-vignettes` | Passed | Passed |
| `R CMD check --no-manual --no-build-vignettes --ignore-vignettes` | **Status: OK** | **Status: OK** |
| PTY binary/control/Unicode smoke test | Not available as a native POSIX PTY validation on Windows | Passed: raw control/invalid UTF-8 bytes rendered as hex, Unicode label reached PTY, no terminal control bytes, normal exit |

The 89 Windows skips are mostly optional packages absent on that host (DBI/RSQLite, Arrow/dbplyr, dplyr, haven, sf, units, bit64, blob, hms, mirai/nanonext, plotting and Shiny integrations), plus a POSIX-only terminal test. The 29 WSL skips are the mirai/nanonext suites and the test that intentionally requires haven to be absent. These are environment skips, not passing executions of those optional integrations.

Build/check ran against an isolated package-stage copy made from the current source tree. The project `.Rbuildignore` is applied only after R CMD build copies the input tree; direct builds from the repository were stopped after showing that they recursively copied the large audit directory. The staged copy excludes only ignored project reports/tools/docs/build metadata and preserves the current package source, generated man pages, tests, and package assets. WSL PTY checks ran on Ubuntu with `TERM=xterm-256color` in controlling-terminal mode.
