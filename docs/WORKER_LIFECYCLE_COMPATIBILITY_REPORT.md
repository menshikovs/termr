# Worker lifecycle compatibility report

This report compares the published termr 1.0.1 behavior with the additive
worker lifecycle APIs in this development tree. It records observed facts
separately from guarantees that could not be exercised in the current
environment.

## A. Baseline

### Artifact and environment

The installed package used for characterization is termr 1.0.1 in
`C:/Users/User001/AppData/Local/R/win-library/4.5/termr`. Its installed
metadata reports `Repository=CRAN`, `RemoteType=standard`, `RemoteSha=1.0.1`,
and `Built=R 4.5.2; 2026-10-21 15:30:53 UTC; windows`. The installed package
tree was copied unchanged to the isolated library
`C:/Users/User001/AppData/Local/Temp/termr-cran-1.0.1-lib/termr` and loaded
from that path for API and inline-worker characterization. The direct
`install.packages()` request for the archived source tarball was also
attempted, but the sandbox could not connect to `cran.r-project.org`; the
existing installation's CRAN repository metadata is the provenance evidence
available here. No archive checksum could be obtained.

Environment: Windows x64 (build 26100; Sys.info reports Windows 10 x64 while
R CMD check identifies Windows 11 x64), R 4.5.2 (`x86_64-w64-mingw32`),
termr 1.0.1, processx 3.8.6, ps 1.9.1, R6 2.6.1, testthat 3.3.2, callr 3.7.6,
and roxygen2 8.1.0. Repository commit before implementation:
`a7f92ee5391deb3417dce6ab7fef24f1ca08981d`.

The reusable executable characterization is
[`tools/compat/worker-lifecycle-baseline.R`](../tools/compat/worker-lifecycle-baseline.R).
Set `TERMR_CRAN_LIB` to the isolated library above and run it with
`Rscript tools/compat/worker-lifecycle-baseline.R`. Set
`TERMR_RUN_PROCESS_PROBE=true` to include real child-process probes; setting
`TERMR_REQUIRE_PROCESS_PROBE=true` makes inability to start a child a failing
result, as used in CI.

[`tests/testthat/test-worker-lifecycle-compat.R`](../tests/testthat/test-worker-lifecycle-compat.R)
is the shared contract suite. It checks the pre-1.0.1 argument order and
defaults, inline success and failure events and callbacks, and synchronous
`Worker$cancel()` behavior. CI runs that same file against both isolated
installations.

### Published API contract observed

The CRAN artifact exports `App`, `Worker`, `app()`, `run()`, `run_worker()`
and `run_process()`. Relevant function signatures are:

```r
app(..., bindings = list(), actions = list(), title = NULL, mouse = TRUE,
    stylesheet = NULL, theme = "default", debug = FALSE, reduce_motion = NULL)

run_worker(fn, args = list(), on_complete = NULL, on_error = NULL,
           on_progress = NULL, name = NULL, owner = NULL,
           packages = character(), inline = FALSE, on_stdout = NULL,
           on_stderr = NULL, timeout = NULL, app = current_app())

run_process(command, args = character(), on_complete = NULL, on_error = NULL,
            on_stdout = NULL, on_stderr = NULL, on_exit = NULL,
            timeout = NULL, wd = NULL, env = NULL, name = NULL,
            owner = NULL, app = current_app())

run(x, ...)
```

The exported `Worker` fields are `name`, `state`, `result`, `error`,
`timed_out`, `progress`, `owner`, `stdout`, `stderr` and `kind`. Its public
methods are `initialize(name, owner = NULL, callbacks = list())`,
`cancel(grace = 0.3)`, `is_running()`, `pid()` and `print(...)` (plus the R6
`clone()` method). `App` exposes `run()`, `exit(value = NULL)`,
`run_worker(...)`, `run_process(...)` and `workers()`.

The current stability guide classifies `run_worker()`, `run_process()` and
worker lifecycle details as public, documented experimental APIs. The
characterized signatures, fields, event names and callback order are published
observable behavior even where their exact lifecycle details are experimental.
Unexported helpers and processx/ps internals are implementation details.

The inline characterization observed `worker.started` followed by
`worker.completed`, result `42L`, one completion callback, and no error
callback. `Worker$cancel()` on a running standalone handle returned `TRUE`
and set `state` to `"cancelled"`; a repeated call returned `FALSE`.
`cancel()` on a terminal completed worker returned `FALSE`.

## B. Existing behavior

### Worker state and event ordering

The published worker states are `running`, `completed`, `failed` and
`cancelled`. Successful completion sets `result`, emits `worker.completed`,
then invokes `on_complete(result, app)`. Failure sets `error`, emits
`worker.failed(error, timed_out, status)`, then invokes `on_error(message,
app)`. `run_process()` additionally invokes `on_exit(status, app)` after its
completion/error callback on natural process exit. Synchronous cancellation
sets `state` to `cancelled` and emits `worker.cancelled`; it does not call
`on_complete`, `on_error` or `on_exit`.

`worker.started`, progress and output are posted as app events. At most 200
output lines are delivered per worker poll. The public `state` remains
`running` until a terminal outcome is observed.

Worker APIs are experimental according to `docs/stability.md`; the class,
function signatures, documented event payloads and callback signatures remain
public. The order recorded above and the 200-line poll bound are observable
behavior characterized from the installed artifact, whether or not each detail
is a stability-guaranteed extension point.

### Cancellation, timeout and cleanup

`Worker$cancel(grace = 0.3)` is synchronous. On Unix it sends an interrupt,
waits up to the grace period, then kills the process tree. On Windows the
current implementation skips the interrupt/wait path and kills the tree
immediately, so the grace argument does not add a delay there.

Timeout is detected during worker polling. A timed-out child is stopped with
the existing 0.3-second termination path, then reported as `failed` with
`timed_out=TRUE`. Natural process exit drains bounded output and kills any
surviving descendants before finishing. Worker job/result/progress/scratch
files are removed at terminal cleanup.

### Application exit and ownership

`App$exit(value = NULL)` stores the return value and sets the exit flag. The
event loop ends after the current tick. `App$run()` shutdown invokes widget
shutdown hooks, cancels app timers and each running worker, clears queued
events, then stops the terminal driver. Each worker is synchronously cancelled
with its default 0.3-second grace. Removing an owner widget or leaving its
screen synchronously calls the same `cancel()` path. The normal shutdown path
restores the terminal; hard process termination cannot run R cleanup.

### Process supervision dependencies

`run_process()` uses `processx::process$new(..., cleanup = TRUE,
cleanup_tree = TRUE)`. `ps` is used for process-tree diagnostics. The installed
processx 3.8.6 help documents `supervise = TRUE` as registering a child with a
separate processx supervisor that kills registered children when the R parent
exits. Its local help documents Unix `SIGTERM` then `SIGKILL` and Windows
CTRL+C/WM_CLOSE then hard termination. The repository does not currently opt
into that supervisor.

### Baseline test attempt

Command:

```text
Rscript -e "testthat::test_local('.', filter = 'workers|worker-bootstrap|lifecycle', reporter = 'summary')"
```

Lifecycle-only tests passed. A process-removal test skipped for the expected
local pipe restriction. Real worker and process tests in the worker bootstrap
file failed at `processx_exec` with Windows system error 5 (`Access is denied`)
while creating a pipe for Rscript. These failures are environmental and do not
establish a worker lifecycle regression. The checked-in suite already notes
this local Windows sandbox limitation.

## C. Changes implemented

### Non-blocking cancellation

* Original: Worker cancel with its default grace synchronously interrupts on
  Unix, waits, kills the process tree, cleans files and emits one cancellation
  event. Windows kills immediately. This contract and its default were retained.
* New: Worker request_cancel with a configurable grace sends processx's
  platform interrupt, records cancel_requested and a deadline, then returns.
  Normal polling drains output and force-kills the tree at the deadline. Zero
  grace force-kills immediately. Repeating a positive request does not extend
  the deadline; a repeated zero-grace request escalates immediately. A process
  already exited when requested keeps its natural completion or failure.
* Opt-in: yes. Existing cancel behavior is unchanged; asynchronous cancellation
  requires the new method.
* Files: R/workers.R, docs/workers.md, man/Worker.Rd, man/run_worker.Rd,
  NEWS.md.
* Tests: tests/testthat/test-worker-lifecycle.R covers validation, idempotence,
  immediate escalation, natural completion/failure races, callback counts,
  terminal events, cleanup files and child cleanup. A multi-worker test checks
  that cancelling one child leaves another free to complete. Real process cases
  could not run here because processx pipe creation is denied.
* Compatibility: additive field/method only. It does not repurpose a state or
  event; an accepted request leaves state as running until cancellation is
  finalized.

### Graceful app shutdown

* Original: App exit with its existing value argument stops after the current
  tick; shutdown synchronously cancels running workers with the existing path.
* New: App exit accepts an optional worker_grace and opts into asynchronous
  cancellation. It keeps polling workers up to the grace period plus a bounded
  one-second final drain. It ignores new terminal input and timers, rejects new
  worker/process starts, processes already queued lifecycle events and restores
  the driver after cleanup.
* Opt-in: yes; omitted worker_grace preserves the existing shutdown route.
* Files: R/app.R, man/App-class.Rd, docs/workers.md, NEWS.md.
* Tests: the new lifecycle test checks worker termination, app return value,
  rejection of new work and driver restoration. It was skipped here because
  worker process creation is blocked.
* Compatibility: the existing first argument and default behavior are
  retained. Repeated graceful exit requests can shorten the deadline but never
  extend it.

### Optional parent-death supervision

* Original: processx cleanup and cleanup_tree handled normal termr cleanup; no
  helper watched children after an R parent crash.
* New: run_worker, run_process and their App methods accept supervision values
  none or parent. The opt-in passes supervise=TRUE to processx when its public
  constructor supports that option. No dependency minimum was raised;
  requesting an unsupported option fails with a clear error.
* Opt-in: yes. none remains the default.
* Files: R/workers.R, R/app.R, man/run_worker.Rd, man/App-class.Rd,
  docs/workers.md, NEWS.md.
* Tests: constructor feature detection is unit-tested; direct-child registration
  and parent signal tests use real children but were skipped because process
  spawning is denied or because they require Unix.
* Compatibility: only new trailing parameters were added. Normal cleanup and
  existing worker ownership are unchanged. The supervisor is processx's
  external helper, not a termr daemon.

### Baseline tooling and documentation

* Added tools/compat/worker-lifecycle-baseline.R as a reusable script for an
  isolated CRAN installation. It validates CRAN metadata before probing APIs
  and inline behavior.
* Added this report and expanded docs/workers.md with examples, transitions,
  platform behavior, migration guidance and known supervision limits.
* Generated roxygen output with Rscript tools/dev.R doc; no exported symbol or
  mandatory dependency was added. Roxygen also refreshed package links in
  man/termr-package.Rd to match the existing DESCRIPTION URLs.

The exact additions to public signatures are:

```r
Worker$request_cancel(grace = 30)
Worker$cancel_requested
App$exit(value = NULL, worker_grace = NULL)
run_worker(..., app = current_app(), supervision = "none")
App$run_worker(..., timeout = NULL, supervision = "none")
run_process(..., app = current_app(), supervision = "none")
App$run_process(..., owner = NULL, supervision = "none")
```

## D. API compatibility matrix

| API | CRAN 1.0.1 behavior | New default behavior | New opt-in behavior | Compatibility |
|---|---|---|---|---|
| Worker cancel(grace = 0.3) | Synchronous termination; Unix interrupt/wait, Windows immediate kill; one worker.cancelled; returns invisible TRUE once and FALSE after terminal | Same; also sets additive cancel_requested = TRUE on a running worker | Not applicable | Signature, return, state and event retained |
| Worker request_cancel(grace = 30) | Not present | New method, unused unless called | Non-blocking request; interrupt then poll/escalate; returns TRUE for the first accepted request, FALSE for an already requested/terminal/unstarted handle; zero grace forces | Additive experimental API |
| Worker cancel_requested | Not present | FALSE until cancellation is accepted/performed | TRUE while asynchronous cancellation is pending and after synchronous cancel | Additive public field |
| run_worker and App run_worker | Spawned worker, default cleanup, callbacks/events as documented | Same defaults | Trailing parent supervision asks processx to supervise the direct child | Existing positional arguments keep their order |
| run_process and App run_process | Spawned program, default cleanup, callbacks/events as documented | Same defaults | Trailing parent supervision asks processx to supervise the direct child | Existing positional arguments keep their order |
| App exit(value = NULL) | Store return value and exit flag; normal shutdown synchronously cancels workers | Same when worker_grace is omitted | worker_grace = seconds requests asynchronous cancellation and bounded drain | Existing value argument and default retained |
| Timeout handling | Poll-detected timeout becomes failed, timed_out = TRUE, with existing callbacks/events | Same path and default | No timeout policy option added | Existing timeout meaning retained |
| Ownership/removal | Removing an owner cancels its worker synchronously | Same | No new owner-removal mode | Existing cleanup path retained |
| Worker events/callbacks | Existing start/progress/output/terminal events, signatures and ordering | Same for natural completion, failure, timeout and synchronous cancellation | Async cancel uses existing worker.cancelled; no completion/error/exit callback | No event removed or renamed; opt-in callback behavior is documented |

## E. Behavioral compatibility

Existing call forms and defaults remain in place. New top-level parameters are
after existing app arguments; new App method parameters follow their prior last
arguments. The existing positional argument order is unchanged.

Natural completion and failure retain their state, result/error, event order
and callbacks. Synchronous cancel retains its existing TRUE/FALSE result and
single cancellation event. The async path keeps the existing public state
values: it leaves the worker running while cancellation is pending, then sets
cancelled, cleans temporary files and emits one worker.cancelled. Neither
cancellation path invokes on_complete, on_error or on_exit. If the child is
already dead when the first asynchronous request is checked, the request
returns FALSE and the next poll records the natural outcome. If it was alive at
the check, a later exit race is reported as cancellation.

The default app exit still cancels workers synchronously. The opt-in app exit
continues polling only while workers or already queued events remain, stops
timers and input during the drain, rejects new work, and forces remaining
workers after the configured bound. Callback/event code already queued before
the exit request can run; app APIs reject starting another worker or process
during this period.

Supervision does not alter normal completion or ownership. With parent
supervision enabled, processx registers the direct child with its helper;
normal termr cancellation and cleanup remain in effect while the parent is
alive. No detached-process mode was added.

## F. Platform guarantees

Verified locally on Windows x64, build 26100, R 4.5.2: the shared API and
inline behavior contract passes against both the isolated CRAN 1.0.1 install
and the isolated development install. The development lifecycle file's
headless assertions pass. Real subprocess behavior could not be exercised
because processx pipe creation is denied in this sandbox. Unix/macOS signal
behavior and process-tree cleanup remain unverified locally. Windows tests
that explicitly require Unix signals were skipped as unsupported.

The parent supervision guarantees are those of processx's public supervise
option. Its helper polls for the parent and terminates registered direct
children. On Unix processx documents SIGTERM followed by SIGKILL after five
seconds; on Windows it documents CTRL+C/WM_CLOSE followed by forced
termination. See the [processx cleanup article](https://processx.r-lib.org/articles/cleanup.html).
The helper's PID tracking is not a PID-reuse-proof identity check; termr does
not claim protection beyond processx's implementation. It does not promise to
terminate arbitrary grandchildren after parent death. Processx also documents
a Windows Defender/antivirus caveat for its bundled supervisor executable.
The PID caveat follows the helper's PID-based liveness check in the
[processx supervisor implementation](https://github.com/r-lib/processx/blob/main/src/supervisor/supervisor.c).
R itself cannot handle SIGKILL or execute app cleanup after it.

## G. Regression testing

Commands and results on this host:

| Command | Result |
|---|---|
| Rscript tools/compat/worker-lifecycle-baseline.R with TERMR_CRAN_LIB set to the isolated CRAN metadata-bearing install | Passed API and inline behavior probes; process probe omitted |
| Same, with TERMR_RUN_PROCESS_PROBE=true | API/inline probes passed; real child spawn failed with system error 5, Access is denied while creating a processx pipe |
| `testthat::test_file('tests/testthat/test-worker-lifecycle-compat.R')`, with `library(termr, lib.loc=...)` set first to the isolated CRAN 1.0.1 install and then to the isolated development install | Both passed: 32 expectations per package covering legacy argument order/defaults, inline success/failure and callback counts, event order, synchronous cancellation and default `App$exit()` return behavior |
| `$env:NOT_CRAN='true'; Rscript -e "testthat::test_local('.', filter = 'worker-lifecycle', reporter = 'summary')"` | Exit 0: headless checks passed; 13 real-process or Unix-only cases skipped. Eleven subprocess cases skip because child pipes are denied; two cases skip because they require Unix behavior on Windows |
| Same baseline script with `TERMR_RUN_PROCESS_PROBE=true` and `TERMR_REQUIRE_PROCESS_PROBE=true` | Exit 1 as intended: strict mode reports the actual Windows system error 5 while creating the processx write pipe. CI sets `CI=true`, so this condition fails the job instead of skipping |
| Side-by-side `testthat::test_file()` comparison of the 10 renderer test files against CRAN 1.0.1 and development, Windows R 4.5.2 with `LC_ALL`, `LC_CTYPE`, `LC_COLLATE`, `LC_MONETARY` and `LC_TIME` set to `C` | Every file reported the same failure/error counts in both versions: accessibility 1; datatable2 5; markdown 10; screens 5 failures + 1 error; scroll 4; split 3; textarea 11; treeview 1; widget-tree 1; widgets-extra 9. Thus all 50 Unicode assertions and the one screen error reproduce on CRAN 1.0.1 under the same environment. |
| `testthat::test_file('tests/testthat/test-database-explorer.R', package='termr')` against CRAN 1.0.1 and development with locale variables set to C | Both runs report the same two warnings at line 118: `unable to translate 'fields:select " café' to native encoding` |
| Rscript tools/dev.R doc | Passed; roxygen output regenerated without warnings |
| `$env:NOT_CRAN='true'; Rscript -e "testthat::test_local('.', filter = 'workers|worker-bootstrap|lifecycle', reporter = 'summary')"` | Exit 1; existing worker/bootstrap subprocess cases failed at processx pipe creation with system error 5; lifecycle tests passed and the expected process-removal test skipped |
| Rscript tools/dev.R test | TOTAL: 1253 tests, 14 failed, 0 errors, 0 skipped, 2 warnings; failures were ASCII/Unicode rendering mismatches in existing accessibility, button and table tests. The run stopped after testthat's max-failure threshold |
| R CMD build --no-build-vignettes . on the full checkout | Interrupted after repeated permission-denied copying of ignored tools/ci-work/python files. A temporary package-only source copy, omitting .Rbuildignore-excluded tools/ and docs/, built successfully with the same build command |
| R CMD check --no-manual --no-build-vignettes --output=TEMP . | Direct source-directory check stopped at DESCRIPTION metadata with missing generated Author/Maintainer fields; the normal build-then-check path was used |
| R CMD check of the built tarball with the inherited C.UTF-8 locale variables | Stopped at DESCRIPTION metadata with 1 error and 1 warning after unsupported locale startup warnings; rerunning with locale variables set to C passed metadata checks |
| R CMD check --no-manual --no-build-vignettes on the rebuilt temporary `termr_1.0.1.tar.gz`, with locale variables set to C | Source/install/load, code, Rd, dependency-in-code and examples checks passed. Test phase ended FAIL 68 / WARN 2 / SKIP 44 / PASS 4382; details and classification are listed below. Check exit status 1 |
| Fresh `R CMD build --no-build-vignettes` and `R CMD check --no-manual --no-build-vignettes` on the current source copy, with `.Rbuildignore` applied and locale variables set to C | Build passed. Install/load, R code, Rd, dependency-in-code and examples checks passed. Test phase ended FAIL 68 / WARN 2 / SKIP 48 / PASS 4414; check status is 1 ERROR, with no R CMD check WARNING |
| PyYAML `BaseLoader` parse of `.github/workflows/R-CMD-check.yaml` and `.github/workflows/worker-lifecycle-compatibility.yaml` plus structure assertions | Passed. `actionlint` is not installed in this environment |
| git diff --check | Passed |

The check's dependency-index lookup could not reach CRAN/Bioconductor; all
dependencies needed to install and load termr were already available. Windows
also emitted a `system2("du")` warning during installed-size checking, which
then passed. These are environment warnings, not R CMD check WARNING status.
No lifecycle-specific failure was observed in the available headless checks.
The real lifecycle integration checks remain unverified because local process
creation is denied. No conclusion about Unix/macOS integration passing follows
from this Windows run.

### Exact failures, warnings and skips from the fresh R CMD check

The check's one R CMD check `ERROR` is the aggregate test failure. Its current
`[FAIL 68 | WARN 2 | SKIP 48 | PASS 4414]` testthat result consisted of the
following items. The preceding check before four additional lifecycle
integration cases had 44 skips; the current check lists all 48 below.

Classification from the evidence available:

* **Actual lifecycle defects:** none demonstrated by the passing shared API
  contract or headless tests. The process behavior is still unverified, so this
  does not establish that the new lifecycle paths are defect-free.
* **Pre-existing behavior:** CRAN 1.0.1 and development reproduced the same
  50 Unicode rendering assertion failures, the same screen test error, and
  the same two database translation warnings in equivalent Windows R 4.5.2
  environments. The renderer emits ASCII borders where these tests expect
  Unicode. In `test-screens.R:142`, the Unicode border search returns `-1`,
  then `get_cell(-1, row)` raises the out-of-buffer error. This screen-position
  error is a consequence of the reproduced baseline rendering mismatch, not a
  separate lifecycle or position regression. These Windows results do not
  establish renderer behavior on a UTF-8 Unix runner.
* **Environment failures:** processx cannot create child-process pipes here
  (Windows system error 5), and the R CMD check host cannot reach CRAN or
  Bioconductor indexes. The `du` warning also comes from the Windows check
  host and does not fail the installed-size check.
* **Unsupported here:** POSIX signal/PTY tests are skipped on Windows; recipe
  Markdown tests are skipped from package builds because `.Rbuildignore`
  intentionally excludes their source files.

* **50 Unicode rendering assertions, all reproduced against CRAN 1.0.1:** `test-accessibility.R:32`;
  `test-datatable2.R:25,26,129,132,135`; `test-markdown.R:23,54-56,65-66,74-77`;
  `test-screens.R:55,139-140,165-166`; `test-scroll.R:21,23-24,60`;
  `test-split.R:16-17,70`; `test-textarea.R:29-31,219,222-223,227,229,231,238,241`;
  `test-treeview.R:91`; `test-widget-tree.R:97`; and
  `test-widgets-extra.R:24,85,114,116,118,123,127,129,143`. The renderer fell
  back to ASCII glyphs while the expectations require Unicode. The side-by-side
  comparison covered every listed rendering file under the same Windows `C`
  locale.
* **One non-worker environment error:** `test-posix-driver.R:86` failed to
  create a processx input pipe with Windows system error 5. The second
  non-worker error, `test-screens.R:142`, is the CRAN-reproduced Unicode
  fallback consequence described above.
* **Sixteen worker process start errors:** `test-worker-bootstrap.R:25,42,98,110,139,157,165,188,206,213`
  and `test-workers2.R:204,250,263,274,287,321`. Each attempted process start
  failed with Windows system error 5 (`Access is denied`) while processx
  created a pipe. These are host restrictions, not evidence that the lifecycle
  behavior passed or failed on an unrestricted host.
* **Two testthat warnings:** both at `test-database-explorer.R:118`, where the
  ASCII/native locale cannot translate `café`. Both warnings were reproduced
  unchanged against CRAN 1.0.1 and development under the same locale.

The 48 skipped tests were:

* **43 `skip_on_cran()` cases:** `test-accessibility.R:97`, `test-button.R:35`,
  `test-datatable.R:15`, `test-examples.R:11`, `test-examples2.R:6,44`,
  `test-grid.R:88`, `test-input.R:112`, `test-lifecycle.R:44`,
  `test-process-view.R:4,24,35,52,65`, `test-treeview.R:26`,
  `test-widget-tree.R:64,81`,
  `test-worker-lifecycle.R:71,108,139,160,198,224,244,284,325,373,396,418,481`,
  `test-workers.R:29,62`, and
  `test-workers2.R:6,40,56,74,91,106,130,148,162,174,219`.
* **One unsupported Windows test:** `test-terminal-posix.R:2` requires POSIX
  signals/terminal behavior.
* **Four source-checkout-only recipe tests:** `test-agent-recipes.R:17,26,38,53`
  are skipped in the built package because the recipe Markdown is excluded.

The earlier `Rscript tools/dev.R test` run reported 14 failures and two
warnings. Its failures were the same ASCII/Unicode rendering class; the
testthat warnings were the two database translation warnings above. The fresh
check keeps the same 68 failures, with no additional lifecycle assertion
failures. Lifecycle integration cases still skip under R CMD check because
they use `skip_on_cran()`; the dedicated workflow sets `NOT_CRAN=true` and
`CI=true` so they run and fail if subprocess creation is unavailable.

## H. External consumer testing

The public [R-Knowledge-MCP repository](https://github.com/menshikovs/R-Knowledge-MCP)
was checked out cleanly by the CI workflow. Its `main` tree does not contain
`tests/test_codex_launcher.py` or the launcher test suite referenced by the
workflow. In runs [40310186089](https://github.com/menshikovs/termr/actions/runs/40310186089),
[40311845330](https://github.com/menshikovs/termr/actions/runs/40311845330),
and [40312594293](https://github.com/menshikovs/termr/actions/runs/40312594293),
pytest exited 4 with `file or directory not found`; no consumer test ran. The
local consumer checkout's launcher files are untracked and cannot establish
compatibility of the public repository. The consumer comparison remains
unresolved and needs a committed, unmodified launcher suite at an agreed path.
No consumer repository files were changed.

Earlier local `testthat::test_dir()` runs against the local consumer checkout
were inconclusive: its headless UI tests skipped on Windows because POSIX
signals are unavailable, and the process wrapper failed to create a processx
pipe with system error 5. Other runnable assertions passed. These local runs do
not replace the missing clean-repository CI comparison.

## I. Remaining limitations

* Ubuntu run 40311845330 passed package installation, both CRAN/development
  compatibility contracts, and the required real-child synchronous
  cancellation probe. Its lifecycle suite had one failure at
  `test-worker-lifecycle.R:219`: the cancellation became terminal after 0.055
  seconds, below the test's 0.1-second minimum for the 0.15-second escalation
  case. The child may have exited on SIGINT before escalation; the logs do not
  establish whether the child fixture handled or ignored that signal as
  intended. This remains unresolved; no test was weakened.
* Windows and macOS run 40311845330 passed the shared contracts, CRAN real-child
  cancellation probe, and all applicable lifecycle tests. The later run
  40312594293 passed both platform jobs again. Windows explicitly skipped two
  POSIX signal cases (`graceful cancellation allows child cleanup` and
  `processx supervision cleans the direct child after parent signals`), both
  reported as unsupported on Windows. macOS had no lifecycle skips.
* Direct-child and descendant cleanup assertions passed on the hosted runners.
  Parent supervision is tested for registered direct children only; arbitrary
  grandchildren are not guaranteed to be terminated. PID reuse is not proven
  impossible by processx's PID-based helper, and Windows Defender/antivirus can
  block its helper.
* The external consumer comparison cannot run until its public repository
  contains the referenced launcher test suite. Its current CI failure is a
  missing test path, not evidence for or against termr behavior.
* The feature branch has no pull request, so the R-CMD-check workflow did not
  run for these changes. Its unfiltered `pull_request` trigger includes pull
  requests from this feature branch. The most recent executed cross-platform
  validation is the dedicated lifecycle workflow, not a branch R CMD check.
* The prior local R CMD check showed Unicode renderer and screen-position
  failures plus database translation warnings that reproduced against CRAN
  1.0.1 in the same environment. Those remain pre-existing, environment-
  sensitive results and have not been re-evaluated on the hosted runners here.

## J. GitHub Actions evidence for the development branch

The original head was `5f3833358adb9b7c446e7e47512017875535b1f0`.
[Run 40307104360](https://github.com/menshikovs/termr/actions/runs/40307104360)
failed with zero jobs, zero check runs, no artifacts, and no available run
logs (the logs endpoint returned 404). GitHub provided no validation
annotation or explicit rejection text. Static inspection identified the
startup defect: `${{ runner.temp }}` appeared in both jobs' job-level `env`
blocks. GitHub's [context-availability table](https://docs.github.com/en/actions/reference/workflows-and-actions/contexts#context-availability)
does not permit `runner` in `jobs.<job_id>.env`, but permits it in
`jobs.<job_id>.steps.env`. Commit
`ce921b095de49ba76d754fd235b77c4f08acb130` moved the paths into a step-level
initializer which writes them to `GITHUB_ENV`. Run 40309289545 created four
jobs and confirmed the initializer succeeded on all four runners.

The first jobful run, [40309289545](https://github.com/menshikovs/termr/actions/runs/40309289545),
passed the 32-expectation shared API/synchronous contract against both CRAN
1.0.1 and development on Windows and macOS. The strict real-child probe then
stopped before spawning because `remotes::install_version()` removes
`RemoteType` metadata. This was a CI provenance assumption, not a lifecycle
failure ([remotes implementation](https://github.com/r-lib/remotes/blob/main/R/install-version.R)).

Run [40310186089](https://github.com/menshikovs/termr/actions/runs/40310186089)
created four jobs. The Ubuntu, Windows and macOS logs show the attempted direct
CRAN archive download failed with `cannot open URL`; the baseline package was
therefore absent and compatibility tests did not run. The Ubuntu consumer job
failed with pytest exit 4 because its clean checkout lacks
`tests/test_codex_launcher.py`.

Commit `b7d2b16cd2e54850bcfe71b264ee1625bd9f1579` changed the baseline fetch to
`install.packages()` from the named CRAN repository index. Run
[40311322090](https://github.com/menshikovs/termr/actions/runs/40311322090)
confirmed that CRAN 1.0.1 downloaded and installed on all three platforms, but
the post-install assertion incorrectly required `RemoteType=standard`. Base
`install.packages()` records `Repository=CRAN` without `RemoteType`, so all
three jobs stopped before contracts or lifecycle tests.

Commit `be8f2ef17c3fb87f07604eb81ab3f1836faead70` keeps the exact version and
`Repository=CRAN` checks, and accepts absent `RemoteType` while rejecting a
present non-standard value. In [run 40311845330](https://github.com/menshikovs/termr/actions/runs/40311845330),
all four jobs started. Windows and macOS completed successfully. Ubuntu
completed its CRAN and development contracts and real-child baseline probe, but
its lifecycle suite had the single escalation-timing failure detailed above.
The consumer job failed because the launcher test path is absent from public
`main`. These results provide real subprocess evidence on all three platforms
and establish shared CRAN 1.0.1 compatibility on all three; they do not yet
establish a clean all-platform lifecycle pass.

The report-only commit `319d4c6f6ea31bc8bd0529306f8187b7f604326e` triggered
[run 40312594293](https://github.com/menshikovs/termr/actions/runs/40312594293),
which created four jobs. Windows and macOS passed again, and the consumer job
failed again on the missing public test path. At 2026-10-26 11:15:31 UTC, the
Ubuntu job was still in `setup-r-dependencies`; it had not rerun the lifecycle
suite.

Commit `3a16a399e670c10a9efc99ca8556b93236a55858` triggered
[run 40313778899](https://github.com/menshikovs/termr/actions/runs/40313778899),
which completed all four jobs. Windows and macOS passed the shared contracts,
the CRAN real-child probe and their applicable lifecycle tests. Windows
reported the same two explicit Windows skips. Ubuntu passed the shared
contracts and CRAN real-child probe, then failed only the lifecycle assertion
at `test-worker-lifecycle.R:219`: elapsed time was 0.054 seconds versus the
fixture's 0.100-second minimum. The logs contain no child-side acknowledgement
or escalation-reason diagnostic. Therefore they cannot distinguish a child
that exited on SIGINT from an early escalation; the prior test itself only
assumed that the child ignored the interrupt. This was an inconclusive test
oracle, not evidence of a worker defect. The new test fixture and private
diagnostic below are pending a hosted rerun.

The pending correction removes the minimum-elapsed assertion. The escalation
fixture now prints an acknowledgement from its interrupt handler and keeps
running; the test checks that it is still alive, then checks a private
monotonic timestamp recorded only when the grace-deadline branch force-kills
it. Separate tests cover a prompt cleanup handler and a child released to exit
naturally after cancellation was accepted. This adds no public API and changes
no cancellation defaults or behavior. On the local Windows sandbox,
`Rscript -e "testthat::test_local('.', filter = 'worker-lifecycle', reporter =
'summary')"` passed the runnable expectations; process tests were skipped
because the environment blocks processx pipes. A hosted rerun is required for
the real-process assertions.

The consumer failure in runs 40311845330, 40312594293 and 40313778899 is an
unpublished-test blocker. The current public R-Knowledge-MCP `main` is
`8f01870558263283ba197dc215d0f1ab5ad864af`. The branch listing contained 34
public heads; recursive tree inspection found no launcher-test file on any of
them. The 25 public pull-request file lists likewise contained no
`tests/test_codex_launcher.py` (or equivalent launcher test path). No public
commit containing the referenced pytest tests was located, so the tests cannot
be run unmodified against either package version. The workflow now pins the
inspected `main` commit; it retains the strict test invocation and does not
substitute unrelated tests. This consumer comparison remains unresolved until
the consumer publishes its suite.

Commit `929fe298471aeeb93d38d2c10f764e6cce1b748e` triggered
[run 40315356760](https://github.com/menshikovs/termr/actions/runs/40315356760),
which created four jobs. All three platform jobs passed the 32-expectation
CRAN and development contracts and the CRAN real-child probe. The consumer job
again failed because the pinned source lacks `tests/test_codex_launcher.py`.
The first deterministic-test attempt was itself invalid: the fixture slept for
60 seconds between signal checks. Ubuntu did not produce the signal-handler
acknowledgement before the grace deadline. macOS and Windows reached the
handler, but the natural-exit test also slept for 60 seconds before checking
the release file; both were killed by escalation instead of exiting naturally.
Their diagnostics recorded `cancel_escalated=TRUE` and exit status `-9` on
macOS and `15` on Windows. These failures identify fixture synchronization
defects, not a confirmed worker regression. The corrected fixtures use a
20-millisecond cooperative polling loop and the natural-exit test releases the
child immediately after cancellation is accepted. That correction is pending
the next hosted run. The original 0.054-second run still has no recorded
termination reason; the corrected deadline test is intended to establish it.

`actionlint` was not installed. A local `go install` attempt failed because
the build network was blocked (`proxy.golang.org` connection refused) and Go's
telemetry path was not writable. PyYAML parsing and structural checks passed
for the preserved Ubuntu/macOS/Windows matrix, step-level `runner.temp`
contexts, isolated CRAN/development libraries, strict real-process probe, and
`pull_request` trigger. Manual review against GitHub's context table found no
other unsupported context placements. This static validation is not a
substitute for the actual runs linked above.

| Platform/job | CRAN 1.0.1 and development contract | Real-child baseline probe | Lifecycle suite | Classification |
|---|---|---|---|---|
| Ubuntu | Pass / pass (32 expectations each) in 40313778899 and 40315356760; CRAN probe passed in both | Pass in both runs | Run 40313778899 failed the 0.100s minimum (actual 0.054s); run 40315356760 failed the handler acknowledgement and natural-exit fixture | No confirmed implementation defect; corrected short-polling fixture pending. Original termination reason unresolved |
| Windows | Pass / pass in runs 40311845330, 40312594293, 40313778899 and 40315356760; CRAN probe pass | Pass in all four runs | Run 40315356760 failed the natural-exit fixture: its 60s sleep caused escalation (`exit_status=15`); 2 explicit Windows skips | Test-fixture defect confirmed; corrected release synchronization pending. Two POSIX signal cases remain unsupported on Windows |
| macOS | Pass / pass in runs 40311845330, 40312594293, 40313778899 and 40315356760; CRAN probe pass | Pass in all four runs | Run 40315356760 failed the natural-exit fixture: its 60s sleep caused escalation (`exit_status=-9`); no skips | Test-fixture defect confirmed; corrected release synchronization pending |
| Ubuntu R-Knowledge-MCP | Package installs succeeded in 40315356760; test source pinned to `8f01870558263283ba197dc215d0f1ab5ad864af` | Not applicable | No tests ran; pytest exit 4 because the pinned consumer revision lacks the requested file | Unresolved: consumer tests are not present on public branches or PRs |

The [R-CMD-check workflow](https://github.com/menshikovs/termr/actions/workflows/R-CMD-check.yaml)
has push filters for `main`, `master` and `develop-*`, plus an unfiltered
`pull_request` trigger. No draft pull request could be created from the
available GitHub connection: repository write APIs returned HTTP 403
`Resource not accessible by integration`, the browser session was signed out,
and no GitHub CLI is installed. Therefore there is no feature-branch R-CMD-check
run. A draft PR from this branch should trigger its matrix: Ubuntu release,
oldrel-1, R 4.1 and devel; macOS release; and Windows release. The dedicated
[worker lifecycle workflow](https://github.com/menshikovs/termr/actions/workflows/worker-lifecycle-compatibility.yaml)
runs real child probes and lifecycle tests on all three operating systems.
The Ubuntu termination reason, consumer suite availability and feature-branch
R CMD check remain open.

## K. Breaking-change assessment

1. **Existing functions removed or renamed?** No.
2. **Existing arguments removed or reordered?** No. Added arguments are
   trailing and defaulted.
3. **Existing defaults changed?** No. cancel, app shutdown, supervision,
   timeout, ownership and callback defaults remain unchanged.
4. **Did synchronous methods become asynchronous by default?** No. Only
   request_cancel and explicit worker_grace use the async route.
5. **Did event or callback semantics change?** No for existing natural exit,
   failure, timeout or default cancellation. The opt-in async path emits one
   existing worker.cancelled event and no completion/error/exit callback.
6. **Did existing process cleanup become weaker?** No change to default
   cleanup_tree or default app/widget cancellation. New parent supervision is
   opt-in and its direct-child/descendant limitations are documented.
7. **Were new mandatory dependencies introduced?** No. The existing processx
   dependency provides supervision when supported; the opt-in errors on an
   older processx version without the constructor option.
8. **Were existing application tests affected?** The new tests do not remove or
   weaken existing tests. All 50 Unicode renderer failures, the screen
   out-of-buffer error, and the two database warnings reproduced identically
  against CRAN 1.0.1 in the prior Windows comparison. The dedicated hosted
  runs now exercise real processes on all three platforms; Windows and macOS
  pass their applicable lifecycle cases, while Ubuntu has one unresolved
  escalation-timing failure. No feature-branch R CMD check has run.
9. **Is migration required?** No. Existing applications retain their behavior
   without code changes.
10. **Is this safe for a backward-compatible CRAN update?** Not yet. The
    shared API contract passes against CRAN 1.0.1 and development on all three
    operating systems. Windows and macOS lifecycle suites pass; Ubuntu has one
    unresolved escalation-timing failure. Feature-branch R CMD check and the
    external consumer comparison are still unverified. Processx supervision's
    identity and descendant limits remain explicit.
