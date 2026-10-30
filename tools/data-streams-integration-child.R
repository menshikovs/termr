# Companion for data-streams-integration.R; not part of the installed package.
args <- commandArgs(trailingOnly = TRUE)
root <- args[[1L]]
mode <- args[[2L]]
path <- args[[3L]]
report <- args[[4L]]
stop_file <- args[[5L]]
demo_path <- file.path(root, "inst", "examples", "system-monitor-live")
append_report <- function(text) cat(text, "\n", file = report, append = TRUE)
if (mode == "collector") {
  source(file.path(demo_path, "collector.R"))
  run_collector(path, interval = 0.05, max_samples = 2000)
} else if (mode == "tui") {
  source(file.path(demo_path, "tui.R"))
  demo <- monitor_tui(path, stale_after = 0.4)
  pilot <- termr::test_app(demo$app, 120, 18)
  tryCatch({
    while (!file.exists(stop_file)) {
      pilot$advance(1.01)
      value <- demo$client$stream$latest()
      append_report(paste(pilot$query_one("#source")$text, "sequence", value$sequence))
      Sys.sleep(0.05)
    }
    pilot$press("q")
  }, finally = { pilot$stop(); demo$close() })
} else if (mode == "shiny") {
  source(file.path(demo_path, "shiny-app.R"))
  shiny::testServer(monitor_server(path, stale_after = 0.4), {
    while (!file.exists(stop_file)) {
      session$elapse(501)
      append_report(paste(output$status, "sequence", current()$snapshot$sequence))
      Sys.sleep(0.05)
    }
    session$close()
    stopifnot(client$stream$is_closed())
  })
} else stop("Unknown child mode.")
