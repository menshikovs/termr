# Test and R CMD check results

## Focused integration coverage

`inkr` 0.1.0 was installed from the local official sibling checkout into a
temporary library on Windows and WSL. The enabled focused run passed 57
expectations; the one skipped test is specifically the optional-free behavior
case, which only applies when `inkr` is absent. The optional-free focused run
passed six expectations and skipped the 12 enabled-only cases. Both runs
returned exit code 0 on both platforms.

The integration tests cover the cascade order, all eight built-in properties,
ignored registry defaults, inheritance, nested selectors, direct class/id
assignment, focus and disabled states, explanations, atomic valid/invalid
replacement, file and AST input, URL-like text fragments and remote URL
rejection, transparent backgrounds, alpha rejection, theme/sheet replacement,
and chart/DataTable widgets. The bundled example inventory test was updated
for the seven new examples and passed.
All seven inkr and no-inkr examples were also sourced with `run()` captured,
then rendered headlessly through `render_widget()`; all reported `OK` on
Windows.

## Full testthat suites

| Platform | R | Result | Skips |
|---|---|---:|---|
| Windows 11 x64 | 4.6.1 | 15,270 passed; 0 failed, errors or warnings | 94 |
| WSL Ubuntu 26.04.1 x86_64 | 4.5.2 | 16,846 passed; 0 failed, errors or warnings | 30 |

Skipped tests are guarded by optional packages unavailable in each test
library, plus platform-only and mutually exclusive optional-package cases.
Windows had 15 unavailable Suggests packages; WSL had only `mirai` and
`nanonext` unavailable for its package check. The WSL full suite additionally
ran tests for packages such as `shiny`, `haven`, `sf`, and `units` which were
present in that environment.

The first Windows full-suite attempt inside the sandbox could not create child
`Rscript` pipes (`Access is denied`) in pre-existing process/worker tests. The
same suite was rerun outside the sandbox, as required for those tests, and
passed. The example-list mismatch found in that first run was corrected by
listing the seven new examples; the focused examples test then passed.

## R CMD check

| Platform | Result | Notes |
|---|---|---|
| Windows 11 x64, R 4.6.1 | `Status: OK`, exit code 0 | `_R_CHECK_FORCE_SUGGESTS_=false`; INFO lists 15 unavailable optional Suggests packages. |
| WSL Ubuntu 26.04.1, R 4.5.2 | `Status: OK`, exit code 0 | `_R_CHECK_FORCE_SUGGESTS_=false`; INFO lists unavailable `mirai` and `nanonext`. |

Both checks passed installation, namespace/load/unload, R code analysis,
documentation metadata/content, examples, and `testthat.R`. No check warnings or
errors were reported. With R's default force-Suggests behavior, the first
Windows check stopped before package checks because the environment lacked
optional Suggests; the complete rerun used the documented check setting above.
The WSL check ran under WSL's R 4.5.2 against the source tarball built by
Windows R 4.6.1 from this checkout; building directly from the `/mnt/c` mount
was avoided because R CMD build first copies the entire checkout before
applying `.Rbuildignore`.

## Documentation and public surface

- `Rscript tools/dev.R doc` completed with exit code 0 and regenerated the
  `App`, `Widget`, `app()` and `inspect_widget()` help topics from roxygen.
- Roxygen still prints the existing `Pilot`/`testing.R` documentation warnings
  (undocumented R6 fields/methods and parameter coverage); these are unrelated
  to inkr and did not make generation fail.
- R CMD check reports `NAMESPACE`, missing docs, Rd metadata, usages, contents
  and code/documentation mismatches as OK.
- No inkr-specific namespace imports or standalone exported functions were
  added. The feature is exposed through the app constructor and documented R6
  methods.

## Terminal limits

Windows and WSL headless Unicode, renderer, widget-tree, focus and styling tests
passed. No live interactive terminal or macOS environment was available, so
these results do not establish terminal-specific color rendering or visual
behavior in a real console.
