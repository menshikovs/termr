# Background work

Long computations must not block the interface. termr runs them in separate
processes and reports back through events and callbacks. This API is
**experimental**.

## R functions: `app$run_worker()`

```r
app$run_worker(
  function(n) {
    for (i in seq_len(n)) {
      cat("step", i, "\n")                       # stdout -> on_stdout
      message("working")                        # stderr -> on_stderr
      termr_progress(i / n, paste("step", i))   # separate progress channel
      Sys.sleep(0.2)
    }
    "done"
  },
  args = list(n = 20),
  timeout = 60,
  on_progress = function(value, message, app) ...,
  on_stdout   = function(line, app) ...,
  on_stderr   = function(line, app) ...,
  on_complete = function(result, app) ...,
  on_error    = function(message, app) ...
)
```

The function runs in a fresh `Rscript --vanilla` session. termr prepares a
minimal closure containing the lexical bindings the function actually
references. Unrelated enclosing bindings are excluded, and referenced values
are captured by value. Simple scalar captures, nested helpers and recursive
helpers work; the caller's original function is not modified.

```r
scalar <- 11L
app$run_worker(function() scalar + 1L)  # returns 12L
```

Large objects still contribute to the job when explicitly referenced, and
values in `args` serialize normally. Prefer `args` for large data and list
required packages in `packages`; this makes the job's inputs explicit rather
than making large data free to transfer. Active bindings and dynamic lexical
lookup (such as `get()`, `eval()` or `parent.frame()`) are rejected before
spawn. Resolve those values in the caller and pass them as named arguments.

The child receives the parent's library search paths. `R_TESTS` is cleared
to prevent check-session startup hooks from rerunning tests, and the worker
uses the installed package helper. The result travels in an RDS file and
progress in an append-only file, so the job's own output is never parsed as
protocol. Output lines have control characters removed; at most 200 lines are
delivered per tick; the last 1,000 are kept in `worker$stdout` / `$stderr`.

## Programs: `app$run_process()`

```r
app$run_process("Rscript", c("-e", "cat('hello\n')"),
                on_stdout = function(line, app) ..., on_exit = function(status, app) ...)
```

Command and arguments are separate; there is no shell, so nothing is
interpolated (use `run_process("sh", c("-c", script))` if you really want one).
A non-zero exit status is a failure.

## Lifecycle

A worker (`Worker`) has `state` (`"running"`, `"completed"`, `"failed"`,
`"cancelled"`), `result`, `error`, `timed_out` and `cancel()`. The existing
`cancel(grace = 0.3)` remains synchronous: on Unix it interrupts first and
kills the process tree after the grace period; on Windows it kills the tree
immediately, as in termr 1.0.1.

```r
worker <- app$run_process("python", c("long_job.py"))
worker$cancel()  # synchronous; uses the existing default grace
```

Use `request_cancel()` when the UI must stay responsive while a child gets
time to clean up:

```r
worker <- app$run_process("python", c("long_job.py"))
worker$request_cancel(grace = 30)  # returns promptly
worker$cancel_requested            # TRUE while shutdown is in progress
# worker$state remains "running" until the process exits or is killed
worker$request_cancel(grace = 0)   # escalate to a force kill immediately
```

The first request sends processx's interrupt (SIGINT on Unix, CTRL+BREAK on
Windows). The app polls workers through its regular event loop and kills the
process tree when `grace` expires. The default grace is 30 seconds. Repeated
requests do not extend the original deadline; `grace = 0` forces immediate
termination. If the process has already exited when `request_cancel()` is
called, its natural completion or failure wins. If it was still alive when
the request was made, cancellation wins a later completion race.

`request_cancel()` emits `worker.cancelled` after the process has ended and
cleanup is complete. Like synchronous `cancel()`, it does not call
`on_complete`, `on_error` or `on_exit`. A cancelled process remains distinct
from a worker failure or timeout.

Applications can opt into graceful worker shutdown when exiting:

```r
app(label("Working"), on("button.pressed", function(event, app) {
  app$exit("done", worker_grace = 30)
}))
```

`app$exit(value, worker_grace = NULL)` keeps the existing synchronous
shutdown when `worker_grace` is omitted. When supplied, it requests
non-blocking cancellation for current workers and keeps polling them for the
configured grace period. Timers, new terminal input and new worker creation
are stopped during this drain; already queued worker events can still be
delivered. After the grace period, any remaining worker is forcefully
cancelled. Shutdown has a one-second final polling bound after the grace so a
failed process cannot hold the terminal indefinitely. The terminal is
restored after this drain.

### Lifecycle transitions

| Current state | Cause | Next state | Terminal event and callback |
|---|---|---|---|
| `running` | Successful function return or process exit 0 | `completed` | `worker.completed`, then `on_complete`; `run_process()` then calls `on_exit` |
| `running` | Function error, non-zero process exit or timeout | `failed` | `worker.failed`, then `on_error`; `run_process()` then calls `on_exit` |
| `running` | `cancel(grace)` | `cancelled` | Synchronous `worker.cancelled`; no completion/error/exit callback |
| `running` | `request_cancel(grace)` and child exits or is forcefully terminated | `cancelled` | Non-blocking `worker.cancelled` after output drain and cleanup; no completion/error/exit callback |
| Terminal state | Repeated cancel request | unchanged | No second terminal event; returns `FALSE` |

An app exit with `worker_grace` follows the asynchronous cancellation row and
delivers terminal worker events before `run()` returns, to the extent that
the process exits within the selected bound. The default `app$exit()` path
retains the 1.0.1 synchronous worker cleanup behavior.

### Optional parent-process supervision

`run_process()` and `run_worker()` accept `supervision = "none"` (the default)
or `supervision = "parent"`. The opt-in value delegates to processx's
`supervise = TRUE` policy. It registers each direct child with a temporary
processx helper. If the R parent exits or crashes, the helper notices within
its polling interval and terminates registered children. On Unix it sends
SIGTERM, waits up to five seconds, then sends SIGKILL. On Windows it sends
CTRL+C / WM_CLOSE and then force-terminates after the grace period. This can
cover parent SIGTERM, SIGHUP and SIGKILL without an R signal handler.

The policy is opt-in and does not change normal process lifetime by default.
Normal termr shutdown still uses processx `cleanup_tree = TRUE` to clean up
descendants. Crash supervision registers direct child PIDs; it does not
promise that arbitrary grandchildren on Unix will be terminated if the
parent R process is killed. Processx also documents a Windows Defender or
antivirus caveat for its bundled supervisor executable. A processx version
without the documented `supervise` constructor option rejects this opt-in;
the termr dependency minimum is not raised for applications that leave
supervision disabled.

termr does not expose detached subprocesses: workers and programs remain
owned by the app and are cleaned up by normal app shutdown. `supervision =
"none"` retains the existing app-owned behavior. `supervision = "parent"`
adds processx's parent-death helper for the direct process.

The helper is a per-R-session process, not a system service. The supervisor
tracks process IDs, so termr does not claim a PID-reuse-proof guarantee beyond
processx's implementation. For deployments requiring that stronger
guarantee, validate the platform and processx version used by the application.
SIGKILL cannot be handled by R itself; the external helper is the mechanism
that observes parent death. Neither processx supervision nor termr can run
application cleanup code after SIGKILL.

Applications written for termr 1.0.1 need no migration to keep their current
behavior. Existing `cancel()`, `app$exit()`, timeout, callback and ownership
defaults are unchanged; the new paths apply only when explicitly requested.

### Existing ownership and timeout behavior

Workers end when cancelled, when their owner widget is removed
(`widget$run_worker()`), after `timeout`, and when the app exits. Owner removal
and the default app exit still call synchronous `cancel()`. Timeouts still
produce `failed` with `timed_out = TRUE`; their meaning is unchanged.
Temporary files have unique names and are removed however the worker ends.

Events (bubbling from the owner widget or the screen, `event$data$worker`):
`worker.started`, `worker.progress`, `worker.stdout`, `worker.stderr`,
`worker.completed`, `worker.failed` (`timed_out`, `status`), `worker.cancelled`.

## Secrets and temporary files

A worker job (the function with its referenced lexical bindings, plus `args`)
is serialized to a temporary file that the worker process reads; unrelated
enclosing state is omitted. Explicitly referenced objects, including large
values and environments, still serialize. The file is
removed when the worker ends. Workers and `run_process()` programs inherit
the app's environment variables. Avoid putting secrets into worker closures
or arguments unnecessarily, and pass only the variables a program needs
through `env` rather than exporting them globally.

## `process_view()`

A ready-made widget: status line plus scrolling log for one program;
Ctrl+X cancels, Ctrl+R restarts, `process.finished` is sent at the end.

## Testing

`inline = TRUE` runs a function in the current process (deterministic);
`pilot$run_worker(fn)`, `pilot$wait_for_workers()` and `pilot$wait_for()` handle
real processes. There is no worker pool: start as many workers as you need.
