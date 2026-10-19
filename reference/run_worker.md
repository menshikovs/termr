# Background workers and subprocesses

`app$run_worker()` runs a function in a separate R process and reports
back through events and callbacks, so the interface stays responsive
during long computations (model fitting, downloads, file processing).
`app$run_process()` does the same for an external program.

## Usage

``` r
run_worker(
  fn,
  args = list(),
  on_complete = NULL,
  on_error = NULL,
  on_progress = NULL,
  name = NULL,
  owner = NULL,
  packages = character(),
  inline = FALSE,
  on_stdout = NULL,
  on_stderr = NULL,
  timeout = NULL,
  app = current_app()
)

run_process(
  command,
  args = character(),
  on_complete = NULL,
  on_error = NULL,
  on_stdout = NULL,
  on_stderr = NULL,
  on_exit = NULL,
  timeout = NULL,
  wd = NULL,
  env = NULL,
  name = NULL,
  owner = NULL,
  app = current_app()
)
```

## Arguments

- fn:

  The function to run.

- args:

  A list of arguments.

- on_complete:

  `function(result, app)`.

- on_error:

  `function(message, app)`.

- on_progress:

  `function(value, message, app)`.

- name:

  Name of the worker.

- owner:

  A widget owning the worker (events come from it, and it is cancelled
  when the widget is removed).

- packages:

  Packages to attach in the worker process.

- inline:

  Run in this process instead (for tests).

- on_stdout, on_stderr:

  `function(line, app)` called for each output line.

- timeout:

  Seconds after which the worker is stopped and fails (`NULL`: no
  limit).

- app:

  The app (defaults to the running app).

- command:

  The program to run (a path or a name found on the `PATH`).

- on_exit:

  `function(status, app)` called when the process ends (whatever the
  status).

- wd:

  Working directory (`NULL`: the current one).

- env:

  Named character vector of extra environment variables.

## Value

A [Worker](https://menshikovs.github.io/termr/reference/Worker.md)
handle with `cancel()`, `state`, `result`, `error`, `stdout` and
`stderr`.

## Details

The function runs in a fresh R session (`Rscript --vanilla`), so it
cannot directly access the caller's global environment. Lexical values
referenced by the function are captured by value in a small environment;
unrelated bindings in the enclosing environment are omitted. For
example, a function using a local `scalar` binding works without
serializing other locals. Referenced nested and recursive helper
functions are captured too. Dynamic lexical lookup
([`get()`](https://rdrr.io/r/base/get.html),
[`eval()`](https://rdrr.io/r/base/eval.html) or
[`parent.frame()`](https://rdrr.io/r/base/sys.parent.html)) and active
bindings are rejected; pass those values explicitly through `args`.
Prefer `args` for large data and list required packages in `packages`.
Inside the function, `termr_progress(value, message)` reports progress
on a channel of its own, so anything the function prints to stdout or
stderr is free for `on_stdout` / `on_stderr`
([`message()`](https://rdrr.io/r/base/message.html) goes to stderr). The
child receives the parent's library search paths, and `R_TESTS` is
cleared so a check-session startup hook cannot rerun the test suite.

`run_process(command, args)` starts a program *without a shell*: the
command and its arguments are separate, so nothing is interpolated or
interpreted. (To use a shell on purpose, run it yourself:
`run_process("sh", c("-c", script))`.) It completes with the exit status
as `result`; a non-zero status counts as failure.

Events (from the owner widget, or the screen), with `event$data$worker`:
`"worker.started"`, `"worker.progress"` (`value`, `message`),
`"worker.stdout"` / `"worker.stderr"` (`line`), `"worker.completed"`
(`result`), `"worker.failed"` (`error`, `timed_out`, `status`),
`"worker.cancelled"`. Output lines are stripped of control characters;
at most 200 lines are delivered per event-loop tick.

Workers stop when `cancel()` is called, when their owner widget is
removed, when `timeout` seconds have passed, and when the app exits. A
stopping worker is interrupted first (Unix) and killed, with its child
processes, if it does not end within a short grace period.

Temporary files (the job, the result and the progress file) have unique
names and are removed when the worker ends, however it ends.

The job (the function with its referenced lexical bindings, and `args`)
is serialized to a temporary file. Explicitly referenced objects and
values in `args` are still serialized. Workers and programs inherit the
app's environment variables: avoid putting secrets into worker closures
or arguments unnecessarily.

There is no worker pool: start as many workers as you need; each is an
independent process. This API is **experimental**.

## Testing

`inline = TRUE` runs the function in the current R process at once
(blocking), which makes tests fast and deterministic. With real
processes, `pilot$wait_for_workers()` waits until they finish.

## Examples

``` r
pilot <- test_app(app(label("Jobs")), width = 30, height = 1)
# `inline = TRUE` runs the job in this process; without it, the same call
# starts a background R process, where `termr_progress()` is available.
pilot$app$run_worker(
  function(n) sum(seq_len(n)),
  args = list(n = 20),
  inline = TRUE,
  on_complete = function(result, app) message("result: ", result)
)
#> result: 210
pilot$step()
pilot$stop()
```
