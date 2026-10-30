source("audit-results/shiny-plotly/environment.R")
source("inst/examples/system-monitor-live/visualization.R")
library(termr)
stream <- termr_stream("bench", history = 600L)
for (i in 1:600) stream$emit(list(timestamp = Sys.time() + i, cpu = i %% 101, ram = 50))
data <- termr_stream_data(stream)
timing <- function(fn, count = 20L) {
  vapply(seq_len(count), function(i) unname(system.time(fn())[["elapsed"]]) * 1000, 0)
}
initial <- timing(function() monitor_plotly_arrays(data, 600L))
frame <- timing(function() termr_stream_data(stream))
ggplot <- timing(function() {
  grDevices::png(tempfile(fileext = ".png"), width = 800, height = 400)
  on.exit(grDevices::dev.off())
  print(monitor_ggplots(data)$compare)
}, 10L)
fake <- list(ns = function(x) if (is.null(x)) "" else x,
  sendCustomMessage = function(type, message) invisible(NULL), onFlushed = function(fn, once) fn())
incremental <- timing(function() monitor_plotly_send(fake, "live", list(type = "extend", data = tail(data, 1L)), 600L))
jsonlite::write_json(list(frame_ms = frame, initial_arrays_ms = initial,
  ggplot_draw_ms = ggplot, incremental_proxy_ms = incremental),
  file.path("audit-results/shiny-plotly", paste0("plot-benchmark-", host, ".json")), auto_unbox = TRUE, pretty = TRUE)
stream$close()
cat("PASS server frame/ggplot/Plotly preparation; browser cost measured separately\n")
