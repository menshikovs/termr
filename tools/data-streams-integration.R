# Run against an installed checkout: Rscript tools/data-streams-integration.R
# Set R_LIBS to a scratch installation if desired. Shiny is optional on Windows.
root <- normalizePath(".", winslash = "/", mustWork = TRUE)
stopifnot(requireNamespace("termr", quietly = TRUE),
          "termr_stream" %in% getNamespaceExports("termr"))
scratch <- file.path(root, "audit-results", "data-streams",
                     paste0("integration-", Sys.info()[["sysname"]], "-", Sys.getpid()))
dir.create(scratch, recursive = TRUE, showWarnings = FALSE)
path <- file.path(scratch, "snapshots")
child <- file.path(root, "tools", "data-streams-integration-child.R")
processes <- list()
launch <- function(mode, generation = 1L) {
  tag <- paste(mode, generation, sep = "-")
  report <- file.path(scratch, paste0(tag, ".txt"))
  stop_file <- file.path(scratch, paste0(tag, ".stop"))
  p <- processx::process$new(file.path(R.home("bin"), "Rscript"),
    c("--vanilla", child, root, mode, path, report, stop_file),
    env = c("current", R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep), R_TESTS = ""),
    stdout = file.path(scratch, paste0(tag, ".stdout")),
    stderr = file.path(scratch, paste0(tag, ".stderr")), cleanup_tree = TRUE)
  processes[[tag]] <<- p
  list(process = p, report = report, stop = stop_file)
}
wait_for <- function(predicate, description, timeout = 30) {
  started <- proc.time()[["elapsed"]]
  while (!isTRUE(predicate())) {
    if (proc.time()[["elapsed"]] - started > timeout) stop("Timeout: ", description)
    Sys.sleep(0.05)
  }
  cat("PASS:", description, "\n")
}
contains <- function(client, text) {
  if (!file.exists(client$report)) return(FALSE)
  any(grepl(text, readLines(client$report, warn = FALSE), fixed = TRUE))
}
stop_client <- function(client) {
  file.create(client$stop)
  client$process$wait(10000)
  stopifnot(identical(client$process$get_exit_status(), 0L))
}
main <- function() {
  on.exit(for (p in processes) if (p$is_alive()) p$kill_tree(), add = TRUE)
  collector <- launch("collector")
  source(file.path(root, "inst", "examples", "system-monitor-live", "common.R"), local = TRUE)
  wait_for(function() identical(monitor_read(path)$status, "live"), "collector publishes real snapshots")
  initial <- monitor_read(path)$snapshot$sequence
  tui <- launch("tui")
  shiny <- if (requireNamespace("shiny", quietly = TRUE)) launch("shiny") else NULL
  wait_for(function() contains(tui, "Source: live"), "independent TUI receives live data")
  if (!is.null(shiny)) wait_for(function() contains(shiny, "Source: live"), "independent Shiny session receives live data")
  stop_client(tui)
  stopifnot(collector$process$is_alive())
  if (!is.null(shiny)) stopifnot(shiny$process$is_alive())
  cat("PASS: TUI exit leaves collector and Shiny running\n")
  tui <- launch("tui", 2L)
  wait_for(function() contains(tui, "Source: live"), "TUI restarts independently")
  if (!is.null(shiny)) {
    stop_client(shiny)
    stopifnot(collector$process$is_alive(), tui$process$is_alive())
    shiny <- launch("shiny", 2L)
    wait_for(function() contains(shiny, "Source: live"), "Shiny restarts independently")
  } else cat("SKIP: Shiny not installed on this host\n")
  # Concurrent readers repeatedly parse complete immutable versions.
  readings <- replicate(300, monitor_read(path), simplify = FALSE)
  stopifnot(all(vapply(readings, function(x) identical(x$status, "live"), logical(1))),
            all(vapply(readings, function(x) monitor_snapshot_valid(x$snapshot), logical(1))),
            monitor_read(path)$snapshot$sequence > initial,
            length(monitor_files(path)) <= 3L)
  cat("PASS: 300 concurrent reads contain valid complete snapshots; bounded retention\n")
  file.create(file.path(path, "STOP"))
  collector$process$wait(10000)
  stopifnot(identical(collector$process$get_exit_status(), 0L), !dir.exists(file.path(path, ".writer-lock")))
  wait_for(function() contains(tui, "Source: stale"), "TUI detects stopped collector")
  if (!is.null(shiny)) wait_for(function() contains(shiny, "Source: stale"), "Shiny detects stopped collector")
  stop_client(tui)
  if (!is.null(shiny)) stop_client(shiny)
  cat("PASS: all child processes exit cleanly\nArtifacts:", scratch, "\n")
}
main()
