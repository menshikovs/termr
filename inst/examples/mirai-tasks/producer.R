# Independent producer: Rscript producer.R [seconds=30] [pub endpoint] [snapshot endpoint].
source_files <- Filter(Negate(is.null), lapply(sys.frames(), function(f) f$ofile))
local_file <- if (length(source_files)) tail(source_files, 1L)[[1L]] else sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1L])
source(file.path(dirname(local_file), "common.R"), local = TRUE)

task_producer <- function(seconds = 30, endpoint = "tcp://127.0.0.1:5581", snapshot_endpoint = "tcp://127.0.0.1:5582",
                          ready_file = Sys.getenv("TERMR_TASK_READY", ""), stop_file = Sys.getenv("TERMR_TASK_STOP", "")) {
  model <- task_demo_model(2L)
  on.exit(model$close(), add = TRUE)
  state <- termr::termr_stream("task.state", history = 1L)
  on.exit(state$close(), add = TRUE)
  publisher <- termr::termr_nano_publish(state, endpoint, snapshot_endpoint)
  on.exit(publisher$close(), add = TRUE)
  for (i in 1:4) model$submit(chunks = 160L)
  if (nzchar(ready_file)) jsonlite::write_json(list(endpoint = publisher$endpoint,
    snapshot_endpoint = publisher$snapshot_endpoint), ready_file, auto_unbox = TRUE)
  start <- proc.time()[["elapsed"]]; next_snapshot <- -Inf
  while (proc.time()[["elapsed"]] - start < seconds && !(nzchar(stop_file) && file.exists(stop_file))) {
    model$pool$poll(); publisher$poll()
    now <- proc.time()[["elapsed"]]
    if (now >= next_snapshot) {state$emit(model$snapshot()); next_snapshot <- now + .25}
    Sys.sleep(.01)
  }
  # Publish best-effort final metadata after owned requests resolve cancelled.
  # Pub/sub remains lossy; this does not turn shutdown into durable replay.
  model$close()
  final <- model$snapshot()
  state$emit(final)
  deadline <- proc.time()[["elapsed"]] + .1
  while (proc.time()[["elapsed"]] < deadline) {publisher$poll(); Sys.sleep(.005)}
  invisible(final)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  task_producer(if (length(args)) as.numeric(args[[1L]]) else 30,
    if (length(args) > 1L) args[[2L]] else "tcp://127.0.0.1:5581",
    if (length(args) > 2L) args[[3L]] else "tcp://127.0.0.1:5582")
}
