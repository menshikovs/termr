# Independent telemetry subscriber. Uses the same environment config as TUI.
source_files <- Filter(Negate(is.null), lapply(sys.frames(), function(f) f$ofile))
local_file <- if (length(source_files)) tail(source_files, 1L)[[1L]] else sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1L])
source(file.path(dirname(local_file), "common.R"), local = TRUE)

run_subscriber <- function(path = monitor_path(), max_samples = Inf) {
  client <- monitor_client(path)
  on.exit(client$close(), add = TRUE)
  sub <- client$stream$subscribe(function(event) {
    cat(event$source_id, event$sequence, "CPU", monitor_format(event$metrics$cpu),
        "RAM", monitor_format(event$metrics$ram), "\n")
  })
  on.exit(sub$unsubscribe(), add = TRUE)
  seen <- 0
  last <- NULL
  while (seen < max_samples) {
    value <- client$poll()
    key <- if (is.null(value$snapshot)) NULL else paste(value$snapshot$source_id, value$snapshot$sequence)
    if (!is.null(key) && !identical(key, last)) { last <- key; seen <- seen + 1 }
    Sys.sleep(0.02)
  }
  invisible(seen)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  run_subscriber(if (length(args)) args[[1L]] else monitor_path(),
    if (length(args) > 1L) as.numeric(args[[2L]]) else Inf)
}
