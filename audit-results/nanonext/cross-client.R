args <- commandArgs(trailingOnly = TRUE)
host <- if (.Platform$OS.type == "windows") "windows" else "wsl"
.libPaths(c(file.path("audit-results/nanonext", paste0("lib-", host)), .libPaths()))
path <- file.path("audit-results/nanonext", args[[1L]])
ready <- jsonlite::read_json(file.path(path, "ready.json"), simplifyVector = TRUE)
r <- termr::termr_nano_connect(ready$endpoint, "bench", ready$snapshot_endpoint,
  request_timeout = 500L, resync_interval = 0.05)
start <- proc.time()[["elapsed"]]
connected <- FALSE
while (proc.time()[["elapsed"]] - start < 8) {
  r$poll()
  if (!is.null(r$latest())) {
    if (!connected) { connected <- TRUE; file.create(file.path(path, "GO")) }
    if (r$latest()$n == 20L) break
  }
  Sys.sleep(0.002)
}
report <- list(direction = args[[1L]], client_R = R.version.string,
  nanonext = as.character(packageVersion("nanonext")), endpoint = ready$endpoint,
  snapshot_endpoint = ready$snapshot_endpoint, publisher = ready,
  connected = connected, latest = r$latest(), status = r$status())
jsonlite::write_json(report, file.path(path, "RESULT.json"), auto_unbox = TRUE, null = "null", pretty = TRUE)
print(report)
r$close(); file.create(file.path(path, "STOP"))
