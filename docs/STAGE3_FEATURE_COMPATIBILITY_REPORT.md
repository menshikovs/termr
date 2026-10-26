# Stage 3 feature compatibility report

Audit date: 2026-10-26  
Branch: `feature/developer-experience-1.1`  
Published baseline: `termr` 1.0.1 on CRAN  
Source revision tested in hosted CI: `89481918a0ba9665764735275db4d4ab015880c3`
Stage 3 commits: `e07d427` (ProcessView), `50e26da` (dynamic workflow),
`cec4771` (widget inspection), `abe5a8c` (audit/docs/workflows),
`a4b53ba` (report), `4fe20eb` (CI assertion correction), and `8948191`
(forced isolated development install).

## A. Baseline

The feature branch is based on Stage 1 commit
[`bbcab0be81d4ce81c33f64c23cef2678e608cb1f`](https://github.com/menshikovs/termr/commit/bbcab0be81d4ce81c33f64c23cef2678e608cb1f).
The Stage 1 lifecycle matrix passed on Ubuntu, Windows and macOS in
[GitHub Actions run 40318579995](https://github.com/menshikovs/termr/actions/runs/40318579995).
The R-Knowledge-MCP consumer job in that run could not execute its requested
test file; see [Real-world usage](#f-real-world-usage).

Local validation used R 4.5.2 (ucrt) on Windows 11 x64. CRAN 1.0.1 was
installed in an isolated library from the CRAN package artifact. The development
package was separately installed from the Stage 3 source tree into another
library. `DESCRIPTION` remains at 1.0.1; no package version bump was made.

The selected Stage 1 base already provides `Worker$request_cancel()`,
`Worker$cancel_requested`, opt-in `App$exit(worker_grace = ...)`,
`supervision = "none" | "parent"`, bounded `LogView`, dynamic list/table APIs,
signals/computed/watch, `inspect_widget()`, focus-chain inspection, bounded
opt-in event logging, a debug overlay, and headless Pilot tests. The full audit
is in [`STAGE3_CAPABILITY_AUDIT.md`](STAGE3_CAPABILITY_AUDIT.md).

## B. Capability audit summary

The work builds on those APIs rather than adding a second worker engine,
reactive state layer, table/list abstraction, event logger, or profiler.
Confirmed Stage 3 gaps were that `ProcessView` did not expose the opt-in Stage 1
graceful cancellation/supervision controls or a useful state/exit status, and
`inspect_widget()` did not show focus position. Dynamic widget operations
already existed; they needed a realistic, discoverable example and clearer
documentation. Stage 2 layout diagnostics are not on this branch base.

## C. Implemented features

### ProcessView

`process_view()` and `ProcessView$new()` now accept trailing optional
`stop_grace = NULL` and `supervision = "none"` arguments. With defaults,
cancellation remains synchronous and supervision remains disabled. Supplying a
grace opts into `Worker$request_cancel()`, a visible `stopping` state and
escalation through the existing Worker implementation. Supplying
`supervision = "parent"` forwards the existing processx policy. The widget adds
read-only `$state` and `$exit_status` fields plus `$clear_output()`. An explicit
restart under opt-in grace starts the new run only after the prior worker has
terminated; retries are never automatic. The existing
`process.finished(status, state)` payload and callback signatures are retained.

Real-process tests were added for asynchronous cancellation, repeated cancel,
restart-after-stop, output limits, exit status, optional parent supervision,
and a missing executable. The process tests are strict in CI and fail rather
than skip there. Local execution was blocked before termr code by processx
write-pipe creation denial (details in [Test evidence](#g-test-evidence)).

### Dynamic widgets

Added the runnable `dynamic-workflow` example and a headless test covering
choice replacement, table updates, conditional visibility, and focus-chain
changes through existing public APIs. No new dynamic widget API was needed.

### Developer inspection

`inspect_widget()` now adds `focused`, `focus_order`, and `focus_count`, and its
printer shows whether the widget is focused and its position in the focus
chain. Existing fields and the result class remain intact. The test covers
current focus, hidden widgets, and printed output. Existing event tracing and
debug overlay behavior are documented; neither was changed.

## D. Features not implemented

- No selectable `stop_signal`: Worker exposes processx's platform interrupt,
  not arbitrary signal selection.
- No guarantee of arbitrary process-tree cleanup. `"parent"` means the
  processx parent-death policy where supported; descendant behavior remains
  processx/platform-dependent.
- No automatic retries, custom process engine, or unbounded output history.
- No new row/list wrapper API, reactive system, inspector, event logger, or
  profiler; existing APIs already cover those needs.
- No layout-warning integration because Stage 2 layout diagnostics are absent
  from the selected base.
- No consumer launcher replacement tests. The public pinned R-Knowledge-MCP
  revision lacks the requested test module.

## E. Public API changes

| API | CRAN 1.0.1 | Development default | New opt-in functionality | Compatibility |
|---|---|---|---|---|
| `process_view()` / `ProcessView$new()` | Existing positional arguments through `style`; synchronous cancel | All old arguments retain order and defaults; new arguments are appended | `stop_grace`, `supervision`, `$state`, `$exit_status`, `$clear_output()` | Existing calls and cancellation defaults preserved; focused signature contract passes against both versions |
| `ProcessView$restart()` | Cancels current run synchronously and starts another | Same when `stop_grace = NULL` | With a configured grace, waits asynchronously for termination before starting | Behavior change requires explicit opt-in |
| `inspect_widget()` | Existing inspection fields and `termr_inspection` result | Existing fields retained | Adds focus fields and printer line | Additive, read-only; no navigation changes |
| Dynamic widget APIs | `OptionList$set_choices()`, `DataTable$set_data()`/`$set_cell()`, visibility and reactive APIs | Unchanged | No API addition; example/docs only | No behavior change |

No exports, dependencies, existing argument order, callback signatures, event
names, or stable defaults were removed or changed.

## F. Real-world usage

The ProcessView additions allow an application to opt into non-blocking stop,
observe `stopping`/terminal state, inspect an exit code, clear bounded logs,
and explicitly restart without rebuilding the containing app. Dynamic form and
table patterns are demonstrated in `inst/examples/dynamic-workflow.R`.

The R-Knowledge-MCP public revision pinned by the compatibility workflow is
`8f01870558263283ba197dc215d0f1ab5ad864af`. That revision does not contain
`tests/test_codex_launcher.py`; the prior Stage 1 run therefore failed at the
consumer test-file lookup before launcher tests ran. Stage 3 CI repeated the
same strict failure because pytest reported `file or directory not found`; no
unrelated tests were substituted. No consumer pass is claimed.

## G. Test evidence

### Focused local tests

Command, after removing invalid inherited `C.UTF-8` locale variables from the
Windows process environment:

```powershell
Rscript -e "testthat::test_local('.', filter = 'process-view-options|devtools|dynamic-workflow|worker-lifecycle-compat|^examples$', reporter = 'summary')"
```

Result: passed. The ProcessView options suite had four skips because this local
sandbox denies child-process pipe creation. The UTF-8 hello snapshot and
dynamic workflow passed. A prior run with the invalid locale variables present
rendered box drawing as ASCII and failed that snapshot; clearing those variables
made the same test pass without changing its expected output.

### CRAN 1.0.1 compatibility comparison

Ran the same test file in separate R processes and isolated library paths:

```powershell
Rscript -e "library(termr, lib.loc = Sys.getenv('TERMR_CRAN_LIB')); testthat::test_file('tests/testthat/test-worker-lifecycle-compat.R', reporter = 'summary')"
Rscript -e "library(termr, lib.loc = Sys.getenv('TERMR_STAGE3_DEV_LIB')); testthat::test_file('tests/testthat/test-worker-lifecycle-compat.R', reporter = 'summary')"
```

Both CRAN 1.0.1 and the installed development package passed the same 36
compatibility expectations. The shared contract covers legacy worker/process
argument order and defaults, synchronous cancel behavior, inline completion
and failure callbacks/events, and the original ProcessView constructor
arguments. It does not substitute for real-child process tests.

### R CMD check

Built the source package and ran `R CMD check --no-manual --as-cran` under R
4.5.2 / Windows 11 with invalid locale variables removed. Package installation,
namespace, dependency/code analysis, Rd checks, examples, and the check setup
passed. Final result: **1 ERROR, 0 WARNING, 4 NOTEs**. Testthat reported
**17 errors, 0 warnings, 53 skips, 4508 passes**.

All 17 errors occurred at `processx_exec` while creating a child-process write
pipe, with Windows system error 5 (“Access is denied”). One is the independent
processx test at `test-posix-driver.R:86`; ten are worker bootstrap cases in
`test-worker-bootstrap.R`; six are worker process cases in `test-workers2.R`.
The stack traces fail before the termr child code runs. This is an environment
failure, not evidence of a Stage 3 implementation regression. The check also
reported notes for unavailable CRAN/GitHub URL access, the existing `.agents`
directory, inability to verify the clock, and missing Pandoc/top-level extra
files. No package WARNING was reported.

### Workflow validation and hosted CI

PyYAML parsed both `.github/workflows/worker-lifecycle-compatibility.yaml` and
`.github/workflows/R-CMD-check.yaml`. `actionlint` was not installed. The
workflow expressions were manually checked; the lifecycle matrix remains
Ubuntu/macOS/Windows, and R CMD check still covers Ubuntu, macOS and Windows
with its existing R-version matrix. Lifecycle and ProcessView tests remain
strict in CI.

The first hosted Stage 3 attempt surfaced test and workflow problems:

- [Lifecycle run 40336758268](https://github.com/menshikovs/termr/actions/runs/40336758268)
  failed ProcessView tests on Ubuntu, Windows and macOS. The tests asserted
  `TRUE` for `Pilot$wait_for()`, which returns the Pilot object after the
  condition is met, and the output fixture used `cat()`'s default separator,
  which inserted spaces between lines. These were test defects; the logged
  wait conditions were met and output matched the fixture behavior.
- [R CMD check run 40336758229](https://github.com/menshikovs/termr/actions/runs/40336758229)
  failed all six package-check matrix jobs on those same ProcessView test
  expectations. The tests now wait and then assert the actual state, and the
  output fixture uses `writeLines()`.
- [Lifecycle rerun 40337489493](https://github.com/menshikovs/termr/actions/runs/40337489493)
  passed macOS and Windows. Ubuntu exposed an isolated-install issue:
  `remotes::install_local()` skipped installing development termr because its
  recorded SHA/version matched 1.0.1, leaving the development library empty.
  The workflow now uses `force = TRUE`; this argument was validated locally,
  and the Ubuntu rerun installed and tested the development package.

On corrected source commit
[`8948191`](https://github.com/menshikovs/termr/commit/89481918a0ba9665764735275db4d4ab015880c3):

- [Lifecycle run 40337980093](https://github.com/menshikovs/termr/actions/runs/40337980093)
  passed all three platform lifecycle jobs. Each ran the CRAN/development
  compatibility contract and real ProcessView tests. Its only failed job is
  the R-Knowledge-MCP launcher job because the pinned repository lacks
  `tests/test_codex_launcher.py`.
- [R CMD check run 40337980089](https://github.com/menshikovs/termr/actions/runs/40337980089)
  passed all six package-check jobs (Ubuntu release, oldrel-1, 4.1, devel;
  macOS release; Windows release), extended suites, SQL, Windows input, and
  both PTY jobs. Its CRAN incoming job was still installing TeX, qpdf and HTML
  Tidy when this report was written. The equivalent tarball check passed on
  this same package source in [run 40337489693](https://github.com/menshikovs/termr/actions/runs/40337489693).

The package-check logs report no ERROR or WARNING on any of the six matrix
jobs. Ubuntu, macOS, and Windows each ran the full suite; the Windows suite
passed with 8,522 expectations and seven platform skips, and the Unix suites
passed with 8,554 expectations and four skips. R CMD check reported two NOTEs
on Unix and three on Windows. The extra Windows NOTE is `checking for detritus
in the temp directory`: it lists six `Rscript`-prefixed entries. The Windows
check for the main-branch baseline commit
[`d6ca75e`](https://github.com/menshikovs/termr/commit/d6ca75ea3e23c9320146602b9b790b4b91b16e92)
in [run 39626174014](https://github.com/menshikovs/termr/actions/runs/39626174014)
reported that directory clean. The development log does not identify which
test created those entries. New lifecycle fixtures do force-stop Rscript
children, so those tests are a plausible source, but the attribution is not
confirmed. This is an unresolved Windows test-temp cleanup NOTE, not a process
test failure; the Windows package-check job itself passed. No claim is made
that arbitrary child-process temporary files are cleaned after forced
termination.

The report-only head [`01c2170`](https://github.com/menshikovs/termr/commit/01c21708f10b3785bf327347a72487c443cb5258)
has new lifecycle and R CMD check runs in progress. The package source is
unchanged from `8948191`; these reruns are not counted as completed evidence.

No R CMD check ERROR or WARNING was reported by the completed hosted
package-check jobs. The local Windows sandbox still reports 17 process-spawn
errors before package child code because it denies pipe creation. No Stage 3
implementation defect was established by the failed attempts.

## H. Performance considerations

Non-blocking cancellation returns control to the app event loop while the
worker remains alive and output continues to be polled. ProcessView retains the
existing bounded `LogView` (2000 lines by default); clearing output does not
stop the process. Focus inspection computes the existing focus chain only when
called. No performance benchmark was run, so no quantitative overhead claim is
made. The event logger remains disabled by default and bounded as before.

## I. Remaining limitations

- Real Stage 3 child-process tests cannot run in this Windows sandbox; hosted
  Linux, Windows and macOS lifecycle jobs pass on the corrected commit.
- The local full `R CMD check` has 17 process-spawn errors before package child
  code because the sandbox denies child pipes. Hosted package checks passed.
- The R-Knowledge-MCP launcher tests are unavailable at the pinned public
  revision; no equivalent unrelated tests were substituted.
- The Windows R CMD check passes with no ERROR or WARNING, but reports one
  additional temp-detritus NOTE from six `Rscript...` entries. The development
  log does not map them to a specific test. Forced Rscript cancellation tests
  are a plausible source, but this remains unconfirmed and should be revisited
  before making a claim about child-created temporary-file cleanup.
- Stage 2 layout diagnostics are not available on this base.
- Initial interrupt selection is fixed by processx/platform behavior. Parent
  supervision is not an arbitrary descendant-tree guarantee.
- The Windows inherited locale variables are invalid for this R build; Unicode
  tests pass when they are removed. This is an environment setup issue.

## J. Breaking-change assessment

1. Existing public APIs removed: **No.**
2. Existing arguments renamed or reordered: **No.** New ProcessView parameters
   are trailing and optional.
3. Existing defaults changed: **No.** Synchronous cancellation and
   `supervision = "none"` remain the defaults.
4. Existing event semantics changed: **No intended change.** The existing
   `process.finished` name and payload fields are retained.
5. Default worker behavior changed: **No.** New cancellation/supervision paths
   require explicit options.
6. Focus or keyboard behavior changed: **No.** Inspection only reports focus.
7. Default rendering behavior changed: **No.** `stopping` is shown only for
   opt-in asynchronous cancellation.
8. New mandatory dependencies added: **No.**
9. Existing applications require migration: **No.**
10. Suitable for a backward-compatible minor release: **Yes for termr's
    public API and default behavior, based on the CRAN contract comparison and
    passing Ubuntu/Windows/macOS lifecycle checks.** The R-Knowledge-MCP
    consumer remains unverified because its test module is absent from the
    pinned public revision.

## Release readiness

**Stage 3 implementation and core platform verification are complete; full
consumer verification remains incomplete.** The corrected ProcessView tests,
six-job package-check matrix and shared CRAN 1.0.1 compatibility contract pass
on Ubuntu, Windows and macOS. The public R-Knowledge-MCP launcher test module
is absent at the pinned revision, so that consumer comparison could not run.
The Windows check also has the unresolved test-temp NOTE described above.
The latest report-only reruns are still in progress; an equivalent CRAN
incoming tarball check passed on the same package source in run 40337489693.
No version bump, merge, or CRAN submission was made. Stage 3 is not fully
release-verified until the consumer suite is available and the Windows temp
NOTE is attributed or shown not to come from the new lifecycle tests.
