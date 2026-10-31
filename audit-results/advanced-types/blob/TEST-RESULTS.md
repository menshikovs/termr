# A2.4 test results

## Commands

- Focused binary tests: passed on Windows R 4.6.1 (0 failures; real `blob` test skipped because that optional package is absent) and Ubuntu/WSL R 4.5.2 (0 failures, including the real `blob` constructor test).
- Typed-data regressions: Windows `testthat::test_local('.', filter = 'datatable-binary|datatable-typed|datatable-units|datatable-haven', reporter = 'summary')` passed with 0 failures. Optional Haven, units, hms, bit64, dplyr and blob cases skipped because those packages are not installed on Windows.
- A seeded fuzz test formats 100 raw payloads, including the empty payload and random control/invalid-UTF-8 bytes. It checks fixed preview bounds, printable output, and source-value identity.
- The headless DataTable test confirms a payload containing ESC is displayed as `1B` and the rendered screen contains no ESC character.
- Full Windows suite (`Rscript tools/dev.R test`, R 4.6.1, process-local UTF-8 locale): **14,643 passed, 0 failed, 0 errors, 0 warnings; 77 skipped** (missing optional dependencies and the POSIX-only test).
- Full Ubuntu/WSL suite (`Rscript tools/dev.R test`, R 4.5.2): **15,934 passed, 0 failed, 0 errors, 0 warnings; 29 skipped**. The real `blob` integration tests ran here.
- Real PTY check: `python3 tools/pty/pty-check-binary.py` in Ubuntu/WSL — passed. It verified a Unicode column name, the exact hex display of ESC/NUL/FF/invalid UTF-8 bytes, no control/invalid-UTF-8 output leak, and normal exit.

## Platform checks

- Windows uses R 4.6.1. Its inherited `LC_ALL=C.UTF-8` is not accepted by this Windows R build; all passing test runs set the process-local locale to `English_United States.utf8`. No system locale was changed.
- The first Windows full-suite attempt inherited unsupported `LC_ALL=C.UTF-8` and had 14 Unicode-rendering failures; the complete rerun with the process-local Windows UTF-8 locale passed.
- Windows `R CMD check` of the built source tarball: **Status: OK** (`--no-manual --no-build-vignettes`, `_R_CHECK_FORCE_SUGGESTS_=false`). It reports unavailable optional Suggests because this Windows environment has no CRAN access.
- Ubuntu/WSL `R CMD check` of the same source tarball: **Status: OK** under Ubuntu 26.04 / R 4.5.2 (`--no-manual --no-build-vignettes`, `_R_CHECK_FORCE_SUGGESTS_=false`). The only unavailable suggested packages were optional `mirai` and `nanonext`.
- The source tarball was built by Windows R 4.6.1 and checked by WSL R 4.5.2. A native WSL build attempt was stopped because copying the full repository, including large ignored audit folders, stalled over `/mnt/c`; the Linux check itself completed from the platform-independent source archive.
- The Windows environment lacks `blob` and could not reach CRAN; Ubuntu/WSL has `blob`, and the real constructor/integration tests passed there. A dependency-free S3 list-of-raw shape is also tested on both systems.
- An initial `R CMD check` directly on the source directory stopped because `Author`/`Maintainer` are derived from `Authors@R` during package build. The standard `R CMD build` then `R CMD check` path passed.
