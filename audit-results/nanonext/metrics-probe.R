host <- if (.Platform$OS.type == "windows") "windows" else "wsl"
.libPaths(c(file.path("audit-results/nanonext", paste0("lib-", host)), .libPaths()))
library(termr)
source("inst/examples/system-monitor-live/common.R")
stream <- termr_stream("system.metrics")
p <- termr_nano_publish(stream, "tcp://127.0.0.1:0")
r <- termr_nano_connect(p$endpoint, "system.metrics", p$snapshot_endpoint)
value <- monitor_collector()()
cat("metrics valid", monitor_snapshot_valid(value), "\n")
stream$emit(value)
start <- proc.time()[["elapsed"]]
while (is.null(r$latest()) && proc.time()[["elapsed"]] - start < 5) { p$poll(); r$poll(); Sys.sleep(0.002) }
print(p$status()); print(r$status()); print(names(r$latest()))
r$close(); p$close()
