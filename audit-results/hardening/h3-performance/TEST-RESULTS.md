# H3 validation results

Windows: TOTAL: 17090 tests, 0 failed, 0 errors, 94 skipped, 0 warnings; Status: OK.

WSL: TOTAL: 18618 tests, 0 failed, 0 errors, 30 skipped, 0 warnings; Status: OK.

| Check | Exit code |
|---|---:|
| h1-h2-baseline | 0 |
| focused-windows | 0 |
| optional-free-windows | 0 |
| full-windows | 0 |
| build-windows | 0 |
| check-windows | 0 |
| build-wsl | 0 |
| inventory-wsl | 0 |
| focused-wsl | 0 |
| optional-free-wsl | 0 |
| full-wsl | 0 |
| check-wsl | 0 |
| pty-fixture-wsl-final | 0 |
| pty-full-wsl | 0 |
| pty-combined-wsl-repeat-1 | 0 |
| pty-combined-wsl-repeat-2 | 0 |
| pty-binary-wsl | 0 |
| before-core | 0 |
| after-core | 0 |
| before-broad | 0 |
| after-broad | 0 |
| before-events-profile | 0 |
| after-events | 0 |
| before-extra | 0 |
| after-extra | 0 |
| after-stream | 0 |
| before-granular | 0 |
| after-granular | 0 |
| before-components | 0 |
| after-components | 0 |
| before-memory | 0 |
| after-memory | 0 |
| paired-bridge | 0 |
| resource-cycles-windows | 0 |
| resource-cycles-wsl | 0 |
| trace-copies | 0 |
| git-diff-check | 0 |

Every listed validation command has a raw .log and real .exit file. The full suite is run through
`Rscript tools/dev.R test` on each platform, so this also satisfies the requested
developer-runner validation. R CMD check runs packaged tests separately with
NOT_CRAN=false, --no-manual and --no-vignettes. Build uses --no-manual and
--no-build-vignettes. Optional-free inkr tests run in a distinct R process.

Expected failing-first and initial diagnostic exits are preserved separately
and excluded from final-success aggregation. Final status is not inferred from
printed PASS text alone. Initial benchmark/focused runner issues and their
repeats are documented in BASELINE.md and REGRESSION-TESTS.md. Read the
dependency manifests and skip lists for incomplete optional/platform coverage.

DESCRIPTION and NAMESPACE hashes match the initial H3 baseline; no generated
man files were changed. git-diff-check and preservation.json document whitespace
and change-scope checks. There are no commits, pushes or releases.

Final Windows and WSL validation artifacts are under final-validation-ring/;
earlier root/final-validation logs belong to intermediate candidates. The final
Windows source is staged from a trusted package archive with all current R and
R-test files overlaid; WSL independently rebuilds the same staged inputs.
archive-source-verification.json compares all 222 packaged R/test/NAMESPACE
files to the final workspace. No old candidate pass certifies the final queue.
The initial WSL whole-working-folder copy was deliberately stopped after
verifying its owned cp command; build-wsl-initial.* retains that diagnostic.
The successful staged WSL build is recorded separately in final-validation-ring/.
PowerShell may wrap R's stderr as NativeCommandError records; real .exit values
and the final R check Status line are checked independently of those wrappers.
