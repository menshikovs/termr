# Trusted local job preparation. Reuse capture rules without modifying processx.
mirai_prepare_job <- function(fn, args, packages, max_bytes) {
  capture <- new.env(parent = emptyenv())
  capture$originals <- capture$copies <- capture$environments <- list()
  copy_value <- function(x, depth = 0L) {
    if (depth > 32L) stop("Task inputs exceed nesting limit 32.", call. = FALSE)
    if (is.function(x)) return(removeSource(worker_copy_function(x, capture)))
    if (inherits(x, "formula")) return(worker_copy_formula(x, capture))
    if (is.list(x)) for (i in seq_along(x)) x[i] <- list(copy_value(x[[i]], depth + 1L))
    x
  }
  fn <- removeSource(worker_copy_function(fn, capture))
  args <- copy_value(args)
  for (env in capture$environments) for (name in ls(env, all.names = TRUE)) {
    value <- get(name, envir = env, inherits = FALSE)
    if (is.function(value)) assign(name, removeSource(value), envir = env)
  }
  safe_value <- function(x, depth = 0L) {
    if (depth > 32L) stop("Task inputs exceed nesting limit 32.", call. = FALSE)
    if (is.environment(x) || inherits(x, "connection") || isS4(x) ||
        typeof(x) %in% c("externalptr", "weakref")) {
      stop("Task inputs cannot contain environments, connections, R6 or external pointers.", call. = FALSE)
    }
    if (is.function(x)) {
      env <- environment(x)
      if (!is.null(env) && !identical(env, baseenv()) && !identical(env, emptyenv()) &&
          !isNamespace(env) && !any(vapply(capture$environments, identical, logical(1), y = env))) {
        stop("Unsupported function capture in task inputs.", call. = FALSE)
      }
      for (value in attributes(x)) safe_value(value, depth + 1L)
      return(invisible(NULL))
    }
    if (is.list(x)) for (value in x) safe_value(value, depth + 1L)
    attrs <- attributes(x)
    if (inherits(x, "formula")) attrs$.Environment <- NULL
    if (length(attrs)) for (value in attrs) safe_value(value, depth + 1L)
    invisible(NULL)
  }
  safe_value(fn); safe_value(args)
  for (env in capture$environments) for (name in ls(env, all.names = TRUE)) {
    safe_value(get(name, envir = env, inherits = FALSE))
  }
  job <- list(fn = fn, args = args, packages = packages, environments = capture$environments)
  wire <- serialize(job, NULL, version = 3L)
  if (length(wire) > max_bytes) stop("Serialized task inputs exceed `max_input_bytes`.", call. = FALSE)
  wire
}

# Base-environment closure: no parent runtime, UI, socket or package namespace
# is serialized to a daemon. Only trusted local mirai jobs use unserialize().
mirai_worker_run <- eval(quote(function(wire, channel) {
  .libPaths(channel$libraries)
  job <- unserialize(wire)
  for (package in job$packages) library(package, character.only = TRUE)
  for (env in job$environments) parent.env(env) <- globalenv()
  started <- as.numeric(Sys.time())
  socket <- nanonext::socket("push")
  on.exit(close(socket), add = TRUE)
  nanonext::opt(socket, "send-buffer") <- 1L
  nanonext::opt(socket, "send-timeout") <- 0L
  nanonext::dial(socket, channel$endpoint, fail = "error")
  sequence <- 0L; last_sent <- -Inf; last_value <- NA_real_; latest_value <- NA_real_
  last_record <- NULL; attempts <- 0L; delivered <- 0L; reported <- 0L; throttled <- 0L
  send <- function(kind, value = NA_real_, message = "") {
    now <- as.numeric(Sys.time())
    record <- list(version = 1L, pool_id = channel$pool_id, task_id = channel$task_id,
      kind = kind, sequence = sequence, started_at = started, timestamp = now,
      value = value, message = message)
    bytes <- charToRaw(enc2utf8(jsonlite::toJSON(record, auto_unbox = TRUE,
      na = "null", null = "null", digits = NA)))
    attempts <<- attempts + 1L
    ok <- !nanonext::is_error_value(nanonext::send(socket, bytes, mode = "raw", block = FALSE))
    if (ok) delivered <<- delivered + 1L
    last_sent <<- proc.time()[["elapsed"]]
    if (kind == "progress") last_record <<- record
    invisible(ok)
  }
  send("started")
  progress <- function(value = NA_real_, message = "") {
    if (!is.numeric(value) || length(value) != 1L || is.nan(value) ||
        (!is.na(value) && (!is.finite(value) || value < 0 || value > 1))) stop("Progress must be NA or a number in [0, 1].")
    if (!is.character(message) || length(message) != 1L || is.na(message)) stop("Invalid progress message.")
    if (!is.na(value) && !is.na(last_value) && value < last_value) stop("Progress cannot decrease.")
    force_final <- !is.na(value) && value == 1 && (is.na(last_value) || last_value < 1)
    if (!is.na(value)) last_value <<- value
    latest_value <<- value
    reported <<- reported + 1L
    if (proc.time()[["elapsed"]] - last_sent < channel$interval && !force_final) {
      throttled <<- throttled + 1L; return(invisible(FALSE))
    }
    sequence <<- sequence + 1L
    send("progress", value, substr(gsub("[[:cntrl:]]", " ", message), 1L, 256L))
  }
  if (channel$progress) job$args$progress <- progress
  outcome <- tryCatch(list(ok = TRUE, value = do.call(job$fn, job$args), error = NULL),
    error = function(e) list(ok = FALSE, value = NULL,
      error = list(message = conditionMessage(e), class = class(e))))
  # The result path reconciles dropped/throttled progress without exposing the
  # result itself to telemetry. It remains mirai's trusted R transport.
  list(termr_task_result = 1L, outcome = outcome, started_at = started,
    last_record = last_record, progress = latest_value,
    progress_stats = list(reported = reported, throttled = throttled, attempted = attempts, accepted = delivered))
}), envir = baseenv())

mirai_launch <- function(workers, profile, memory, libraries, timeout, seed) {
  old <- Sys.getenv(c("R_LIBS", "R_TESTS"), unset = NA_character_)
  on.exit(for (name in names(old)) {
    if (is.na(old[[name]])) Sys.unsetenv(name) else do.call(Sys.setenv, stats::setNames(list(old[[name]]), name))
  }, add = TRUE)
  Sys.setenv(R_LIBS = paste(libraries, collapse = .Platform$path.sep), R_TESTS = "")
  mirai::daemons(workers, memory = memory, seed = seed, .compute = profile)
  deadline <- now_seconds() + timeout
  repeat {
    status <- mirai::status(.compute = profile)
    if (status$connections >= workers) break
    if (now_seconds() >= deadline) stop("mirai daemon startup timed out.", call. = FALSE)
    Sys.sleep(0.01)
  }
  probes <- mirai::everywhere(Sys.getpid(), .min = workers, .compute = profile)
  while (any(vapply(probes, mirai::unresolved, logical(1)))) {
    if (now_seconds() >= deadline) stop("mirai worker identity probe timed out.", call. = FALSE)
    Sys.sleep(.005)
  }
  pids <- vapply(probes, function(probe) {
    value <- probe$data
    if (mirai::is_error_value(value) || !is.numeric(value) || length(value) != 1L) stop("Worker identity probe failed.", call. = FALSE)
    as.integer(value)
  }, 0L)
  if (length(unique(pids)) != workers) stop("Unexpected worker identities.", call. = FALSE)
  pids
}

# Stop peers before resetting the dispatcher. On nanonext 1.10.3, closing an
# active dispatcher poly socket has been observed to wait indefinitely inside
# nni_sock_shutdown. Use public mirai operations to quiesce the owned profile.
# Verified ps handles permit a bounded force-stop only for our own workers if
# user compiled code does not honour the backend interrupt/quit request.
mirai_shutdown <- function(profile, worker_handles) {
  connections <- function() {
    value <- mirai::status(.compute = profile)$connections
    if (is.null(value)) 0L else value
  }
  if (connections() > 0L) {
    shutdown <- tryCatch(mirai::everywhere(quit(save = "no", status = 0L), .min = 1L, .compute = profile),
      error = function(e) NULL)
    deadline <- now_seconds() + .5
    while (connections() > 0L && now_seconds() < deadline) Sys.sleep(.005)
    if (connections() > 0L) {
      for (handle in worker_handles) {
        # ps handles check process creation time, guarding against PID reuse.
        if (ps::ps_is_running(handle)) try(ps::ps_kill(handle), silent = TRUE)
      }
      deadline <- now_seconds() + 1
      while (connections() > 0L && now_seconds() < deadline) Sys.sleep(.005)
    }
    if (connections() > 0L) stop("Owned daemons did not disconnect; dispatcher reset deferred.", call. = FALSE)
  }
  mirai::daemons(0L, .compute = profile)
  invisible(NULL)
}
