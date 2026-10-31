from pathlib import Path
from collections import defaultdict
from statistics import median
import csv, json, re

out = Path('audit-results/hardening/h3-performance')
def read(name):
    final = out / 'final-validation-ring' / name
    p = final if final.exists() else out / name
    if not p.exists(): return 'NOT RUN'
    raw = p.read_bytes()
    return raw.decode('utf-16' if raw.startswith((b'\xff\xfe', b'\xfe\xff')) else 'utf-8-sig', errors='replace').strip()
def csvrows(name):
    p = out / name
    return list(csv.DictReader(p.open(encoding='utf-8-sig'))) if p.exists() else []
data = defaultdict(list)
for phase in ['before', 'after']:
    for group in ['core', 'broad', 'events', 'extra', 'stream', 'granular']:
        for r in csvrows(f'{phase}-{group}.csv'):
            if phase == 'after' and group == 'core' and r['id'] == 'continuous-stream' and (out/'after-stream.csv').exists():
                continue
            data[(r['id'], int(r['n']), phase)].append(r)
def stat(id, n, phase):
    rows = data.get((id, n, phase), [])
    if not rows: return 'NOT RUN'
    times = [float(r['elapsed']) for r in rows]
    alloc = median(float(r['allocated']) for r in rows)
    return f'{median(times):.3f} s [{min(times):.3f}, {max(times):.3f}]; {alloc/1e6:.4f} MB; n={len(rows)}'
def table(keys):
    lines = ['| Scenario | Size | Before: median [min,max]; allocations | After: median [min,max]; allocations |',
             '|---|---:|---|---|']
    for id, n in keys:
        lines.append(f'| {id} | {n:,} | {stat(id,n,"before")} | {stat(id,n,"after")} |')
    return '\n'.join(lines)
keys = sorted({(k[0], k[1]) for k in data})
keycases = [('unmount-no-sheet',1000), ('render-repeated',10000), ('render-unique',10000),
            ('deep-cold',100), ('micro-element',1000), ('micro-hit',1000),
            ('events-enqueue',10000), ('events-dequeue',10000)]
paired = defaultdict(list)
for r in csvrows('paired-bridge.csv'):
    paired[(r['op'],r['phase'])].append(r)
paired_lines = ['| Paired bridge operation | Before median [min,max], seconds | After median [min,max], seconds |', '|---|---:|---:|']
for op in dict.fromkeys(k[0] for k in paired):
    cells = []
    for phase in ['before','after']:
        values = [float(r['elapsed']) for r in paired[(op,phase)]]
        cells.append(f'{median(values):.3f} [{min(values):.3f}, {max(values):.3f}]')
    paired_lines.append('| '+op+' | '+' | '.join(cells)+' |')
paired_table = '\n'.join(paired_lines)
method = '''Measurements use native Windows R 4.6.1 and the headless driver, seed 20261031,
one unrecorded warm-up and three recorded repetitions per scenario. Setup and
cleanup are outside timing; Rprofmem and 5 ms Rprof are enabled during the main
harness. CSV files contain every repetition, elapsed seconds and gross recorded
R allocation bytes; CPU profile CSVs preserve the first repetition's stack summary.
Reported spread is min–max, not a confidence interval. Sub-centisecond results
are below useful Windows timer resolution. MB means 1,000,000 bytes.

These are instrumented developer-machine measurements, not isolated-machine
latency guarantees. Some baseline and validation jobs overlapped; CPU contention
especially widens the 10,000-widget timing range. Allocation differences and
algorithmic evidence are stronger than small timing differences. Cross-platform
results are never used as speedup evidence. Rprofmem does not account for every
small SEXP or external-library allocation. Gross bytes are neither retained heap,
RSS nor peak memory. Credible process peak memory was not measured.'''
statuses = ['h1-h2-baseline','focused-windows','optional-free-windows','full-windows','build-windows','check-windows','build-wsl',
            'inventory-wsl','focused-wsl','optional-free-wsl','full-wsl','check-wsl','pty-fixture-wsl-final',
            'pty-full-wsl','pty-combined-wsl-repeat-1','pty-combined-wsl-repeat-2','pty-binary-wsl',
            'before-core','after-core','before-broad','after-broad','before-events-profile','after-events',
            'before-extra','after-extra','after-stream','before-granular','after-granular','before-components','after-components','before-memory','after-memory','paired-bridge',
            'resource-cycles-windows','resource-cycles-wsl','trace-copies','git-diff-check']
status_table = '| Check | Exit code |\n|---|---:|\n' + '\n'.join(f'| {s} | {read(s+".exit")} |' for s in statuses)
def total(name):
    s = read(name)
    matches = re.findall(r'TOTAL: [^\r\n]+',s)
    return matches[-1] if matches else 'See raw log; no TOTAL line.'
def check(name):
    matches = re.findall(r'Status: [^\r\n]+',read(name))
    return matches[-1] if matches else 'See raw log; final status unavailable.'
def memory_table():
    rows = ['| Workload | Sample | Ncells used | Vcells used | R connections |', '|---|---:|---:|---:|---:|']
    for phase in ['before','after']:
        data = csvrows(f'{phase}-memory.csv')
        for r in data:
            rows.append(f'| {phase} | {r["cycles"]} | {r["ncells"]} | {r["vcells"]} | {r["connections"]} |')
    return '\n'.join(rows)
docs = {}
docs['EXECUTIVE-SUMMARY.md'] = f'''# H3 performance and memory

Four focused internal changes address measured costs: unused inkr reset during
unmount, repeated construction of inkr ancestor elements/keys, quadratic event
queue list copying, and chart publication starvation under a sustained backlog.
There is no new renderer, stylesheet engine, event loop, mandatory dependency,
native code, version change, commit, push or release.

{table(keycases)}

Windows: {total('full-windows.log')}. {check('check-windows.log')}.
WSL: {total('full-wsl.log')}. {check('check-wsl.log')}.
Use TEST-RESULTS.md for exit codes and dependency exclusions, and
BENCHMARKS-BEFORE-AFTER.md for all repetitions and measurement limitations.

The final changes are four R files, three test files (one new), and two guides.
The two existing chart tests now require publication after the first bounded
chunk; all drain/order/capacity checks remain. H1/H2 source atomicity, export,
ownership, count validation, bubbling, Pilot cleanup and projection-key tests
remain in the regression run. Chart publication adds useful redraw work; it is
a freshness fix, not an allocation optimization.

Residual risks: sibling removal remains quadratic, global style epochs still
invalidate broadly, and public inkr session insertion still copies sibling keys
quadratically. Long-duration host/DB/network soak testing belongs to H4.
'''
docs['BASELINE.md'] = f'''# Reproducible baseline

Baseline HEAD: {read('head-before.txt')}; branch 2.0-termr; package 1.0.1.
git-status-before.txt records the pre-existing dirty tree. baseline/R contains
the actual H2-era working files, not a clean checkout of HEAD. The baseline
manifest covers 567 initial files outside audit-results; preservation.json and
h3-only.patch distinguish H3 edits from existing work.

{method}

Run from the repository root with the same R library paths:

```powershell
$env:TERMR_H3_PACKAGE='audit-results/hardening/h3-performance/baseline'
Rscript audit-results/hardening/h3-performance/benchmark-frozen.R before core
Remove-Item Env:TERMR_H3_PACKAGE
Rscript audit-results/hardening/h3-performance/benchmark-frozen.R after core
```

Repeat with `broad` and `events`; extra-benchmark.R takes `before extra` or
`after extra`; granular-benchmark.R takes `before granular` or `after granular`.
component-micro.R takes the phase. lifecycle-events.R runs the
1,000-cycle App/stream test. All scripts use temporary profiling files only.
The final frozen harness is never edited during execution.

The initial core run completed its recorded rows but exited 1 after this agent
edited the script while R was still reading it; before-core-initial.* preserves
that attempt. The canonical core baseline was rerun against the verified source
snapshot. The initial extra run exposed a benchmark-only partial `$p` match to
`$parent`; cleanup now uses exact `[["p"]]` lookup and the run was repeated.
Neither failed attempt is silently presented as a passing command.

Fresh-App startup and repeated startup of the same App are measured separately;
fresh-process R/package load startup is not timed. Detailed scenario coverage is
in the subsystem reports and the raw CSVs.
'''
docs['PROFILING.md'] = f'''# Profiling evidence and root causes

{method}

CPU profiles are named before/after-SCENARIO-SIZE-profile.csv. Their sampled
total percentages overlap through callers and must not be summed. Short cases
can have no samples. trace-copies.log demonstrates list duplication in the
original EventQueue; the timed allocation series supplies the scale evidence.

Before: unmount-no-sheet records 33,096,000 bytes under
inkr_reset_style_cache for 1,000 children and 165,480,000 for 5,000. App called
the reset and an extra subtree walk even without a stylesheet. The reset creates
an environment and a 4,096-slot character ring every time.

Before: render-unique-1000 spends substantial sampled time under
inkr_style_for_widget and inkr_element_for_widget. Every widget reconstructs the
same ancestor elements; every cache hit reconstructs ancestor signature lists.
The patch reuses epoch-scoped immutable public inkr elements and path prefixes.
The style adapter statements are extracted from the actual function body by
component-micro.R, so mapping timing does not use a separately maintained engine.

Before: enqueue of 10,000 events records 820,920,240 bytes; dequeue records
534,178,976. R6's environment holds a list, whose replacement through `$` copies
the growing/shrinking list. The revised hash environment avoids these copies.
Ordinary one-event and 100-event workloads are retained in the comparison table.

Chart evidence is structural: before-stream-freshness.csv shows processed=100,
displayed=0 and pending=48 after 21 flushes. Publication was conditional on an
empty queue. After publication occurs on the first chunk, at 60 Hz while
backlogged, and immediately on final drain, while yielding through widget
timers. This repair intentionally performs additional rendering.

Full Rprof raw sampling files are temporary; first-repeat summary stacks,
recorded allocation totals, scripts and per-repeat CSVs are retained. There is
no claim that these samples prove absence of all other bottlenecks.
'''
docs['INKR-OPTIMIZATION.md'] = f'''# inkr bridge

{table([k for k in keycases if 'render' in k[0] or 'micro' in k[0] or 'deep' in k[0]])}

The bridge still calls only public inkr exports. inkr itself is unchanged.
inkr_element_for_widget now recursively reuses parent representations through
the existing widget epoch cache. inkr_path_key_for_widget memoizes the same
validated control-delimited path representation, using a cached parent prefix.
The sheet generation remains part of the App cache key. Cache hits avoid
ancestor-list construction; misses still use the original cascade, explicit
ancestor flags and eight-property adapter.

State overrides are part of the widget-local cache entry. Ancestor class/state,
focus, disabled, tree mutation and stylesheet replacement continue to use the
existing epoch invalidation. Clear/unmount explicitly remove the new entries.
Entries contain inkr values/strings, not references to widgets or Apps. The
existing per-App FIFO remains limited to 4,096 styles; there is no global cache
or TTL. The tradeoff is two additional lazy cache entries per visited widget,
and path-prefix strings still grow with depth. Global invalidation is retained.

Core CSVs cover 100/1,000/10,000 repeated and unique identities, 100 nested
containers, element creation, parent paths, cache hits and public ink_compute.
Component CSVs separately measure ink_match, adapter mapping, insertion,
invalidation, class changes and stylesheet swaps. Existing integration tests
cover cascade, inheritance, precedence, focus, disabled and atomic replacement;
H3 adds construction-count, override and reparenting tests.

Public ink_session_set insertion is measured unchanged at 100/1,000/2,000
siblings: allocations are approximately 0.047/4.098/16.185 MB. Doubling the
last size almost quadruples bytes. The independent inkr source still appends
sibling keys with c(existing, key); see R/session-state.R in the sibling repo.
The stateless bridge is retained rather than switching to this session path.
The minimal independent reproducer is the inkr-session-insert block in the
frozen benchmark; it uses only public functions and can run in inkr's repository.
'''
docs['WIDGET-LIFECYCLE.md'] = f'''# Widget lifecycle

{table([('unmount-no-sheet', n) for n in [100,1000,5000]])}

App widget_unmounting and screen_leaving skip bridge cleanup/reset when no
inkr stylesheet exists. Clearing a stylesheet already clears all bridge state.
When a sheet exists the original cleanup and invalidation remain. Disposal,
timer cancellation, worker ownership, focus/hover/capture cleanup, lifecycle
events and parent mutation order are unchanged. Startup/shutdown and large
subtree mount are included in broad/extra scenarios; the full suite covers
custom remove hooks, DBI ownership (WSL), reactive disposal and detached bubbling.

The vapply(identity) search and parent list reconstruction in Widget detach
remain O(n²) across remove_children. Removing or reordering those operations
would change observations made by custom remove/dispose callbacks. This stage
removes the proven redundant allocation without silently changing callback
ordering. At 5,000 siblings the residual cost is significant and is a concrete
H4/H-next optimization candidate requiring a dedicated lifecycle contract.

The 1,000-cycle create/mount/stream/unbind/close workload checks subscriber
count and running state on every cycle; MEMORY.md records GC-visible live
objects and open R connections. These assertions complement, rather than
replace, longer resource-lifecycle tests.
'''
docs['LAYOUT-RENDERER.md'] = '''# Layout and renderer

No layout algorithm, framebuffer, ANSI diff or dirty-rectangle code changed.
Fresh initial renders, warm chart renders, idle App ticks, one-widget paint
updates, full layout/render, partial selection redraw and resize are represented
in the core/broad/extra CSVs. The chart *-paint.txt artifacts preserve full,
dirty-cell, rectangle and ANSI-byte counters after the requested operation.

The inkr bridge optimization reduces style preparation before layout. It does
not assume that a foreground-only declaration cannot affect layout through
selectors, inheritance or custom styles. The existing conservative stylesheet
layout invalidation and global epochs remain. No new dirty-render shortcut was
introduced without evidence that its semantics are safe.

The full suite includes dirty rendering, incremental/full framebuffer equality,
layout, regions, scrolling, resize storms and Unicode bounds. PTY covers live
POSIX input/output and restoration separately. Warm render_widget timings still
compose a frame and are distinct from App idle ticks that can avoid a frame.
Fresh-process startup and monitor-to-screen latency are not measured here.
'''
docs['DATATABLE.md'] = '''# DataTable and virtual sources

R/widget-datatable.R and the typed handlers are unchanged by H3. Broad CSVs
measure local tables at 1,000, 100,000 and 1,000,000 rows with integer/double/
character columns: construction, first render, distant scroll, sort, predicate
filter, resize, scalar edit, row lookup, selection and bounded A4 value export.
Export explicitly selects ten rows; it is not a full-million-row code export.
Sort/filter legitimately inspect local data; virtualization claims concern
display formatting and lazy-source requests, not those global operations.

The lazy fixture has 10,000,000 rows and 40 columns; width 109 shows 12 columns,
pages contain 100 rows and the existing FIFO capacity is 32. It visits 40 distant
positions. *-source-requests.csv records every projection and request count;
the initial bounded schema sample reads all 40 columns. Later viewport requests
read 12 columns. Before: 8,100 rows requested, 480 rendered, 5,760 cells rendered.
There is no full collect. A second dedicated resource-cycle test asserts cache
size <=32 through repeated source switches and renders.

Focused/full suites exercise typed attributes, optional units/haven/lubridate/
blob/sf/vctrs handlers, source paging/projection, schema rejection and atomic
replacement, edits, sorting/filtering and exact A4 reproduction. Windows lacks
several optional packages; WSL supplies the broader type/DB matrix. No type
handler or source transaction was weakened to save an allocation.

Source cache-hit/projection collisions and failed-source recovery retain their
H1/H2 contract tests. Callback time remains synchronous; arbitrary DB latency
and network-backed paging are not bounded by these synthetic fixture timings.
'''
docs['CHARTS-STREAMS.md'] = '''# Native charts and sustained streams

All five chart types have initial/warm render, resize, update_data, partial
selection redraw, forced full redraw and hit-plan measurements. The extra
scenarios invoke the existing update and hit logic; painting counters are saved
alongside timings. Rendering uses a headless terminal; it does not measure
physical terminal flush latency.

The continuous producer emits 64 events, then another 16 before each of 20
timer advances. Each consumer chunk processes 16; the queue therefore remains
non-empty. Before: processed view=100, displayed=0, pending=48, flushes=21.
The drain-only publication rule could starve indefinitely. H3 changes exactly
that predicate: the first chunk publishes immediately, a continuously non-empty
queue publishes at a 60 Hz cadence, and final drain publishes immediately.
The 1 ms timer yield, queue cap, max_points, error handling, gaps and ordering
remain unchanged. Stream freshness artifacts record before/after state.

The H3 regression requires a strictly advancing displayed latest value every
20 ms of simulated time, at most four paints over 40 ms, equality to processed
values when published, max_points <=100, and no subscription or callback work
after removal. Existing tests cover overflow/gap semantics,
selection, replacement and finite burst drain. Two old expectations requiring
no intermediate display were updated; their remaining assertions are intact.

This change increases redraw/allocation work when the producer never pauses.
The continuous-stream row in the before/after table quantifies the tradeoff.
It is a correctness and responsiveness repair, not a claimed faster stream
processor. Virtual-time advances test scheduling/freshness, not a real 1 ms
wall-clock guarantee. PTY and H4 long continuous input/stream tests remain
necessary for terminal-host latency confidence.
'''
docs['EVENT-LOOP.md'] = f'''# Event queue and input latency

{table([('events-'+op,n) for n in [1,100,10000] for op in ['enqueue','dequeue']])}

The event loop is unchanged. Only EventQueue's private storage changes from
a copy-on-modify list to an instance-owned hash environment with reusable FIFO
ring slots. Capacity starts at 64, doubles on demand, and shrinks when drained.
Popped bindings are removed immediately. Draining a large burst replaces its
expanded hash table; small queues reuse their storage. clear() releases all
bindings. NULL push remains a no-op. Ring indices stay within capacity and
size() remains integer. Slot names are bounded by peak queue depth, avoiding
both lifetime index overflow and an unbounded stream of interned R symbols.
The queue is not newly bounded: App's existing per-tick budget is retained.

Regression tests check allocation growth, 1,100-item interleaved FIFO, empty/
clear/reuse, independent instances, wrapped growth and 10,000 sustained
non-empty operations with bounded slot indices.
The budget is 2 MB for 1,000 prebuilt events, comfortably above observed new
allocations and below the original 8.29 MB quadratic copies. There is no
wall-clock test threshold. Timer/input/worker suites and PTY Tab+Enter validate
dispatch order and reentrant behavior at the App level.

Extra rows separate direct dispatch including a handler from enqueue-through-
next-headless-frame for 1/100/10,000 events. Event construction and setup are
excluded from these operations. Other rows measure idle, focus, widget update
and resize. Do not read these as OS keyboard-to-photon latency. The parser and
real POSIX PTY remain separate validation layers; Windows live-console timing
was not available.
'''
docs['MEMORY.md'] = f'''# Memory and resource lifecycle

The fixed workload creates, starts, mounts, streams once, unbinds and closes
1,000 Apps. Every cycle asserts zero subscribers and a stopped App. Every 100
cycles a full gc() samples live Ncells/Vcells and open R connections. The same
script runs before and after; its observer retains one small result row per
sample, so tiny linear observer growth must not be called a product leak.

{memory_table()}

resource-cycles-windows.csv and resource-cycles-unix.csv add RSS snapshots (when optional ps is available), live
heap and connection counts during 100 repeated source/style cycles. Each cycle
performs five lazy-source switches and stylesheet apply/clear operations,
asserting source cache <=32 and a cleared App bridge cache. On WSL the same
resource runner also connects/closes 100 owned SQLite sources. DBI absence on
Windows is explicitly skipped. H2 tests verify borrowed/owned widget cleanup.

The new widget-local cache stores immutable inkr data rather than Widget/App
references and clears on unmount/sheet changes. The revised queue removes
event references on pop/clear and drops large empty hash storage. Gross
allocation reductions do not imply identical RSS savings: R's allocator may
retain a high-water mark. RSS samples are not peaks or leak proofs.

These finite runs establish bounded subscriber/cache/connection observations
in the tested workloads. They do not prove absence of every retained R6 cycle,
foreign allocation, OS handle, socket or worker-process leak. Dedicated
process/socket/handle census and long async/network soaks were not performed;
mirai/nanonext are unavailable. See H4-HANDOFF.md for explicit follow-ups.
'''
docs['BENCHMARKS-BEFORE-AFTER.md'] = '# Complete before/after measurements\n\n' + method + '\n\n' + table(keys) + '''

Component microbenchmarks are in before/after-components.csv (matching,
mapping, cache insert/reset, class changes and sheet swaps). The unchanged
public inkr session rows are controls and do not represent a bridge speedup.
before-core-initial.csv is historical diagnostic evidence only; the canonical
before-core.csv comes from the verified pre-H3 source snapshot.
'''
docs['REGRESSION-TESTS.md'] = '''# Regression contracts

New test-h3-performance-contracts.R covers EventQueue FIFO/allocation/lifetime
indices, no-sheet unmount cache identity, shared inkr parent construction,
epoch/state override invalidation, ancestor classes, stylesheet swap/removal,
reparenting, continuously advancing chart output, bounded points and cleanup.
failing-first*.log and queue-failing-first.log preserve the original failures.
No public API, generated documentation or dependency changes were necessary.

Existing test-chart-streams.R and test-h2-contracts.R change only the expected
first-chunk publication. Finite drain, bounded queue, order and cleanup checks
remain. h3-only.patch shows exact additions against the initial dirty snapshot.

H1/H2 filters cover atomic source replacement (F01), exact sorted/filtered
reproducibility (F02), detached ancestor bubbling (F04), Pilot startup cleanup
(F05), projection-key collisions (F06), documentation hygiene (F07), owned DBI
cleanup (F08) and finite/whole count validation (F09). Windows DBI tests skip;
the WSL dependency matrix executes them. inkr optional-free tests are run in
separate processes without the temporary inkr library path.

The full suites also include widget/layout/dirty-render, typed attributes,
data-source schema/cache/atomicity, native chart selection and streaming,
timers, key parsing, lifecycle and worker contracts. Check logs preserve the
actual platform exclusions. One initial focused run overlapped a queue-source
edit and saw an old loaded method with a newly added test; its log is retained
as focused-windows-initial.*, and final focused/full runs use frozen code.
'''
docs['WINDOWS-WSL.md'] = f'''# Platform and dependency matrix

Native Windows R 4.6.1 and WSL Ubuntu R 4.5.2 are independent validation targets.
packages-windows.csv and packages-unix.csv record installed optional versions.
Temporary inkr 0.1.0 libraries use the independent sibling checkout; neither
its source nor a global user library was modified. inkr session behavior is
documented against that installed checkout, not assumed from a newer release.

Windows full suite: {total('full-windows.log')}

Windows check: {check('check-windows.log')}

WSL full suite: {total('full-wsl.log')}

WSL check: {check('check-wsl.log')}

Each platform builds its own archive from the frozen final working files;
SHA-256 artifacts record archive identity and archive-source-verification.json
checks every packaged R/test source against the workspace. The final archives
are under final-validation-ring/build and final-validation-ring/build-wsl.
_R_CHECK_FORCE_SUGGESTS_=false permits absent optional
dependencies and is not complete Suggests coverage. Missing mirai/nanonext/
duckdb scenarios must remain explicit. WSL has the broader DBI/SQLite/Arrow/
dbplyr/units/haven/sf/lubridate/blob matrix; Windows's absences are visible in
its manifest and skip list.

Windows validation runs outside the restricted sandbox because processx pipe
creation is blocked there. This is an environment constraint, not a termr test
failure. WSL uses C.UTF-8; native Windows clears invalid inherited LC_* values
before R starts. Headless Unicode and parser tests run in the suites. Live
POSIX PTY, binary safety and combined Tab+Enter restoration tests are separate
logs. No current macOS CI or real Windows console session was run; historical
platform reports are not reused as H3 passes.
'''
docs['TEST-RESULTS.md'] = f'''# H3 validation results

Windows: {total('full-windows.log')}; {check('check-windows.log')}.

WSL: {total('full-wsl.log')}; {check('check-wsl.log')}.

{status_table}

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
'''
docs['FIXES.md'] = '''# H3 code changes

1. R/app.R: guard inkr tree release/cache reset in widget_unmounting and
   screen_leaving by presence of an active inkr stylesheet. Root cause and
   allocations: redundant 4,096-slot resets without the integration enabled.
   Resource ownership, hooks, tree order and App lifecycle are unchanged.
2. R/inkr-integration.R: add epoch-scoped public element and path-prefix
   reuse; avoid rebuilding an ancestor signature list on style-cache hits;
   explicitly release both new entries during tree/sheet cleanup. Preserve the
   existing bounded App cache, public inkr engine and typed style mapping.
3. R/event-queue.R: replace copy-on-modify list storage with per-instance
   reusable ring hash bindings; remove consumed references and release expanded
   empty tables. Preserve FIFO, clear, empty/NULL behavior and integer size.
   Bounded slot indices prevent lifetime overflow and interned-symbol growth.
4. R/chart-widget.R: publish the first chunk and final drain immediately and
   coalesce intermediate publication to 60 Hz while backlog remains. Previously
   empty-queue-only publication starved continuous streams. The initial eager
   candidate published every chunk at 473 MB in the fixture; the coalesced final
   candidate uses about 104 MB while retaining freshness. This is an intentional
   freshness repair with additional redraw work relative to a stale display.
5. tests/testthat/test-h3-performance-contracts.R: new correctness/allocation
   contracts. test-chart-streams.R and test-h2-contracts.R: update only the
   intermediate publication expectation, preserving the original drain checks.

The baseline includes substantial prior user work. h3-only.patch is the review
diff against that baseline, not git diff against HEAD. preservation.json checks
all 567 initial non-audit files and permits only the eight existing files listed
above including docs/charts.md and docs/inkr-integration.md; the new test and audit
artifacts are additive. No unrelated changes were
staged, reset or overwritten. See benchmark tables for costs and residuals.
'''
docs['KNOWN-LIMITATIONS.md'] = '''# Known limitations

- Repeated sibling removal still searches/rebuilds the parent list quadratically;
  lifecycle callback observability prevents a casual bulk-detach rewrite.
- inkr session sibling insertion remains quadratic in the independent package.
  The existing stateless bridge is retained. Deep path prefixes still consume
  depth-dependent strings; global epochs and conservative layout invalidation
  remain broader than ideal.
- Continuous chart publication now performs more real redraw work. Max-points
  and queue caps remain unchanged; virtual time is not physical frame latency.
- Timings are instrumented and some jobs overlapped. Use min/max and allocation
  evidence; small timing differences are not established speedups. Windows
  timer resolution makes zero-duration cases unsuitable for ratios.
- Gross Rprofmem bytes exclude some small/external allocations. Peak process
  memory, keyboard-to-photon latency, fresh-process startup, dedicated OS handle/
  process/socket counts and exhaustive long-duration leak freedom are unproven.
- Local table sort/filter are global operations; bounded display does not make
  them constant time. A4 benchmark exports ten selected rows, not a full table.
- Optional dependency absences are listed per platform. No current mirai,
  nanonext or duckdb integration soak, macOS CI, real Windows console or network
  terminal latency run is claimed. No global packages were installed.

The reports describe measured coverage and unmeasured boundaries separately.
They do not equate successful check with complete Suggests/platform coverage.
'''
docs['H4-HANDOFF.md'] = '''# H4 long-run handoff

Use the source archive/hash and h3-only.patch as the exact H3 candidate. Start
with the commands in run-windows.ps1 and run-wsl-final.sh, inspect every .exit,
and load platform manifests before enabling optional workloads. Do not undo
H1/H2 atomic source replacement, exact export, ownership, finite count checks,
detached bubbling, Pilot cleanup or projection keys.

Run 1h/8h/24h continuous producer tests with keyboard input and terminal resizes.
Keep producer faster than consumer, record displayed sequence lag, max queue/
points, timer delay, handler and frame p50/p95/p99, ANSI bytes, disconnects and
post-unmount callbacks. H3's virtual-time fairness check is a deterministic
starting reproducer, not a real-time certificate.

Extend 1,000-cycle memory tests with object reference tracking and separate
R-live-heap, RSS, OS handle, child-process and socket census. Sample after warmup
and after explicit GC; compare slopes with the observer's own retained rows.
Combine stylesheet swap/clear, large subtree replacement, source switching,
owned and borrowed DBI connections, stream bind/unbind and optional async task
cancellation. Keep bounded cache/subscriber assertions active throughout.

Priority remaining investigations: semantics-preserving bulk child removal;
App-local versus global style epochs; deep-prefix retained memory; narrower
layout invalidation; independent inkr session key insertion. Coordinate any
inkr change in its own repository using the public reproducer, never copy its
engine into termr. EventQueue remains unbounded by total pending events; the
existing per-tick budget prevents a single dispatch turn from monopolizing the
loop, but overload policy is a separate API/design decision.

Repeat clean-machine timing on Windows/WSL separately, with profiling disabled
for a latency series and enabled for an allocation series. Add current macOS
CI and actual Windows console/ConPTY host runs. Any future performance patch
must retain the new freshness, FIFO/reference-release and cache-invalidation
contracts and compare the unchanged neighboring scenarios.

Temporary staging folders were removed after successful archive verification.
For this audit's staged rerun, first run prepare-ring-validation.py to recreate
the Windows staging directory and ring runners. These helpers overlay R/test
sources onto the trusted earlier archive; if other package files or fixtures
change in H4, stage the complete new package inputs instead. The workspace and
verified final archives, rather than the old ring-stage.json path, are the
authoritative H3 candidate.
'''
docs['EXECUTIVE-SUMMARY.md'] += '''
The alternating paired bridge experiment is the stronger inkr timing control:
four repetitions per variant in one R process, with the original bridge loaded
from the immutable snapshot. Element reuse and cache-hit work improve; the
unchanged public compute control is stable. Cold 1,000-wide unique render
ranges overlap, so a material wide-render speedup is not established. Do not
attribute the larger unpaired core timing differences entirely to this patch.
'''
docs['INKR-OPTIMIZATION.md'] += '\n## Alternating paired control\n\n' + paired_table + '''

This series alternates before/after and after/before order, after warming both,
with four recorded repetitions per variant. It compares the actual baseline
bridge functions with current ones, not a rewritten model. Setup is excluded.
Whole cold wide render is effectively unchanged within spread; the clear gains
are repeated public element requests, deep ancestor reuse and bridge cache
hits. The unchanged ink_compute control helps detect unrelated machine drift.
The main core series remains useful for allocations and coverage, with its
larger timing limitations explicitly retained.
'''
docs['MEMORY.md'] += '''
## Rejected intermediate queue and final lifetime test

The first environment candidate used monotonically increasing binding names.
At 50,000 push/pop operations with only one pending item it retained 152,001
additional Ncells and used live key 50,001. This was introduced during H3 and
rejected before completion; it is not a claim about the initial H2 list queue.
The final growable ring reuses names within capacity. The same test stays
within 64 slots and records 2,263 additional Ncells at 50,000 operations;
from 10,000 onward almost all small growth is the retained observer rows.
queue-lifetime-before-ring.csv and queue-lifetime-after-ring.csv preserve all
ten samples. A regression keeps the queue non-empty for 10,000 operations and
also checks growth while the FIFO wraps across the end of its storage.

R environment bindings use symbols and hashed storage; this explains why
bounding live queue length alone was insufficient for the first candidate.
See the primary [R Internals manual, environments/hash tables](https://stat.ethz.ch/CRAN/doc/manuals/r-release/R-ints.html#Environments-and-variable-lookup).
Our retained-memory finding comes from the observed current-R experiment;
it is not inferred solely from RSS or the manual.
'''
docs['EVENT-LOOP.md'] += '''
Growth reindexes only pending items when capacity doubles, so push is amortized
O(1), pop O(1), and a growth step O(pending). An empty large queue releases its
expanded storage. R may retain interned slot symbols up to the largest historic
capacity; their range depends on peak pending depth, not lifetime throughput.
The rejected monotonically numbered candidate and its lifetime measurements
are documented in MEMORY.md. Original list-copy measurements remain the H2
baseline; final ring measurements replace the intermediate environment numbers.
'''
docs['TEST-RESULTS.md'] += '''
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
'''
docs['BENCHMARKS-BEFORE-AFTER.md'] += '\n## Paired bridge control\n\n' + paired_table + '''

The final continuous-stream row comes from after-stream.csv. The earlier
after-core.csv stream row is the rejected eager-render candidate and is
excluded from this table. The remaining core timed paths do not call the
modified EventQueue; they retain the same final App/inkr functions. Queue,
stream, broad/extra App scenarios and lifecycle/resource runs were repeated
after the ring change. before/after-components.csv measures unchanged bridge
component code independently. Ring lifetime measurements are separate live
heap observations, not gross-allocation benchmarks.
'''
docs['FIXES.md'] += '''
docs/charts.md documents coalesced live publication; docs/inkr-integration.md
documents epoch-scoped parent/path reuse. No public function formals, exports,
DESCRIPTION dependencies, NAMESPACE or generated man files changed.
'''
docs['WINDOWS-WSL.md'] += '''
Use run-windows-ring.ps1 and run-wsl-ring.sh for this final candidate. Preparing
their staging copy requires the trusted earlier archive plus the current R/test
overlay; ring-stage.json records that source set. The first WSL invocation
selected docker-desktop by default, and the first audit shell script needed LF
normalization. Final runs explicitly use `wsl.exe -d Ubuntu` and LF scripts.
These launch/staging issues are not represented as passing package checks.
'''
docs['LAYOUT-RENDERER.md'] += '''
Granular CSVs separately time layout_tree and paint_tree for 1,000 unique
widgets, with and without inkr. Painting starts from a prepared layout and
buffer; those setup costs are excluded. This separates measurement/layout work
from painting instead of treating compose_frame as a layout-only measurement.
'''
docs['EVENT-LOOP.md'] += '''
Granular CSVs also measure 100 actual Tab transitions through an App with 1,000
focusable buttons and parser feeds containing 1/100/10,000 combined Tab+Enter
pairs. Parser rows count pairs (two events each); they exclude OS reads and App
dispatch. The earlier tree-focus row has non-focusable labels and measures the
empty-chain scan, not the same workload as real button focus traversal.
'''
docs['DATATABLE.md'] += '''
Granular source-cache-hit and source-replacement rows separately measure a
prepared cached render and set_data of the same synthetic 10-million-row source
followed by render. This one-column fixture isolates cache/replacement overhead;
the 40-column/12-visible-column fixture remains the projection/scroll workload.
'''
for name, body in docs.items():
    (out/name).write_text(body.strip()+'\n', encoding='utf-8')
assert len(docs) == 17
print('Generated', len(docs), 'reports;', len(keys), 'benchmark scenario/size pairs')
