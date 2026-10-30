# Installed-checkout multiprocess fanout benchmark and lifecycle driver.
# Rscript tools/nanonext_integration.R [1|10|50] [target=200] [raw]
args <- commandArgs(trailingOnly = TRUE)
count <- if (length(args)) as.integer(args[[1L]]) else 1L
target <- if (length(args) > 1) as.integer(args[[2L]]) else 200L
raw_mode <- length(args) > 2L && args[[3L]] == "raw"
stopifnot(count %in% c(1L, 10L, 50L))
root <- normalizePath(".", winslash = "/")
scratch <- file.path(root, "audit-results/nanonext", paste0(if (raw_mode) "raw-" else "fanout-", Sys.info()[["sysname"]], "-", count, "-", Sys.getpid()))
dir.create(scratch, recursive = TRUE)
children <- list()
read_json <- function(path) {
  if (!file.exists(path)) return(NULL)
  tryCatch(jsonlite::read_json(path, simplifyVector = TRUE), error = function(e) NULL)
}
wait_for <- function(predicate, description, timeout = 90) {
  start <- proc.time()[["elapsed"]]
  while (!isTRUE(predicate())) {
    if (proc.time()[["elapsed"]] - start > timeout) stop("Timeout: ", description, "; logs: ", scratch)
    Sys.sleep(0.01)
  }
}
launch <- function(mode, tag, endpoint, snapshot_endpoint, slow = FALSE) {
  config <- list(mode = mode, root = root, libraries = .libPaths(), timeout = 180,
    endpoint = endpoint, snapshot_endpoint = snapshot_endpoint, target = target, interval = 0.005,
    slow = slow, stop = file.path(scratch, paste0(tag, ".stop")), go = file.path(scratch, "GO"),
    ready = file.path(scratch, paste0(tag, ".ready")), report = file.path(scratch, paste0(tag, ".json")))
  file <- file.path(scratch, paste0(tag, "-config.json"))
  jsonlite::write_json(config, file, auto_unbox = TRUE, null = "null")
  p <- processx::process$new(file.path(R.home("bin"), "Rscript"),
    c("--vanilla", file.path(root, "tests/testthat/fixtures/nano_child.R"), file),
    env = c("current", R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep), R_TESTS = ""),
    stdout = file.path(scratch, paste0(tag, ".stdout")), stderr = file.path(scratch, paste0(tag, ".stderr")), cleanup_tree = TRUE)
  children[[tag]] <<- p
  list(process = p, config = config)
}
main <- function() {
  on.exit(for (p in children) if (p$is_alive()) p$kill_tree(), add = TRUE)
  pub <- launch(if (raw_mode) "raw-publisher" else "publisher", "publisher", "tcp://127.0.0.1:0", "tcp://127.0.0.1:0")
  wait_for(function() !is.null(read_json(pub$config$ready)), "publisher bound endpoints")
  address <- read_json(pub$config$ready)
  clients <- lapply(seq_len(count), function(i) launch(if (raw_mode) "raw-subscriber" else "subscriber", paste0("sub-", i), address$endpoint,
    address$snapshot_endpoint, slow = i == count && count > 1L))
  wait_for(function() all(vapply(clients, function(x) !is.null(read_json(x$config$ready)), logical(1))), "all subscribers snapshot-ready")
  start <- proc.time()[["elapsed"]]
  file.create(file.path(scratch, "GO"))
  wait_for(function() all(vapply(clients, function(x) !is.null(read_json(x$config$report)), logical(1))), "all subscribers reach latest state")
  elapsed <- proc.time()[["elapsed"]] - start
  reports <- lapply(clients, function(x) read_json(x$config$report))
  stopifnot(all(vapply(reports, function(x) x$latest$n == target && x$history <= 16L && x$status$pending <= 2L, logical(1))))
  for (x in clients) { x$process$wait(10000); stopifnot(x$process$get_exit_status() == 0L) }
  file.create(pub$config$stop); pub$process$wait(10000)
  stopifnot(pub$process$get_exit_status() == 0L)
  summary <- list(platform = Sys.info()[["sysname"]], R = R.version.string, nanonext = as.character(packageVersion("nanonext")),
    endpoints = address, subscribers = count, events = target, elapsed = elapsed,
    observed_events_per_second = target / elapsed,
    delivered_per_second = sum(vapply(reports, function(x) x$delivered, 0)) / elapsed,
    raw_mode = raw_mode, offered_interval = if (raw_mode) 0 else 0.005,
    reports = reports, publisher = read_json(pub$config$report))
  jsonlite::write_json(summary, file.path(scratch, "SUMMARY.json"), auto_unbox = TRUE, null = "null", pretty = TRUE)
  cat("PASS", count, "independent subscribers;", target, "events;", round(elapsed, 3), "seconds\n")
  if (!raw_mode) cat("Median client p50/p95 ms:", stats::median(vapply(reports, function(x) x$latency_ms[[1L]], 0)),
      stats::median(vapply(reports, function(x) x$latency_ms[[2L]], 0)), "\n")
  cat("Observed offered / delivered per second:", summary$observed_events_per_second, summary$delivered_per_second, "\n")
  cat("RSS range MiB:", range(vapply(reports, function(x) x$rss_bytes / 1024^2, 0)), "\nLogs:", scratch, "\n")
}
main()
