# Optional asynchronous tasks with mirai

The task pool API is experimental. Install mirai >=2.7.3, nanonext >=1.10.0 and
jsonlite only when using it. No optional namespace is loaded by ordinary termr
use. Existing processx workers and the reactive engine remain unchanged.

```r
pool <- termr::termr_mirai_pool(workers = 2L, max_pending = 128L)
task <- pool$submit(function(n) sum(seq_len(n)), args = list(n = 1000000L))
task$status()     # queued/running/completed/failed/cancelled/timed_out
task$ready()      # nonblocking
task$info()       # identity, times, progress, bounded metadata, cancellation flag
# In a TUI timer: pool$poll(); update widgets from task$info().
# Only explicitly requested waits block:
task$wait(timeout = 10)$result()
pool$close()
```

`termr_mirai_submit(pool, fn, args=...)` is also exported. Argument lists must
be uniquely named; no implicit global export is performed. Minimal lexical
captures reuse the processx capture rules: helpers/scalars and ordinary R data
work; dynamic lexical lookup, active bindings and reference-bearing input
objects (environment, connection, R6, external pointer, S4) are rejected. Function
source references are removed from the copy. Namespace functions retain their
namespace semantics; `packages` attaches explicitly required packages in the
daemon. Input preparation/serialization uses CPU synchronously, so large inputs
are not free to submit. Default serialized input limit is 8 MiB per task.

The pool owns a unique private compute profile, uses mirai's dispatcher and
`try_mirai()` for admission, and never resets the default/another caller's pool.
Worker count is bounded (1..64). `max_pending` limits unresolved tasks; `memory`
defaults to 64 MB of approximate dispatcher queued payloads. Native memory
capacity can overshoot by one admitted payload; per-task input size and task
count remain bounded. A saturated queue rejects submission immediately instead
of waiting or silently queuing in an extra scheduler. Local pool construction
waits up to `startup_timeout` for worker connections and propagates current
library paths with R_TESTS cleared only for launch; parent variables are restored.

`pool$close()` is idempotent, cancels owned requests and closes only its private
profile/socket/stream. `pool$restart()` explicitly cancels pending requests and
recreates that profile after a daemon crash. No hidden retry changes user side
effects. Pool cleanup belongs in app/session try/finally. `pool$tasks()` contains
active handles only; terminal handles/results are caller-owned. Bound your own
retained results. There is no finalizer guarantee if the owner neglects cleanup.

Shutdown first asks only the private profile's daemons to exit and waits for
their connections to disconnect before resetting the dispatcher. This avoids
a reproduced nanonext 1.10.3 native wait when an active dispatcher is reset.
If workers ignore the interrupt/exit request, close/restart can force-stop only
the worker processes verified at pool startup (ps handles include creation time
to guard against PID reuse). This stronger owner-shutdown action is separate
from ordinary task cancellation. Third-party package files are not patched.

`task$result()` never waits: it errors while unresolved or unsuccessful and
returns the full native R value only on completion. Numeric vectors, lists,
data.frames, factors, POSIXct and NA/NaN/Inf retain R semantics. They are not
round-tripped through JSON. A separate result summary in telemetry contains
only type/length/size. `finished_at` means host resolution time, not a measured
worker stop time. `started_at` remains unknown until a worker start/progress
message or result wrapper confirms it; no dispatch estimate is invented.

Cancellation calls public `stop_mirai()`. Already-observed completion wins;
repeated cancellation returns FALSE. Backend code 20 confirms cancelled mirai
resolution, not immediate physical cessation of compiled code or all side
effects. Timeout code 5 maps to timed_out and includes waiting in the dispatcher
queue; unexpected daemon termination/code 19 maps to failed. A task's terminal
state/event is emitted once. The explicit `task$wait(timeout)` limit leaves an
unresolved task active; use `cancel()` if desired.

## Progress and events

```r
task <- pool$submit(function(progress) {
  for (i in 1:100) {
    # Work on a chunk here.
    progress(i / 100, paste("chunk", i))
  }
  TRUE
}, progress = TRUE)
subscription <- pool$events$subscribe(function(event) print(event$event))
# Owner's timer/main loop calls pool$poll().
subscription$unsubscribe()
```

The worker creates its own reporter/socket; no parent stream, environment,
connection or R6 object is passed into it. One pool-owned pull socket and one
push socket per executing task carry bounded raw JSON on an ephemeral loopback
port. Send is nonblocking, progress is throttled (default .05 s), native buffers
are bounded, and poll drains at most 128 messages by default. Slow consumers can
lose intermediate progress. Final envelopes reconcile last known progress and
start data. Repeating `progress(1)` cannot bypass throttling.

Known fractions must be monotonic in [0,1]; NA means unknown and does not reset
the last-known monotonic bound. NaN/Inf are rejected for percentages. Messages
are truncated/control-cleaned. `progress_stats` counts reported/throttled calls
and attempted/accepted native sends; accepted is not a consumer delivery ACK.
Progress event `timestamp` is host publication time; `reported_at` is the worker
message time and `progress_sequence` supports deduplication/diagnostics.

The read-only `pool$events` view is backed by termr_stream, shares its subscription
contract and works with the existing nano publisher/Shiny receiver. It publishes
task_submitted, confirmed task_started, task_progress and exactly one of
task_completed/task_failed/task_cancelled/task_timed_out. Metadata history is
bounded (default 256), full results are excluded. Duplicate/out-of-order/late
progress cannot change terminal state. Reentrant pool mutation during delivery
is rejected before changing state; defer actions until delivery returns. Callback
errors remain isolated by the stream. There is no replay or global task registry.

## TUI, Shiny and ownership

See [runnable examples](../inst/examples/mirai-tasks/README.md). TUI owns a timer
and pool, and closes it in try/finally. Heavy work runs in daemons. Shiny
`task$promise()` uses native event-driven mirai/promises conversion; it installs
no timer. With ExtendedTask, snapshot reactive inputs into invoke arguments and
return this promise from the computation function. The example handles terminal
errors/cancellation as a displayed outcome and creates its ExtendedTask outside
a session scope to permit safe late callback completion.

An independent producer has a different owner. Its bounded state snapshots use
existing stream/nanonext APIs; remote Shiny sessions observe one shared receiver,
never create a pool per graph and never close the producer. Loopback telemetry
is local and unauthenticated; it carries metadata, not executable commands.

## processx and platform differences

Processx run_worker starts a fresh Rscript per job, streams stdout/stderr and
file-based progress, and has app/widget ownership. Mirai reuses bounded workers,
uses native local result transport and an explicit native progress channel,
with explicit pool/task ownership. Neither backend replaces the other. Small
jobs may cost more to dispatch than to run inline; offload to preserve UI
responsiveness or when measured parallel work amortizes overhead.

Windows uses mirai local IPC, WSL local abstract IPC (observed versions); neither
requires fork. Use one OS per pool. Progress stays on that OS's loopback. The
previous Windows-publisher→WSL-localhost limitation applies to optional remote
telemetry, not same-host mirai workers. No firewall/network setting is changed.
Cancellation of uninterruptible compiled code remains a backend limitation.
Tasks that spawn their own independent processes or manage external resources
need their own cleanup; this pool manages its mirai daemons, not an OS sandbox.
See audit-results/mirai for measured versions, performance, PTY coverage and
known limitations rather than inferring terminal support from headless tests.

Official references: [mirai evaluation/try_mirai](https://mirai.r-lib.org/reference/mirai.html),
[daemon pools](https://mirai.r-lib.org/reference/daemons.html),
[cancellation](https://mirai.r-lib.org/reference/stop_mirai.html),
[evaluate everywhere](https://mirai.r-lib.org/reference/everywhere.html),
and [Shiny ExtendedTask](https://shiny.posit.co/r/articles/improve/nonblocking/).
