"""Compose Phase E reports from retained, current-run evidence."""
from pathlib import Path
import csv,json,statistics,datetime
root=Path(__file__).resolve().parents[2]
out=root/'audit-results/real-world-apps'
def read(path):return json.loads((out/path).read_text())
def table(headers,rows):
    return '| '+' | '.join(headers)+' |\n| '+' | '.join(['---']*len(headers))+' |\n'+''.join('| '+' | '.join(map(str,row))+' |\n' for row in rows)
def write(name,text):
    (out/(name+'.md')).write_text('# Phase E — '+name.replace('-',' ').title()+'\n\n'+text.strip()+'\n',encoding='utf-8')
win=read('final-windows/run-summary.json');linux=read('final-wsl/run-summary.json')
assert all(x['status']=='PASS' for x in win['results']+linux['results'])
browser=read('browser-visual-final/browser-results.json')
life_w=read('runner-windows-final/lifecycle-results.json');life_l=read('runner-wsl/lifecycle-results.json')
core=read('coverage/core-summary.json');apps=read('coverage/apps-summary.json');func=read('coverage/function-summary.json')
preserved=read('preservation-results.json');legacy=read('rtop-comparison.json')
recordings=read('final-recordings/recording/results.json')
assert all(x['status']=='PASS' for x in recordings)
lint_w=read('runner-env-final/lint-summary.json');lint_l=read('runner-env-wsl-final/lint-summary.json')
packages={}
for platform in ['windows','unix']:
    with (out/f'packages-{platform}.csv').open(newline='') as file:packages[platform]=list(csv.DictReader(file))
package_rows=[]
for name in ['inkr','mirai','nanonext','shiny','ggplot2','plotly','processx','covr','lintr','profvis']:
    package_rows.append([name,*[next(x['version'] if x['available']=='TRUE' else 'absent' for x in packages[p] if x['package']==name) for p in ['windows','unix']]])
versions=table(['Package','Windows','WSL'],package_rows)
benchmark_rows=[]
for directory,platform in [('runner-windows-final','Windows'),('runner-wsl','WSL')]:
    data=read(directory+'/hyperfine.json')
    for result in data['results']:
        if 'measurements' in result:
            values=[x['time_wall_clock']['value'] for x in result['measurements']]
            name=result['name'];mean=statistics.mean(values);sd=statistics.stdev(values)
        else:name=result['command'];mean=result['mean'];sd=result['stddev']
        benchmark_rows.append([platform,name,f'{mean*1000:.1f}',f'{sd*1000:.1f}',5])
benchmark=table(['Platform','Scenario','Mean ms','SD ms','Runs'],benchmark_rows)
checks=table(['Check','Windows','WSL Ubuntu'],[
 ['Full checkout testthat','17,238 PASS / 56 SKIP / 0 FAIL / 0 WARN','18,736 PASS / 2 SKIP / 0 FAIL / 0 WARN'],
 ['Application tests','83 expectations / 0 FAIL / 0 SKIP','83 expectations / 0 FAIL / 0 SKIP'],
 ['Processx','10 cases PASS','10 cases PASS'],
 ['R CMD build/check','exit 0 / Status: OK','exit 0 / Status: OK'],
 ['Real terminal','Native attached-console NOT RUN','4 pexpect apps + 2 Expect + 3 tmux PASS'],
 ['Browser','Chrome/Shiny real browser PASS','Browser engine not rerun in WSL'],
 ['Lifecycle','100 start/stop + 1000 UI + 100 source/theme/chart','Same controlled workload PASS'],
 ['Profiles / hyperfine','PASS / PASS','PASS incl. rtop / PASS'],
 ['Coverage','Not rerun with covr on Windows','Core 79.04%, apps 92.07% line coverage']])
common_commands='''```sh
Rscript integration-apps/run.R --app=showcase --mode=terminal
Rscript integration-apps/run.R --app=analytics --mode=terminal
Rscript integration-apps/run.R --app=analytics --mode=web
Rscript integration-apps/run.R --app=monitor --mode=terminal
```'''
preservation='''The checkout remains `2.0-termr` at `1b10370d1df50e54a63706673b150feaf7b04889`.
No commit, push, release, version change or staging was performed. R source,
DESCRIPTION, NAMESPACE and man/ match the Phase E initial hashes. `.Rbuildignore`
adds only exclusions for `integration-apps` and the pre-existing `typescript`
terminal recording (the original recording was retained).

The final hash audit found three H2 test files differing from the initial
snapshot: two trailing-newline changes and a stream-backlog test rewrite in
`test-h2-contracts.R`. Their origin is not established. Current contents were
retained; exact initial bytes, SHA256 and diffs are in
`preservation-baseline/` and `preservation-results.json`. Therefore this report
does not claim that every initial file remained byte-identical: 564 of 568 did.
No core H1/H2/H3 implementation fixes were reverted. Both final tarballs were
checked against 374 current R/man/test/metadata inputs; generated DESCRIPTION
fields/DCF folding are accounted for. Applications, runtime data, audits and
the recording are absent from both 443-entry source archives.'''
write('EXECUTIVE-SUMMARY',f'''
Three working applications and opt-in automation are implemented outside the
package core. All final runner tasks passed on their applicable platforms.
One confirmed application shortcut defect was reproduced failing-first and
fixed. No new termr core defect requiring a code fix was confirmed.

{checks}

rtop's eleven fixture scenarios are identical between the genuine release
baseline and the candidate, including normalized screen text. Original upstream
tests and real Linux collectors pass against both. The candidate DESCRIPTION
still says 1.0.1; this is explicitly not a version 2.0.0 release claim.

Windows repeated native compute-profile creation retains approximately two OS
handles per cycle after warmup. A separate direct-mirai reproducer shows the
same trend without termr. This remains an open P2 optional-backend/H4 risk;
worker shutdown and stable RSS are not proof of leak-free native resources.
Native Windows attached-console behavior is not certified. lintr has style
debt (see LINTR.md), and branch coverage is unmeasured.

{common_commands}

On this machine prepend `& 'C:/Program Files/R/R-4.6.1/bin/Rscript.exe'` instead
of `Rscript` in PowerShell. Run commands from the checkout root. Full controls,
isolated dependencies and runner modes are documented in
`../../integration-apps/README.md`.

{preservation}

Evidence index: APPLICATIONS.md, E2E-TEST-MATRIX.md, RTOP-COMPATIBILITY.md,
COVERAGE.md, RESOURCE-LIFECYCLE.md, KNOWN-LIMITATIONS.md and H4-HANDOFF.md.
''')
write('APPLICATIONS',f'''
{common_commands}

| Application source | Behavior |
| --- | --- |
| integration-apps/01-termr-showcase/app.R | Data Workbench: cars/iris/typed fixtures, filter/sort/find/select, supported safe edits, local/lazy 10k switch, type metadata, A4 value/pipeline dialogs, five native charts, bounded stream, inkr styles and fallback |
| integration-apps/02-shiny-visual-analytics/app.R | Standalone TUI plus real Shiny/ggplot2/Plotly/table/status/read-only terminal snapshot sharing deterministic values |
| integration-apps/03-mirai-nanonext-monitor/app.R | Real local workers, controlled success/failure/cancellation, progress and results, bounded metrics transported through nanonext, disconnect/reconnect and shutdown |

New support files include `integration-apps/bootstrap.R`, `run.R`, two `.inkr`
stylesheets, application tests, legacy fixtures/driver wrapper, automation scripts
and `tools/integration/run-all.R`. Existing-file change intentionally made by
Phase E is `.Rbuildignore`; separately observed H2 test changes are documented
under WINDOWS-WSL.md. There are no new public exports or dependencies in DESCRIPTION.

Workbench: F2 dataset, Alt+S source, F4 theme, F5 filter, F6 edit modal, F7
selection, F8/F9 A4, F10 sample, Alt+C charts, Alt+T types, Escape data, q quit.
Sidebar inputs/buttons are keyboard reachable; below 70 columns it hides and
shortcuts remain. Custom unknown S3/vctrs columns follow read-only type handlers.
Fixtures are conditional: Windows lacks units/haven/bit64; WSL exercises them.
Charts summarize finite original dataset values; filtered-table chart linkage
is not claimed. Stream history 64 and chart max_points 64 bound memory.

Analytics terminal: F2 sample, Alt+S source, F4 empty, F5 nonfinite. Web uses its
own controls, not terminal keystrokes. Monitor: n/l/e/c/d/r/F5/q with task details,
progress and narrow-screen action tabs. All app owner cleanup is idempotent.
No new scheduler, binary protocol, custom unit system or C/C++ code was added.

Automated app tests, real headless subprocesses and PTY input validated these
behaviors. See TESTTHAT.md and PEXPECT-EXPECT.md for scope and evidence.
''')
write('RTOP-COMPATIBILITY',f'''
Upstream: https://github.com/menshikovs/rtop at
`0856d8c1dc33c0c9c7ca6bf0d94204349be56722`, clean isolated `upstream/` checkout.
Baseline: exact local Git tag v1.0.1 at
`79d6871d18f700197a31a17b7756c424c5ac7d66`, separately installed in
`.deps/baseline-linux` (also installed on Windows, where Linux collectors cannot run).
Candidate: current branch source, separately installed in `.deps/R-linux`.

`legacy-source.json` records provenance. Both packages report 1.0.1; the current
checkout was never relabelled2.0.0. Thus the unchanged upstream version gate
accepts this candidate already. `rtop-version-gate.patch` extends only the gate
to permit 2.0.0 in a separate compatibility copy; no upstream UI/module was edited.

```sh
Rscript integration-apps/legacy-rtop/run.R --library=baseline --mode=headless
Rscript integration-apps/legacy-rtop/run.R --library=candidate --mode=headless
python3 integration-apps/automation/pty-e2e.py --app=rtop --legacy-library=baseline
```

{table(['Scenario','Values equal','Screen equal','State equal'],[[x['scenario'],x['values_equal'],x['screen_equal'],x['state_equal']] for x in legacy['scenarios']])}

Only wall-clock HH:MM:SS is normalized. Original widgets, state, formatters,
keyboard bindings, refresh logic and resize behavior are used. Deterministic
collector substitution is confined to the wrapper and disclosed; terminal mode
delegates to real exported `run()`. Original upstream tests ran unchanged with
live `/proc` collectors for both libraries: exit 0, `rtop checks passed` in
`rtop-upstream-baseline.log` and `rtop-upstream-candidate.log`.

Baseline/candidate PTY, candidate tmux and fixture-only asciinema all pass.
`rtop-comparison.csv`, both RDS snapshots, `pty-baseline/results.json`,
`final-wsl/pty/results.json` and `final-recordings/recording/rtop.cast` retain
evidence. No API adapter beyond the optional version-gate copy was needed.
No incompatibility was hidden by rewriting rtop. Linux-specific collectors and
finite fixture coverage limit the compatibility conclusion.
''')
write('SHINY-GGPLOT-PLOTLY',f'''
The web application is real Shiny with ggplot2 rendering, two Plotly traces,
a numeric table, source/timestamp/status and a read-only `render_text()` snapshot.
One producer and one receiver are application-owned; sessions acquire leases
through existing termr Shiny APIs. One reactive frame feeds all views. Actions
explicitly poll the receiver after updating the model to avoid a delayed stale
frame. Source identities reset sequence, empty markers clear traces and NA/NaN
become gaps. Values are deterministic by source and sequence; timestamps are live.

Plotly uses the existing `system-monitor-live/visualization.R` example's bounded
ready/ack/proxy helpers, not a new transport protocol. `renderPlotly` builds once
per session; frame changes use proxy updates. The browser checks DOM identity,
CPU formula agreement within 1e-10, source reset, cleared data, gaps, loaded ggplot
image and absence of Shiny output errors. A single sample has no Plotly line
segment; the final screenshot intentionally contains six samples.

```sh
Rscript tools/integration/run-all.R --mode=browser --timeout=180
```

Chrome {browser['browser']} passed the real Playwright browser scenarios.
`browser-visual-final/browser-results.json` records no page/console/HTTP errors;
`analytics-browser.png` was visually reviewed. Four sessions close cleanly.
`browser-lifecycle.json` shows sessions 0, observers 0 and producer_observers 0
after application shutdown. While idle before owner close, the receiver retains
one suspended observer by design; treating it as a leak was a test-oracle error.

The browser never holds a running TUI handle and cannot change its focus, send
keys or execute its commands. Browser controls modify only demonstration data.
No pixel equivalence between ggplot2, Plotly and terminal charts is claimed.
''')
write('MIRAI-NANONEXT',f'''
The monitor uses public `termr_mirai_pool`, task handles, event subscriptions,
`termr_stream`, `termr_nano_publish` and `termr_nano_connect`. There are real R
worker processes and real loopback sockets, not mocked task results. OS-assigned
ports avoid assuming fixed-port availability. It shows jobs, progress, failure
text, results, throughput, history and transport states. App queue internals are
not inspected; pending-job/AIO counts are labelled for their actual public meaning.

The real workload computes square-root sums in chunks; a controlled failure is
raised at chunk 2, a long task supports cancellation. Five repeated cancel races
assert one terminal transition per task, and active shutdown verifies only newly
owned child handles (pre-existing runner supervisor children are excluded).
Disconnect closes the publisher; reconnect closes/replaces the receiver and
rebinds the chart. Histories cap 128, retained tasks 24, pending jobs 8.

Windows uses mirai 2.7.3/nanonext 1.10.3; WSL uses mirai 2.7.3/nanonext 1.10.4.
Actual success/failure/cancel/reconnect ran in application tests, subprocesses,
PTY/Expect/tmux and lifecycle loops. Missing-native-package startup was tested
in a separate normal-library scope, without uninstalling global packages.
`final-windows/process-results.json` and `final-wsl/process-results.json` retain
the ten process cases; app tests contain the task/socket assertions.

Owner shutdown unbinds charts, unsubscribes, closes receiver/publisher/streams
and pool. Worker counts return to their prior process baseline. An independent
Windows probe nevertheless shows about two retained OS handles per new compute
profile even using direct mirai without termr. This is an open P2 backend risk,
not a leak-free certification; see RESOURCE-LIFECYCLE.md and H4-HANDOFF.md.
''')
write('E2E-TEST-MATRIX',f'''
{checks}

Final reproducible runner invocations (checkout root):

```sh
Rscript tools/integration/run-all.R --mode=unit,headless,process,browser,lint --timeout=180 --out=audit-results/real-world-apps/final-windows
Rscript tools/integration/run-all.R --mode=unit,headless,process,legacy,pty,expect,tmux,lint --timeout=180 --out=audit-results/real-world-apps/final-wsl
Rscript tools/integration/run-all.R --mode=recording,lint --timeout=180 --out=audit-results/real-world-apps/final-recordings
```

The first command was run with native Windows R; the second/third inside Ubuntu
WSL. All final task exit codes are0 in each `run-summary.json`. Heavy lifecycle,
profiling, benchmarking and coverage are separate opt-in modes. `--app` focuses
apps, `--out` controls artifacts, `--timeout` is seconds per task. A missing POSIX
platform/tool yields an explicit SKIP; real task failure yields process exit 1.
`runner-skip/run-summary.json` demonstrates skip output; `runner-invalid.exit`
contains1 for invalid mode input. No ordinary R CMD check starts the demo apps.

PTY asserts semantic state plus terminal restoration; browser asserts actual
data/widget behavior. Headless success is never counted as terminal success.
Earlier harness/profiler/recorder failures remain in separate directories and
are classified in BUG-FINDINGS.md; final results do not erase those failures.
''')
write('TESTTHAT',f'''
Full checkout suites were run with `Rscript tools/dev.R test`, NOT_CRAN=true,
using platform-appropriate project/normal libraries. Windows: 17,238 PASS,
56 SKIP,0 FAIL/ERROR/WARN (`full-windows.log`, exit 0). WSL: 18,736 PASS,
2 SKIP,0 FAIL/ERROR/WARN (`full-wsl.log`, exit 0). These are current Phase E runs,
not copied H3 totals. Additional final app suites have 83 expectations each,
zero skips/failures/errors/warnings; see `final-*/app-test-summary-*.json`.

Application files: `test-showcase.R`, `test-analytics.R`, `test-monitor.R` under
`integration-apps/tests`. They validate source switching, typed edit/rejection,
unchanged attributes, find/selection/A4, chart selection/resize/history, themes
with and without inkr, Shiny frame agreement/widget reuse/lease cleanup, real
tasks/failure/cancel/socket reconnect and owned worker shutdown.

The saved failing-first showcase run exits1 with three expectations exposing
reserved-key collisions. After Alt+S/Alt+C bindings, focused and final full app
suites pass. The task-shutdown test now compares new children against a captured
baseline; a runner's pre-existing processx supervisor must not be killed by it.

Windows skips include unavailable bit64, units, haven, hms, sf, RSQLite and
dbplyr paths plus POSIX-only testing. WSL skips only opposite absent-package
branches (haven and inkr are installed). Installed-package checks additionally
skip four recipes excluded from the tarball: Windows check 17,227 PASS/60 SKIP;
WSL check 18,725 PASS/6 SKIP. Both check test suites have zero warnings/failures.
Exact skip locations remain in logs; no skipped workload is labelled passed.
''')
write('PEXPECT-EXPECT','''
`integration-apps/automation/pty-e2e.py` uses real POSIX pexpect terminals with
the installed candidate, UTF-8, 100x30 initial size and bounded semantic waits.
It drains output continuously (preventing a full PTY buffer from starving R),
and waits for observable state around Escape rather than relying on long sleeps.
It exercises arrows, Tab/Shift+Tab/Enter/Escape, fragmented CSI input, Unicode
search, dataset/source/theme/A4/chart selection, live tasks and reconnects.

Final `final-wsl/pty/results.json`: showcase, analytics, monitor and rtop PASS,
normal exit 0 and restored `stty -g`. `pty-baseline/results.json` separately
certifies the genuine baseline rtop path. `pty-crash/results.json` verifies
controlled Ctrl+E callback failure (expected exit 1) restores the terminal;
`pty-interrupt/results.json` verifies normal Ctrl+C exit 0/restoration after
focusing the chart (DataTable intentionally reserves Ctrl+C for copy).

Independent Tcl Expect 5.45.4 smoke tests run showcase and monitor with keyboard
input and restoration checks; a controlled timeout fixture is cleaned up using
only its owned PID. Final logs are under `final-wsl/expect/`, with both exit 0
in the runner summary. The pexpect module is4.9.0, Python 3.14.4.

The initial PTY harness failed because it did not drain output and assumed
Escape reached App while a cell editor consumed it. Those harness/oracle issues
were fixed; they were not termr rendering defects. Failure cleanup targets only
the newly spawned process group, first interrupt then bounded force-stop.
These Linux PTY results do not certify native Windows Console, SSH or RStudio.
''')
write('PROCESSX','''
Processx3.9.0 checks run on native Windows and Ubuntu WSL. Final ten cases PASS:
quiet successful exit; separate stderr; exit 7 preservation; bounded timeout;
owned grandchild cleanup; each of the three real app headless processes; explicit
missing-package diagnostic; actual monitor startup without project native
optionals. Outputs, stderr and `process-results.json` are retained in
`final-windows/` and `final-wsl/`.

`process-fixture.R` contains only controlled fixtures. Readiness is required
before inspecting an owned child's creation-time-aware ps handle. Process
cleanup uses processx's owned tree; no system-wide process-name kill is used.
No native backend is mocked in the three real app cases. Missing packages are
tested by separate child library paths, not a global uninstall.

Three harness errors were found and fixed: run() timeout is seconds while
process$wait() uses milliseconds; env overrides need `current` to retain the
Windows environment; streamed stdout must be concatenated without inserting
newlines between chunks. The last issue split `CHILD <pid>` on Windows and
made readiness falsely time out. Atomic fixture writes and correct buffer
assembly fix it. `process-windows-final`/earlier runner logs retain failures;
`process-windows-verified` and the final runner prove the corrected cases.

The unified runner limits task duration, captures stdout/stderr separately,
reports SKIP with a reason, returns nonzero for failure and records exit codes.
Windows process pipes required the managed sandbox's elevated execution path;
no global permission or package setting was changed.
''')
write('TMUX','''
`tmux-e2e.py` creates a fresh `tmux -L termr-phase-e-<uuid>` server namespace,
then runs real showcase, distributed monitor and fixture rtop applications.
It waits for startup, sends actual keys, resizes to42x18 and back to100x30,
captures pane text and quits normally. Shell-side before/after terminal-mode
comparison must write PASS. A finally block kills only that fresh namespace.

Final three cases PASS with cleanup=true in `final-wsl/tmux/results.json`;
pane captures and owned-session marker files are alongside it. Ubuntu tmux 3.6
was actually run. Windows tmux 3.6a-win32 was discovered but not used as a
substitute for native attached-console validation. No unrelated user session
or server was stopped.

Run `Rscript tools/integration/run-all.R --mode=tmux --timeout=180` in WSL.
The captures complement semantic app and pexpect assertions: a pane image alone
does not establish safe data edits or worker cleanup. No claim is made about
screen, arbitrary SSH clients or other terminal emulators.
''')
write('COVERAGE',f'''
covr 3.6.5 was actually run in Ubuntu. Core line coverage: {core['line_percent']:.4f}%.
Three application files: {apps['line_percent']:.4f}%. Raw RDS, public data.frame
CSV, Cobertura XML and local HTML reports are in `coverage/` (`core.html`,
`apps.html`, with `lib/` assets). Branch coverage is **not measured** by this
line-instrumented run; it is not inferred from assertion counts.

Core instrumentation uses normal Linux libraries, deliberately excluding the
project-only inkr/mirai/nanonext installations. Their unexecuted lines remain
in the denominator; no core file/function exclusion inflates the percentage.
Native cross-process R bodies cannot carry the parent's covr counter registry.
Normal tests independently exercise those real optional backends.

Application instrumentation does use real workers/sockets. Its worker body is
the identical uninstrumented `monitor_work` copy; its lines remain uncovered,
while controllers, UI and lifecycle are instrumented. This is explicitly not
coverage of a remote R process's CPU workload. Core/full test coverage and
application coverage have separate scopes and are not averaged together.

Function-label hit coverage from covr's exported `functions` field:
core {func['core']['hit_labels']}/{func['core']['function_labels']} = {func['core']['percent']:.2f}%;
apps {func['apps']['hit_labels']}/{func['apps']['function_labels']} = {func['apps']['percent']:.2f}%.
A distinct(file,function label) counts hit if any instrumented expression ran;
nested/anonymous/R6 labels may be grouped. This is entry/hit coverage, not full
function-path coverage. `*-functions.csv` and `function-summary.json` document it.

Commands: `bash audit-results/real-world-apps/run-coverage-wsl.sh` then
`python3 integration-apps/automation/coverage-functions.py`. Both coverage exit
files contain0. This single-platform coverage run is not a Windows covr claim.
''')
write('LINTR',f'''
Default lintr was run against {lint_w['files']} Phase E/critical-core R files (see actual JSON
file count), retaining style findings instead of reformatting prior user code.
Windows lintr 3.4.0: {lint_w['findings']} findings; WSL lintr 3.3.0.1:
{lint_l['findings']}. Both report zero `error` diagnostics. The runner's PASS means
the scan completed without error diagnostics, **not** a clean default-lint result.

{table(['Scope','Windows findings','WSL findings'],[[scope,lint_w['by_scope'].get(scope,0),lint_l['by_scope'].get(scope,0)] for scope in ['Phase E application/tool','pre-existing core (unchanged)']])}

Most new findings are quotes, long lines, commas, compact semicolon/brace/space
style and indentation. They remain explicit style debt. Existing unchanged core
findings are not new regressions. The two object-usage messages are ggplot2 NSE
bindings `cpu` and `segment` in `aes`, verified against the supplied data frame
and actual rendering; no meaningless globalVariables declarations were added.

`runner-env-final/lintr-findings.csv` and
`runner-env-wsl-final/lintr-findings.csv` contain every location/linter/message and
scope. `lint-summary.json` groups counts. Tool-version differences explain
small platform count differences. No parse-error or confirmed static-analysis
functional bug remains. Broad style cleanup is outside this integration phase;
the reports do not silently suppress or relabel those diagnostics as zero.
''')
write('RPROF-PROFVIS','''
Real Rprof workloads on both platforms cover application startup, DataTable and
event input, native stream-chart updates, Shiny reactive updates and real mirai
completion/nanonext traffic. WSL additionally profiles original rtop fixture
refresh in a separate candidate process. Rprof uses 10ms samples with memory
profiling; CPU/self/total CSVs, raw profiles, summary RDS and timing scope are in
`profiles-windows-final/` and `profiles-wsl-final/`. Both final runners exit 0.

`workbench-profvis.html` plus its local assets is a genuine profvis 0.4.0 workload,
saved without requiring Pandoc. `rtop-refresh.Rprof`/`rtop-refresh-total.csv`
capture the legacy path. Time includes setup/cleanup and lazy package/JIT costs;
these sampled profiles are diagnostic, not latency benchmarks. Worker compute
is in a different R process and not attributed to controller CPU.

An initial requested 5ms interval was clamped by this platform to 10ms; the final
script requests 10ms explicitly. A real Rprof/summaryRprof interoperability issue
also appeared: Shiny/Plotly debug call labels contain physical newlines and
break summaryRprof's memory parser. Raw `.Rprof` files are untouched. A separate
`shiny_updates-normalized.Rprof` joins only record-continuation lines; no samples
are dropped. `profile-summary.json` records the exact parser error, join count
and derived file on each platform. Other profiles parse directly.

Hot tables include termr layout/painting/event dispatch and Shiny/ggplot render
machinery as expected. No additional core performance rewrite was justified by
these short application profiles. Use H4 sustained loads to distinguish package
warmup, UI frame cost and backend/collector time before optimizing.
''')
write('HYPERFINE',f'''
Real external-process benchmarks use one warmup and five measurements, exit 0
throughout. Windows hyperfine 2.0.0 uses schema2 JSON; WSL 1.19.0 uses schema1.
Both original JSON formats are retained, not rewritten to hide version changes.

{benchmark}

App commands launch installed-candidate Rscript, create a headless app, render
an initial frame (`--steps=0`) and cleanly close it. Monitor includes real worker
and socket startup/teardown. These are whole-process CLI measurements, not
microbenchmarks of pure R calls, PTY response times or steady-state rendering.
rtop commands additionally execute eleven deterministic scenarios, so their
absolute times are not comparable with an app's startup-only scenario.

WSL candidate rtop mean is about 6.6% above genuine baseline in this short run.
The packages differ substantially before Phase E, and other validation jobs
overlapped; this is descriptive evidence, not a controlled regression attribution
or an improvement claim. Repeat on an idle same-platform machine with more runs
before setting a performance gate. Cross-platform wall times are not rankings.

Artifacts: `runner-windows-final/hyperfine.json`, `runner-wsl/hyperfine.json`,
stdout/stderr logs and `benchmark-scope.json`. Reproduce with
`Rscript tools/integration/run-all.R --mode=benchmark --timeout=180`.
''')
write('ASCIINEMA',f'''
Four local real-terminal recordings were created with asciinema 2.4.0 in WSL:

{table(['Application','Recording','Exit','Terminal restored'],[[x['app'],x['recording'].replace('audit-results/real-world-apps/',''),x['exit_status'],x['terminal_restored']] for x in recordings])}

Final unified recording runner exits0. Recordings demonstrate actual keyboard
actions and redraws, not generated animations or screenshots. The monitor uses
real workers and transport. rtop recording uses deterministic fixture collectors;
live user process/network data is never recorded. The cast headers/output were
scanned for user home paths, User001, Bearer/password/token markers and matched
none of those checks. This bounded deny-list is not a universal secret detector.
Nothing was uploaded or published.

Play locally: `asciinema play audit-results/real-world-apps/final-recordings/recording/showcase.cast`.
The adjacent JSONL markers and PTY logs supply assertions independently of the
recording. One earlier all-app recording hit transient errno61 for rtop; its
failed result remains in `recordings/results.json`. A standalone retry and the
final all-app recording passed; recorder portability remains an H4/tooling risk.
''')
write('BUG-FINDINGS','''
Counts:0 confirmed new core defects requiring a source fix;1 confirmed functional
application defect reproduced failing-first and fixed;0 known open P0/P1 in the
tested scenarios. Additional application integration refinements and harness
issues are separated from that defect count. One open P2 native backend resource
trend remains; absence of an orphan worker is not absence of all leaks.

| Finding | Class/severity | Reproducer/evidence | Resolution/status |
| --- | --- | --- | --- |
| APP-01 reserved shortcut collisions | Application/P2 | Focus DataTable then former F3/Ctrl+G shortcuts; `apps-failing-first.log` has 3 failed expectations and exit 1 | Alt+S source and Alt+C chart/focus; final83 app expectations pass on both OS and real PTY |
| INT-01 delayed frame after Shiny action | Application integration refinement | Existing periodic receiver initially delayed updates; testServer checks immediate frame agreement | Explicit public receiver poll in action callbacks; browser/testServer agreement pass; no core change |
| TEST-01 suspended receiver observer | Test-oracle error | sessions 0 but observer 1 until owner closes | Assert suspended lease lifecycle, then owner close→0 |
| TOOL-01 PTY output starvation/Escape | Harness | Saved initial PTY timeout; editor consumes Escape | Continuously drain output; semantic waits and focus handling; final4 PTY cases pass |
| TOOL-02 processx timeout/environment | Harness | Early process results fail/timeout | Correct seconds vs milliseconds; inherit current environment; all10 final cases pass |
| TOOL-03 fragmented stdout marker | Harness | Windows `CHILD` and PID arrived in separate reads | Concatenate bytes without injected newline; atomic fixture marker; owned cleanup passes |
| TOOL-04 multiline Rprof debug label | Profiler interoperability | Raw Shiny profile fails summaryRprof memory parser | Preserve raw; normalize continuations in derived copy; zero dropped samples; final profiles pass |
| TOOL-05 rtop recording errno61 | Recorder/environment transient | Earlier recording result FAIL | Separate retry and final all-app recording PASS; no silent retry relabeling |
| BACKEND-01 Windows native handle retention | Optional backend/P2 open |15 fresh profiles via direct mirai, pool and model in separate processes | Direct mirai alone reproduces ~2 handles/cycle after warmup; document for H4/upstream; no speculative core patch |
| ENV-01 unavailable Windows typed packages/console | Environment limitation | Package inventory and platform matrix | Honest SKIP/NOT RUN; WSL supplies corresponding supported tests |

Preventive app refinements (scrollable actions, preserving task cursor during
refresh, live timestamps, one-point ggplot handling and favicon) are not counted
as independently confirmed termr bugs. No new user-data eval/parse, scheduler,
protocol or API shim was introduced to hide a failure.
''')
write('FIXES','''
APP-01 root cause: workbench global bindings reused keys already consumed by a
focused DataTable (F3 find-next and Ctrl+G goto). Bindings moved to Alt+S and
Alt+C; chart activation also focuses its line chart. No DataTable default binding
was changed. Three failing-first expectations and exit 1 are retained; final
headless tests and real keyboard/PTy scenarios validate the fix on the public API.

The analytics app explicitly polls its shared receiver after browser actions,
so frame/table/snapshot/Plotly state updates in the same reactive flush. It uses
one cached frame and one widget per session; owner cleanup destroys observers.
Other app changes preserve cursor position when real task rows refresh, put
buttons in a scrollable tab for narrow screens, use current timestamps and omit
a ggplot line for a single point. A data favicon avoids a cosmetic browser404.

Harness fixes address buffer draining, modal Escape semantics, baseline-owned
process counting, processx timeout units/env inheritance and fragmented stdout.
Profiler normalization is confined to a derived artifact. These changes neither
weaken core assertions nor modify terminal input/worker backend behavior.

Code paths are in `integration-apps/` and `tools/integration/`; public R source,
NAMESPACE and man files remain unchanged relative to the initial hashes.
Observed H2 test differences are explicitly retained and archived, not attributed
to an invented core fix. Packaging exclusions keep demo dependencies, runtime
data and the pre-existing recording out of the distributable tarball.

No speculative fix was made for the Windows handle trend: direct mirai reproduces
it without termr, so causal/native ownership work is handed to H4. Both package
checks pass with no warning suppression/global-variable declarations.
''')
write('WINDOWS-WSL',f'''
Windows 11 build26100, native R4.6.1; Ubuntu 26.04.1 on WSL2, R4.5.2,
Linux6.18.54.1-microsoft-standard-WSL2. WSL commands explicitly selected Ubuntu
(the default distro is docker-desktop and unsuitable for these shell scripts).
Windows invalid inherited LC_* variables were removed in child launch shells;
WSL ran C.UTF-8. Python is3.14.4 on both platforms.

{versions}

Executable versions/paths and availability are in `tools-windows.json` and
`tools-wsl.json`. `packages-*.csv` preserve full final library paths;
`*-initial.csv` preserve discovery state. Missing optional web/native packages
were installed only into `.deps/R-windows`/`.deps/R-linux`; inkr 0.1.0 was installed
from the sibling source without modifying it. Baseline and candidate termr have
separate libraries. Windows Python Playwright 1.64.1 is under `.deps/python-windows`;
the existing Chrome executable was used. No global installation was performed.

Both R CMD build and check exit 0, `Status: OK`, using `--no-manual
--no-build-vignettes` (no PDF manual/vignette validation claim). `_R_CHECK_FORCE_SUGGESTS_=false`
permits unavailable optional packages; their actual test skips remain visible.
Neither platform reports WARNING/NOTE/ERROR in final00check.log. Windows
PowerShell redirected ordinary native stderr as NativeCommandError text in the
wrapper log; authoritative R exit/00check.log and test counts are retained.

Real Unicode/control/resize/restoration checks ran through Linux PTY/Expect/tmux.
Windows parser/headless tests passed, but no native attached-console run is
claimed. Browser tests used native Windows Chrome. No macOS/SSH/RStudio test ran.

{preservation}
''')
def resources(life):
    rows=life['samples'];chosen=[rows[0],rows[1],rows[10],rows[12],rows[-1]]
    return [[x['label'],f"{x['rss']/1024**2:.1f}",x['live_heap_mb'],x['children'],x['r_connections'],x['descriptors']] for x in chosen]
write('RESOURCE-LIFECYCLE',f'''
Both OS ran 100 application startup/shutdown cycles, 1000 keyboard UI actions,
100 source changes, 100 theme changes, 100 chart updates, 5 real worker-pool cycles
and 20 transport reconnects. Counters, history limits and zero owned subscribers
after close were asserted. These are finite controlled series, not an H4 soak.

Windows samples (ps descriptors API reports OS handles on Windows):

{table(['Checkpoint','RSS MiB','Live R heap MB','Child count','R connections','Handles'],resources(life_w))}

WSL samples:

{table(['Checkpoint','RSS MiB','Live R heap MB','Child count','R connections','FDs'],resources(life_l))}

Warmup allocations are distinct from retained growth: UI live heap stabilizes
across startup 10→100; OS RSS may retain allocator arenas after GC. Action/render
median/p95: Windows {life_w['render_action_seconds']['50%']*1000:.1f}/{life_w['render_action_seconds']['95%']*1000:.1f}ms;
WSL {life_l['render_action_seconds']['50%']*1000:.1f}/{life_l['render_action_seconds']['95%']*1000:.1f}ms.
These synchronous headless timings include event+layout+paint, not terminal I/O
or a production responsiveness SLA. Samples/quantiles are in lifecycle JSON/CSV.

Windows handles rise by roughly2 per repeated new compute profile after warmup.
`resource-probe.R` isolates direct mirai, termr pool and distributed model in
fresh processes,15 cycles each, GC and a short settle before each measurement.
Direct mirai alone rises 223→251 handles from cycle1→15, pool 256→284;
model settles to the same per-cycle trend after initial native initialization.
No additional workers remain; direct probe's one child is its prior supervisor
baseline. This is an open P2 optional-backend retention risk, not dismissed as
mere temporary allocation. Exact CSVs are in `resource-probes/`. Initial direct
probe lacked child R_LIBS and was terminated only by its verified owned PID;
the corrected timeout-bounded probe passes.

WSL file descriptors stabilize at 8 after native warmup. R connections remain 3
on both OS; no database was opened. Public subscription/transport diagnostics
are tested, but individual private App timers/caches are deliberately not
inspected. Browser shutdown independently reports zero sessions/observers/producer.
''')
write('KNOWN-LIMITATIONS','''
1. Native Windows attached-console behavior is NOT RUN. Windows R headless,
   parser, process tests and Chrome are covered; real terminals were WSL POSIX.
   macOS, SSH, RStudio Terminal and arbitrary emulator combinations are untested.
2. Windows lacks bit64/units/haven/hms/sf/RSQLite/dbplyr in the selected libraries;
   corresponding core tests skip and showcase fixtures are conditional. WSL runs
   those available integration/type paths. No absent-package path is labelled PASS.
3. Direct mirai on Windows reproduces approximately 2 retained handles per new
   compute profile. This P2 backend risk remains open for H4 despite stable RSS
   and terminated workers. Private native allocation ownership is not inferred.
4. Core covr run excludes project-only native/inkr integrations while retaining
   their uncovered denominator. App worker compute is uninstrumented. Branch
   coverage and Windows covr are unmeasured; function-label hit metrics group
   some nested/anonymous methods.
5. Default lintr retains substantial new style debt and pre-existing core
   findings. Completion/zero parse errors does not mean lint-clean code.
6. Profiling required a disclosed derived-copy repair for multiline Shiny debug
   labels. Raw data is retained. One earlier rtop/asciinema run hit transient
   errno61; final and standalone repeats passed, portability is not guaranteed.
7. Finite resource/latency series are not a soak test. Hyperfine5-run samples
   overlapped some validation activity and cannot establish performance regressions
   or compare OS speeds. rtop baseline/candidate workload is broader than app startup.
8. Workbench charts use original finite dataset values, not current table filter
   results. Unknown S3/vctrs fixtures remain read-only. A4 uses app-local clipboard.
   No exact round-trip claim is added for unsupported types. A one-point Plotly
   lines-only trace has no visible segment until another sample arrives.
9. Candidate package metadata remains1.0.1. Compatibility establishes current API
   behavior, not a published2.0.0 release/version-gate contract.
10. Three H2 test files differ from the initial manifest; provenance is unresolved.
    Current versions were retained and originals/diffs archived. All R core/man/API
    hashes are unchanged; a blanket byte-for-byte preservation claim is inappropriate.

No known open P0/P1 was found in the tested paths. These limitations are explicit
handoff items, not claims that unsupported workloads are safe.
''')
write('H4-HANDOFF','''
The three applications, final runners, real PTY/browser evidence, exact rtop
baseline comparison and both Status:OK package checks provide an executable
starting point. Do not replace these finite runs with claims of long-duration
stability. Start with the highest-signal open items:

| Priority | Next experiment | Retained evidence |
| --- | --- | --- |
| P2 | Isolate retained Windows handles across repeated named mirai compute profiles; compare native versions/long-lived profile reuse and native handle types | resource-probe.R, resource-probes/*.csv, lifecycle samples; direct mirai reproduces |
| P2 | Native Windows Console/ConPTY manual/automated keyboard/resize/error-restoration run | Existing docs/platform-testing.md; WSL PTY is not certification |
| P2 | Longer sustained UI/chart/input plus worker/reconnect soak, idle-machine latency distribution | lifecycle.R; bounded histories; final recordings |
| P2 | Review provenance of observed H2 test rewrite before merging | preservation-baseline/ and preservation-results.json; current file deliberately retained |
| P3 | Reduce new application/tool style debt without mass-formatting user core changes | final lintr CSVs grouped by scope |
| P3 | Extend missing Windows optional type packages and coverage scope; capture remote worker instrumentation separately if feasible | package inventories; current coverage limitations |
| P3 | Repeat rtop hyperfine with more idle-machine samples; watch recorder errno61 | raw baseline/candidate JSON and earlier failed recording |

```sh
Rscript tools/integration/run-all.R --mode=unit,headless,process --timeout=180
Rscript tools/integration/run-all.R --mode=lifecycle,profile,benchmark --timeout=600
Rscript tools/integration/run-all.R --mode=pty,expect,tmux,recording --timeout=300
python3 tools/integration/verify-preservation.py
```

Use Ubuntu for POSIX modes, native Windows R for its platform checks. Existing
project dependency libraries are controlled but ignored by Git; a fresh machine
must install matching optional packages and exact baseline/candidate libraries.
The runner reports absent POSIX tools/platforms as skips and failed jobs as
nonzero. Install instructions and app controls are in integration-apps/README.md.

No core API/version changes or releases were made. Preserve the already dirty
A1–H3 tree and archived initial hashes. `.Rbuildignore` intentionally excludes
the applications and pre-existing terminal recording from package builds.
Do not silently discard the observed H2 differences or call them a verified
Phase E core fix. No additional manual repair is required to launch the apps.
''')
summary=dict(generated_at=datetime.datetime.now(datetime.timezone.utc).isoformat(),
 reports=21,core_line_percent=core['line_percent'],app_line_percent=apps['line_percent'],
 confirmed_core_fixes=0,confirmed_application_defects_fixed=1,open_backend_risk='Windows native handle retention (P2)',
 final_windows_tasks=len(win['results']),final_wsl_tasks=len(linux['results']),
 baseline_files=preserved['initial_files'],preservation_status=preserved['status'])
(out/'report-summary.json').write_text(json.dumps(summary,indent=2))
print(json.dumps(summary,indent=2))
