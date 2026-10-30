source("audit-results/shiny-plotly/environment.R")
results <- list()
for (kind in c("inherit", "partial", "current", "full")) {
  opts <- list(command = file.path(R.home("bin"), "Rscript"),
    args = c("--vanilla", "audit-results/shiny-plotly/minimal_crash_child.R", "cli"),
    stdout = paste0("audit-results/shiny-plotly/env-", kind, ".stdout"),
    stderr = paste0("audit-results/shiny-plotly/env-", kind, ".stderr"), cleanup_tree = TRUE)
  overrides <- c(R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep), R_TESTS = "")
  if (kind == "partial") opts$env <- overrides
  if (kind == "current") opts$env <- c("current", overrides)
  if (kind == "full") {env <- Sys.getenv(); env[names(overrides)] <- overrides; opts$env <- env}
  child <- do.call(processx::process$new, opts)
  child$wait(10000)
  if (child$is_alive()) child$kill_tree()
  results[[kind]] <- child$get_exit_status()
}
jsonlite::write_json(results, "audit-results/shiny-plotly/environment-crash.json", auto_unbox = TRUE, pretty = TRUE)
print(results)
