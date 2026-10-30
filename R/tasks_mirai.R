mirai_require <- function() {
  if (!requireNamespace("mirai", quietly = TRUE) || utils::packageVersion("mirai") < "2.7.3") {
    stop("Install optional package 'mirai' (>= 2.7.3) to use this backend.", call. = FALSE)
  }
  nano_require()
}

mirai_pool_state <- function(pool) {
  state <- attr(pool, "termr_mirai", exact = TRUE)
  if (!inherits(pool, "termr_mirai_pool") || !is.environment(state)) stop("Invalid mirai pool.", call. = FALSE)
  state
}

#' An explicitly owned optional mirai task pool
#'
#' Experimental UI-independent runtime. Uses a private named mirai compute
#' profile and its dispatcher, never the caller's default/shared pool. Creation
#' waits at most `startup_timeout` for local daemons; task dispatch and polling
#' do not wait for computation or queue capacity. Serialization still costs CPU.
#' Requires optional mirai >= 2.7.3, nanonext and jsonlite. Ordinary termr use
#' does not load them. Existing processx workers are unchanged.
#'
#' Methods: `$submit(fn, args, ...)` (same arguments as [termr_mirai_submit()]
#' except pool), `$poll(max_messages = 128L)`, `$tasks()` (active task handles),
#' `$diagnostics()`, `$close()`, `$restart()` and `$is_closed()`. Close is
#' idempotent, cancels owned tasks and resets only its private compute profile.
#' Restart cancels pending tasks and recreates only this pool, retaining its
#' event history. Neither method operates on another application's pool.
#' Shutdown asks private daemon peers to exit before resetting the dispatcher;
#' a bounded grace period can be followed by force-stopping only the verified
#' owned worker processes. Ordinary task cancellation does not force-kill them.
#'
#' `$events` is a read-only stream view (latest/history/subscribe/poll) backed
#' by [termr_stream()]. Events have a monotonic pool sequence and bounded JSON
#' metadata; full results remain in caller-owned task handles. Terminal tasks
#' are removed from the pool registry. Callers must bound retained handles and
#' result objects. There is no additional scheduler, automatic retry or replay.
#'
#' Polling drains at most `max_messages` progress records and reconciles at
#' most `max_pending` tasks. R callbacks run on the main thread. Slow callbacks
#' delay their owner. Reentrant pool mutation from stream callbacks is rejected;
#' defer submit/cancel/close until after delivery. Explicitly close your pool in
#' app/session cleanup. A session monitoring an independent producer must not
#' close that producer's pool.
#'
#' @param workers Number of local daemons, 1..64.
#' @param max_pending Maximum admitted unresolved tasks, 1..10000.
#' @param history Retained metadata events, 1..100000.
#' @param memory Dispatcher queued payload limit in MB, 1..4096.
#' @param max_input_bytes Serialized input limit per task, 1024..268435456.
#' @param progress_interval Minimum progress send interval in seconds, .01..60.
#' @param startup_timeout Maximum seconds to wait for daemon connections.
#' @param seed Optional integer seed passed to mirai's reproducible RNG.
#' @return A pool handle with a read-only event stream.
#' @export
#' @examples
#' if (interactive() && requireNamespace("mirai", quietly = TRUE)) {
#'   pool <- termr_mirai_pool(2L)
#'   task <- pool$submit(function(n) sum(seq_len(n)), args = list(n = 1000L))
#'   task$wait(10)
#'   task$result()
#'   pool$close()
#' }
termr_mirai_pool <- function(workers = 2L, max_pending = 128L, history = 256L,
                             memory = 64, max_input_bytes = 8 * 1024^2,
                             progress_interval = 0.05, startup_timeout = 15, seed = NULL) {
  mirai_require()
  integer_option <- function(x, name, low, high) {
    if (!nano_number(x, low, high, TRUE)) stop("Invalid `", name, "`.", call. = FALSE)
    as.integer(x)
  }
  workers <- integer_option(workers, "workers", 1, 64)
  max_pending <- integer_option(max_pending, "max_pending", 1, 10000)
  history <- integer_option(history, "history", 1, 100000)
  max_input_bytes <- integer_option(max_input_bytes, "max_input_bytes", 1024, 268435456)
  if (!nano_number(memory, 1, 4096) || !nano_number(progress_interval, .01, 60) ||
      !nano_number(startup_timeout, .1, 300)) stop("Invalid pool limit or interval.", call. = FALSE)
  if (!is.null(seed) && !nano_number(seed, 0, .Machine$integer.max, TRUE)) stop("Invalid seed.", call. = FALSE)
  state <- new.env(parent = emptyenv())
  state$id <- paste0("termr-", Sys.getpid(), "-", basename(tempfile()), "-", sprintf("%.0f", as.numeric(Sys.time()) * 1e6))
  state$profile <- state$id; state$closed <- FALSE; state$busy <- FALSE
  state$tasks <- new.env(hash = TRUE, parent = emptyenv())
  state$worker_handles <- list()
  state$counter <- 0; state$sequence <- 0
  state$counts <- stats::setNames(rep(0, 6L), c("submitted", "completed", "failed", "cancelled", "timed_out", "progress"))
  state$invalid <- 0L; state$late <- 0L
  state$max_pending <- max_pending; state$max_input_bytes <- max_input_bytes
  state$libraries <- normalizePath(.libPaths(), winslash = "/")
  state$stream <- termr_stream("tasks", history = history)
  state$pull <- nano_socket("pull", 4096L, 128L)
  ready <- FALSE
  on.exit(if (!ready) {
    close(state$pull)
    try(mirai_shutdown(state$profile, state$worker_handles), silent = TRUE)
    state$stream$close()
  }, add = TRUE)
  state$endpoint <- nano_listen(state$pull, "tcp://127.0.0.1:0")
  state$assert_mutable <- function() {
    if (state$closed) stop("Pool is closed.", call. = FALSE)
    if (state$busy) stop("Defer pool mutation until after event delivery.", call. = FALSE)
  }
  task_info <- function(task) list(task_id = task$id, task_type = task$type, backend = "mirai",
    submitted_at = task$submitted, started_at = task$started, finished_at = task$finished,
    status = task$status, progress = task$progress, error = task$error,
    cancel_requested = task$cancel_requested, metadata = task$metadata, progress_stats = task$progress_stats)
  emit <- function(task, type) {
    state$sequence <- state$sequence + 1
    event <- c(list(schema_version = 1L, source_id = state$id, sequence = state$sequence,
      timestamp = as.numeric(Sys.time()), event = type), task_info(task))
    if (!is.null(event$error)) event$error <- substr(event$error, 1L, 512L)
    if (type == "task_progress") {
      event$message <- task$message
      event$reported_at <- task$progress_reported_at
      event$progress_sequence <- task$progress_sequence
    }
    if (type == "task_completed") event$result_summary <- list(type = typeof(task$value),
      length = length(task$value), bytes = as.numeric(utils::object.size(task$value)))
    state$stream$emit(event)
  }
  started <- function(task, time) {
    if (task$status != "queued" || !nano_number(time, 0) || time > as.numeric(Sys.time()) + 5) return(invisible(NULL))
    task$started <- time; task$status <- "running"; emit(task, "task_started")
    invisible(NULL)
  }
  receive <- function(record) {
    if (!is.list(record) || !identical(record$version, 1L) || !identical(record$pool_id, state$id) ||
        !nano_id(record$task_id) || !exists(record$task_id, envir = state$tasks, inherits = FALSE) ||
        !nano_number(record$sequence, 0, 2^53 - 1, TRUE) ||
        !is.character(record$kind) || length(record$kind) != 1L || !record$kind %in% c("started", "progress")) {
      state$late <- state$late + 1L; return(invisible(NULL))
    }
    task <- get(record$task_id, envir = state$tasks, inherits = FALSE)
    if (record$sequence <= task$progress_sequence) return(invisible(NULL))
    if (!nano_number(record$started_at, 0) || record$started_at > as.numeric(Sys.time()) + 5) {
      state$invalid <- state$invalid + 1L; return(invisible(NULL))
    }
    value <- if (is.null(record$value)) NA_real_ else record$value
    if (!(is.numeric(value) && length(value) == 1L && (is.na(value) || nano_number(value, 0, 1))) ||
        (!is.na(value) && !is.na(task$last_known) && value < task$last_known) ||
        !is.character(record$message) || length(record$message) != 1L || is.na(record$message) ||
        nchar(record$message, type = "bytes") > 1024L) {
      state$invalid <- state$invalid + 1L; return(invisible(NULL))
    }
    started(task, record$started_at)
    task$progress_sequence <- record$sequence
    if (record$kind == "progress") {
      task$progress <- value; task$message <- record$message
      task$progress_reported_at <- if (nano_number(record$timestamp, 0)) record$timestamp else NULL
      if (!is.na(value)) task$last_known <- value
      state$counts[["progress"]] <- state$counts[["progress"]] + 1
      emit(task, "task_progress")
    }
    invisible(NULL)
  }
  settle <- function(task) {
    if (!task$status %in% c("queued", "running") || mirai::unresolved(task$native)) return(invisible(NULL))
    value <- task$native$data
    if (mirai::is_error_value(value)) {
      code <- if (is.integer(value) && length(value) == 1L) as.integer(value) else NA_integer_
      task$status <- if (identical(code, 20L)) "cancelled" else if (identical(code, 5L)) "timed_out" else "failed"
      task$error <- if (identical(code, 20L)) "Cancellation resolved by mirai; execution may still be stopping." else
        if (identical(code, 5L)) "Task timeout (including queue time)." else paste(as.character(value), collapse = " ")
    } else if (is.list(value) && identical(value$termr_task_result, 1L)) {
      started(task, value$started_at)
      if (!is.null(value$last_record)) receive(value$last_record)
      task$progress <- value$progress
      task$progress_stats <- value$progress_stats
      task$value <- value$outcome$value
      task$status <- if (isTRUE(value$outcome$ok)) "completed" else "failed"
      if (!is.null(value$outcome$error)) task$error <- value$outcome$error$message
    } else {
      task$status <- "failed"; task$error <- "Unexpected mirai result envelope."
    }
    task$finished <- as.numeric(Sys.time())
    state$counts[[task$status]] <- state$counts[[task$status]] + 1
    rm(list = task$id, envir = state$tasks)
    emit(task, paste0("task_", task$status))
    # Caller-owned results survive; pool/native duplicate references do not.
    task$native <- NULL
    invisible(NULL)
  }
  state$poll <- function(max_messages = 128L) {
    if (!nano_number(max_messages, 1, 8192, TRUE)) stop("Invalid progress message budget.", call. = FALSE)
    if (state$closed || state$busy) return(invisible(NULL))
    state$busy <- TRUE; on.exit(state$busy <- FALSE, add = TRUE)
    for (i in seq_len(max_messages)) {
      wire <- nanonext::recv(state$pull, mode = "raw", block = FALSE)
      if (nanonext::is_error_value(wire)) break
      record <- tryCatch({
        if (!is.raw(wire) || length(wire) > 4096L || any(wire == as.raw(0))) stop("Invalid progress bytes")
        jsonlite::fromJSON(rawToChar(wire), simplifyVector = FALSE)
      }, error = function(e) NULL)
      if (is.null(record)) state$invalid <- state$invalid + 1L else receive(record)
    }
    for (id in ls(state$tasks, all.names = TRUE)) settle(get(id, envir = state$tasks, inherits = FALSE))
    invisible(NULL)
  }
  state$info <- task_info; state$emit <- emit
  state$cancel <- function(task) {
    state$assert_mutable(); state$poll()
    if (!task$status %in% c("queued", "running")) return(invisible(FALSE))
    task$cancel_requested <- TRUE
    ok <- mirai::stop_mirai(task$native)
    state$poll()
    invisible(ok)
  }
  close_tasks <- function() {
    state$poll()
    for (id in ls(state$tasks, all.names = TRUE)) {
      task <- get(id, envir = state$tasks, inherits = FALSE)
      task$cancel_requested <- TRUE; mirai::stop_mirai(task$native)
    }
    state$poll()
    mirai_shutdown(state$profile, state$worker_handles)
    state$poll()
  }
  close_pool <- function() {
    if (state$closed) return(invisible(NULL))
    state$assert_mutable(); close_tasks()
    state$closed <- TRUE; close(state$pull); state$pull <- NULL
    state$stream$close()
    invisible(NULL)
  }
  state$worker_handles <- lapply(mirai_launch(workers, state$profile, memory, state$libraries, startup_timeout, seed), ps::ps_handle)
  events <- structure(list(name = "tasks", latest = state$stream$latest, history = state$stream$history,
    subscribe = state$stream$subscribe, subscriber_count = state$stream$subscriber_count,
    is_closed = state$stream$is_closed, poll = state$poll), class = c("termr_task_events", "termr_stream"))
  pool <- structure(list(events = events, poll = state$poll, close = close_pool,
    is_closed = function() state$closed,
    tasks = function() {state$poll(); lapply(ls(state$tasks, all.names = TRUE), function(id) get(id, state$tasks)$handle)},
    diagnostics = function() list(pool_id = state$id, closed = state$closed, workers = workers,
      pending = length(ls(state$tasks, all.names = TRUE)), max_pending = max_pending,
      counters = as.list(state$counts), history = length(state$stream$history()),
      invalid_progress = state$invalid, late_progress = state$late,
      backend = if (state$closed) NULL else mirai::status(.compute = state$profile)),
    restart = function() {
      state$assert_mutable(); close_tasks()
      state$worker_handles <- lapply(mirai_launch(workers, state$profile, memory, state$libraries, startup_timeout, seed), ps::ps_handle)
      invisible(NULL)
    }), class = "termr_mirai_pool", termr_mirai = state)
  # A small submit closure, without a captured last submit frame/result.
  pool$submit <- function(fn, args = list(), timeout = NULL, progress = FALSE,
                          task_type = "R", metadata = list(), packages = character()) {
    termr_mirai_submit(pool, fn, args, timeout, progress, task_type, metadata, packages)
  }
  state$progress_interval <- progress_interval
  ready <- TRUE
  pool
}

#' Submit an asynchronous task to an owned mirai pool
#'
#' Task methods `$status()`, `$ready()`, `$info()` and `$result()` refresh without
#' waiting. Result errors while unresolved or unsuccessful. `$wait(timeout=30)`
#' is an explicitly blocking wait and returns the handle; its wait limit does
#' not cancel the task. `$cancel()` returns whether mirai accepted cancellation,
#' resolves queued/running tasks via backend code 20, and is idempotent.
#' Already-resolved completion wins a cancellation race. Cancelled resolution
#' does not guarantee immediate interruption of compiled code or side effects.
#'
#' States: queued/running/completed/failed/cancelled/timed_out. Running and
#' started_at require confirmation from the worker wrapper. The backend timeout
#' includes queue time. finished_at is host resolution time. `$info()` contains
#' task_id/type/backend, timestamps, status/progress/error, cancel_requested and
#' bounded caller metadata. Only the handle retains the full R result.
#'
#' With `progress=TRUE`, `fn` must accept `progress` (or `...`). The injected
#' function accepts `progress(value=NA_real_, message="")`: known fractions
#' must be monotonic in [0,1]; NA means unknown. Calls are throttled and native
#' sends never wait for a slow consumer. Messages are bounded raw JSON; final
#' envelopes reconcile dropped latest progress. Results use mirai's local R
#' serialization, not JSON. Reference-bearing inputs are rejected; lexical
#' captures follow [run_worker()] rules. Input serialization itself is synchronous.
#'
#' `$promise()` requires optional promises and uses mirai's event-driven
#' conversion, resolving to the result or rejecting with an error. Use it with
#' Shiny ExtendedTask; it does not install a polling scheduler.
#'
#' @param pool An open [termr_mirai_pool()].
#' @param fn Function evaluated in a daemon.
#' @param args Named list of function arguments.
#' @param timeout Optional total task timeout in seconds, at most 2147483.
#' @param progress Inject a nonblocking progress reporter.
#' @param task_type Short diagnostic label.
#' @param metadata JSON-safe metadata, encoded size at most 4096 bytes.
#' @param packages Character vector of packages attached in the daemon.
#' @return A task handle. Queue saturation errors before admission, without waiting.
#' @export
#' @examples
#' if (interactive() && requireNamespace("mirai", quietly = TRUE)) {
#'   pool <- termr_mirai_pool(1L)
#'   task <- termr_mirai_submit(pool, function(x) x * 2, args = list(x = 21))
#'   task$wait(10)$result()
#'   pool$close()
#' }
termr_mirai_submit <- function(pool, fn, args = list(), timeout = NULL, progress = FALSE,
                               task_type = "R", metadata = list(), packages = character()) {
  state <- mirai_pool_state(pool)
  state$assert_mutable(); state$poll()
  check_function(fn, "fn"); check_flag(progress, "progress")
  if (!is.list(args) || (length(args) && (is.null(names(args)) || anyNA(names(args)) ||
      any(!nzchar(names(args))) || anyDuplicated(names(args))))) stop("`args` must be a uniquely named list.", call. = FALSE)
  if (!is.null(timeout) && !nano_number(timeout, .001, 2147483)) stop("Invalid task timeout.", call. = FALSE)
  if (!is.character(packages) || anyNA(packages) || any(!nzchar(packages))) stop("Invalid packages.", call. = FALSE)
  if (!is.character(task_type) || length(task_type) != 1L || is.na(task_type) ||
      nchar(task_type, type = "bytes") > 128L) stop("Invalid task_type.", call. = FALSE)
  if (progress && (!any(c("progress", "...") %in% names(formals(fn))) || "progress" %in% names(args))) {
    stop("With `progress=TRUE`, fn must accept an injected progress argument.", call. = FALSE)
  }
  metadata <- nano_payload(metadata)
  if (length(nano_encode(metadata, 4096L)) > 4096L) stop("Metadata too large.", call. = FALSE)
  if (length(ls(state$tasks, all.names = TRUE)) >= state$max_pending) stop("Pool pending task limit reached.", call. = FALSE)
  if (mirai::status(.compute = state$profile)$connections < 1L) stop("No connected daemons; restart the pool.", call. = FALSE)
  wire <- mirai_prepare_job(fn, args, packages, state$max_input_bytes)
  state$counter <- state$counter + 1
  task <- new.env(parent = emptyenv())
  task$id <- paste0(state$id, ".", state$counter); task$type <- task_type
  task$status <- "queued"; task$submitted <- as.numeric(Sys.time())
  task$started <- NULL; task$finished <- NULL; task$progress <- NA_real_; task$last_known <- NA_real_
  task$progress_sequence <- -1; task$message <- ""; task$error <- NULL
  task$progress_reported_at <- NULL
  task$value <- NULL; task$metadata <- metadata; task$cancel_requested <- FALSE
  task$progress_stats <- NULL
  channel <- list(endpoint = state$endpoint, libraries = state$libraries, pool_id = state$id,
    task_id = task$id, progress = progress, interval = state$progress_interval)
  expression <- quote(runner(job, channel))
  native <- mirai::try_mirai(.expr = expression,
    .args = list(runner = mirai_worker_run, job = wire, channel = channel),
    .timeout = if (is.null(timeout)) NULL else as.integer(ceiling(timeout * 1000)), .compute = state$profile)
  if (is.null(native)) stop("mirai dispatcher memory capacity reached; task not admitted.", call. = FALSE)
  task$native <- native
  handle <- mirai_task_handle(task, state)
  task$handle <- handle
  assign(task$id, task, envir = state$tasks)
  state$counts[["submitted"]] <- state$counts[["submitted"]] + 1
  state$busy <- TRUE; on.exit(state$busy <- FALSE, add = TRUE)
  state$emit(task, "task_submitted")
  handle
}

mirai_task_handle <- function(task, state) {
  refresh <- function() state$poll()
  ready <- function() {refresh(); !task$status %in% c("queued", "running")}
  result <- function() {
    if (!ready()) stop("Task is unresolved; use an explicit wait() if needed.", call. = FALSE)
    if (task$status != "completed") stop(task$error, call. = FALSE)
    task$value
  }
  handle <- structure(list(status = function() {refresh(); task$status}, ready = ready,
    info = function() {refresh(); state$info(task)}, result = result,
    cancel = function() {
      if (task$status %in% c("completed", "failed", "cancelled", "timed_out")) return(invisible(FALSE))
      state$cancel(task)
    },
    wait = function(timeout = 30) {
      if (!is.numeric(timeout) || length(timeout) != 1L || is.na(timeout) || timeout < 0) stop("Invalid wait timeout.", call. = FALSE)
      deadline <- now_seconds() + timeout
      while (!ready()) {
        if (now_seconds() >= deadline) stop("Task wait timed out; task remains active.", call. = FALSE)
        Sys.sleep(.005)
      }
      invisible(handle)
    },
    promise = function() {
      if (!requireNamespace("promises", quietly = TRUE)) stop("Install optional package 'promises'.", call. = FALSE)
      if (ready()) return(promises::promise(function(resolve, reject) {
        if (task$status == "completed") resolve(task$value) else reject(simpleError(task$error))
      }))
      promises::then(promises::as.promise(task$native),
        onFulfilled = function(value) result(),
        onRejected = function(reason) {refresh(); stop(task$error, call. = FALSE)})
    }), class = "termr_mirai_task")
  handle
}
