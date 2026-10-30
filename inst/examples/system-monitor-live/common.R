# Demo-local helpers, deliberately separate from the stream's public API.
monitor_path <- function() {
  Sys.getenv("TERMR_METRICS_DIR", unset = file.path(tools::R_user_dir("termr", "cache"), "metrics"))
}

monitor_number <- function(x, lower = 0, upper = Inf) {
  is.numeric(x) && length(x) == 1L && !is.na(x) && is.finite(x) && x >= lower && x <= upper
}

monitor_snapshot_valid <- function(x) {
  scalar_text <- function(v) is.character(v) && length(v) == 1L && !is.na(v) && nzchar(v)
  metric <- function(v) is.null(v) || monitor_number(v, 0, 100)
  is.list(x) && identical(x$schema_version, 1L) && scalar_text(x$source_id) &&
    monitor_number(x$sequence, 1, 2^53 - 1) && x$sequence == floor(x$sequence) &&
    monitor_number(x$timestamp) && monitor_number(x$collected_at) &&
    is.list(x$metrics) && all(c("cpu", "ram", "processes", "unavailable") %in% names(x$metrics)) &&
    metric(x$metrics$cpu) && metric(x$metrics$ram) &&
    is.list(x$metrics$unavailable) && is.list(x$metrics$processes) &&
    length(x$metrics$processes) <= 100L &&
    all(vapply(x$metrics$processes, function(p) {
      is.list(p) && monitor_number(p$pid, 0) &&
        (is.null(p$name) || scalar_text(p$name)) &&
        (is.null(p$rss) || monitor_number(p$rss))
    }, logical(1)))
}

monitor_files <- function(path) {
  # Fixed-width publication time sorts versions, including across restarts.
  sort(list.files(path, pattern = "^snapshot-[0-9]{20}-.+\\.json$", full.names = TRUE), decreasing = TRUE)
}

monitor_writer <- function(path, min_interval = 1, retain = 3L) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) stop("Install optional package 'jsonlite'.")
  if (!monitor_number(min_interval) || !monitor_number(retain, 2) || retain != floor(retain)) {
    stop("Invalid publication interval or retention.")
  }
  if (!dir.exists(path) && !dir.create(path, recursive = TRUE)) stop("Cannot create snapshot directory.")
  lock <- file.path(path, ".writer-lock")
  if (!dir.create(lock, showWarnings = FALSE)) stop("Snapshot writer already locked: ", lock)
  closed <- FALSE
  last_write <- -Inf
  versions <- monitor_files(path)
  last_stamp <- if (length(versions)) as.numeric(sub("^snapshot-([0-9]{20})-.*$", "\\1", basename(versions[[1L]]))) else 0
  close <- function() {
    if (!closed) unlink(lock, recursive = TRUE)
    closed <<- TRUE
    invisible(NULL)
  }
  publish <- function(snapshot) {
    if (closed) stop("Snapshot writer is closed.")
    if (!monitor_snapshot_valid(snapshot)) stop("Invalid snapshot schema.")
    now <- proc.time()[["elapsed"]]
    if (now - last_write < min_interval) return(invisible(FALSE))
    # Prune before publishing, so even concurrent readers see at most retain
    # versions. A persistent access failure must not grow disk use unboundedly.
    versions <- monitor_files(path)
    if (length(versions) >= retain) {
      unlink(versions[seq.int(retain, length(versions))])
      if (length(monitor_files(path)) >= retain) stop("Cannot prune old snapshots; check file access.")
    }
    tmp <- tempfile(".pending-", tmpdir = path)
    on.exit(unlink(tmp), add = TRUE)
    jsonlite::write_json(snapshot, tmp, auto_unbox = TRUE, null = "null", na = "null", digits = NA)
    # New name, same directory/filesystem; never remove/overwrite a live version.
    last_stamp <<- max(last_stamp + 1, floor(as.numeric(Sys.time()) * 1e6))
    stamp <- sprintf("%020.0f", last_stamp)
    target <- tempfile(paste0("snapshot-", stamp, "-"), tmpdir = path, fileext = ".json")
    if (!file.rename(tmp, target)) stop("Cannot publish snapshot version.")
    last_write <<- now
    invisible(TRUE)
  }
  list(publish = publish, close = close)
}

monitor_read <- function(path, stale_after = 5, now = as.numeric(Sys.time())) {
  result <- function(status, snapshot = NULL, message = NULL) {
    list(status = status, snapshot = snapshot, message = message)
  }
  if (!requireNamespace("jsonlite", quietly = TRUE)) return(result("unavailable", message = "Install 'jsonlite'."))
  if (!monitor_number(stale_after) || !monitor_number(now)) stop("Invalid snapshot age configuration.")
  if (!dir.exists(path) || file.access(path, 4L) != 0L) return(result("unavailable", message = "Snapshot directory unavailable."))
  files <- monitor_files(path)
  if (!length(files)) return(result("unavailable", message = "Waiting for collector."))
  # Two listings tolerate a reader racing version cleanup. Temporary files are ignored.
  for (attempt in seq_len(2L)) {
    file <- monitor_files(path)
    if (!length(file)) next
    # Read only the newest publication: corrupt current data must be visible,
    # rather than silently falling back to an older apparently healthy source.
    file <- file[[1L]]
    snapshot <- tryCatch({
      bytes <- file.info(file)$size
      if (is.na(bytes) || bytes > 2 * 1024^2) stop("Snapshot missing or exceeds 2 MiB.")
      jsonlite::fromJSON(file, simplifyVector = FALSE)
    }, error = function(e) e)
    if (inherits(snapshot, "error")) {
      if (!file.exists(file)) next
      return(result("invalid", message = conditionMessage(snapshot)))
    }
    if (!monitor_snapshot_valid(snapshot)) return(result("invalid", message = "Unsupported or malformed snapshot schema."))
    age <- now - snapshot$timestamp
    if (age < -5) return(result("invalid", message = "Snapshot timestamp is in the future; check clocks."))
    return(result(if (age > stale_after) "stale" else "live", snapshot))
  }
  result("unavailable", message = "Snapshot changed during read; retrying next poll.")
}

monitor_collector <- function(source_id = paste(Sys.info()[["nodename"]], Sys.getpid(),
                                                sprintf("%.0f", as.numeric(Sys.time()) * 1e6), sep = "-")) {
  previous <- NULL
  sequence <- 0
  collect <- function() {
    unavailable <- list()
    safe <- function(name, expr) tryCatch(expr, error = function(e) {
      unavailable[[name]] <<- conditionMessage(e)
      NULL
    })
    collected_at <- as.numeric(Sys.time())
    times <- safe("cpu", ps::ps_system_cpu_times())
    cpu <- NULL
    if (!is.null(times)) {
      # guest times on Linux are already included in user/nice. Windows
      # system time returned by ps excludes idle (see ps API documentation).
      keys <- intersect(c("user", "nice", "system", "idle", "iowait", "irq", "softirq", "steal"), names(times))
      current <- unlist(times[keys], use.names = TRUE)
      if (!is.null(previous) && identical(names(previous), names(current))) {
        delta <- current - previous
        total <- sum(delta)
        idle <- sum(delta[intersect(c("idle", "iowait"), names(delta))])
        if (all(is.finite(delta)) && all(delta >= 0) && total > 0 && "idle" %in% names(delta)) {
          cpu <- min(100, max(0, 100 * (total - idle) / total))
        }
      }
      previous <<- current
      if (is.null(cpu)) unavailable$cpu <- "CPU needs two valid cumulative samples."
    } else previous <<- NULL
    memory <- safe("ram", ps::ps_system_memory())
    ram <- if (!is.null(memory) && monitor_number(memory$total, 1) && monitor_number(memory$avail)) {
      min(100, max(0, 100 * (1 - memory$avail / memory$total)))
    } else NULL
    if (is.null(ram) && is.null(unavailable$ram)) unavailable$ram <- "System memory unavailable."
    # Bound collection itself, not just the final table. ps::ps() gathers all
    # metadata for every PID and can take seconds on Windows. This monitor
    # needs only PID/name/RSS, for a sample of at most 100 PIDs.
    records <- safe("processes", {
      pids <- utils::head(unique(c(Sys.getpid(), sort(ps::ps_pids(), decreasing = TRUE))), 100L)
      values <- lapply(pids, function(pid) tryCatch({
        handle <- ps::ps_handle(pid)
        name <- tryCatch(ps::ps_name(handle), error = function(e) NULL)
        rss <- tryCatch(unname(ps::ps_memory_info(handle)[["rss"]]), error = function(e) NULL)
        list(pid = as.integer(pid), name = name, rss = rss)
      }, error = function(e) NULL))
      values <- Filter(Negate(is.null), values)
      rss <- vapply(values, function(p) if (is.null(p$rss)) -Inf else p$rss, 0)
      values[order(rss, decreasing = TRUE)]
    })
    if (is.null(records)) records <- list()
    sequence <<- sequence + 1
    list(schema_version = 1L, source_id = source_id, sequence = sequence,
         timestamp = as.numeric(Sys.time()), collected_at = collected_at,
         metrics = list(cpu = cpu, ram = ram, processes = records, unavailable = unavailable))
  }
  collect
}

monitor_client <- function(path, history = 120L, stale_after = 5,
                           transport = Sys.getenv("TERMR_METRICS_TRANSPORT", "file"),
                           endpoint = Sys.getenv("TERMR_METRICS_ENDPOINT", "tcp://127.0.0.1:5555"),
                           snapshot_endpoint = Sys.getenv("TERMR_METRICS_SNAPSHOT_ENDPOINT", "")) {
  if (!transport %in% c("file", "nano")) stop("Client transport must be file or nano.")
  if (transport == "nano") {
    remote <- termr::termr_nano_connect(endpoint, "system.metrics",
      if (nzchar(snapshot_endpoint)) snapshot_endpoint else NULL,
      history = history, stale_after = stale_after, request_timeout = 3000L)
    poll <- function(now = as.numeric(Sys.time())) {
      remote$poll()
      state <- remote$status()
      value <- remote$latest()
      status <- if (state$state == "connecting") "unavailable" else state$state
      if (!is.null(value)) {
        if (!monitor_snapshot_valid(value)) status <- "invalid"
        else if (now - value$timestamp > stale_after) status <- "stale"
      }
      list(status = status, snapshot = value, missed = state$gaps, message = state$last_error)
    }
    return(list(poll = poll, stream = remote, close = remote$close))
  }
  stream <- termr::termr_stream("system.metrics", history = history)
  last_source <- NULL
  last_sequence <- 0
  missed <- 0
  last_snapshot <- NULL
  poll <- function(now = as.numeric(Sys.time())) {
    reading <- monitor_read(path, stale_after, now)
    x <- reading$snapshot
    if (!is.null(x)) {
      if (!identical(x$source_id, last_source)) {
        stream$clear()
        last_sequence <<- 0
        missed <<- 0
      }
      if (x$sequence < last_sequence) {
        reading$status <- "invalid"
        reading$message <- "Sequence moved backwards for the same source."
      } else if (x$sequence > last_sequence) {
        if (last_sequence > 0) missed <<- missed + max(0, x$sequence - last_sequence - 1)
        last_source <<- x$source_id
        last_sequence <<- x$sequence
        last_snapshot <<- x
        stream$emit(x)
      }
    }
    reading$snapshot <- last_snapshot
    reading$missed <- missed
    reading
  }
  list(poll = poll, stream = stream, close = function() stream$close())
}

monitor_format <- function(x) if (is.null(x)) "unavailable" else sprintf("%.1f%%", x)

monitor_status <- function(reading) {
  snapshot <- reading$snapshot
  updated <- if (is.null(snapshot)) "never" else format(as.POSIXct(snapshot$timestamp, origin = "1970-01-01"), tz = "UTC", usetz = TRUE)
  paste("Source:", reading$status, "| updated:", updated, "| missed:", reading$missed,
        if (!is.null(reading$message)) paste("|", reading$message) else "")
}
