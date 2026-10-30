# Finite independent telemetry producer for integration and load measurements.
args <- commandArgs(trailingOnly = TRUE)
config <- jsonlite::read_json(args[[1L]], simplifyVector = TRUE)
.libPaths(config$libraries)
library(termr)
main <- function() {
  source <- termr_stream("shiny.bench", history = 4L)
  publisher <- termr_nano_publish(source, config$endpoint, config$snapshot_endpoint,
    heartbeat = 0.1, buffer = 256L)
  on.exit({publisher$close(); source$close()}, add = TRUE)
  emit <- function(n) source$emit(list(n = n, timestamp = as.numeric(Sys.time()),
    sent_at = as.numeric(Sys.time()), cpu = n %% 101, ram = 50))
  emit(0L)
  jsonlite::write_json(list(endpoint = publisher$endpoint,
    snapshot_endpoint = publisher$snapshot_endpoint), config$ready, auto_unbox = TRUE)
  started <- proc.time()[["elapsed"]]
  while (!file.exists(config$go)) {
    publisher$poll()
    if (proc.time()[["elapsed"]] - started > config$timeout) stop("GO timeout")
    Sys.sleep(0.002)
  }
  started <- proc.time()[["elapsed"]]; n <- 0L
  repeat {
    elapsed <- proc.time()[["elapsed"]] - started
    if (elapsed > config$duration || file.exists(config$stop)) break
    # Deadline schedule allows bounded catch-up after coarse Windows sleeps.
    target <- floor(elapsed * config$rate)
    for (i in seq_len(min(128L, max(0L, target - n)))) {n <- n + 1L; emit(n)}
    publisher$poll(); Sys.sleep(0.001)
  }
  # Keep snapshot service alive until the parent has consumed the final value.
  deadline <- proc.time()[["elapsed"]] + 5
  while (!file.exists(config$stop) && proc.time()[["elapsed"]] < deadline) {
    publisher$poll(); Sys.sleep(0.002)
  }
  jsonlite::write_json(list(events = n, elapsed = elapsed, status = publisher$status()),
    config$report, auto_unbox = TRUE, null = "null")
}
main()
