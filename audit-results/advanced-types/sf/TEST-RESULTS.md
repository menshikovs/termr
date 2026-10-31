# A2.5 Test Results

## Automated tests

- Focused WSL test: `testthat::test_local('.', filter = 'datatable-sf', reporter = 'summary')` — passed after adding the randomized valid-geometry cases.
- Full Windows suite before the final fuzz-only test addition: 14,643 passed, 0 failed, 0 errors, 0 warnings, 86 skipped. The sf-specific tests were skipped because `sf` is not installed on Windows. The final Windows package check ran the updated test tree successfully.
- Full WSL suite before the final fuzz-only test addition: 16,166 passed, 0 failed, 0 errors, 0 warnings, 29 skipped. The sf tests ran against sf 1.0.24. The focused run and final package check included the fuzz test.
- Randomized structure tests cover 40 seeded valid geometries; other cases cover geometry families, multiple sfc columns, empty and missing values, CRS and dimensions, Unicode, 10,000-coordinate geometry, attribute edits, and row alignment.
- `git diff --check` — passed. `NAMESPACE` has no changes.

## R CMD check

- Windows 11, R 4.6.1, `--no-manual --no-build-vignettes`, optional suggestions disabled for unavailable packages: **Status: OK**. `sf` was not installed, so spatial tests were skipped. The check reported INFO for unavailable optional Suggests; no warnings or notes were reported.
- WSL Ubuntu 26.04.1, R 4.5.2, same check options: **Status: OK**, including the updated tests with `sf` 1.0.24. Optional `mirai` and `nanonext` were not installed and were reported as unavailable suggestions.

Logs and the built source archive are in `final-validation/`.

## PTY smoke test

`python3 tools/pty/pty-check-ci.py` under WSL exercised terminal mode restoration, Unicode, input, resize, mouse, paste, error handling, no-TTY, and fragmented input. All checks passed except two assertions in the generic combined-input app: a single PTY write containing text, Tab, and Enter produced focus but no button activation. The app exited normally and restored terminal modes. This test does not exercise DataTable or spatial rendering, and the failure is outside the A2.5 source paths; it remains a separate terminal smoke-test failure rather than being reported as a passing PTY run.
