stopifnot(.Platform$OS.type == "windows")
.libPaths(c("audit-results/nanonext/lib-windows", .libPaths()))
root <- normalizePath(".", winslash = "/")
linux <- "/mnt/c/programming_pj/r_textualize"
path <- file.path(root, "audit-results/nanonext/cross-restart")
dir.create(path, showWarnings = FALSE)
children <- list()
read_json <- function(file) if (file.exists(file)) tryCatch(jsonlite::read_json(file, simplifyVector = TRUE), error = function(e) NULL) else NULL
launch <- function(generation, endpoint, snapshot_endpoint) {
  name <- paste0("publisher-", generation)
  windows_base <- file.path(path, name)
  wsl_base <- sub(root, linux, windows_base, fixed = TRUE)
  config <- list(mode = "publisher", root = NULL,
    libraries = paste0(linux, "/audit-results/nanonext/lib-wsl"), timeout = 45,
    endpoint = endpoint, snapshot_endpoint = snapshot_endpoint, target = 20L, interval = 0.01,
    stop = paste0(wsl_base, ".stop"), go = paste0(wsl_base, ".go"),
    ready = paste0(wsl_base, ".ready"), report = paste0(wsl_base, ".json"))
  jsonlite::write_json(config, paste0(windows_base, "-config.json"), auto_unbox = TRUE, null = "null")
  p <- processx::process$new("wsl.exe", c("-d", "Ubuntu", "--exec", "env",
    paste0("R_LIBS=", linux, "/audit-results/nanonext/lib-wsl"), "Rscript", "--vanilla",
    paste0(linux, "/tests/testthat/fixtures/nano_child.R"), paste0(wsl_base, "-config.json")),
    stdout = paste0(windows_base, ".stdout"), stderr = paste0(windows_base, ".stderr"), cleanup_tree = TRUE)
  children[[name]] <<- p
  list(process = p, base = windows_base)
}
wait_for <- function(predicate, timeout = 15) {
  start <- proc.time()[["elapsed"]]
  while (!isTRUE(predicate())) {
    if (proc.time()[["elapsed"]] - start > timeout) stop("Cross restart timed out")
    Sys.sleep(0.002)
  }
}
main <- function() {
  on.exit(for (p in children) if (p$is_alive()) p$kill_tree(), add = TRUE)
  p <- launch(1L, "tcp://127.0.0.1:0", "tcp://127.0.0.1:0")
  wait_for(function() !is.null(read_json(paste0(p$base, ".ready"))))
  endpoints <- read_json(paste0(p$base, ".ready"))
  r <- termr::termr_nano_connect(endpoints$endpoint, "bench", endpoints$snapshot_endpoint, resync_interval = 0.05)
  on.exit(r$close(), add = TRUE)
  latency <- numeric()
  r$subscribe(function(value) if (value$n > 0) latency <<- c(latency, (as.numeric(Sys.time()) - value$sent_at) * 1000))
  wait_for(function() {r$poll(); !is.null(r$latest())})
  file.create(paste0(p$base, ".go"))
  wait_for(function() {r$poll(); r$latest()$n == 20L})
  first_source <- r$status()$source_id
  file.create(paste0(p$base, ".stop")); p$process$wait(5000)
  stopifnot(p$process$get_exit_status() == 0L)
  p <- launch(2L, endpoints$endpoint, endpoints$snapshot_endpoint)
  wait_for(function() !is.null(read_json(paste0(p$base, ".ready"))))
  wait_for(function() {r$poll(); !identical(r$status()$source_id, first_source)})
  file.create(paste0(p$base, ".go"))
  wait_for(function() {r$poll(); r$latest()$n == 20L})
  file.create(paste0(p$base, ".stop")); p$process$wait(5000)
  stopifnot(p$process$get_exit_status() == 0L)
  report <- list(direction = "WSL publisher -> Windows subscriber", endpoints = endpoints,
    restart = TRUE, final = r$status(), latency_ms = as.list(stats::quantile(latency, c(0.5, 0.95, 0.99))))
  jsonlite::write_json(report, file.path(path, "RESULT.json"), auto_unbox = TRUE, pretty = TRUE)
  print(report)
  cat("PASS cross-OS loopback and restart\n")
}
main()
