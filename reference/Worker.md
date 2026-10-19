# Worker handle

Returned by `app$run_worker()` and `app$run_process()`. See
[`run_worker()`](https://menshikovs.github.io/termr/reference/run_worker.md).

## Public fields

- `name`:

  Name of the worker (used in events).

- `state`:

  `"running"`, `"completed"`, `"failed"` or `"cancelled"`.

- `result`:

  The value returned by the function (workers) or the exit status
  (processes).

- `error`:

  The error message, if it failed.

- `timed_out`:

  Did the worker fail because its timeout expired?

- `progress`:

  Last reported progress value.

- `owner`:

  Widget that owns the worker, or `NULL`.

- `stdout, stderr`:

  The most recent output lines (at most 1000).

- `kind`:

  `"worker"` (an R function) or `"process"`.

## Methods

### Public methods

- [`Worker$new()`](#method-Worker-initialize)

- [`Worker$cancel()`](#method-Worker-cancel)

- [`Worker$is_running()`](#method-Worker-is_running)

- [`Worker$pid()`](#method-Worker-pid)

- [`Worker$print()`](#method-Worker-print)

- [`Worker$clone()`](#method-Worker-clone)

------------------------------------------------------------------------

### `Worker$new()`

Create a worker (use `app$run_worker()`).

#### Usage

    Worker$new(name, owner = NULL, callbacks = list())

#### Arguments

- `name`:

  Name.

- `owner`:

  Owner widget.

- `callbacks`:

  List of callbacks.

------------------------------------------------------------------------

### `Worker$cancel()`

Stop the worker: an interrupt is sent first (Unix) and the process tree
is killed if it has not ended after `grace` seconds.

#### Usage

    Worker$cancel(grace = 0.3)

#### Arguments

- `grace`:

  Seconds to wait before killing.

------------------------------------------------------------------------

### `Worker$is_running()`

Is the worker still running?

#### Usage

    Worker$is_running()

------------------------------------------------------------------------

### `Worker$pid()`

Process id of the child (or `NA`).

#### Usage

    Worker$pid()

------------------------------------------------------------------------

### `Worker$print()`

Print the worker.

#### Usage

    Worker$print(...)

#### Arguments

- `...`:

  Ignored.

------------------------------------------------------------------------

### `Worker$clone()`

The objects of this class are cloneable with this method.

#### Usage

    Worker$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
