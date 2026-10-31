# Live metrics on a native terminal chart. Run with:
#   Rscript -e 'termr::run_example("native-charts-stream")'
# Press q to exit.

library(termr)

events <- termr_stream("demo-metrics", history = 512L)
chart <- line_chart(numeric(), numeric(), title = "Live latency (ms)",
                    x_label = "UTC time", y_label = "ms", mode = "auto",
                    id = "live-chart")
chart$bind_stream(
  events,
  x = function(event) event$timestamp,
  y = function(event) event$latency_ms,
  max_points = 180L
)

sequence <- 0L
ui <- app(
  vertical(
    chart,
    label("Synchronous local stream; bounded to 180 chart points")
  ),
  bind("q", function(app) {
    events$close()
    app$exit()
  })
)
ui$set_interval(0.25, function(app) {
  sequence <<- sequence + 1L
  timestamp <- as.POSIXct(Sys.time(), tz = "UTC")
  latency <- 18 + 5 * sin(sequence / 7) + stats::runif(1, -1.5, 1.5)
  events$emit(list(source_id = "demo-1", sequence = sequence,
                   timestamp = timestamp, latency_ms = latency))
})

run(ui)
