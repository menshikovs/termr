host <- if (.Platform$OS.type == "windows") "windows" else "wsl"
.libPaths(c(normalizePath(file.path("audit-results/nanonext", paste0("lib-", host)), winslash = "/"), .libPaths()))
root <- normalizePath(".", winslash = "/")
scratch <- file.path(root, "audit-results/nanonext", paste0("monitor-", Sys.info()[["sysname"]], "-", Sys.getpid()))
dir.create(scratch, recursive = TRUE)
path <- file.path(scratch, "snapshots")
dir.create(path)
processes <- list()
read_json <- function(path) {
  if (!file.exists(path)) return(NULL)
  tryCatch(jsonlite::read_json(path, simplifyVector = TRUE), error = function(e) NULL)
}
wait_for <- function(predicate, description, timeout = 30) {
  start <- proc.time()[["elapsed"]]
  while (!isTRUE(predicate())) {
    if (proc.time()[["elapsed"]] - start > timeout) stop("Timeout: ", description, "; logs: ", scratch)
    Sys.sleep(0.02)
  }
  cat("PASS:", description, "\n")
}
launch <- function(mode, tag, endpoint, snapshot_endpoint) {
  config <- list(mode = mode, root = root, libraries = .libPaths(), timeout = 90, path = path,
    endpoint = endpoint, snapshot_endpoint = snapshot_endpoint, target = 0L, slow = FALSE,
    stop = file.path(scratch, paste0(tag, ".stop")), ready = file.path(scratch, paste0(tag, ".ready")),
    report = file.path(scratch, paste0(tag, ".json")))
  cfg <- file.path(scratch, paste0(tag, "-config.json"))
  jsonlite::write_json(config, cfg, auto_unbox = TRUE, null = "null")
  p <- processx::process$new(file.path(R.home("bin"), "Rscript"),
    c("--vanilla", "tests/testthat/fixtures/nano_child.R", cfg),
    env = c(R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep), R_TESTS = ""),
    stdout = file.path(scratch, paste0(tag, ".stdout")), stderr = file.path(scratch, paste0(tag, ".stderr")), cleanup_tree = TRUE)
  processes[[tag]] <<- p
  list(process = p, config = config)
}
stop_client <- function(client) {
  file.create(client$config$stop); client$process$wait(5000)
  stopifnot(client$process$get_exit_status() == 0L)
}
is_state <- function(client, text) {
  x <- read_json(client$config$report)
  !is.null(x) && grepl(text, x$status, fixed = TRUE)
}
main <- function() {
  on.exit(for (p in processes) if (p$is_alive()) p$kill_tree(), add = TRUE)
  collector <- launch("collector", "collector", "tcp://127.0.0.1:0", "tcp://127.0.0.1:0")
  ready <- function() {
    file <- collector$config$ready
    if (!file.exists(file)) return(NULL)
    x <- readLines(file, warn = FALSE)
    if (length(x) == 2L) x else NULL
  }
  wait_for(function() !is.null(ready()), "collector owns dynamic loopback endpoints")
  endpoints <- ready()
  tui <- launch("tui", "tui-1", endpoints[[1]], endpoints[[2]])
  shiny <- if (requireNamespace("shiny", quietly = TRUE)) launch("shiny", "shiny-1", endpoints[[1]], endpoints[[2]]) else NULL
  independent <- termr::termr_nano_connect(endpoints[[1]], "system.metrics", endpoints[[2]], request_timeout = 3000L)
  on.exit(independent$close(), add = TRUE)
  tryCatch(wait_for(function() { independent$poll(); !is.null(independent$latest()) }, "independent R subscriber receives metrics"),
    error = function(e) { print(independent$status()); stop(e) })
  wait_for(function() is_state(tui, "Source: live"), "TUI receives live metrics")
  if (!is.null(shiny)) wait_for(function() is_state(shiny, "Source: live"), "Shiny receives live metrics")
  source(file.path(root, "inst/examples/system-monitor-live/common.R"), local = TRUE)
  file_client <- monitor_client(path, transport = "file")
  on.exit(file_client$close(), add = TRUE)
  reading <- file_client$poll()
  stopifnot(reading$status == "live", reading$snapshot$source_id == independent$latest()$source_id)
  cat("PASS: simultaneous file snapshots and live payloads share collector identity\n")
  stop_client(tui)
  stopifnot(collector$process$is_alive(), is.null(shiny) || shiny$process$is_alive())
  tui <- launch("tui", "tui-2", endpoints[[1]], endpoints[[2]])
  wait_for(function() is_state(tui, "Source: live"), "TUI restarts without collector shutdown")
  if (!is.null(shiny)) {
    stop_client(shiny)
    stopifnot(collector$process$is_alive())
    shiny <- launch("shiny", "shiny-2", endpoints[[1]], endpoints[[2]])
    wait_for(function() is_state(shiny, "Source: live"), "Shiny restarts independently")
  } else cat("SKIP: Shiny absent on this host\n")
  file.create(file.path(path, "STOP")); collector$process$wait(5000)
  stopifnot(collector$process$get_exit_status() == 0L)
  wait_for(function() is_state(tui, "Source: stale"), "TUI detects stopped collector")
  if (!is.null(shiny)) wait_for(function() is_state(shiny, "Source: stale"), "Shiny detects stopped collector")
  # Remove only our graceful stop marker, then reuse the same bound endpoints.
  unlink(file.path(path, "STOP"))
  previous <- independent$latest()$source_id
  collector <- launch("collector", "collector-2", endpoints[[1]], endpoints[[2]])
  wait_for(function() { independent$poll(); !is.null(independent$latest()) && independent$latest()$source_id != previous }, "subscriber recovers collector restart")
  wait_for(function() is_state(tui, "Source: live"), "TUI recovers after source restart")
  if (!is.null(shiny)) wait_for(function() is_state(shiny, "Source: live"), "Shiny recovers after source restart")
  stop_client(tui)
  if (!is.null(shiny)) stop_client(shiny)
  file.create(file.path(path, "STOP")); collector$process$wait(5000)
  stopifnot(collector$process$get_exit_status() == 0L)
  cat("PASS: independent processes and source lifecycle; all exits clean\nLogs:", scratch, "\n")
}
main()
