test_that("scratch library daemon startup preserves parent environment and resolves results", {
  before <- Sys.getenv(c("R_LIBS", "R_TESTS"), unset = NA_character_)
  pool <- mirai_test_pool(1L)
  on.exit(pool$close(), add = TRUE)
  expect_identical(Sys.getenv(c("R_LIBS", "R_TESTS"), unset = NA_character_), before)
  task <- pool$submit(function(n) {Sys.sleep(.1); sum(seq_len(n))}, args = list(n = 100L))
  expect_false(task$ready())
  expect_error(task$result(), "unresolved")
  task$wait(10)
  expect_identical(task$status(), "completed")
  expect_identical(task$result(), 5050L)
  expect_true(is.numeric(task$info()$started_at))
  expect_lte(task$info()$submitted_at, task$info()$finished_at)
  expect_false(task$cancel())
  events <- pool$events$history()
  expect_identical(vapply(events, `[[`, "", "event"), c("task_submitted", "task_started", "task_completed"))
  expect_equal(vapply(events, `[[`, 0, "sequence"), seq_along(events))
  expect_length(pool$tasks(), 0L)
  pool$close(); expect_silent(pool$close())
  expect_error(pool$submit(function() 1), "closed")
  expect_true(pool$events$is_closed())
  expect_identical(task$result(), 5050L)
})

test_that("native results preserve R types without publishing them to JSON telemetry", {
  pool <- mirai_test_pool(2L, history = 32L, max_input_bytes = 16 * 1024^2)
  on.exit(pool$close(), add = TRUE)
  object <- list(numbers = c(NA_real_, NaN, Inf, -Inf),
    frame = data.frame(x = 1:3, f = factor(c("a", "b", NA))),
    time = as.POSIXct("2026-01-01", tz = "UTC"), large = raw(2 * 1024^2))
  task <- pool$submit(identity, args = list(x = object))
  task$wait(10)
  expect_identical(task$result(), object)
  expect_lt(as.numeric(object.size(pool$events$history())), 16384)
  expect_false("result" %in% names(tail(pool$events$history(), 1L)[[1L]]))
  multiplier <- 3L
  helper <- function(x) x * multiplier
  captured <- pool$submit(function(x) helper(x) + 1L, args = list(x = 4L))
  captured$wait(10); expect_identical(captured$result(), 13L)
  argument <- pool$submit(function(fn) fn(5L), args = list(fn = helper))
  argument$wait(10); expect_identical(argument$result(), 15L)
})

test_that("reference inputs and excessive admission fail before adding a task", {
  pool <- mirai_test_pool(1L, max_pending = 2L, max_input_bytes = 4096L)
  on.exit(pool$close(), add = TRUE)
  expect_error(pool$submit(identity, args = list(x = new.env())), "environments")
  env <- new.env(); fn <- function() env$x
  expect_error(pool$submit(fn), "environments")
  expect_error(pool$submit(identity, args = list(x = raw(8192))), "max_input_bytes")
  expect_error(pool$submit(identity, args = list(1)), "named list")
  expect_error(pool$submit(function() 1, progress = TRUE), "injected")
  one <- pool$submit(function() Sys.sleep(5))
  two <- pool$submit(function() 2)
  expect_error(pool$submit(function() 3), "pending task limit")
  expect_equal(pool$diagnostics()$pending, 2)
  expect_true(two$cancel()); expect_false(two$cancel())
  expect_null(two$info()$started_at)
  expect_identical(two$status(), "cancelled")
  expect_error(two$result(), "Cancellation")
  one$cancel()
  expect_equal(pool$diagnostics()$pending, 0)
})

test_that("progress is real, bounded, ordered and separated from final result", {
  pool <- mirai_test_pool(1L, history = 16L, progress_interval = .01)
  on.exit(pool$close(), add = TRUE)
  task <- pool$submit(function(progress) {
    for (i in 1:12) {Sys.sleep(.02); progress(i / 12, paste("step", i))}
    list(answer = 42L)
  }, progress = TRUE)
  mirai_wait_for(function() any(vapply(pool$events$history(), function(x) x$event == "task_progress", logical(1))), pool)
  expect_identical(task$status(), "running")
  expect_false(task$ready())
  progress_event <- tail(Filter(function(x) x$event == "task_progress", pool$events$history()), 1L)[[1L]]
  expect_type(progress_event$reported_at, "double")
  expect_lte(progress_event$reported_at, progress_event$timestamp)
  task$wait(10)
  expect_identical(task$result(), list(answer = 42L))
  events <- pool$events$history()
  fractions <- vapply(Filter(function(x) x$event == "task_progress", events), `[[`, 0, "progress")
  expect_true(all(diff(fractions) >= 0))
  expect_lte(length(events), 16L)
  expect_identical(tail(events, 1L)[[1L]]$event, "task_completed")
  expect_true(all(vapply(events, function(x) x$task_id == task$info()$task_id, logical(1))))
})

test_that("timeouts include queue time and terminal events are emitted once", {
  pool <- mirai_test_pool(1L)
  on.exit(pool$close(), add = TRUE)
  busy <- pool$submit(function() Sys.sleep(5))
  timeout <- pool$submit(function() 42, timeout = .05)
  timeout$wait(5)
  expect_identical(timeout$status(), "timed_out")
  expect_null(timeout$info()$started_at)
  expect_false(timeout$cancel())
  busy$cancel()
  expect_identical(busy$status(), "cancelled")
  for (i in 1:4) pool$poll()
  events <- pool$events$history()
  expect_equal(sum(vapply(events, function(x) x$event == "task_timed_out", logical(1))), 1)
  expect_equal(sum(vapply(events, function(x) x$event == "task_cancelled", logical(1))), 1)
  recovered <- pool$submit(function() 7L)
  recovered$wait(10); expect_identical(recovered$result(), 7L)
  failed <- pool$submit(function() stop("intentional task error"))
  failed$wait(10); expect_identical(failed$status(), "failed")
  expect_error(failed$result(), "intentional task error")
})

test_that("independent pools survive another pool shutdown and promise completion", {
  first <- mirai_test_pool(1L)
  on.exit(first$close(), add = TRUE)
  second <- mirai_test_pool(1L)
  on.exit(second$close(), add = TRUE)
  first$submit(function() Sys.sleep(5))
  task <- second$submit(function() {Sys.sleep(.05); 21L})
  first$close()
  task$wait(10); expect_identical(task$result(), 21L)
  skip_if_not_installed("promises")
  skip_if_not_installed("later")
  value <- NULL
  promise_task <- second$submit(function() 42L)
  promises::then(promise_task$promise(), function(x) value <<- x)
  mirai_wait_for(function() {later::run_now(0); identical(value, 42L)}, second)
  expect_identical(value, 42L)
  expect_length(second$tasks(), 0L)
})

test_that("progress cannot roll back after an unknown percentage", {
  pool <- mirai_test_pool(1L)
  on.exit(pool$close(), add = TRUE)
  task <- pool$submit(function() Sys.sleep(5))
  info <- task$info(); pool_id <- pool$diagnostics()$pool_id
  # Internal protocol injection tests validation independently of throttling.
  receive <- environment(pool$poll)$receive
  record <- list(version = 1L, pool_id = pool_id, task_id = info$task_id,
    kind = "progress", sequence = 100L, started_at = as.numeric(Sys.time()),
    value = .8, message = "known")
  receive(record)
  record$sequence <- 101L; record$value <- NULL; receive(record)
  before <- pool$diagnostics()$invalid_progress
  record$sequence <- 102L; record$value <- .2; receive(record)
  expect_equal(pool$diagnostics()$invalid_progress, before + 1L)
  task$cancel()
})

test_that("task function attributes cannot smuggle parent reference objects", {
  pool <- mirai_test_pool(1L)
  on.exit(pool$close(), add = TRUE)
  fn <- function() 42L
  attr(fn, "reference") <- new.env()
  expect_error(pool$submit(fn), "environments")
  expect_equal(pool$diagnostics()$pending, 0)
})

test_that("repeated final progress remains throttled", {
  pool <- mirai_test_pool(1L, progress_interval = .05)
  on.exit(pool$close(), add = TRUE)
  task <- pool$submit(function(progress) {
    for (i in 1:1000) progress(1)
    TRUE
  }, progress = TRUE)
  task$wait(10)
  expect_true(task$result())
  stats <- task$info()$progress_stats
  expect_true(is.list(stats))
  expect_gt(stats$throttled, 900)
  expect_lt(stats$attempted, 100)
})

test_that("a task without progress reports has a confirmed running state", {
  pool <- mirai_test_pool(1L)
  on.exit(pool$close(), add = TRUE)
  task <- pool$submit(function() {Sys.sleep(.5); TRUE})
  mirai_wait_for(function() task$status() == "running" || task$ready(), pool)
  expect_identical(task$status(), "running")
  expect_false(task$ready())
  task$cancel()
})

test_that("daemon exit fails its task and explicit restart recovers the owned pool", {
  pool <- mirai_test_pool(1L)
  on.exit(pool$close(), add = TRUE)
  task <- pool$submit(function() quit(save = "no", status = 17L))
  task$wait(10)
  expect_identical(task$status(), "failed")
  expect_error(task$result())
  pool$restart()
  recovered <- pool$submit(function() 99L)
  recovered$wait(10)
  expect_identical(recovered$result(), 99L)
})

test_that("callback errors and reentrant mutation cannot duplicate terminal transitions", {
  pool <- mirai_test_pool(1L)
  on.exit(pool$close(), add = TRUE)
  seen <- character()
  bad <- pool$events$subscribe(function(event) {
    if (event$event == "task_completed") pool$close()
  })
  good <- pool$events$subscribe(function(event) seen <<- c(seen, event$event))
  task <- pool$submit(function() 1L)
  expect_warning(task$wait(10), "Defer pool mutation")
  expect_identical(task$result(), 1L)
  expect_false(pool$is_closed())
  expect_equal(sum(seen == "task_completed"), 1)
  good$unsubscribe(); good$unsubscribe(); bad$unsubscribe()
  expect_equal(pool$events$subscriber_count(), 0)
})

test_that("a slow progress consumer cannot hold up its computation", {
  pool <- mirai_test_pool(1L, history = 16L, progress_interval = .01)
  on.exit(pool$close(), add = TRUE)
  task <- pool$submit(function(progress) {
    for (i in 1:400) {Sys.sleep(.002); progress(i / 400)}
    42L
  }, progress = TRUE, timeout = 20)
  native <- environment(task$wait)$task$native
  deadline <- proc.time()[["elapsed"]] + 25
  # Deliberately do not poll/drain the parent's native progress socket.
  while (mirai::unresolved(native)) {
    if (proc.time()[["elapsed"]] > deadline) stop("Slow consumer stalled worker")
    Sys.sleep(.01)
  }
  expect_identical(task$result(), 42L)
  expect_equal(task$info()$progress, 1)
  expect_lte(length(pool$events$history()), 16L)
  expect_equal(pool$diagnostics()$pending, 0)
})

test_that("the read-only task stream can publish through the existing nano adapter", {
  pool <- mirai_test_pool(1L)
  on.exit(pool$close(), add = TRUE)
  publisher <- termr_nano_publish(pool$events, "tcp://127.0.0.1:0")
  on.exit(publisher$close(), add = TRUE)
  remote <- termr_nano_connect(publisher$endpoint, "tasks", publisher$snapshot_endpoint)
  on.exit(remote$close(), add = TRUE)
  task <- pool$submit(function() 42L)
  mirai_wait_for(function() {
    publisher$poll(); remote$poll()
    identical(remote$latest()$event, "task_completed")
  }, pool)
  expect_equal(remote$latest()$task_id, task$info()$task_id)
  expect_false("result" %in% names(remote$latest()))
  expect_null(pool$events$emit)
})

test_that("closing an owned pool leaves a foreign compute profile untouched", {
  skip_if_not_installed("mirai", "2.7.3")
  withr::local_envvar(R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep), R_TESTS = "")
  foreign <- paste0("foreign-test-", Sys.getpid(), "-", basename(tempfile()))
  mirai::daemons(1L, .compute = foreign)
  on.exit(mirai::daemons(0L, .compute = foreign), add = TRUE)
  task <- mirai::mirai({Sys.sleep(.2); 42L}, .compute = foreign)
  mine <- mirai_test_pool(1L)
  mine$close()
  deadline <- proc.time()[["elapsed"]] + 10
  while (mirai::unresolved(task) && proc.time()[["elapsed"]] < deadline) Sys.sleep(.005)
  expect_false(mirai::unresolved(task))
  expect_identical(task$data, 42L)
  expect_equal(mirai::status(.compute = foreign)$connections, 1L)
})
