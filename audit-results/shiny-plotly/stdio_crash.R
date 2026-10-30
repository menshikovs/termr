source("audit-results/shiny-plotly/environment.R")
results <- list()
for (mode in c("cli", "rlang", "testserver")) for (stdio in c("files", "pipes", "inherit", "stdin-inherit")) {
  base <- file.path("audit-results/shiny-plotly", paste0("stdio-", mode, "-", stdio))
  opts <- list(command = file.path(R.home("bin"), "Rscript"),
    args = c("--vanilla", "audit-results/shiny-plotly/minimal_crash_child.R", mode),
    env = c(R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep), R_TESTS = ""), cleanup_tree = TRUE)
  if (stdio == "pipes") {opts$stdout <- "|"; opts$stderr <- "|"}
  else if (stdio == "inherit") {opts$stdout <- ""; opts$stderr <- ""; opts$stdin <- ""}
  else {opts$stdout <- paste0(base, ".stdout"); opts$stderr <- paste0(base, ".stderr")}
  if (stdio == "stdin-inherit") opts$stdin <- ""
  child <- do.call(processx::process$new, opts)
  child$wait(10000)
  if (child$is_alive()) child$kill_tree()
  if (stdio == "pipes") {
    writeLines(child$read_all_output(), paste0(base, ".stdout"))
    writeLines(child$read_all_error(), paste0(base, ".stderr"))
  }
  results[[paste(mode, stdio)]] <- child$get_exit_status()
}
jsonlite::write_json(results, "audit-results/shiny-plotly/stdio-crash.json", auto_unbox = TRUE, pretty = TRUE)
print(results)
