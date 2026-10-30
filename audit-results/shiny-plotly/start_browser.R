source("audit-results/shiny-plotly/environment.R")
args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args)) args[[1L]] else "dashboard"
path <- normalizePath("audit-results/shiny-plotly", winslash = "/")
snapshot <- file.path(path, Sys.getenv("TERMR_AUDIT_SNAPSHOTS", "browser-snapshots"))
dir.create(snapshot, showWarnings = FALSE)
endpoint <- Sys.getenv("TERMR_AUDIT_ENDPOINT", "tcp://127.0.0.1:5565")
rpc <- Sys.getenv("TERMR_AUDIT_RPC", "tcp://127.0.0.1:5566")
if (mode == "collector") {
  writeLines(as.character(Sys.getpid()), file.path(path, paste0("browser-collector-pid-", host, ".txt")))
  source("inst/examples/system-monitor-live/collector.R")
  run_collector(snapshot, interval = as.numeric(Sys.getenv("TERMR_AUDIT_INTERVAL", "0.1")), transport = "both", endpoint = endpoint, snapshot_endpoint = rpc)
} else {
  source("inst/examples/system-monitor-live/dashboard.R")
  app <- monitor_dashboard(snapshot, "plotly", max_points = 50L, transport = "nano",
    endpoint = endpoint, snapshot_endpoint = rpc, probe = TRUE)
  writeLines(as.character(Sys.getpid()), file.path(path, "browser-dashboard-pid.txt"))
  stop_file <- file.path(path, "browser-dashboard.STOP")
  unlink(stop_file)
  write_diag <- function() {
    if (app$receiver$is_closed()) return(invisible(NULL))
    if (file.exists(stop_file)) {shiny::stopApp(); return(invisible(NULL))}
    jsonlite::write_json(c(app$diagnostics(), list(status = app$receiver$status())),
      file.path(path, "browser-diagnostics.json"), auto_unbox = TRUE, null = "null")
    later::later(write_diag, 1)
  }
  write_diag()
  Rprof(file.path(path, paste0("browser-", host, "-Rprof.out")), interval = .02)
  tryCatch(shiny::runApp(app$app, host = "127.0.0.1", port = 3838L, launch.browser = FALSE), finally = {
    app$close(); Rprof(NULL)
    jsonlite::write_json(app$diagnostics(), file.path(path, paste0("browser-shutdown-", host, ".json")), auto_unbox = TRUE)
  })
}
