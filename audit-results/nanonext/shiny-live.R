.libPaths(c("audit-results/nanonext/lib-wsl", .libPaths()))
library(termr)
source("inst/examples/system-monitor-live/shiny-app.R")
stream <- termr_stream("system.metrics", history = 1L)
p <- termr_nano_publish(stream, "tcp://127.0.0.1:0")
endpoint <- p$endpoint; snapshot_endpoint <- p$snapshot_endpoint
Sys.setenv(TERMR_METRICS_TRANSPORT = "nano", TERMR_METRICS_ENDPOINT = endpoint,
  TERMR_METRICS_SNAPSHOT_ENDPOINT = snapshot_endpoint)
collect <- monitor_collector("shiny-live")
stream$emit(collect())
shiny::testServer(monitor_server(stale_after = 5), {
  wait_state <- function(predicate, publisher = TRUE, timeout = 10) {
    started <- proc.time()[["elapsed"]]
    while (!isTRUE(predicate())) {
      if (publisher) p$poll()
      session$elapse(51)
      if (proc.time()[["elapsed"]] - started > timeout) stop("Shiny live state timeout")
      Sys.sleep(0.002)
    }
  }
  wait_state(function() !is.null(current()$snapshot))
  stopifnot(grepl("RAM:", output$metrics), is.list(output$history), current()$status == "live")
  cat("PASS live Shiny metrics, bounded history plot and status rendering\n")
  old <- client$stream$status()$source_id
  p$close()
  wait_state(function() current()$status == "stale", publisher = FALSE)
  cat("PASS Shiny stale after publisher stop\n")
  stream$emit(collect())
  p <- termr_nano_publish(stream, endpoint, snapshot_endpoint)
  wait_state(function() client$stream$status()$source_id != old && current()$status == "live")
  stopifnot(length(client$stream$history()) == 1L)
  session$close()
  stopifnot(client$stream$is_closed(), client$stream$status()$pending == 0L)
  cat("PASS Shiny restart resync and session cleanup\n")
})
p$close(); stream$close()
