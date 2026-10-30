# Terminal input and layout compatibility report

## A. Environment

- Repository: [menshikovs/termr](https://github.com/menshikovs/termr)
- Working branch: `feature/terminal-input-layout-1.1`
- Working tree base commit: `d6ca75ea3e23c9320146602b9b790b4b91b16e92` (current `main` at inspection time)
- Published comparison source: CRAN 1.0.1, local branch commit
  `89065a4de65d8372cf14c3c51f08e6ae654d5967`
- Local platform: Windows 11 x64, build 26100; R 4.5.2 (ucrt); Python 3.14.4.
- Package `DESCRIPTION` remains version 1.0.1. Stage 2 changes are uncommitted
  in this workspace, so the base SHA does not identify the changed tree.
- At local validation time, the Stage 2 feature branch had no remote ref or
  pull request, so no cross-platform check had run.

## B. Baseline behavior

The CRAN 1.0.1 source already parses a byte stream containing Tab then Enter
into ordered `tab`, `enter` events. The defect was in app event targeting:
`App$post_input()` snapshotted the focused widget for every key and paste event
before the queue dispatched any event. Thus, when both keys arrived in one
driver read, Enter still targeted the pre-Tab widget. A headless reproduction
against the installed CRAN 1.0.1 package reported `focused= go pressed= 0`.

In the development source, the same sequence reports `focused= go pressed= 1`.
Events now resolve their target when dispatched, so the second event observes
the focus update made by the first. The app-level regression queues both keys
before a single `pilot$step()` and checks focus and press callback order.

## C. Input investigation and fix

The parser was not dropping Tab. The event queue preserved order; the stale
target was assigned earlier in `post_input()`. `App$dispatch()` now resolves a
private marker to the current focused widget for each driver-provided key or
paste event. This corrects grouped and split input to have the same focus
behavior without inserting delays. Directly posted events with an explicit
target through `App$post()` retain their target; driver input uses the private
focus marker.

`test-keys.R` covers `Tab+Enter`, repeated Tab, text plus Tab+Enter, two arrow
sequences, UTF-8 text, terminal control bytes, every two-part byte boundary,
byte-at-a-time input, incomplete sequences and unknown sequences. The app test
checks ordered focus and activation callbacks. `tools/pty/pty-check.py` adds a
real-driver case that sends `b"Ada\t\r"` in one PTY write and checks that focus
and activation each occur once and in order. The CI wrapper
`pty-check-ci.py` runs that script.

The parser and headless app tests pass locally. The real PTY case was not
executed on this Windows host; Ubuntu and macOS PTY CI results are pending.
The existing Windows driver tests exercise console-record mapping
synthetically, not an interactive Windows console.

## D. Testing infrastructure

- Parser tests feed byte chunks directly to the internal `KeyParser`; they do
  not spawn a process or claim to test terminal transport.
- The headless app test batches key events and checks dispatch ordering.
- The PTY harness starts the real POSIX driver and terminal transport; it is
  configured in the [R-CMD-check workflow](../.github/workflows/R-CMD-check.yaml)
  for Ubuntu and macOS.
- The same workflow runs Windows input regressions against the Windows driver.
- The workflow also runs the package check on Ubuntu release, oldrel-1, R 4.1
  and R-devel, macOS release, and Windows release. These jobs are triggered by
  pull requests. No Stage 2 workflow run or run URL is available yet.
  Creating the remote branch was blocked: the connected GitHub integration
  returned HTTP 403 (`Resource not accessible by integration`), the alternate
  connector requires authentication, and local `.git` is read-only. No PR or
  CI run could be created from this environment.

## E. Layout diagnostics

`App$layout_diagnostics(width, height)` performs an on-demand layout pass and
returns widget class and ID, available and measured dimensions, clipping
direction, and an assessment that fixed-size clipping may be intentional. It
does not render or warn, and it does not change the normal clipping policy.
When inspecting alternate dimensions, it restores the app's current widget
regions afterward; a regression test checks that live geometry is unchanged.
Tests cover a fixed-height container, an overlong label, a bordered input,
radio options, wrapped text and a scroll view. The compact form is also sourced
headlessly.

Scroll views and widgets with internal scrolling, virtualization or viewport
rules are excluded because their natural content size is not a reliable
indicator of a defect. Measurements are heuristic: they identify content
that exceeds the widget's own content box, not whether a user considers that
clipping intentional or whether every focusable child is visible. Dynamic
layout and application-specific rendering still require visual review.

## F. Pilot exit testing

`Pilot$wait_until_exit(timeout, interval)` is additive and returns the app's
exit value, including when the app has already exited. The new test covers
timer-driven exit, immediate inspection after exit, and invalid intervals.
Existing `Pilot$wait_for()` behavior is unchanged and still errors after app
exit.

## G. Constructor API audit

`label()`, `vertical()`, `horizontal()`, `grid_layout()`, and constructors
created by `widget()` now accept an initial `visible` argument. Each new
argument is appended to its signature; defaults remain `TRUE`. Existing
widgets already expose reactive `$visible`, so other focused constructors can
still be hidden after creation. `disabled` remains specific to applicable
controls and generated widgets; it was not added indiscriminately to labels or
containers. Existing `id`, `classes`, and `style` arguments retain their
meaning and order.

## H. Compatibility matrix

| API / behavior | CRAN 1.0.1 | Development default | Opt-in behavior | Compatibility |
|---|---|---|---|---|
| Tab then Enter in one driver read | Enter uses focus snapshotted before Tab; reproduced as no activation | Each event resolves current focus; activation follows Tab | None | Observable bug fix, tested at app level; real PTY pending |
| Key parser byte chunking | Parser API unchanged | Added grouped/split chunk regression coverage | None | No API change; focused tests pass |
| Layout and clipping | Existing rendering policy | Same rendering policy | Call `App$layout_diagnostics()` | Additive, no warning or render side effect |
| Pilot shutdown checks | No `wait_until_exit()` | New additive method | Call `Pilot$wait_until_exit()` | `wait_for()` behavior unchanged |
| Initial widget visibility | Helpers vary; `label()` did not accept `visible` | `visible = TRUE` added to selected helpers | Pass `visible = FALSE` | Additive trailing arguments; defaults preserved |
| Package version and dependencies | 1.0.1 | Still 1.0.1 | None | No version bump or new dependency |

## I. Test evidence

All R tests below were run with `LC_ALL` and `LANG` set to
`English_United States.utf8` so Windows R used UTF-8.

### Focused and full development tests

- `Rscript -e "testthat::test_local('.', filter = '^(app|examples|keys|parser-fragments|layout|reactive)$', reporter = 'summary')"`
  — passed after the geometry restoration fix, zero failures or errors.
- `Rscript -e "devtools::load_all('.', quiet = TRUE); source('inst/examples/compact-form.R', local = new.env())"`
  — passed, including the example's headless self-check.
- Python syntax command:
  ```powershell
  @'
  import ast
  from pathlib import Path
  ast.parse(Path('tools/pty/pty-check.py').read_text(encoding='utf-8'))
  '@ | python -
  ```
  — passed. This validates syntax only; it is not a PTY test.
- `Rscript tools/dev.R doc` — exited 0 and regenerated the checked-in help
  topics. Roxygen emitted R6 method/field documentation warnings; the built
  package check reported no missing help topics or code/documentation mismatch.
- `Rscript tools/validate-dev.R` — **8,198 expectations; 0 assertion
  failures; 36 errors; 2 skips; 0 warnings**. All 36 errors are process-based
  cases blocked before child startup by processx: creating a write pipe fails
  with Windows system error 5, `Access is denied`. Testthat displayed ten
  error details and noted 26 more. The skips were subprocess cleanup
  (`test-lifecycle.R`, sandbox restriction) and the POSIX driver test (Windows
  platform).

### Built package checks and CRAN comparison

Both sources were built and checked with R 4.5.2 on the same Windows host and
UTF-8 locale. The development source was staged without local-only `.agents`
and `.codex` directories and with `.Rbuildignore`'s `tools` and `docs` paths
excluded; an initial direct build of the workspace could not copy ignored
`tools/ci-work/python/pefile.py` and `peutils.py` into R's temporary build tree
because Windows denied file-copy access.

- Development: `R CMD build --no-build-vignettes --no-manual <staged-source>`;
  `R CMD check --no-manual termr_1.0.1.tar.gz` — package install, load,
  namespace, code, documentation and examples checks passed. Testthat ended
  **FAIL 17, WARN 0, SKIP 35, PASS 4488**; final check status was **1 ERROR**
  because those tests could not create child-process pipes.
- CRAN 1.0.1 at `89065a4de65d8372cf14c3c51f08e6ae654d5967`, built and checked
  the same way — **FAIL 17, WARN 0, SKIP 31, PASS 4427**; final check status
  was **1 ERROR** for processx child-pipe creation.
- The 17 failing test names are identical in both runs. Each error reports
  processx pipe creation denied with Windows system error 5. Therefore these
  package-check errors are environment failures, not regressions. The four
  additional development skips are existing recipe tests that require source
  checkout files omitted from a built package; the strict source-checkout
  validation ran those tests.
- The check environment could not reach CRAN/Bioconductor package indexes, but
  dependency checking completed successfully using locally installed
  dependencies. No package-check WARNING was reported. The test ERROR remains
  unresolved on this host and prevents a clean `R CMD check` result.

### CI and consumer evidence

- CI configuration: [R-CMD-check.yaml](../.github/workflows/R-CMD-check.yaml).
  It includes Ubuntu, Windows, macOS, a POSIX PTY job on Ubuntu/macOS, and a
  Windows input job. A workflow definition is not evidence of a passing run;
  all these Stage 2 results are pending.
- No Stage 2 CI run URL is available. The base commit has no associated PR
  workflow run; cross-platform results remain pending a draft PR.
- The public [R-Knowledge-MCP repository](https://github.com/menshikovs/R-Knowledge-MCP/tree/8f01870558263283ba197dc215d0f1ab5ad864af)
  at main commit `8f01870558263283ba197dc215d0f1ab5ad864af` does not contain
  `tests/test_codex_launcher.py` or a committed launcher test suite. The
  inspected integration branch commit `243ae1752ae6447bc6a860040e6605556e5b4c2a`
  likewise has no launcher/PTY tests. Consumer compatibility was not run; no
  unrelated tests were substituted.

## J. Remaining limitations

- Ubuntu and macOS test results, including real PTY integration, are pending
  CI. Windows real-process lifecycle tests are blocked by this sandbox's
  denied child pipes; they must pass on a normal Windows runner.
- Interactive Windows console behavior was not exercised locally. The shared
  parser, headless dispatch, and synthetic Windows key mapping tests pass.
- No public R-Knowledge-MCP launcher suite was found, so its real consumer
  behavior remains unverified.
- Layout diagnostics are heuristic and intentionally omit specialized
  scrolling or virtualized widgets.
- `R CMD check` does not pass locally because 17 process-dependent tests are
  blocked by environment policy. This is also reproduced against CRAN 1.0.1,
  but a clean CI check is still required.

## K. Breaking-change assessment

No public API was removed or renamed, no existing argument changed position or
meaning, no default changed, no required dependency was added, and the package
version was not bumped. `wait_for()` and default rendering/clipping behavior
are unchanged. The only non-additive observable correction is that key and
paste events from the same driver read now target the focus established by
earlier events in that read. This fixes the reproduced Tab+Enter activation
bug and is covered by parser and app tests. It is documented in NEWS and the
terminal guide.

**Stage 2 is not yet verified complete.** The focused Windows tests pass and
the CRAN comparison found no new package-check failure, but real PTY tests,
cross-platform CI, clean `R CMD check`, and the external launcher remain
pending or blocked.
