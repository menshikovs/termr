source("audit-results/shiny-plotly/environment.R")
library(termr)
results <- list()
inherited <- "inherited" %in% commandArgs(trailingOnly = TRUE)
for (mode in c("pkgload-no-nano", "installed", "pkgload", "pkgload-no-helpers", "installed-shiny", "pkgload-shiny")) {
  for (iteration in 1:2) {
    stream <- termr_stream("crash")
    p <- termr_nano_publish(stream, "tcp://127.0.0.1:0", heartbeat = 0.05)
    stream$emit(list(n = 100L))
    stem <- file.path("audit-results/shiny-plotly", paste0("crash-", mode, "-", iteration))
    child <- processx::process$new(file.path(R.home("bin"), "Rscript"),
      c("--vanilla", "audit-results/shiny-plotly/crash_child.R", mode, p$endpoint, p$snapshot_endpoint),
      env = c(if (inherited) "current", R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep), R_TESTS = ""),
      stdout = paste0(stem, ".stdout"), stderr = paste0(stem, ".stderr"), cleanup_tree = TRUE)
    start <- proc.time()[["elapsed"]]
    while (child$is_alive() && proc.time()[["elapsed"]] - start < 20) {p$poll(); Sys.sleep(0.002)}
    if (child$is_alive()) child$kill_tree()
    child$wait(1000)
    results[[length(results) + 1L]] <- list(mode = mode, iteration = iteration, exit = child$get_exit_status())
    p$close(); stream$close()
  }
}
jsonlite::write_json(results, if (inherited) "audit-results/shiny-plotly/crash-matrix-inherited.json" else
  "audit-results/shiny-plotly/crash-matrix.json", auto_unbox = TRUE, pretty = TRUE)
print(results)
