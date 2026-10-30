host <- if (.Platform$OS.type == "windows") "windows" else "wsl"
.libPaths(c(file.path("audit-results/nanonext", paste0("lib-", host)), .libPaths()))
pkgload::load_all(".", quiet = TRUE)
x <- termr_stream("metrics")
p <- termr_nano_publish(x, "tcp://127.0.0.1:0", heartbeat = 0.05)
r <- termr_nano_connect(p$endpoint, "metrics", p$snapshot_endpoint, resync_interval = 0.1)
on.exit <- NULL
x$emit(list(cpu = 42, timestamp = Sys.time()))
started <- proc.time()[["elapsed"]]
while (is.null(r$latest()) && proc.time()[["elapsed"]] - started < 5) {
  p$poll(); r$poll(); Sys.sleep(0.002)
}
print(r$latest()); print(r$status()); print(p$status())
stopifnot(identical(r$latest()$cpu, 42L))
r$close(); p$close(); x$close()
cat("PASS snapshot and raw live adapter\n")
