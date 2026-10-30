source("audit-results/shiny-plotly/environment.R")
results <- list()
for (mode in c("plain", "pkgload", "testthat", "rlang", "shiny", "shiny-mock", "testserver", "test-that")) {
  base <- file.path("audit-results/shiny-plotly", paste0("minimal-crash-", mode))
  child <- processx::process$new(file.path(R.home("bin"), "Rscript"),
    c("--vanilla", "audit-results/shiny-plotly/minimal_crash_child.R", mode),
    env = c(R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep), R_TESTS = ""),
    stdout = paste0(base, ".stdout"), stderr = paste0(base, ".stderr"), cleanup_tree = TRUE)
  child$wait(15000)
  if (child$is_alive()) child$kill_tree()
  results[[mode]] <- child$get_exit_status()
}
jsonlite::write_json(results, "audit-results/shiny-plotly/minimal-crash.json", auto_unbox = TRUE, pretty = TRUE)
print(results)
