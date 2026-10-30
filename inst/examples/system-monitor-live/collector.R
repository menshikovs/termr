# Run with Rscript collector.R [snapshot-directory] [max-samples].
source_files <- Filter(Negate(is.null), lapply(sys.frames(), function(f) f$ofile))
local_file <- if (length(source_files)) tail(source_files, 1L)[[1L]] else sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1L])
source(file.path(dirname(local_file), "common.R"), local = TRUE)

run_collector <- function(path = monitor_path(), interval = 1, max_samples = Inf,
                          transport = Sys.getenv("TERMR_METRICS_TRANSPORT", "file"),
                          endpoint = Sys.getenv("TERMR_METRICS_ENDPOINT", "tcp://127.0.0.1:5555"),
                          snapshot_endpoint = Sys.getenv("TERMR_METRICS_SNAPSHOT_ENDPOINT", "")) {
  if (!monitor_number(interval, 0.05) || !(identical(max_samples, Inf) || monitor_number(max_samples, 1))) stop("Invalid collector configuration.")
  if (!transport %in% c("file", "nano", "both")) stop("Collector transport must be file, nano or both.")
  if (!dir.exists(path) && !dir.create(path, recursive = TRUE)) stop("Cannot create collector control directory.")
  stream <- termr::termr_stream("system.metrics", history = 1L)
  on.exit(stream$close(), add = TRUE)
  writer <- NULL; publisher <- NULL; subscription <- NULL
  on.exit({
    if (!is.null(subscription)) subscription$unsubscribe()
    if (!is.null(writer)) writer$close()
    if (!is.null(publisher)) publisher$close()
  }, add = TRUE, after = FALSE)
  if (transport %in% c("file", "both")) {
    writer <- monitor_writer(path, min_interval = interval)
    subscription <- stream$subscribe(function(x) writer$publish(x))
  }
  if (transport %in% c("nano", "both")) {
    publisher <- termr::termr_nano_publish(stream, endpoint,
      if (nzchar(snapshot_endpoint)) snapshot_endpoint else NULL, request_timeout = 3000L)
    # Lets automated consumers discover OS-allocated bound ports safely.
    ready <- Sys.getenv("TERMR_METRICS_READY", "")
    if (nzchar(ready)) writeLines(c(publisher$endpoint, publisher$snapshot_endpoint), ready)
  }
  collect <- monitor_collector()
  n <- 0L
  next_sample <- proc.time()[["elapsed"]]
  while (n < max_samples && !file.exists(file.path(path, "STOP"))) {
    now <- proc.time()[["elapsed"]]
    if (now >= next_sample) {
      stream$emit(collect())
      n <- n + 1L
      next_sample <- proc.time()[["elapsed"]] + interval
    }
    if (!is.null(publisher)) publisher$poll()
    if (n < max_samples) Sys.sleep(min(0.02, max(0, next_sample - proc.time()[["elapsed"]])))
  }
  invisible(n)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  run_collector(if (length(args)) args[[1L]] else monitor_path(),
                max_samples = if (length(args) > 1L) as.numeric(args[[2L]]) else Inf)
}
