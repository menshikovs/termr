source("audit-results/shiny-plotly/environment.R")
library(termr)
root <- normalizePath(".", winslash = "/")
base <- file.path(root, "audit-results/shiny-plotly", paste0("performance-", host))
dir.create(base, recursive = TRUE, showWarnings = FALSE)
read_json <- function(path) {
  if (!file.exists(path)) return(NULL)
  tryCatch(jsonlite::read_json(path, simplifyVector = TRUE), error = function(e) NULL)
}
quantiles <- function(x) if (length(x)) unname(quantile(x, c(.5, .95, .99))) else numeric()
run <- function(count, rate, duration, capacity = 64L) {
  path <- file.path(base, paste(count, rate, duration, sep = "-"))
  dir.create(path, showWarnings = FALSE)
  config <- list(libraries = .libPaths(), endpoint = "tcp://127.0.0.1:0",
    snapshot_endpoint = "tcp://127.0.0.1:0", rate = rate, duration = duration, timeout = 30,
    ready = file.path(path, "ready.json"), report = file.path(path, "publisher.json"),
    go = file.path(path, "GO"), stop = file.path(path, "STOP"))
  unlink(c(config$ready, config$report, config$go, config$stop))
  config_file <- file.path(path, "config.json")
  jsonlite::write_json(config, config_file, auto_unbox = TRUE)
  child <- processx::process$new(file.path(R.home("bin"), "Rscript"),
    c("--vanilla", file.path(root, "tests/testthat/fixtures/shiny_stream_child.R"), config_file),
    env = c("current", R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep), R_TESTS = ""),
    stdout = file.path(path, "stdout"), stderr = file.path(path, "stderr"), cleanup_tree = TRUE)
  on.exit(if (child$is_alive()) child$kill_tree(), add = TRUE)
  deadline <- proc.time()[["elapsed"]] + 30
  while (is.null(address <- read_json(config$ready))) {
    if (!child$is_alive() || proc.time()[["elapsed"]] > deadline) stop("Publisher startup: ", path)
    Sys.sleep(.01)
  }
  remote <- termr_nano_connect(address$endpoint, "shiny.bench", address$snapshot_endpoint,
    history = 4L, buffer = 256L, resync_interval = 2)
  receiver <- termr_shiny_receiver(remote, max_points = capacity, close_source = TRUE)
  on.exit(receiver$close(), add = TRUE)
  transport <- reactive <- e2e <- numeric(); delivered <- integer(count)
  bounded <- function(x, value) tail(c(x, value), 4000L)
  remote$subscribe(function(x) transport <<- bounded(transport, (as.numeric(Sys.time()) - x$sent_at) * 1000))
  sessions <- lapply(seq_len(count), function(i) shiny::MockShinySession$new())
  on.exit(for (session in sessions) session$close(), add = TRUE)
  observers <- lapply(seq_len(count), function(i) {
    value <- termr_shiny_reactive(receiver, sessions[[i]])
    history <- termr_shiny_history(receiver, sessions[[i]], max_points = capacity)
    shiny::observe({
      x <- value(); records <- history()
      if (!is.null(x) && length(records)) {
        delivered[[i]] <<- delivered[[i]] + 1L
        reactive <<- bounded(reactive, (as.numeric(Sys.time()) - tail(records, 1L)[[1L]]$received_at) * 1000)
        e2e <<- bounded(e2e, (as.numeric(Sys.time()) - x$sent_at) * 1000)
      }
    }, domain = sessions[[i]])
  })
  # Public session flush executes observers. The same receiver poll is invoked
  # once per 50 ms, independent of the number of sessions (manual scheduler).
  sessions[[1L]]$flushReact()
  cpu <- proc.time(); start <- proc.time()[["elapsed"]]
  rss <- numeric(); rss_at <- numeric(); last_rss <- -Inf
  file.create(config$go)
  repeat {
    receiver$poll(); sessions[[1L]]$flushReact()
    elapsed <- proc.time()[["elapsed"]] - start
    if (elapsed - last_rss >= .5) {
      rss <- c(rss, unname(ps::ps_memory_info()[["rss"]])); rss_at <- c(rss_at, elapsed); last_rss <- elapsed
    }
    if (elapsed > duration + .3) break
    Sys.sleep(.05)
  }
  file.create(config$stop); child$wait(10000)
  stopifnot(child$get_exit_status() == 0L, receiver$diagnostics()$observers == 1L,
    receiver$diagnostics()$sessions == count, length(receiver$history()) <= capacity,
    remote$status()$pending <= 2L, all(delivered > 0))
  cpu <- proc.time() - cpu
  result <- list(sessions = count, rate = rate, duration = duration, elapsed = elapsed,
    cpu_seconds = sum(cpu[1:2]), cpu_percent_one_core = 100 * sum(cpu[1:2]) / elapsed,
    transport_ms = quantiles(transport), reactive_ms = quantiles(reactive), publisher_to_reactive_ms = quantiles(e2e),
    diagnostic = receiver$diagnostics(), source_status = remote$status(), delivered = delivered,
    rss_mib = rss / 1024^2, rss_at = rss_at, publisher = read_json(config$report))
  for (session in sessions) session$close()
  stopifnot(receiver$diagnostics()$sessions == 0L)
  receiver$close()
  stopifnot(receiver$diagnostics()$observers == 0L, remote$status()$pending == 0L)
  jsonlite::write_json(result, file.path(path, "RESULT.json"), auto_unbox = TRUE, null = "null", pretty = TRUE)
  cat("PASS", count, "sessions", rate, "Hz", duration, "s; CPU", round(result$cpu_percent_one_core, 2), "%\n")
  result
}
results <- list()
for (count in c(1L, 5L, 20L)) for (rate in c(0, 1, 10, 100)) {
  results[[length(results) + 1L]] <- run(count, rate, 3)
}
results[[length(results) + 1L]] <- run(20L, 100, 60, capacity = 600L)
jsonlite::write_json(results, file.path(base, "SUMMARY.json"), auto_unbox = TRUE, null = "null", pretty = TRUE)
