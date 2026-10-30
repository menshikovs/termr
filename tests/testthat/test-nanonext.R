nano_test_dependencies <- function() {
  skip_if_not_installed("nanonext", minimum_version = "1.10.0")
  skip_if_not_installed("jsonlite")
}

nano_wait <- function(predicate, publishers = list(), remotes = list(), timeout = 8) {
  started <- proc.time()[["elapsed"]]
  repeat {
    for (p in publishers) p$poll()
    for (r in remotes) r$poll()
    if (isTRUE(predicate())) return(invisible(TRUE))
    if (proc.time()[["elapsed"]] - started > timeout) {
      stop("nano_wait timed out; states: ", paste(capture.output(str(lapply(remotes, function(x) x$status()))), collapse = " "))
    }
    Sys.sleep(0.002)
  }
}

test_that("nano JSON rejects malformed envelopes, deep data and executable objects", {
  skip_if_not_installed("jsonlite")
  message <- nano_message("source", "metrics", 1, "event", list(x = 1, at = as.numeric(Sys.time())))
  wire <- nano_encode(message, 1000)
  expect_identical(nano_decode(wire, 1000)$payload$x, 1L)
  for (field in c("schema_version", "source_id", "stream_id", "sequence", "timestamp", "message_type")) {
    bad <- message; bad[[field]] <- NULL
    expect_error(nano_decode(nano_encode(bad, 1000), 1000), "envelope")
  }
  message$schema_version <- 99L
  expect_error(nano_decode(nano_encode(message, 1000), 1000), "envelope")
  expect_error(nano_decode(charToRaw("{bad"), 1000))
  expect_error(nano_decode(as.raw(c(123, 0, 125)), 1000), "bytes")
  expect_error(nano_decode(charToRaw(paste0(strrep("[", 100), "0", strrep("]", 100))), 1000), "nesting")
  expect_error(nano_encode(list(x = strrep("x", 1000)), 256), "max_bytes")
  expect_error(nano_payload(new.env()), "JSON values")
  expect_error(nano_payload(function() 1), "JSON values")
  expect_error(nano_payload(Inf), "Infinite")
  expect_error(nano_payload(list(a = 1, a = 2)), "unique")
  expect_true(is.numeric(nano_payload(Sys.time())))
})

test_that("nano endpoints are loopback-only and ports are owned during allocation", {
  for (endpoint in c("tcp://0.0.0.0:5555", "tcp://localhost:5555", "tcp://192.168.1.1:5555", "tcp://127.0.0.1:65536", "ipc://x")) {
    expect_error(nano_endpoints(endpoint, NULL), "loopback")
  }
  expect_error(nano_endpoints("tcp://127.0.0.1:5555", "tcp://127.0.0.1:5555"), "distinct")
  nano_test_dependencies()
  x <- termr_stream("metrics")
  p <- termr_nano_publish(x, "tcp://127.0.0.1:0")
  on.exit(p$close(), add = TRUE)
  expect_false(grepl(":0$", p$endpoint))
  expect_false(identical(p$endpoint, p$snapshot_endpoint))
  expect_error(termr_nano_publish(x, p$endpoint, p$snapshot_endpoint))
  expect_identical(x$subscriber_count(), 1L)
  p$close(); p$close()
  expect_identical(x$subscriber_count(), 0L)
  expect_false(x$is_closed())
  expect_identical(p$status()$pending, 0L)
})

test_that("nano snapshots establish latest state before live delivery and deduplicate", {
  nano_test_dependencies()
  x <- termr_stream("metrics", history = 0)
  x$emit(list(n = 1))
  p <- termr_nano_publish(x, "tcp://127.0.0.1:0", heartbeat = 0.02)
  on.exit(p$close(), add = TRUE)
  r <- termr_nano_connect(p$endpoint, "metrics", p$snapshot_endpoint, history = 3, resync_interval = 0.02)
  on.exit(r$close(), add = TRUE)
  seen <- integer()
  r$subscribe(function(v) seen <<- c(seen, v$n))
  nano_wait(function() identical(r$latest()$n, 1L), list(p), list(r))
  for (i in 2:6) {
    x$emit(list(n = i))
    nano_wait(function() identical(r$latest()$n, i), list(p), list(r))
  }
  expect_identical(seen, 1:6)
  expect_identical(vapply(r$history(), `[[`, 0L, "n"), 4:6)
  before <- r$status()$resyncs
  nano_wait(function() r$status()$resyncs > before, list(p), list(r))
  expect_identical(seen, 1:6)
  expect_lte(r$status()$pending, 2L)
  expect_lte(p$status()$pending, 1L)
  r$close(); r$close()
  expect_identical(r$subscriber_count(), 0L)
  expect_identical(r$status()$pending, 0L)
  expect_silent(r$poll())
  expect_error(r$subscribe(identity), "closed")
})

test_that("nano recovers restart, gaps, slow readers and an unobserved final event", {
  nano_test_dependencies()
  x <- termr_stream("metrics")
  p <- termr_nano_publish(x, "tcp://127.0.0.1:0", heartbeat = 0.02)
  on.exit(p$close(), add = TRUE)
  endpoint <- p$endpoint; snapshot_endpoint <- p$snapshot_endpoint
  p$close()
  r <- termr_nano_connect(endpoint, "metrics", snapshot_endpoint, buffer = 1L,
    request_timeout = 50L, resync_interval = 0.03, stale_after = 0.03)
  on.exit(r$close(), add = TRUE)
  expect_silent(r$poll())
  expect_identical(r$status()$state, "connecting")
  p <- termr_nano_publish(x, endpoint, snapshot_endpoint, heartbeat = 0.02)
  x$emit(list(n = 1))
  nano_wait(function() identical(r$latest()$n, 1L), list(p), list(r))
  # Real slow reader with a one-message native queue: intermediate events drop.
  for (i in 2:200) x$emit(list(n = i))
  nano_wait(function() identical(r$latest()$n, 200L), list(p), list(r))
  expect_gt(r$status()$gaps, 0)
  expect_true(all(diff(vapply(r$history(), `[[`, 0L, "n")) > 0))
  old_source <- r$status()$source_id
  p$close()
  nano_wait(function() identical(r$status()$state, "stale"), remotes = list(r))
  p <- termr_nano_publish(termr_stream("metrics"), endpoint, snapshot_endpoint, heartbeat = 0.02)
  # Reach the supplied stream only as a white-box test to publish a restart.
  environment(p$poll)$stream$emit(list(n = 999))
  nano_wait(function() identical(r$latest()$n, 999L), list(p), list(r))
  expect_false(identical(r$status()$source_id, old_source))
  expect_length(r$history(), 1L)
  expect_equal(r$status()$sequence, 1)
  # Stop only live delivery: periodic snapshot must recover a dropped final event.
  nanonext::unsubscribe(environment(r$poll)$sub, charToRaw("termr/metrics\n"))
  environment(p$poll)$stream$emit(list(n = 1000))
  nano_wait(function() identical(r$latest()$n, 1000L), list(p), list(r))
})

test_that("nano topic boundaries, corrupted packets and schema errors are isolated", {
  nano_test_dependencies()
  x <- termr_stream("metrics")
  p <- termr_nano_publish(x, "tcp://127.0.0.1:0", heartbeat = 0.02)
  on.exit(p$close(), add = TRUE)
  r <- termr_nano_connect(p$endpoint, "metrics", p$snapshot_endpoint, max_bytes = 2048L, resync_interval = 0.05)
  on.exit(r$close(), add = TRUE)
  x$emit(1)
  nano_wait(function() identical(r$latest(), 1L), list(p), list(r))
  pub <- environment(p$poll)$pub
  wrong <- c(charToRaw("termr/metrics.extra\n"), nano_encode(nano_message(p$source_id, "metrics.extra", 2, "event", 88), 2048))
  nanonext::send(pub, wrong, mode = "raw", block = FALSE)
  # Snapshot barrier proves the peer is polled; no fixed sleep determines success.
  before <- r$status()$resyncs
  nano_wait(function() r$status()$resyncs > before, list(p), list(r))
  expect_identical(r$latest(), 1L)
  bad <- c(charToRaw("termr/metrics\n"), charToRaw("{bad"))
  nano_wait(function() {
    nanonext::send(pub, bad, mode = "raw", block = FALSE)
    r$status()$invalid > 0
  }, list(p), list(r))
  expect_identical(r$latest(), 1L)
  expect_lte(r$status()$pending, 2L)
  x$emit(2)
  nano_wait(function() identical(r$latest(), 2L), list(p), list(r))
})

test_that("nano close inside payload callback cancels pending operations", {
  nano_test_dependencies()
  x <- termr_stream("metrics")
  p <- termr_nano_publish(x, "tcp://127.0.0.1:0")
  on.exit(p$close(), add = TRUE)
  r <- termr_nano_connect(p$endpoint, "metrics", p$snapshot_endpoint)
  on.exit(r$close(), add = TRUE)
  r$subscribe(function(v) { r$close(); p$close() })
  x$emit(1)
  nano_wait(function() r$is_closed(), list(p), list(r))
  expect_identical(r$status()$pending, 0L)
  expect_identical(p$status()$pending, 0L)
  expect_identical(x$subscriber_count(), 0L)
  expect_silent(x$emit(2))
})

test_that("nano exchanges snapshots and events with an independent R process", {
  nano_test_dependencies()
  installed_namespaces <- file.path(.libPaths(), "termr", "NAMESPACE")
  current_peer <- any(vapply(installed_namespaces[file.exists(installed_namespaces)], function(path) {
    any(grepl("export(termr_nano_connect)", readLines(path), fixed = TRUE))
  }, logical(1)))
  if (!current_peer) skip("Install the current checkout for the independent-process peer test.")
  x <- termr_stream("bench")
  p <- termr_nano_publish(x, "tcp://127.0.0.1:0", heartbeat = 0.02)
  on.exit(p$close(), add = TRUE)
  x$emit(list(n = 0L, sent_at = as.numeric(Sys.time())))
  dir <- withr::local_tempdir()
  config <- list(mode = "subscriber", root = normalizePath(test_path("..", ".."), winslash = "/"),
    libraries = .libPaths(), endpoint = p$endpoint, snapshot_endpoint = p$snapshot_endpoint,
    timeout = 20, slow = FALSE, target = 5L, ready = file.path(dir, "ready.json"),
    report = file.path(dir, "report.json"), stop = file.path(dir, "STOP"))
  path <- file.path(dir, "config.json")
  jsonlite::write_json(config, path, auto_unbox = TRUE)
  child <- tryCatch(processx::process$new(file.path(R.home("bin"), "Rscript"),
    c("--vanilla", normalizePath(test_path("fixtures", "nano_child.R"), winslash = "/"), path),
    env = c("current", R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep), R_TESTS = ""),
    stdout = file.path(dir, "stdout"), stderr = file.path(dir, "stderr"), cleanup_tree = TRUE), error = function(e) {
      if (.Platform$OS.type == "windows" && !nzchar(Sys.getenv("CI")) && grepl("Access is denied", conditionMessage(e), fixed = TRUE)) {
        skip("Windows sandbox denies processx pipes; rerun outside sandbox.")
      }
      stop(e)
    })
  on.exit(if (child$is_alive()) child$kill_tree(), add = TRUE)
  read_report <- function(path) {
    if (!file.exists(path)) return(NULL)
    tryCatch(jsonlite::read_json(path, simplifyVector = TRUE), error = function(e) NULL)
  }
  nano_wait(function() !is.null(read_report(config$ready)), list(p), timeout = 20)
  for (i in 1:5) x$emit(list(n = i, sent_at = as.numeric(Sys.time())))
  nano_wait(function() !is.null(read_report(config$report)), list(p), timeout = 20)
  child$wait(5000)
  expect_identical(child$get_exit_status(), 0L,
    info = paste(readLines(file.path(dir, "stderr"), warn = FALSE), collapse = "\n"))
  report <- read_report(config$report)
  expect_equal(report$latest$n, 5)
  expect_identical(report$status$state, "live")
  expect_lte(report$status$pending, 2L)
})

test_that("one bounded poll drains multiple already queued live messages", {
  nano_test_dependencies()
  source <- termr_stream("drain")
  publisher <- termr_nano_publish(source, "tcp://127.0.0.1:0", heartbeat = 0.02)
  on.exit(publisher$close(), add = TRUE)
  remote <- termr_nano_connect(publisher$endpoint, "drain", publisher$snapshot_endpoint, buffer = 128L)
  on.exit(remote$close(), add = TRUE)
  source$emit(0L)
  nano_wait(function() identical(remote$latest(), 0L), list(publisher), list(remote))
  # Encoding twenty messages lets the native receive queue fill while R is
  # publishing; completion is checked by state, never by a guessed sleep.
  for (i in 1:20) source$emit(i)
  publisher$poll()
  count <- remote$poll(max_messages = 4L)
  expect_lte(count, 4L)
  expect_gte(count, 2L)
  nano_wait(function() identical(remote$latest(), 20L), list(publisher), list(remote))
  expect_lte(remote$status()$pending, 2L)
})
