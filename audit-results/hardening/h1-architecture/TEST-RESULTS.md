# Fresh validation results

All results below come from this H1 turn, not earlier completion reports.

| Run | Result |
|---|---|
| Windows focused integration | exit 0; missing optional integrations explicitly skipped |
| WSL focused integration | exit 0; installed typed/DBI/Shiny/Plotly cases execute |
| Windows optional-free inkr | exit 0 |
| WSL optional-free inkr | exit 0 |
| Windows tools/dev.R test | 15371 assertions: 15277 pass, 0 fail, 0 errors, 94 skips, 0 warnings; exit 0 |
| WSL tools/dev.R test | 16883 assertions: 16853 pass, 0 fail, 0 errors, 30 skips, 0 warnings; exit 0 |
| Windows R CMD build | exit 0 |
| Windows R CMD check | Status: OK; exit 0 |
| WSL R CMD check | Status: OK; exit 0 |
| WSL headless PTY fixture | exit 0 |
| WSL full real PTY harness | exit 0 |
| WSL combined-focus repeats | 0, 0 |
| WSL binary/control PTY | exit 0 |

Windows is R 4.6.1 on Windows 11 x64; WSL is R 4.5.2 on Ubuntu 26.04.1 LTS,
both UTF-8. Package checks use --no-manual --no-vignettes and
_R_CHECK_FORCE_SUGGESTS_=false. Windows check lists 15 missing Suggests as INFO;
WSL lists mirai/nanonext. Those native runtimes were not validated. MacOS,
minimum R 4.1, live Windows console glyph rendering and PDF manual are NOT RUN.

H1's failing-first main regressions reproduce Pilot retention and source-cache
collision; both pass after fixes. The separate open-regressions script is
intentionally nonzero: Windows has five failed candidate/defect assertions and
one DBI skip; WSL has six failures and no skips. F03 is a documented design
limitation and F04 is a proposed contract policy, not counted as proven defects.
These audit-only files are excluded from the package suite by location.

Developer runner status was independently checked with isolated temporary
packages: failure=1, error=1, success=0. Windows processx sandbox denial was
compared with a successful authorized outside-sandbox probe using the same
code. It was not worked around by skipping worker tests in final validation.

The Windows-built source archive is installed/checked natively in WSL; both
digest records refer to the same file. The earlier baseline combined-focus
run plus full-harness case plus two final repeats provide four current-tree
combined-focus observations. This is not a proof that every historical PTY
race is fixed, and the old failure's exact root cause remains unresolved.

Roxygen generation now emits no Pilot diagnostics. Public man/NAMESPACE hashes
and other baseline hashes are checked in preservation.csv. git diff --check
output is saved in git-diff-check.txt. No release readiness claim follows from
successful checks while P1 findings remain open.
