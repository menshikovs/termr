# Ordinary ggplot2 time series from an independently collected stream.
source_files <- Filter(Negate(is.null), lapply(sys.frames(), function(f) f$ofile))
local_file <- if (length(source_files)) tail(source_files, 1L)[[1L]] else sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[1L])
source(file.path(dirname(local_file), "common.R"), local = TRUE)
source(file.path(dirname(local_file), "visualization.R"), local = TRUE)

monitor_ggplot_history <- function(path = monitor_path(), seconds = 10, output = "termr-history") {
  if (!requireNamespace("ggplot2", quietly = TRUE)) stop("Install optional package 'ggplot2'.")
  if (!is.numeric(seconds) || length(seconds) != 1L || !is.finite(seconds) || seconds <= 0) stop("Invalid duration.")
  client <- monitor_client(path, history = 600L)
  on.exit(client$close(), add = TRUE)
  start <- proc.time()[["elapsed"]]
  while (proc.time()[["elapsed"]] - start < seconds) {client$poll(); Sys.sleep(0.05)}
  data <- termr::termr_stream_data(client$stream, c("cpu", "ram"), extractor = monitor_extract)
  plots <- monitor_ggplots(data)
  for (name in names(plots)) ggplot2::ggsave(paste0(output, "-", name, ".png"), plots[[name]], width = 8, height = 4, dpi = 120)
  invisible(list(data = data, plots = plots))
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  monitor_ggplot_history(if (length(args)) args[[1L]] else monitor_path(),
    seconds = if (length(args) > 1L) as.numeric(args[[2L]]) else 10,
    output = if (length(args) > 2L) args[[3L]] else "termr-history")
}
