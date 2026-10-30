from pathlib import Path
import json, statistics, hashlib, re
base = Path(__file__).resolve().parent
root = base.parents[1]
def read(name): return json.loads((base/name).read_text(encoding='utf-8'))
def log_text(path):
    data=path.read_bytes()
    return data.decode('utf-16' if data.startswith(b'\xff\xfe') else 'utf-8',errors='replace').replace('\r\n','\n')
def write(name, body): (base/name).write_text(body.strip()+'\n',encoding='utf-8')
def q(values,p):
    a=sorted(v for v in values if isinstance(v,(float,int)))
    return a[int((len(a)-1)*p)] if a else None
def pair(values): return f"{q(values,.5):.2f} / {q(values,.95):.2f}"
write('ARCHITECTURE.md','''# Phase 4–5 architecture

Independent collector → bounded local stream → optional raw JSON nanonext
pub/sub + request/reply snapshot → one remote handle per Shiny R process →
one explicit shared receiver → session reactives → ordinary data.frame →
base/ggplot2 or Plotly proxy. The existing TUI and simple Shiny fallback remain.

The receiver is created outside `server`, owns one source subscription, at most
one process-level poll observer and a bounded observation ring. Session wrappers
share a lease in session$userData; ending one session cannot stop the others.
First lease resumes the driver, last release suspends it. The app owner closes
the receiver explicitly; source ownership is controlled by close_source.
An implicit receiver created from a source is session-owned, but never closes
its caller's source. There is no global connection registry or cross-process
sharing. No collector or OS process is launched by these adapters.

Source polling is bounded/nonblocking. Callbacks run on the main R thread and
store records; a poll emits at most one reactive revision. Known duplicate and
older sequences are discarded; source changes clear history. Missing metadata
has only local identity. Invalid payload/time preserves cached latest with an
invalid status; stale measurement and receipt ages are independent of heartbeats.

Presentation uses normal frames. Segment groups and null Plotly y values avoid
bridging gaps. A session keeps its graph cursor. Ordered observations extend;
initial/window/source/gap/invalid changes explicitly replace history. One
browser acknowledgement permits at most one graph command in flight; slow tabs
coalesce subsequent data in the bounded ring. No unbounded application queue
or blind retry timer is added. Plotly/native websocket internals are external.

The generic receiver defaults to 50 ms. Profiling showed expensive reactive
fanout at 20 tabs, so the full example defaults to 500 ms and batches points.
This is a scheduling target, not a real-time guarantee. Slow R callbacks/plots
still delay the shared R thread. Public API details: API.md and docs/shiny.md.
''')
write('API.md','''# Experimental public API

Five new exports; 163 explicit exports total, existing S3 registrations unchanged.
Generated help comes from roxygen source; unrelated existing help was preserved.

| API | Purpose / default |
|---|---|
| `termr_shiny_receiver(source, interval=50L, max_points=600L, stale_after=5, validate=NULL, close_source=FALSE)` | Explicit process-local shared receiver; source caller-owned by default |
| `termr_shiny_reactive(source, session=shiny::getDefaultReactiveDomain(), max_points=600L)` | Reactive last valid unchanged payload |
| `termr_shiny_history(source, session=shiny::getDefaultReactiveDomain(), max_points=600L)` | Reactive bounded observation records |
| `termr_shiny_status(source, session=shiny::getDefaultReactiveDomain())` | Reactive live/unavailable/stale/invalid/closed status |
| `termr_stream_data(source, fields=c("cpu","ram"), max_points=600L, extractor=NULL)` | Ordinary typed frame, no optional packages required |

Receiver plain methods: latest/history/status/diagnostics/poll/close/is_closed.
History is observed data plus an initial latest snapshot, not remote replay.
Records carry payload/source_id/sequence/timestamp/received_at/gap. Unknown
metadata gets local identity. Restart generation clears old observations,
including restart with an empty snapshot. Consumers must check status before
presenting cached metrics as current.

Frames always have POSIXct UTC timestamp and received_at; numeric requested
fields; character source_id; double sequence; logical gap; integer segment.
Missing/non-numeric/NaN/Inf metrics are NA_real_. Raw invalid time is NA;
observation order is retained. An explicit extractor flattens nested metrics.
max_points=0 gives a typed empty frame. No global ggplot method is installed.

New dependencies are Suggests only: ggplot2, htmlwidgets and plotly. Existing
Shiny/nanonext/jsonlite integrations remain optional. No Imports/Depends change.
See docs/shiny.md, docs/plotly.md and docs/data-stream-visualization.md.
''')
write('IMPLEMENTATION.md','''# Implementation and scope

New maintained files:

- R/shiny_streams.R, R/stream_data.R; generated man/shiny_streams.Rd,
  man/termr_shiny_receiver.Rd, man/termr_stream_data.Rd and five NAMESPACE exports.
- inst/examples/system-monitor-live/dashboard.R, visualization.R,
  ggplot_history.R and README launch/lifecycle instructions.
- tests/testthat/test-shiny-streams.R, test-shiny-process.R, test-stream-data.R,
  test-plotly-live.R and fixtures/shiny_stream_child.R.
- docs/shiny.md, docs/plotly.md, docs/data-stream-visualization.md.

Updates: DESCRIPTION Suggests, NEWS, README, stability and API inventory.
.Rbuildignore excludes the browser tool's local artifact directory. Existing
stream, signal, app, widget, layout and terminal implementations are unchanged
relative to the task's initial 467-file hash manifest. Initial user edits remain.

Evidence-driven corrections:

1. Dashboard observer cursor required enclosing assignment (`<<-`); ordinary
   assignment reset it every run and sent full history repeatedly. Regression
   test proves initial restyle, ordered extend, idle noop and gap replacement.
2. A new publisher with an empty snapshot must clear the previous cached value.
3. Ready native packets are drained with nonblocking recv after the completed
   AIO, bounded by max_messages. Rearming AIO per packet usually delivered only
   one packet per poll and fell behind busy graphs. Pending AIO count stays <=2.
4. One frame conversion per receiver revision is cached across sessions.
5. Acknowledgements bound per-session Plotly commands; 500 ms dashboard batching
   gives reactive fanout time to yield to HTTP. Generic API default stays 50 ms.
6. The owned widget omits a redundant legacy typedarray dependency requiring an
   absent GLOBAL loader. Complete scratch CRAN Shiny assets fix the tested
   system Shiny 1.10.0 strftime asset mismatch. Third-party files are unmodified.
7. Owned processx launchers now use env=c("current",...). A partial environment
   caused Windows native exits, including scripts with no nanonext. This fixes
   tools/data-streams-integration.R, tools/nanonext_integration.R and the nano
   subprocess test. Existing R/workers.R already preserved current environment.

Roxygen: Rscript tools/dev.R doc in WSL; then restore unrelated baseline help
rewritten by a different installed roxygen version. No new help was hand-edited.
No commit, staging, push, release, public bind or system installation performed.
''')
rows=[]
for host in ['windows','wsl']:
    results=read(f'performance-{host}/SUMMARY.json')
    for x in results:
        if x['duration']!=3: continue
        rows.append(f"| {host} | {x['sessions']} | {x['rate']} | {x['cpu_percent_one_core']:.2f} | "
          f"{x['transport_ms'][0]:.2f} / {x['transport_ms'][1]:.2f} | "
          f"{x['reactive_ms'][0]:.2f} / {x['reactive_ms'][1]:.2f} | "
          f"{x['publisher_to_reactive_ms'][0]:.2f} / {x['publisher_to_reactive_ms'][1]:.2f} | "
          f"{x['diagnostic']['processed']} / {x['source_status']['gaps']} |")
perf='''# Performance measurements

Windows R 4.6.1; WSL Ubuntu R 4.5.2; nanonext 1.10.3. Scratch CRAN Shiny
1.14.0 and Plotly 4.12.1; ggplot2 Windows 4.0.3 / WSL 4.0.2. Measurements
are local observations on this shared host, not production capacity guarantees.

## Independent publisher → receiver → reactive

`Rscript audit-results/shiny-plotly/performance_shared.R` uses a finite
independent processx publisher, 1/5/20 MockShinySession subscribers sharing one
receiver, one manual source poll/flush per ~50 ms. The one shared observer is
created but real timer scheduling/browser/websocket costs are not represented
by this harness. Source callbacks timestamp transport arrival; the reactive
observer timestamps receipt-to-observer and publisher-to-observer independently.
Samples are bounded to the latest 4000 per stage; short 3 s runs include startup
and have too few samples at 1 Hz for robust tails. Rate 0 emits only a seed and
heartbeats (its latency is initial load, not idle-event latency). CPU is R parent
user+system/wall, percent of one core; it excludes publisher/browser CPU. The
public session flush plus manual scheduling has overhead; this is not bare
socket CPU. First prototype polling for readiness emitted missing-file warnings;
the harness now checks existence. Those warnings did not change measured data.

| Host | Sessions | Target Hz | CPU % | Transport p50/p95 ms | Receipt→reactive p50/p95 ms | Publisher→reactive p50/p95 ms | Accepted / sequence gaps |
|---|---:|---:|---:|---:|---:|---:|---:|
'''+ '\n'.join(rows)+'\n\n'
for host in ['windows','wsl']:
    x=read(f'performance-{host}/SUMMARY.json')[-1]
    rss=x['rss_mib']; diag=x['diagnostic']
    perf+=f"**{host}, 20 sessions, target 100 Hz for 60 s:** accepted {diag['processed']}, gaps {x['source_status']['gaps']}, coalesced {diag['coalesced']}, retained {diag['history']} <=600; CPU {x['cpu_percent_one_core']:.2f}%; RSS {min(rss):.2f}–{max(rss):.2f} MiB (first {rss[0]:.2f}, last {rss[-1]:.2f}). Publisher→reactive p50/p95 {x['publisher_to_reactive_ms'][0]:.2f}/{x['publisher_to_reactive_ms'][1]:.2f} ms.\n\n"
perf+='''Native pending operations stayed <=2. All leases released, receiver observer
destroyed and pending operations reached zero at teardown (assertions in harness).
The history and sampling lists are structurally bounded. RSS warmed up and
levelled within the observed range; a one-minute run is not proof of absence of
all long-duration/native/browser leaks. Windows dropped six sequences in the
long run; telemetry is lossy and gaps are reported, not concealed.

## Server-side plotting preparation

Synthetic 600-row frame; 20 repetitions except 10 PNG ggplot draws. Proxy uses a
fake immediate-flush session; these timings exclude websocket and browser work.
Millisecond timer resolution yields zero for some tiny operations.

| Host | Frame p50/p95 ms | Initial arrays p50/p95 ms | ggplot PNG p50/p95 ms | One-point proxy p50/p95 ms |
|---|---:|---:|---:|---:|
'''
for host in ['windows','wsl']:
    x=read(f'plot-benchmark-{host}.json')
    perf+=f"| {host} | {pair(x['frame_ms'])} | {pair(x['initial_arrays_ms'])} | {pair(x['ggplot_draw_ms'])} | {pair(x['incremental_proxy_ms'])} |\n"
perf+='''
## Actual browser stage

Real Playwright Chromium, real independent system collector and Shiny app.
Probe records completion after the actual Plotly promise plus two animation
frames; this is not a GPU presentation timestamp. End-to-end uses the **incoming**
measurement timestamp captured before a later command can mutate graph.data.
This is latency of the newest point in each update; earlier points in a batch
may wait longer. Core reactive latency likewise measures observed latest values,
not a promise that every intermediate event invalidates a reactive separately.
Clock agreement is required. Background-tab throttling contributes strongly.
Samples are bounded (2000 in browser, latest 50/tab or 200 single-tab exported).
'''
for name in ['browser-1-batched.json','browser-20-batched-10hz.json']:
    x=read(name)
    frames=x['frames'] if 'frames' in x else [f for tab in x['data'] for f in tab['frames']]
    perf+=f"\n{name}: {len(frames)} samples, browser update p50/p95 {pair([f['browserUpdateMs'] for f in frames])} ms; end-to-end p50/p95 {pair([f['endToEndMs'] for f in frames])} ms."
    if 'initialHistoryMs' in x: perf+=f" Navigation→initial 50-point history completion {x['initialHistoryMs']:.0f} ms."
    perf+='\n'
x=read('browser-20-batched-10hz.json')['data'][0]['frames']
valid=[(int(f['lastKey'].rsplit(':',1)[1]), f['at']-f['endToEndMs']) for f in x if f.get('lastKey') and f.get('endToEndMs') is not None]
rate=(valid[-1][0]-valid[0][0])*1000/(valid[-1][1]-valid[0][1]) if len(valid)>1 and valid[-1][1]>valid[0][1] else 0
perf+=f"\nThe real collector's configured interval was 0.1 s **plus collection cost**; observed publication rate across that sampled trace was about {rate:.2f}/s, not a guaranteed 10 Hz. The controlled synthetic benchmark above supplies the 100 Hz rate test.\n"
perf+='''
## Baseline and changes supported by it

Before optimizing, repeated restyle was observed in real browsers (cursor
scope bug), per-session repeated frame conversion was counted, and AIO rearm
drained about one ready message per poll under graph load. The ready-queue drain
and shared frame conversion address those measured costs. Native polling remains
bounded. Browser-20 baseline and subsequent JSON snapshots preserve evidence.

Even after true extension, 50 ms dashboard polling with 20 tabs saturated R,
delayed diagnostics and caused page-open timeouts. `browser-profile-summary.txt`
shows reactive flush/fanout and renderText/JSON/frame work. One in-flight command
per browser prevents graph command accumulation; 500 ms dashboard batching gives
that fanout time to finish. In the final 20-tab run all traces extended, stayed
<=50, closing 19 tabs and reloading the remaining tab succeeded. The shared
receiver API retains its 50 ms default for smaller/custom applications.
'''
write('PERFORMANCE.md',perf)
write('WINDOWS-WSL.md','''# Windows / WSL and native crash

| Collector | Shiny | Observed result |
|---|---|---|
| WSL | WSL | Real browser: base/ggplot2/Plotly, 1/5/20 tabs, stale/restart, bounded history and true extends |
| Windows | Windows | Real Windows collector and Shiny app, browser extends and live status; browser-windows-native.json |
| WSL | Windows | Real Windows Shiny app receives WSL loopback publisher, browser extends; browser-windows-shiny-wsl-collector.json |
| Windows | WSL | Unavailable through localhost: ten-second bounded testServer probe accepted 0 events, state connecting/unavailable; network-receiver-wsl.json |

For the unavailable direction, Windows listened on 127.0.0.1:5571/5572, while
WSL had its own virtual interface (172.22.144.73 during this run). All Windows
firewall profiles were enabled. No packet trace/rule-level diagnosis was made,
so attributing the failure specifically to firewall would be unsupported. The
established observation is that this topology does not forward Windows loopback
into WSL localhost. No system networking, firewall or bind address was changed.
The package deliberately accepts loopback endpoints only. Use one OS for both
ends, or the validated WSL publisher→Windows subscriber direction when available.

Reproduce: run Windows collector with TERMR_METRICS_TRANSPORT=nano and endpoints
tcp://127.0.0.1:5571 / :5572. In WSL run network_receiver.R (bounded ten seconds)
or dashboard.R with those variables. Expect unavailable here. Reverse the hosts
with :5565/:5566 to reproduce the working direction. Normal commands are in the
example README. No public-interface workaround is proposed.

## Native exit diagnosis

The old Phase 3 audit associated Windows exit -1073741819 (0xC0000005) with
pkgload. The controlled current audit narrows it to the **launch environment**:

- minimal cli/rlang/Shiny/pkgload scripts can fail even without nanonext;
- direct Rscript invocation succeeds;
- processx with partial env=c(R_LIBS=...,R_TESTS="") fails;
- inherited, env=c("current",...) and full cloned environments exit 0;
- all 12 repeats of installed/pkgload/no-nano/Shiny matrix modes exit 0 with
  the current-environment form. See environment-crash.json and
  crash-matrix-inherited.json; minimal_crash_child.R is the small reproducer.

The individual missing environment variable/native library defect was not
isolated. The sufficient repair in our owned launchers is preserving current
environment and overriding only R_LIBS/R_TESTS. This is not evidence that termr
or nanonext native code caused the crash. Installed-package and pkgload runtimes
both now complete. No third-party code was patched. Scratch fresh rlang alone
did not fix partial-env launches. R/workers.R already used the correct form.

Initial Windows full tests in the restricted sandbox failed to create processx
pipes (system error 5), a separate permission failure. The approved run outside
that restriction passed; it must not be confused with the native access violation.
''')
write('BROWSER-VALIDATION.md','''# Real browser validation

Playwright Chromium drove an actual loopback Shiny app and independent actual
system-metrics collector. Synthetic core load tests are separately labelled.

Validated:

- Initial bounded history, two named CPU/RAM traces; zero-based proxy indices
  0/1; array shape preserved for a single point; maxPoints honoured.
- Ordered data produces actual Plotly.extendTraces calls. Initial/gap/source/
  window resynchronization uses explicit restyle, not claimed as incremental.
- 1, 5 and 20 tabs receive data from one process-level receiver/observer and
  independent collector. Final 20-tab data and acknowledgement counts are in
  browser-20-batched-10hz.json; two traces per tab <=50, unique source:sequence
  keys excluding explicit gap separators. Configured collector interval is
  0.1 s plus sampling cost; actual rate is reported in PERFORMANCE.md.
- Closing 19 tabs releases their leases. After closing the last tab sessions
  reach zero, poll count stops increasing, shared driver is suspended. Explicit
  app shutdown destroys it (browser-shutdown-wsl.json / -windows.json).
- Collector stopped gracefully: stale/reconnecting status and cached-value
  label appear. Restart changes source_id, clears old source keys, replaces
  history once and resumes extension. No missing history is fabricated.
- Window input changed to 20: both traces reduced to <=20 by full replacement.
- Actual ggplot2 and base PNG outputs rendered; switching back recreates Plotly
  and performs initial history synchronization. Screenshots plotly-stale.png
  and ggplot-live.png were visually inspected. ggplot_history.R produced and
  saved CPU/RAM/comparison PNGs from real samples.
- Acknowledgement deliberately withheld: source sequence advanced 547→549
  while extension count stayed 37; releasing it resumed delivery. slow-browser.json.
- Final error-level browser console capture: 0 errors (browser-console-complete.txt).

Current browser/native typed arrays are required by this owned example widget.
The legacy redundant typedarray dependency is omitted without editing Plotly.
The complete CRAN Shiny scratch installation fixes a pre-existing system asset
filename mismatch. Early baseline console failures are retained in older raw
artifacts, not presented as current success.

Browser timing uses Plotly promise + two animation frames, not GPU timestamps.
The final one-tab reload after closing the other 19 succeeded and initial
50-point history completed in 811 ms on that observation. See PERFORMANCE.md
for distributions and background-tab constraints. A 50 ms dashboard baseline
did overload this environment; 500 ms batching is the shipped example default.
''')
write('KNOWN-LIMITATIONS.md','''# Known limitations

- Experimental process-local API; one receiver per Shiny R process, no broker,
  server-wide registry, cross-process sharing or durable replay.
- Pub/sub is lossy latest state. Gaps are visible; resync recovers current state
  only. Windows 100 Hz minute run had six skipped sequences. Native buffers,
  observation history and application graph commands are bounded.
- R is single-threaded here. Slow validators/callbacks/ggplot draws delay the
  whole process. The dashboard batches at 500 ms by default; 50 ms with 20
  real tabs overloaded this environment. Background browser RAF throttling
  can make its visible updates much slower than the producer.
- One graph command remains pending until the browser acknowledges. A failed
  or non-acknowledging widget stops graph delivery until recreated; no unbounded
  retry queue is added. Status and healthy sessions continue at available CPU.
- Browser/native websocket/Plotly internals are third-party; the application
  bounds its own pending commands, retained frames and probe samples.
- Local payloads without source/sequence cannot support cross-process dedupe;
  timestamps need clock agreement. Missing metrics stay NA, never zeros.
- Loopback is not authentication or encryption against other local processes.
  Windows publisher→WSL localhost is unavailable in this topology; firewall
  profiles were observed, but no rule-level root cause was asserted or changed.
- Native partial-env crash is reproducible and avoided by preserving current
  environment. The exact missing variable/native failure path remains unknown.
- Current browsers with native typed arrays; complete Shiny assets required.
  Probe timestamps approximate completion after two animation frames, not GPU
  presentation. Real collector configured interval includes sampling overhead.
- Minute-scale RSS observation is not a long soak, memory-leak proof, stress
  certificate, concurrency capacity guarantee or browser heap profiler.
- Windows terminal GUI/ConPTY checks were not automated here. Existing Windows
  driver unit tests and WSL real PTY suite passed; no macOS terminal was available.
''')
write('NEXT-PHASE.md','''# Readiness for mirai

The stream/transport/reactive boundaries are ready for an optional mirai
producer experiment: plain validated telemetry payloads, main-thread bounded
polling, explicit ownership/cleanup, source identity/sequence and bounded
presentation history are available. A future worker can publish observations
without a TUI or Shiny session owning its lifetime.

Do not add mirai to Imports or replace the existing worker system as part of
this phase. Before calling that backend ready, test worker creation/failure,
cancel/restart, mailbox/backpressure limits, independent-process snapshots,
package/environment propagation and Windows lifecycle using inherited launch
environment. Preserve JSON wire data boundaries; never deserialize executable
R payloads from a network peer. Add multi-process Shiny worker tests and a
longer browser/native-memory soak. Durable replay and authenticated remote
transport would require separate architecture and scope.

No mirai implementation, new daemon service, system networking change or
release was performed. Current limits are explicit in KNOWN-LIMITATIONS.md.
''')
lines=[]
for name in ['full-windows-unsandboxed.log','full-wsl.log','focused-ack-windows.log','focused-final-wsl.log','focused-ack-wsl.log']:
    content=log_text(base/name)
    totals=re.findall(r'TOTAL .*',content)
    lines.append(f"- `{name}`: {totals[-1] if totals else 'inspect raw log'}." )
checks=[]
for host in ['windows','wsl']:
    p=base/f'check-batched-{host}.log'
    text=log_text(p) if p.exists() else ''
    statuses=re.findall(r'Status:.*',text)
    checks.append(f"- Final batched R CMD check {host}: {statuses[-1] if statuses else 'RUNNING — regenerate this report after completion'}; `{p.name}`.")
    test_log=base/f'check-{host}-batched/termr.Rcheck/tests/testthat.Rout'
    if test_log.exists():
        counts=re.findall(r'\[ FAIL .*?\]',log_text(test_log))
        if counts: checks.append(f"  Package testthat {host}: {counts[-1]}.")
write('TEST-RESULTS.md','''# Validation results

Run date: 2026-10-29, Windows R 4.6.1 / WSL R 4.5.2. NOT_CRAN=true for full
source tests and checks. No mandatory dependency added. Raw logs remain here.

'''+ '\n'.join(lines)+'\n'+ '\n'.join(checks)+'''

The earlier pre-batching full R CMD checks also completed with Status: OK on
both platforms (check-final-*.log). The final checks include the selected 500 ms
example interval and full testthat suite from the final tarball. Build excludes
audit reports, local browser artifacts and temporary snapshots. No manual PDFs
or built vignettes were requested (`--no-manual --no-build-vignettes`).

Commands:

```text
Rscript audit-results/shiny-plotly/run_tests.R .
Rscript audit-results/shiny-plotly/run_tests.R shiny-process
Rscript audit-results/shiny-plotly/check.R batched
Rscript audit-results/shiny-plotly/minimal.R
Rscript audit-results/shiny-plotly/performance_shared.R
Rscript audit-results/shiny-plotly/plot_benchmark.R
WSL: bash audit-results/shiny-plotly/pty.sh
python audit-results/shiny-plotly/preservation.py
```

Focused Shiny suite covers lifecycle/coalescing, bounded history, invalid/stale
status, metadata dedupe/order/source restart (including empty snapshot), 20
shared leases and implicit cleanup. testServer validates independent processx
publisher delivery and dashboard cursor/proxy/acknowledgement behavior. Nano
suite covers raw malformed JSON/schema, exact topics, snapshots/gaps/reconnect,
callback close and bounded ready-queue drain. Frame tests cover typed empty,
NA/NaN/Inf, bad timestamps, nesting/extractors and discontinuity segments.
Stream suite covers callback errors. These are layer-specific tests; not every
corrupt-packet case was also driven through a browser.

Minimal isolated libraries on BOTH hosts contain only mandatory dependencies:
TUI/core/frame work without Shiny/ggplot2/Plotly/nanonext, and Shiny constructor
reports a clear optional-package error. Existing WSL PTY suite: all checks passed,
including raw mode, focus/input batching, resize, Ctrl+C/error restoration.
Windows terminal behavior is unit-tested; no interactive ConPTY automation or
macOS host was available.

Windows 18 source-suite skips concern unavailable DBI/RSQLite/knitr or POSIX-only
tests; see raw reasons. Initial sandbox run failed processx pipe creation, then
approved unrestricted run passed. Early readiness-file test warnings were a
harness race and were fixed; clean focused runs and final checks supersede them.

`preservation.json` verifies 455 of 467 initial files byte-for-byte; the 12
changed baseline files are explicitly authorized scope. Unrelated initial user
changes, old stream/signal/TUI implementations and existing help are preserved.
Index remains unstaged. `git diff --check` passed; Git only warned about existing
CRLF normalization in initial geometry/style files. See IMPLEMENTATION.md for
the maintained change list and BROWSER-VALIDATION.md for actual browser evidence.
''')
print('Wrote nine Phase 4–5 reports.')
