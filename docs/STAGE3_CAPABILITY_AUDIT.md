# Stage 3 capability audit

Audit date: 2026-10-26  
Stage 3 branch base: `feature/worker-lifecycle-1.1` at
`bbcab0be81d4ce81c33f64c23cef2678e608cb1f` (`docs: record completed lifecycle
matrix evidence`). The selected base is the Stage 1 branch because its
compatibility report records completed lifecycle jobs on Ubuntu, Windows and
macOS in [run 40318579995](https://github.com/menshikovs/termr/actions/runs/40318579995).
The Stage 2 edits in the other checkout are uncommitted and are intentionally
not included in this branch. Stage 2's layout diagnostics are therefore not
available here.

## Existing capabilities

### Process execution and workers

`process_view()` is already an exported experimental widget. Its existing
signature is `process_view(command, args, wd, env, timeout, autostart,
max_lines, id, classes, style)` with defaults preserved in the constructor. It
runs an argument-vector command through `App$run_process()` (no shell), streams
stdout and stderr into a bounded `LogView`, autostarts on mount, and uses
`owner = self` so normal widget removal and app shutdown clean up the worker.
The default Ctrl+X and Ctrl+R bindings already cancel and restart. `$start()`
rejects a second concurrent run; each new run clears the old log.

`LogView` already provides bounded line retention, live writes, stderr levels,
automatic follow-to-end, pause/resume and clear. The 2000-line `ProcessView`
default avoids unbounded output history. Filtering is not available and is not
needed for this component's current purpose.

The selected Stage 1 base adds `Worker$request_cancel(grace = 30)`,
`Worker$cancel_requested`, opt-in `App$exit(worker_grace = ...)`, and
`supervision = "none" | "parent"` to worker/process entry points. Its default
interrupt uses processx (`SIGINT` on POSIX and `CTRL+BREAK` on Windows); there
is no API for selecting an arbitrary initial signal. Parent supervision is
provided by processx, is opt-in, and does not promise arbitrary descendant
tree supervision.

The current `ProcessView` only uses synchronous `Worker$cancel()` and always
uses default supervision. It renders `running`, `completed`, `cancelled`, or
failure/timeout text, but does not show a pending asynchronous stop or expose a
convenient state/exit-status view. Its `process.finished` message has the
existing `status` and `state` fields. `Worker$result` supplies an exit status
for success; process `on_exit(status, app)` supplies it for both natural
success and failure. Cancellation intentionally has no exit callback and no
reliable exit code.

### Dynamic widgets and state

- `Widget$visible` and `$disabled` are writable reactive fields. The focus
  manager already excludes hidden and disabled widgets and reconciles invalid
  focus on subsequent app ticks.
- `OptionList$set_choices()` replaces choices, resets the highlight to the
  first choice (or no choice for an empty list), and resets scrolling. It does
  not emit selection/highlight events during the programmatic replacement.
- `DataTable$set_data()` replaces data and currently resets cursor, scroll,
  sorting, filtering and selection. `DataTable$set_cell()`, `$filter()`,
  `$refresh()` for lazy sources, and column operations cover incremental
  updates. There is no row append/remove API; replacing a data frame or editing
  a cell covers the common application use cases without another abstraction.
- Labels and other built-in widgets expose direct update/assignment APIs.
  `signal()`, `computed()`, `watch()`, `batch()`, and `Widget$bind_reactive()`
  already support reactive labels and widget state. No second state system is
  needed.

### Developer tools and tests

- `inspect_widget()` reports widget type, region, visibility/displayed/enabled
  state, pseudo-states, reactive state (with password value redacted), styles,
  matching rules, bindings, parent and children.
- `App$focus_chain()` returns currently focusable widgets in order and
  `App$focused` returns the focused widget.
- `App$log_events()` / `$event_log()` provide an opt-in, bounded trace of
  dispatched event time, type, target and limited detail. It is disabled by
  default and does not record arbitrary widget values.
- `app(debug = TRUE)` enables the F12 overlay with dimensions, widget/screen
  counts, focus/hover, last event, repaint and worker/timer summaries. It is a
  non-focusable screen layer.
- `test_app()` / `Pilot` provide headless event/render tests and real-worker
  waiting. The Stage 1 lifecycle suite adds real-process coverage.

No separate inspector, event logger, profiler, or test driver is justified.
The selected base has no `layout_diagnostics()` API; layout-warning integration
must wait for Stage 2 integration.

## Confirmed limitations and proposed additions

1. Add trailing, optional `stop_grace = NULL` and `supervision = "none"` to
   `process_view()`. A `NULL` grace keeps existing synchronous cancellation.
   A supplied grace opts in to `Worker$request_cancel()` and a visible
   `stopping` presentation. The ProcessView owner observes the existing
   `worker.cancelled` message to finish that run once. `supervision` is passed
   through unchanged and remains `"none"` by default. No arbitrary
   `stop_signal` argument is proposed because Worker does not support it.
2. Add read-only ProcessView state/exit-status access and a `clear_output()`
   method using the existing worker and log. Keep the existing
   `process.finished(status, state)` payload and callback contracts. Record
   status from the existing `on_exit` callback; report `NA_integer_` when a
   cancelled process has no final status.
3. Keep explicit restart synchronous under legacy defaults. When a configured
   graceful stop is opted into, make an explicit `restart()` wait logically
   for the current Worker to become terminal before starting another run. Do
   not auto-retry. Preserve log clearing on each start.
4. Extend `inspect_widget()` additively with current focus and focus-chain
   position when the widget belongs to an app. Do not change key navigation.
5. Add a runnable dynamic-app example and focused tests using existing public
   list, table, visibility, focus and reactive APIs. Improve docs for existing
   capabilities instead of adding redundant row/list/widget wrappers.
6. Document event logging and the debug overlay as existing tools. Do not add
   handler instrumentation or change event dispatch/propagation semantics.
   Document that layout diagnostics are unavailable on this base.

## Features excluded as redundant or unsupported

- No new worker/process engine, custom signal selection, arbitrary process-tree
  guarantee, automatic retry, unbounded output store, table row wrapper API,
  second reactive layer, second inspector, event profiler, or global debug key.
- No Stage 2 layout-warning integration until its branch is integrated.
- No new mandatory package dependencies.

## Compatibility risks to validate

- All constructor additions must be trailing and optional. `stop_grace = NULL`
  and `supervision = "none"` must preserve current default cancel, shutdown,
  event, ownership and cleanup behavior.
- Asynchronous status and restart behavior must only activate when the caller
  supplies `stop_grace`; the existing Ctrl+X behavior stays synchronous by
  default. Existing `process.finished` fields and ordering must be retained.
- Process start errors, nonzero exit status, output limits, callback count and
  app/widget ownership must retain their existing contracts.
- Inspector fields are additive; the current result class and existing fields
  must remain intact. Focus diagnostics must not change focus dispatch.
- Stage 1's three-platform lifecycle evidence does not establish Stage 3
  behavior. The consumer launcher suite remains unavailable in the pinned
  public R-Knowledge-MCP revision because it does not contain the referenced
  test file, as documented in the Stage 1 compatibility report.
