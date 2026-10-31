"""Build the E-FIX report set exclusively from fresh e-fix evidence."""
from pathlib import Path
import csv,json,statistics,datetime
root=Path(__file__).resolve().parents[2]
out=root/'audit-results/real-world-apps/e-fix'
def read(path):return json.loads((out/path).read_text())
def table(headers,rows):
    return '| '+' | '.join(headers)+' |\n| '+' | '.join(['---']*len(headers))+' |\n'+''.join('| '+' | '.join(map(str,row))+' |\n' for row in rows)
def write(name,text):(out/(name+'.md')).write_text('# E-FIX — '+name.replace('-',' ').title()+'\n\n'+text.strip()+'\n',encoding='utf-8')
windows=read('proof-windows/terminal-gates/results.json')
wsl=read('proof-wsl/terminal-gates/results.json')
web_w=read('proof-windows/browser-gates/gates.json');web_l=read('proof-web-wsl/gates.json')
assert all(x['status']=='PASS' and x['start'] and x['render'] and x['interact'] and x['shutdown'] and x['exit_code']==0 for x in windows+wsl)
assert all(x[key]=='PASS' for x in [web_w,web_l] for key in ['start','render','interact','integration','shutdown'])
for path in ['core-windows.exit','core-wsl.exit',
 'final-check-windows/build.exit','final-check-windows/check.exit','final-check-wsl/build.exit','final-check-wsl/check.exit',
 'proof-coverage.exit','proof-windows.exit','proof-wsl.exit','proof-web-wsl.exit']:
    assert (out/path).read_text().strip()=='0',path
api_w=read('proof-windows/api-summary.json');api_l=read('proof-wsl/api-summary.json')
coverage=read('proof-coverage/apps-summary.json')
lint_w=read('proof-windows/lint-summary.json');lint_l=read('proof-wsl/lint-summary.json')
for platform in ['windows','wsl']:
    for app in ['showcase','analytics','monitor']:
        runtime=read(f'proof-{platform}/terminal-gates/{app}/runtime.json')
        loaded={item['package']:item for item in runtime['packages']}
        assert loaded['termr']['loaded'] and '/.deps/current-' in loaded['termr']['namespace_path'].replace('\\','/')
        assert runtime['utf8'] is True
        if app=='showcase':assert loaded['inkr']['loaded']
        if app=='monitor':assert loaded['mirai']['loaded'] and loaded['nanonext']['loaded']
for browser in ['proof-windows/browser-gates/browser-results.json','proof-web-wsl/browser-results.json']:
    assert any(x['case']=='Unicode-source-label' and x['status']=='PASS' for x in read(browser)['checks'])
preservation=read('preservation.json')
gates=table(['App','Start','Render','Interact','Integration','Shutdown'],[
 [app,*['PASS']*5] for app in ['Showcase','Analytics TUI','Analytics Web','Task Monitor']])
commands='''```powershell
$R = 'C:/Program Files/R/R-4.6.1/bin/Rscript.exe'
& $R integration-apps/run.R --app=showcase --mode=terminal
& $R integration-apps/run.R --app=analytics --mode=terminal
& $R integration-apps/run.R --app=analytics --mode=web
& $R integration-apps/run.R --app=monitor --mode=terminal
```
Run from the checkout root in VS Code **Terminal → New Terminal**. A TUI paints
that terminal rather than opening a separate window. Web mode prints its URL;
open that URL in a browser (automatic browser launch is intentionally disabled).
From any working directory on Windows:
`& 'C:/programming_pj/r_textualize/integration-apps/launch.ps1' -App showcase`.
The launcher was itself run in a native Windows PTY from the system Temp directory;
the interface rendered and q exited0 (`launcher-real-pty.json`).'''
write('ROOT-CAUSES',f'''
The user's reported symptom was “the interface did not open”, without an error
message or a specified mode. **The original root-directory startup failure was
not reproduced in this environment.** Before changing application code, all
three documented TUI commands rendered and accepted input in Windows ConPTY and
WSL PTYs. The original web entrypoint also rendered real Plotly/ggplot2 in Chrome.
Fresh `before-windows`, `before-wsl`, `before-web-windows` logs/runtime metadata
retain that evidence. This does not disprove the user's observation or identify
their particular VS Code launch context. Prior Phase E reports were not used as
proof of current functionality.

Confirmed defects/gaps, with failing-first evidence:

| Issue | Cause | Fix |
| --- | --- | --- |
| Startup outside repository cwd fails | run.R sourced bootstrap by relative cwd before resolving the project | Resolve entrypoint/project root, then source absolute bootstrap and restore caller cwd |
| Corrupt Windows Unicode labels | Unsupported inherited C.UTF-8 settings left R in locale C; app source used native encoding | Select supported UCRT UTF-8 LC_CTYPE inside Rscript and source app/helper files explicitly as UTF-8 |
| Empty Analytics shows stale chart | Table was cleared but chart stayed bound to nonempty history | Unbind/clear chart on empty, rebind on recovery; empty samples remain gaps |
| Monitor Enter does nothing | No datatable.row_activated handler despite the UI promise | Wire the documented event to task details |
| Monitor details omit result | selected_row() supplies an index, and the original dialog showed str(index) | row_data(index), locate the retained task and show its actual result/error |
| Different launch/test code paths | Default bootstrap used pkgload; old automation forced TERMR_USE_INSTALLED=1 | One current installed library with source/payload/R-platform fingerprints; reject stale/global fallback |
| Alt key delivery varies in native ConPTY | Some real native runs did not deliver Alt+S after F2, while WSL did | Visible F11/F12 alternatives; retain Alt aliases; no core input rewrite |
| Error-hook cleanup/exit semantics | Unhandled global error hooks can run before on.exit/finally-only unwinding; a returning diagnostic hook produced exit0 | Catch the condition at the app boundary, clean up, then rethrow; diagnostic hook preserves exit1 |

`failing-first-verified.log` has six failed expectations and exit1 before the
application fixes. Visual review later caught corrupt Windows Unicode labels
missed by numeric/DOM-only assertions. `unicode-before` is an additional real
browser failing-first run (exit1). Corrected proof now requires literal Tokyo
characters in both browser and native terminal output. The first draft test also contained an invalid processx env
vector; that harness error was corrected before the verified failing-first run.
The latest app suite has115 passing expectations per OS. No core defect was
confirmed or patched; all core/H1/H2/H3 hashes match the E-FIX starting snapshot.
''')
write('INVALID-API-CALLS',f'''
No nonexistent exported function had to be invented or substituted. The material
API misuse was the **return contract**: DataTable$selected_row() returns a row
index/source key, not row data. The original details dialog displayed that index;
an interim repair that treated it as a list failed with `$ operator is invalid
for atomic vectors`. Current code uses row_data(index), then the actual task's
public info()/result() methods. Before/after regression logs retain the failure.

Static installed-API audit:

{table(['Platform','Namespace calls','Invalid namespace calls','Resolved method calls','Invalid methods'],[
 ['Windows',api_w['calls'],api_w['invalid'],api_w['resolved_method_calls'],api_w['invalid_methods']],
 ['WSL',api_l['calls'],api_l['invalid'],api_l['resolved_method_calls'],api_l['invalid_methods']]])}

`namespace-calls.csv` records file, expression and actual installed formals for
termr/shiny/ggplot2/plotly/mirai/nanonext/inkr calls. `method-calls.csv` checks
statically resolvable app/view/table/chart/stream/pool receivers. The summary
records real constructor classes and public method signatures; selected_row is
integer while row_data is a list. Dynamic owner callbacks are not falsely claimed
to be completely statically resolved: actual constructor, headless, PTY, browser
and worker tests cover their runtime contracts.

The documented on(type, function(event, app) ...) overload is valid even though
handler is a formally missing argument. The initial generic required-argument
checker falsely flagged two such calls; the audit now recognizes that documented
overload. Events cell_changed, row_activated, tabs.changed and chart selection
were checked against current documentation and actual emitted events. No
termr::: or private R6 access was added. App APIs are experimental where noted
in docs/stability.md; these applications are not new stable exports.

Evidence: `proof-windows/api-summary.json`, namespace/method CSVs there,
and `proof-wsl/`. These are new E-FIX runs against current-* installed builds.
''')
write('APPLICATION-FIXES',f'''
The existing three applications were repaired in place.

- run.R resolves its own root independently of cwd and keeps the same CLI modes.
- App/helper files are sourced explicitly as UTF-8. Windows bootstrap repairs
  only this process's non-UTF-8 LC_CTYPE to the supported UCRT locale before
  parsing. User/system settings and other locale categories are untouched.
  Correct Unicode is asserted in actual terminal and browser output.
- bootstrap.R loads only `.deps/current-windows/termr` or `current-linux/termr`.
  `source-manifest.R` and `install-current.R` stamp source and installed payload,
  version, R minor and platform; missing/stale/modified builds fail explicitly.
  No implicit install, pkgload fallback, global overwrite or version bump occurs.
- Workbench retains filtering/sorting, typed local editing, A4 and five charts.
  F11 source/F12 charts avoid the observed native Alt delivery issue. Actual
  cell-changed and chart-tab telemetry makes native assertions observable.
- Analytics TUI empties both table and chart, and reconnects its chart binding
  when data returns. Both TUI and web use analytics_model; separate processes
  are not falsely claimed to share one in-memory stream. Web views within a
  server share one frame/model, with existing Plotly proxy helpers.
- Monitor Enter now opens details and displays the real completed result.
  Closure diagnostics check pool/transport/source state and subscriptions;
  optional telemetry records creation-time-aware descendant identities.
- The terminal owner catches errors/interrupts, performs cleanup, then rethrows
  the original condition. Active-task crash tests verify this behavior.
- launch.ps1 provides a concrete Windows entrypoint from any directory.

{commands}

Reinstall after package source changes only:
`& $R tools/integration/install-current.R`. Current builds are already installed
for both tested platforms. Source R, DESCRIPTION, NAMESPACE, man and user H1/H2/H3
tests were not changed. Complete changed-file evidence is `preservation.json`.
''')
write('REAL-EXECUTION',f'''
{gates}

All five mandatory gates pass for the tested Windows/WSL execution paths. This
matrix is derived from new entrypoint results, not test-count inference or old
Phase E reports. Normal processes exit0; controlled fatal callback tests exit1
and count as separate expected-failure recovery tests.

{commands}

| Evidence | What actually ran |
| --- | --- |
| proof-windows/terminal-gates/ | Actual run.R in native Windows ConPTY, installed current-windows package |
| proof-wsl/terminal-gates/ | Actual run.R in POSIX PTYs, installed current-linux package, stty restored |
| proof-windows/browser-gates/ | Actual web command + Windows Chrome; shared values and live Plotly traces |
| proof-web-wsl/ | Actual WSL R web command + Windows Chrome through loopback forwarding |
| active-crash-windows/ and active-crash-wsl/ | Real long task submitted, callback failure, owner closed, observed owned PIDs stopped |

Every terminal case retains stdout.log, stderr.log, result.json, events.jsonl and
runtime.json with R/package versions and namespace paths. Error cases additionally
retain traceback.txt. Normal cases have no traceback because no error occurred.
The Windows wrapper redirects stderr while leaving real console I/O attached.

Workbench native actions include dataset/source/theme, filter, native modal edit
to12.5, A4 value/pipeline, chart selection, all five chart tabs, resize and quit.
Analytics performs sample/source/empty operations with visible changes. Monitor
performs real completion/result/failure/cancel/disconnect/reconnect and shutdown.
`owned-cleanup.*.log` verifies creation-time-aware descendant PIDs after process
exit; pool/source/transport closure is independently asserted. Final global R
process snapshots complement those scoped checks; no unrelated process is killed.
''')
write('E2E-TEST-AUDIT',f'''
Previous Phase E reports were excluded from gate decisions. Reused scripts were
read, repaired where necessary and executed again into e-fix/ directories.

The earlier tests did use real renderers/workers, but had material blind spots:
default startup loaded source through pkgload while automation selected an old
isolated installed build; no fingerprint tied that installation to the checkout.
This was a provenance gap, not proof that stale package code caused the user's
particular startup symptom. A diagnostic R_PROFILE_USER records paths and errors;
it does not source a different app. Manual launcher execution also used the
ordinary profile path. Numeric/DOM browser assertions originally missed corrupt
Unicode labels; final assertions require the literal Unicode label as well.
Many tests called application constructors rather than the CLI. Chart assertions
often checked only screen height; theme/source flags could not prove displayed
data. No test pressed Enter and asserted real task result text, nor asserted that
empty cleared the chart. App-level error-to-notification handlers can keep a
process alive despite a failed action, so exit0 alone is inadequate.
The integration-apps directory and its tests are excluded from the package
tarball. An ordinary R CMD check therefore does not execute these applications
at all; it must never substitute for their separate startup/interaction gates.

Current layers:

1. Installed export/formal/method audit and recorded real return classes.
2. Missing/stale/tampered-build negative controls and cwd startup regression.
3. Real headless renders, data/order/edit assertions and five distinct numeric
   chart bodies, not just nonempty title/screen dimensions.
4. Actual documented entrypoint under native ConPTY and POSIX PTYs, bounded
   first-frame/state waits, stderr and exit validation.
5. Real keyboard operations with screen changes and semantic events.
6. Invalid edits, empty/recovery, failed/cancelled tasks and controlled crash.
7. Pool/transport/source/subscription cleanup and independent observed PID checks.

The new diagnostic error hook initially exposed two harness pitfalls: quit() can
bypass unprotected owner unwinding, while returning from options(error=...) can
make Rscript exit0. The app now catches/cleans/rethrows before the hook; the hook
captures traceback and preserves exit1. Failed exploratory logs remain retained.

WSL DrvFS sometimes returned ENODATA(61) while reading an actively appended JSONL
journal. A traceback located the failure in Python file.read, not the application
or recorder. event_log.py retries only EAGAIN/ENODATA/ESTALE reads, at most5 times
with10ms gaps, logs retries, and raises persistent errors. It never repeats app
actions or whole scenarios. This corrects an observability race rather than
silently converting application failures into passes.

Unified command: `Rscript tools/integration/run-all.R --mode=api,gates,unit,process`.
Windows gates include Chrome. Linux terminal gates run directly; the runner
explicitly tells users to invoke the separately verified Windows browser bridge
for WSL Shiny rather than falsely claiming a Linux browser-engine test.
''')
write('WINDOWS-WSL',f'''
| Check (fresh E-FIX run) | Windows R4.6.1 | WSL Ubuntu R4.5.2 |
| --- | --- | --- |
| App testthat |115 PASS,0 fail/error/skip/warn |115 PASS,0 fail/error/skip/warn |
| Full core testthat |17,238 PASS,56 SKIP,0 fail/warn |18,736 PASS,2 SKIP,0 fail/warn |
| R CMD build/check |exit0 / Status: OK |exit0 / Status: OK |
| Real terminal |Native ConPTY all three apps PASS |POSIX PTY all three apps PASS |
| Shiny browser |Windows R server + real Chrome PASS |WSL R server + real Windows Chrome PASS |
| Processx / analysis |New runs PASS; see run-summary.json |New runs PASS; see run-summary.json |

Package metadata remains1.0.1 on branch2.0-termr. Actual namespace paths in every
runtime.json are current-windows/termr or current-linux/termr after the fix;
baseline pre-fix records show the different pkgload source path. Fresh installs
come from the current checkout, not the earlier H3 archive. mirai2.7.3 is used
with nanonext1.10.3 on Windows and1.10.4 on WSL; inkr is0.1.0. Browser dependencies
and paths are recorded per web process. Pywinpty3.1.2 was installed only into the
project's ignored Python directory, using a binary wheel. No global package,
core dependency, version, Git index or branch was changed.

Windows inherited unsupported LC_*=C.UTF-8 categories and emitted startup
warnings before app code. The original process fell back to locale C, which
corrupted Unicode when external app files were read with native encoding. Final
bootstrap selects supported .UTF-8 for LC_CTYPE in the R process and reads files
with explicit UTF-8. Actual final runtime.json records utf8=true; native and web
assertions require Tokyo characters. No system/user setting is edited. Check
shells clear invalid inherited variables before R startup; raw normal runs retain
startup warnings emitted before bootstrap. The earlier bad-locale lintr failure
is retained; the final proof scan runs after process-local normalization.
WSL ran C.UTF-8 normally. No blanket Unicode success is inferred from ASCII UI.
Windows absent optional typed packages remain absent and their core paths skip;
those skips are not successes. R CMD check uses --no-manual --no-build-vignettes
and _R_CHECK_FORCE_SUGGESTS_=false; PDF/manual/vignette validation is not claimed.

`preservation.json` verifies all initial615 files still exist, only scoped
application/tool files changed, core/man/API/H1/H2/H3 bytes remain unchanged,
Git index/HEAD remain unchanged, and both current source archives match374
R/man/test/metadata inputs. Applications/runtime/audits are excluded from builds.
git diff --check exits0; pre-existing CRLF advisory messages are retained.
''')
write('SHINY-BROWSER',f'''
Both web paths pass all gates: native Windows R server and WSL R server, each
tested with real Chrome via Playwright. This is not an HTTP-start-only test.
`proof-windows/browser-gates/ and proof-web-wsl/browser-results.json` records actual Plotly trace arrays, CPU formula
agreement within1e-10, source identity reset, empty clearing, NA/NaN gaps, loaded
ggplot image, stable widget DOM identity and absence of Shiny output errors.
No page/console/HTTP errors were observed in these final browser runs.

The app uses one model, receiver and cached frame per server, one producer and
one Plotly construction per session. Data changes use the existing example's
acknowledged proxy helpers. Four browser sessions were opened/closed per run.
`gates.json` captures sessions0, observers0 and producer_observers0 after owner
shutdown; no stale receiver lease was accepted as successful cleanup.

Commands: documented `--app=analytics --mode=web` starts the actual server;
`entrypoint-browser.R` drives that command, browser and graceful stop. Run its
`--wsl-server` option from native Windows R for the WSL-server/Chrome bridge.
Raw stdout/stderr, runtime package paths, lifecycle events, browser results and
`analytics-browser.png` are in both web-final directories. Screenshots were
reviewed for visible ggplot/Plotly/table/snapshot content.

Browser controls change only demonstration data. The server does not hold or
control a running TUI, send terminal keys, change terminal focus or implement a
new WebSocket protocol. Terminal and web modes in separate processes instantiate
the same model code but are not claimed to share process-local mutable memory.
These tests use Windows Chrome; no Linux-native, macOS, Safari or Firefox engine
certification is implied. A single lines-only Plotly sample has no line segment;
the final screenshots contain several actual samples.
''')
write('MIRAI-NANONEXT','''
The actual Monitor entrypoint constructs termr's real mirai pool and nanonext
publisher/subscriber. No task completion/progress or IPC payload is mocked.
Native keyboard tests submit the real CPU workload, await completion, press
Enter and assert the worker's chunks/result text, trigger a real error, cancel
a long task, disconnect/reconnect and observe the receiver return to live.
The app uses OS-assigned loopback ports and bounded history/pending limits.

Evidence: terminal-gates/monitor/events.jsonl in final-runner-windows,
proof-wsl/terminal-gates/monitor/, normal stdout/stderr and runtime manifests. The details
event includes the actual result payload (sum and chunks), not a local synthetic
status assignment. Task transitions and transport sequence values come from
public pool/receiver APIs. Headless app tests independently verify task results,
failure text, cancel races, resubscription and active pool shutdown.

Normal and active-crash runs require closed=true, pool_closed=true,
transport_closed=true, source_closed=true and zero pool event subscribers.
Observed descendant identities are captured with PID and creation time, then
checked from a separate R process after the entrypoint exits:3 on Windows,
1 on WSL in the recorded runs. This is explicitly an observed descendant list,
not a claim that all backend internals expose public PID lists. Public pool
shutdown and final global process snapshots complement those checks.

`active-crash-windows` and `active-crash-wsl` submit a real long task before
Ctrl+E; expected exit1 follows cleanup, PID checks pass, and WSL stty restores.
Their traceback files identify the controlled failing callback. No unrelated
process-name kill is used. Failure cleanup targets only the harness's fresh
owned process tree/group. Real absent-native-package startup is separately
tested through library scope in the processx suite; no global uninstall occurs.
Long-duration native handle retention is not resolved or disproven by these
bounded shutdown tests.
''')
recordings=read('proof-wsl/recording/results.json')
record_table=table(['Application','Fresh recording'],[[x['app'],x['recording'].replace('audit-results/real-world-apps/e-fix/','')] for x in recordings if x['app']!='rtop'])
write('REGRESSION-TESTS',f'''
New `integration-apps/tests/test-e-fix.R` covers cwd-independent startup, clearing
an empty chart, Enter/result details, strict missing/stale/tampered installation
rejection, portable source/chart keys, real sorted row values and five distinct
painted chart bodies with numeric data. The verified failing-first run exits1
with six failed expectations. Current full app suites have115 passing
expectations on each OS, no fail/error/skip/warn. Their files and summaries are
`proof-windows/app-test-summary-windows.json` and `proof-wsl/app-test-summary-unix.json`.

`entrypoint-pty.py` launches the real CLI with TERMR_USE_INSTALLED unset, under
Windows ConPTY or POSIX PTY, captures first-frame bytes, performs real keyboard
operations and checks semantic/data events, exits and ownership cleanup. It
never substitutes a miniature independent app. `entrypoint-browser.R` launches
the actual web mode and asserts the live browser. Controlled error cases expect
exit1, so a falsely successful returning error hook fails the harness.

Fresh additional tools:

| Tool | E-FIX evidence/scope |
| --- | --- |
| processx |Ten cases on both OS, including actual headless app entrypoints, failure/timeout/owned child cleanup |
| Expect |Two independent real terminal smokes, keyboard and terminal restoration |
| tmux |Fresh isolated namespace; showcase/monitor pane capture, input and resize (legacy third case kept separately) |
| covr |{coverage['line_percent']:.4f}% of the three current app source files; HTML/XML/CSV/RDS in proof-coverage/ |
| lintr |Fresh scans,0 error diagnostics; substantial style debt retained; counts in proof-windows/ and proof-wsl/ |
| Rprof/profvis |Fresh actual startup/table/chart/Shiny/native workloads after functional gates, raw/summary/HTML artifacts |
| hyperfine |Fresh process startup/render/shutdown runs, warmup1/runs5; JSON in proof-windows/ and proof-wsl/ |
| asciinema |New real recordings below; no upload |

{record_table}

Coverage includes real controller/native operations; the identical worker body
runs uninstrumented in its separate R process and remains uncovered. Branch
coverage and fresh core covr are not claimed. Public API/source provenance and
real gates are separate from coverage percentage. Profiling preserves raw
Shiny profiles and a disclosed derived normalization for multiline debug labels.
Benchmark timings include setup/render/cleanup and overlapping validation load;
they are not a steady-state latency or performance-improvement claim.

Default lintr is not clean: Windows{lint_w['findings']} findings and WSL{lint_l['findings']},
mostly style; existing core diagnostics are separately labelled. Known ggplot
NSE names cpu/segment were checked against real browser rendering rather than
silenced with global-variable declarations.
''')
write('REMAINING-ISSUES','''
No mandatory gate is FAILED in the final tested matrix. No H4 work was started.
The following limits remain explicit:

- The exact initial “no interface” symptom from the user's unspecified VS Code
  launch context was not reproduced using the root commands in real terminals.
  The confirmed cwd failure is repaired; the launcher and documentation explain
  terminal-vs-Output and web URL behavior. This is not proof of a specific editor
  extension's execution host or of every terminal emulator.
- Alt combinations were inconsistent in native ConPTY. F11/F12 are the tested
  primary bindings, with Alt aliases retained; no speculative core driver patch.
- Unsupported inherited Windows C.UTF-8 locale variables still produce startup
  warnings before R code. Bootstrap now normalizes process-local LC_CTYPE and
  explicit UTF-8 source loading; final glyph assertions pass. System/user settings
  are untouched. This was tested on Windows UCRT R4.6.1; older non-UTF-8-capable
  Windows R sessions fail explicitly rather than silently corrupting labels.
- One WSL append-log read returned ENODATA. Bounded read-only retries are logged;
  persistent failures still fail the test. No whole-scenario automatic retry hides
  application failures. Earlier exploratory failing results remain retained.
- Static audit resolves documented namespace signatures and selected receiver
  aliases; it is not a complete proof of arbitrary dynamic R behavior. Runtime
  gates cover the implemented operations. Default lint style debt remains.
- App coverage excludes instrumentation of remote worker compute; branches/core
  covr were not remeasured. Five-run benchmarks under concurrent load are
  descriptive; historical Phase E performance/coverage is not reused as evidence.
- Long-running native handle retention, arbitrary networks, macOS, other browser
  engines and stress beyond these bounded cases are not certified. Current
  cleanup/PID results do not resolve the historically reported handle concern.
- Windows optional typed fixtures remain conditional; unavailable packages are
  reported and their core tests skipped. No absent integration is labelled passed.
- DESCRIPTION still says1.0.1. Fingerprints identify current development source;
  this is not a release or a metadata claim that2.0.0 was published.

The package core and H1/H2/H3 tests are byte-identical to the E-FIX start.
No commit, push, merge, reset, clean, release or unrelated overwrite occurred.
The prior Phase E artifacts remain historical and were not used to certify
current startup. See preservation.json and git-status-after.txt for the exact
scope. Working applications and current isolated installs are present locally;
no manual code repair is required before running the documented commands.
''')
(out/'gates.json').write_text(json.dumps(dict(status='PASS',apps=[dict(app=app,start='PASS',render='PASS',interact='PASS',integration='PASS',shutdown='PASS') for app in ['Showcase','Analytics TUI','Analytics Web','Task Monitor']],generated_at=datetime.datetime.now(datetime.timezone.utc).isoformat()),indent=2))
print(gates)
