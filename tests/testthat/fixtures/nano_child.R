# Trusted test harness only. Network payloads remain JSON, never R objects.
args <- commandArgs(trailingOnly = TRUE)
config <- jsonlite::read_json(args[[1L]], simplifyVector = TRUE)
.libPaths(c(config$libraries, .libPaths()))
library(termr)
write_json <- function(x, path) jsonlite::write_json(x, path, auto_unbox = TRUE, null = "null", digits = NA)
started <- proc.time()[["elapsed"]]
alive <- function() proc.time()[["elapsed"]] - started < config$timeout && !file.exists(config$stop)
main <- function() {
  if (config$mode == "raw-publisher") {
    socket <- nanonext::socket("pub", listen = config$endpoint)
    on.exit(close(socket), add = TRUE)
    endpoint <- paste0("tcp://127.0.0.1:", nanonext::opt(socket$listener[[1L]], "tcp-bound-port"))
    write_json(list(endpoint = endpoint, snapshot_endpoint = "unused", source = "raw"), config$ready)
    n <- 0L
    packet <- function(n) charToRaw(paste0("raw\n", sprintf("%010d", n), strrep("x", 150L)))
    while (alive()) {
      if (file.exists(config$go) && n < config$target) {
        for (i in seq_len(min(256L, config$target - n))) {
          n <- n + 1L
          nanonext::send(socket, packet(n), mode = "raw", block = FALSE)
        }
      } else {
        nanonext::send(socket, packet(n), mode = "raw", block = FALSE)
        Sys.sleep(0.001)
      }
    }
    write_json(list(n = n), config$report)
  } else if (config$mode == "raw-subscriber") {
    socket <- nanonext::socket("sub")
    nanonext::opt(socket, "recv-size-max") <- 256L
    nanonext::opt(socket, "recv-buffer") <- if (isTRUE(config$slow)) 1L else 64L
    nanonext::subscribe(socket, "raw\n")
    nanonext::dial(socket, config$endpoint, fail = "error")
    operation <- nanonext::recv_aio(socket, mode = "raw", timeout = 1000L)
    on.exit({nanonext::stop_aio(operation); close(socket)}, add = TRUE)
    latest <- -1L; delivered <- 0L; ready <- FALSE
    while (alive() && latest < config$target) {
      if (!nanonext::unresolved(operation)) {
        wire <- operation$data
        nanonext::stop_aio(operation)
        if (is.raw(wire) && length(wire) == 164L) {
          n <- as.integer(rawToChar(wire[5:14]))
          if (n > latest) {latest <- n; delivered <- delivered + 1L}
          if (!ready) {write_json(list(ready = TRUE), config$ready); ready <- TRUE}
        }
        operation <- nanonext::recv_aio(socket, mode = "raw", timeout = 1000L)
      } else Sys.sleep(0.001)
    }
    write_json(list(latest = list(n = latest), delivered = delivered, status = list(pending = 1L),
      rss_bytes = unname(ps::ps_memory_info()[["rss"]]), history = 0L), config$report)
    if (latest != config$target) quit(status = 2L)
  } else if (config$mode == "publisher") {
    stream <- termr::termr_stream("bench", history = 1L)
    pub <- termr::termr_nano_publish(stream, config$endpoint, config$snapshot_endpoint, heartbeat = 0.05)
    on.exit({pub$close(); stream$close()}, add = TRUE)
    stream$emit(list(n = 0L, sent_at = as.numeric(Sys.time())))
    write_json(list(endpoint = pub$endpoint, snapshot_endpoint = pub$snapshot_endpoint,
      source = pub$source_id, R = R.version.string, nanonext = as.character(packageVersion("nanonext"))), config$ready)
    n <- 0L; next_emit <- Inf; total_emit <- 0
    while (alive()) {
      if (file.exists(config$go) && is.infinite(next_emit)) next_emit <- proc.time()[["elapsed"]]
      if (n < config$target && proc.time()[["elapsed"]] >= next_emit) {
        n <- n + 1L
        before <- proc.time()[["elapsed"]]
        stream$emit(list(n = n, sent_at = as.numeric(Sys.time())))
        total_emit <- total_emit + proc.time()[["elapsed"]] - before
        next_emit <- proc.time()[["elapsed"]] + config$interval
      }
      pub$poll()
      Sys.sleep(0.001)
    }
    write_json(list(n = n, emit_seconds = total_emit, status = pub$status()), config$report)
  } else if (config$mode == "subscriber") {
    remote <- termr::termr_nano_connect(config$endpoint, "bench", config$snapshot_endpoint,
      history = 16L, buffer = if (isTRUE(config$slow)) 1L else 64L,
      resync_interval = 0.05, request_timeout = 250L)
    on.exit(remote$close(), add = TRUE)
    latencies <- numeric(); delivered <- 0L
    remote$subscribe(function(x) {
      delivered <<- delivered + 1L
      if (x$n > 0 && length(latencies) < 10000L) latencies <<- c(latencies, (as.numeric(Sys.time()) - x$sent_at) * 1000)
    })
    ready <- FALSE
    while (alive()) {
      remote$poll()
      if (!ready && remote$status()$state == "live") { write_json(list(ready = TRUE), config$ready); ready <- TRUE }
      if (!is.null(remote$latest()) && remote$latest()$n >= config$target) break
      Sys.sleep(if (isTRUE(config$slow)) 0.05 else 0.001)
    }
    write_json(list(latest = remote$latest(), status = remote$status(), delivered = delivered,
      latency_ms = if (length(latencies)) as.list(stats::quantile(latencies, c(0.5, 0.95, 0.99))) else NULL,
      rss_bytes = unname(ps::ps_memory_info()[["rss"]]), history = length(remote$history())), config$report)
    if (is.null(remote$latest()) || remote$latest()$n < config$target) quit(status = 2L)
  } else if (config$mode %in% c("tui", "shiny", "collector")) {
    demo <- file.path(config$root, "inst/examples/system-monitor-live")
    Sys.setenv(TERMR_METRICS_TRANSPORT = if (config$mode == "collector") "both" else "nano",
      TERMR_METRICS_ENDPOINT = config$endpoint, TERMR_METRICS_SNAPSHOT_ENDPOINT = config$snapshot_endpoint,
      TERMR_METRICS_READY = config$ready)
    if (config$mode == "collector") {
      source(file.path(demo, "collector.R"))
      run_collector(config$path, interval = 0.1, max_samples = 2000)
    } else if (config$mode == "tui") {
      source(file.path(demo, "tui.R"))
      ui <- monitor_tui(config$path, stale_after = 2)
      pilot <- termr::test_app(ui$app, 120, 18)
      on.exit({pilot$stop(); ui$close()}, add = TRUE)
      while (alive()) {
        pilot$advance(0.051)
        value <- ui$client$stream$latest()
        if (!is.null(value)) write_json(list(status = pilot$query_one("#source")$text,
          source = value$source_id, sequence = value$sequence), config$report)
        Sys.sleep(0.01)
      }
    } else {
      source(file.path(demo, "shiny-app.R"))
      shiny::testServer(monitor_server(config$path, stale_after = 2), {
        while (alive()) {
          session$elapse(51)
          value <- current()$snapshot
          if (!is.null(value)) write_json(list(status = output$status, source = value$source_id,
            sequence = value$sequence), config$report)
          Sys.sleep(0.01)
        }
        session$close()
      })
    }
  } else stop("Unknown child mode")
}
main()
