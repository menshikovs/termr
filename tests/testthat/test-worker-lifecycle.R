lifecycle_rscript <- function() {
  file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
}

lifecycle_start_process <- function(app, command = lifecycle_rscript(), args, ...) {
  worker <- tryCatch(app$run_process(command, args, ...), error = identity)
  if (inherits(worker, "error") &&
      grepl("Access is denied", conditionMessage(worker), fixed = TRUE) &&
      !identical(tolower(Sys.getenv("CI")), "true")) {
    skip("The sandbox blocks processx child-process pipes.")
  }
  if (inherits(worker, "error")) stop(worker)
  worker
}

lifecycle_start_worker <- function(app, fn, ...) {
  worker <- tryCatch(app$run_worker(fn, ...), error = identity)
  if (inherits(worker, "error") &&
      grepl("Access is denied", conditionMessage(worker), fixed = TRUE) &&
      !identical(tolower(Sys.getenv("CI")), "true")) {
    skip("The sandbox blocks processx child-process pipes.")
  }
  if (inherits(worker, "error")) stop(worker)
  worker
}

lifecycle_wait_for_output <- function(pilot, worker, line, timeout = 10) {
  pilot$wait_for(function(app) line %in% worker$stdout, timeout = timeout)
}

lifecycle_pid_running <- function(pid) {
  handle <- tryCatch(ps::ps_handle(as.integer(pid)), error = function(e) NULL)
  !is.null(handle) && isTRUE(tryCatch(ps::ps_is_running(handle), error = function(e) FALSE))
}

lifecycle_kill_pid <- function(pid) {
  handle <- tryCatch(ps::ps_handle(as.integer(pid)), error = function(e) NULL)
  if (!is.null(handle)) try(ps::ps_kill(handle), silent = TRUE)
  invisible(NULL)
}

test_that("non-blocking cancellation options are additive and validated", {
  processx_methods <- processx::process$public_methods
  expect_identical(
    processx_supports_supervision(),
    is.list(processx_methods) && is.function(processx_methods$initialize) &&
      "supervise" %in% names(formals(processx_methods$initialize))
  )
  application <- app(label("x"))
  pilot <- test_app(application, 10, 1)
  on.exit(pilot$stop(), add = TRUE)

  worker <- application$run_worker(function() 42L, inline = TRUE)
  expect_identical(worker$state, "completed")
  expect_false(worker$request_cancel())
  expect_false(worker$cancel_requested)
  expect_error(worker$request_cancel(grace = -1), "finite, non-negative")
  expect_error(application$run_worker(function() 1L, inline = TRUE, supervision = "parent"),
               "requires a separate worker process")
  expect_error(application$run_process("unused", supervision = "tree"),
               "must be `\"none\"` or `\"parent\"`")
  expect_error(application$exit(worker_grace = Inf), "finite, non-negative")

  standalone <- Worker$new("unstarted")
  expect_false(standalone$request_cancel())
  expect_true(standalone$cancel())
  expect_false(standalone$cancel())
})

test_that("asynchronous cancellation is idempotent and emits one terminal event", {
  skip_on_cran()
  events <- character()
  callbacks <- c(complete = 0L, error = 0L, exit = 0L)
  application <- app(
    label("x"),
    on("*", function(event, app) {
      if (startsWith(event$type, "worker.")) events <<- c(events, event$type)
    })
  )
  pilot <- test_app(application, 20, 2)
  worker <- lifecycle_start_process(
    application,
    args = c("--vanilla", "-e", "Sys.sleep(60)"),
    on_complete = function(result, app) callbacks[["complete"]] <<- callbacks[["complete"]] + 1L,
    on_error = function(message, app) callbacks[["error"]] <<- callbacks[["error"]] + 1L,
    on_exit = function(status, app) callbacks[["exit"]] <<- callbacks[["exit"]] + 1L
  )
  on.exit({
    if (worker$is_running()) worker$cancel(grace = 0)
    pilot$stop()
  }, add = TRUE)

  started <- now_seconds()
  expect_true(worker$request_cancel(grace = 5))
  expect_lt(now_seconds() - started, 1)
  expect_true(worker$cancel_requested)
  expect_identical(worker$state, "running")
  expect_false(worker$request_cancel(grace = 5))
  expect_true(worker$request_cancel(grace = 0))
  pilot$wait_for(function(app) !worker$is_running(), timeout = 8)

  expect_identical(worker$state, "cancelled")
  expect_identical(sum(events == "worker.cancelled"), 1L)
  expect_identical(callbacks, c(complete = 0L, error = 0L, exit = 0L))
})

test_that("synchronous cancellation retains its result, event and callback behavior", {
  skip_on_cran()
  events <- character()
  callbacks <- c(complete = 0L, error = 0L, exit = 0L)
  application <- app(
    label("x"),
    on("*", function(event, app) {
      if (startsWith(event$type, "worker.")) events <<- c(events, event$type)
    })
  )
  pilot <- test_app(application, 20, 2)
  worker <- lifecycle_start_process(
    application, args = c("--vanilla", "-e", "Sys.sleep(60)"),
    on_complete = function(result, app) callbacks[["complete"]] <<- callbacks[["complete"]] + 1L,
    on_error = function(message, app) callbacks[["error"]] <<- callbacks[["error"]] + 1L,
    on_exit = function(status, app) callbacks[["exit"]] <<- callbacks[["exit"]] + 1L
  )
  on.exit({
    if (worker$is_running()) worker$cancel(grace = 0)
    pilot$stop()
  }, add = TRUE)

  expect_true(worker$cancel(grace = 0))
  expect_false(worker$cancel(grace = 0))
  pilot$step()
  expect_identical(worker$state, "cancelled")
  expect_true(worker$cancel_requested)
  expect_identical(events, c("worker.started", "worker.cancelled"))
  expect_identical(callbacks, c(complete = 0L, error = 0L, exit = 0L))
})

test_that("cancelling one worker leaves other app workers unaffected", {
  skip_on_cran()
  application <- app(label("x"))
  pilot <- test_app(application, 20, 2)
  first <- lifecycle_start_process(application, args = c("--vanilla", "-e", "Sys.sleep(60)"))
  second <- lifecycle_start_worker(application, function() 42L)
  on.exit({
    if (first$is_running()) first$cancel(grace = 0)
    if (second$is_running()) second$cancel(grace = 0)
    pilot$stop()
  }, add = TRUE)

  expect_length(application$workers(), 2L)
  expect_true(first$request_cancel(grace = 0))
  pilot$wait_for(function(app) !first$is_running() && !second$is_running(), timeout = 10)
  expect_identical(first$state, "cancelled")
  expect_identical(second$state, "completed")
  expect_identical(second$result, 42L)
  expect_length(application$workers(), 0L)
})

test_that("graceful cancellation allows child cleanup while the event loop stays responsive", {
  skip_on_cran()
  skip_on_os("windows")
  marker <- tempfile("termr-graceful-marker-")
  script <- tempfile("termr-graceful-child-", fileext = ".R")
  writeLines(c(
    "tryCatch({",
    '  cat("READY\\n"); flush(stdout())',
    "  Sys.sleep(60)",
    "}, interrupt = function(e) {",
    sprintf("  writeLines('cleaned', %s)", deparse(marker)),
    "  quit(save = 'no', status = 0L, runLast = FALSE)",
    "})"
  ), script)
  on.exit(unlink(c(marker, script), force = TRUE), add = TRUE)

  ticks <- 0L
  application <- app(label("x"))
  pilot <- test_app(application, 20, 2)
  worker <- lifecycle_start_process(
    application, args = c("--vanilla", script),
    on_exit = function(status, app) ticks <<- ticks + 1000L
  )
  on.exit({
    if (worker$is_running()) worker$cancel(grace = 0)
    pilot$stop()
  }, add = TRUE)
  application$set_interval(0.02, function(app) ticks <<- ticks + 1L)
  lifecycle_wait_for_output(pilot, worker, "READY")

  started <- now_seconds()
  expect_true(worker$request_cancel(grace = 2))
  expect_lt(now_seconds() - started, 1)
  pilot$wait_for(function(app) !worker$is_running(), timeout = 8)
  expect_identical(worker$state, "cancelled")
  expect_true(file.exists(marker))
  expect_null(worker$.__enclos_env__$private$cancel_escalated_at)
  expect_match(worker$.__enclos_env__$private$last_diagnostics,
               "exit_status=0;.*cancel_escalated=FALSE")
  expect_gt(ticks, 0L)
  expect_lt(ticks, 1000L)
})

test_that("a child that remains alive after an interrupt is killed at the grace deadline", {
  skip_on_cran()
  marker <- tempfile("termr-interrupt-handled-")
  script <- tempfile("termr-unresponsive-child-", fileext = ".R")
  writeLines(c(
    sprintf("interrupt_marker <- %s", deparse(marker)),
    "tryCatch({",
    '  cat("READY\\n"); flush(stdout())',
    "  Sys.sleep(60)",
    "}, interrupt = function(e) {",
    '  writeLines("handled", interrupt_marker)',
    "  repeat Sys.sleep(60)",
    "})"
  ), script)
  on.exit(unlink(c(marker, script), force = TRUE), add = TRUE)

  application <- app(label("x"))
  pilot <- test_app(application, 20, 2)
  worker <- lifecycle_start_process(application, args = c("--vanilla", script))
  on.exit({
    if (worker$is_running()) worker$cancel(grace = 0)
    pilot$stop()
  }, add = TRUE)
  lifecycle_wait_for_output(pilot, worker, "READY")

  expect_true(worker$request_cancel(grace = 0.15))
  deadline <- worker$.__enclos_env__$private$cancel_deadline
  pilot$wait_for(function(app) !worker$is_running(), timeout = 8)
  private <- worker$.__enclos_env__$private
  expect_identical(worker$state, "cancelled")
  # processx sends POSIX SIGINT on Unix. On Windows it uses CTRL+BREAK, which
  # does not provide the same handler acknowledgement contract; the assertions
  # below still require the process to survive until, and be killed after, the
  # requested grace deadline.
  if (.Platform$OS.type != "windows") {
    expect_true(file.exists(marker), info = private$last_diagnostics)
  }
  expect_true(is.numeric(private$cancel_escalated_at), info = private$last_diagnostics)
  expect_true(private$cancel_escalated_at >= deadline, info = private$last_diagnostics)
  expect_match(private$last_diagnostics, "cancel_escalated=TRUE")
})

test_that("a natural child exit during a cancellation request is not escalated", {
  skip_on_cran()
  release <- tempfile("termr-cancel-natural-release-")
  received <- tempfile("termr-cancel-natural-received-")
  script <- tempfile("termr-cancel-natural-child-", fileext = ".R")
  writeLines(c(
    sprintf("release <- %s", deparse(release)),
    sprintf("received <- %s", deparse(received)),
    "tryCatch({",
    '  cat("READY\\n"); flush(stdout())',
    "  Sys.sleep(60)",
    "}, interrupt = function(e) {",
    '  writeLines("handled", received)',
    "  repeat {",
    "    Sys.sleep(0.02)",
    '    if (file.exists(release)) quit(save = "no", status = 0L, runLast = FALSE)',
    "  }",
    "})"
  ), script)
  on.exit(unlink(c(release, received, script), force = TRUE), add = TRUE)

  application <- app(label("x"))
  pilot <- test_app(application, 20, 2)
  worker <- lifecycle_start_process(application, args = c("--vanilla", script))
  on.exit({
    if (worker$is_running()) worker$cancel(grace = 0)
    pilot$stop()
  }, add = TRUE)
  lifecycle_wait_for_output(pilot, worker, "READY")

  expect_true(worker$request_cancel(grace = 5))
  expect_true(worker$cancel_requested)
  pilot$wait_for(function(app) file.exists(received), timeout = 5)
  writeLines("exit naturally", release)
  pilot$wait_for(function(app) !worker$is_running(), timeout = 8)
  private <- worker$.__enclos_env__$private
  expect_identical(worker$state, "cancelled")
  expect_null(private$cancel_escalated_at)
  expect_match(private$last_diagnostics, "exit_status=0;.*cancel_escalated=FALSE")
})

test_that("asynchronous cancellation removes worker temporary files", {
  skip_on_cran()
  worker_temp_files <- function() {
    list.files(tempdir(), pattern = "^termr-(job|result|progress|worker-tmp|trace)-")
  }
  before <- worker_temp_files()
  application <- app(label("x"))
  pilot <- test_app(application, 20, 2)
  worker <- lifecycle_start_worker(application, function() Sys.sleep(60))
  on.exit({
    if (worker$is_running()) worker$cancel(grace = 0)
    pilot$stop()
  }, add = TRUE)

  expect_true(worker$request_cancel(grace = 0))
  pilot$wait_for(function(app) !worker$is_running(), timeout = 8)
  expect_identical(worker$state, "cancelled")
  expect_identical(setdiff(worker_temp_files(), before), character())
})

test_that("requesting cancellation after natural completion preserves the result", {
  skip_on_cran()
  application <- app(label("x"))
  events <- character()
  application$on("*", function(event, app) {
    if (startsWith(event$type, "worker.")) events <<- c(events, event$type)
  })
  pilot <- test_app(application, 20, 2)
  on.exit(pilot$stop(), add = TRUE)

  callback_order <- character()
  completed <- lifecycle_start_process(
    application, args = c("--vanilla", "-e", "quit(status=0L)"),
    on_complete = function(result, app) callback_order <<- c(callback_order, "complete"),
    on_exit = function(status, app) callback_order <<- c(callback_order, "exit")
  )
  completed$.__enclos_env__$private$process$wait(5000)
  expect_false(completed$request_cancel(grace = 1))
  pilot$wait_for_workers(8)
  expect_identical(completed$state, "completed")
  expect_identical(callback_order, c("complete", "exit"))
  expect_identical(events, c("worker.started", "worker.completed"))
  expect_identical(completed$result, 0L)

  events <- character()
  callback_order <- character()
  failed <- lifecycle_start_process(
    application, args = c("--vanilla", "-e", "quit(status=3L)"),
    on_error = function(message, app) callback_order <<- c(callback_order, "error"),
    on_exit = function(status, app) callback_order <<- c(callback_order, "exit")
  )
  failed$.__enclos_env__$private$process$wait(5000)
  expect_false(failed$request_cancel(grace = 1))
  pilot$wait_for_workers(8)
  expect_identical(failed$state, "failed")
  expect_identical(callback_order, c("error", "exit"))
  expect_identical(events, c("worker.started", "worker.failed"))
  expect_match(failed$error, "status 3")
})

test_that("a cancellation race produces one terminal outcome and invokes matching callbacks once", {
  skip_on_cran()
  events <- character()
  callbacks <- c(complete = 0L, error = 0L, exit = 0L)
  application <- app(
    label("x"),
    on("*", function(event, app) {
      if (startsWith(event$type, "worker.")) events <<- c(events, event$type)
    })
  )
  pilot <- test_app(application, 20, 2)
  on.exit(pilot$stop(), add = TRUE)

  outcomes <- character()
  for (i in seq_len(3L)) {
    events <- character()
    callbacks[] <- 0L
    worker <- lifecycle_start_process(
      application,
      args = c("--vanilla", "-e", "Sys.sleep(0.15); quit(status=0L)"),
      on_complete = function(result, app) callbacks[["complete"]] <<- callbacks[["complete"]] + 1L,
      on_error = function(message, app) callbacks[["error"]] <<- callbacks[["error"]] + 1L,
      on_exit = function(status, app) callbacks[["exit"]] <<- callbacks[["exit"]] + 1L
    )
    request_accepted <- worker$request_cancel(grace = 0.1)
    pilot$wait_for(function(app) !worker$is_running(), timeout = 8)
    outcomes <- c(outcomes, worker$state)
    if (request_accepted) {
      expect_identical(worker$state, "cancelled")
      expect_identical(callbacks, c(complete = 0L, error = 0L, exit = 0L))
      expect_identical(sum(events == "worker.cancelled"), 1L)
    } else {
      expect_identical(worker$state, "completed")
      expect_identical(callbacks, c(complete = 1L, error = 0L, exit = 1L))
      expect_identical(sum(events == "worker.completed"), 1L)
    }
    expect_identical(sum(events %in% c("worker.completed", "worker.failed", "worker.cancelled")), 1L)
  }
  expect_true(all(outcomes %in% c("completed", "cancelled")))
})

test_that("force cancellation removes both a direct child and its descendant", {
  skip_on_cran()
  direct_pid_file <- tempfile("termr-cancel-direct-pid-")
  descendant_pid_file <- tempfile("termr-cancel-descendant-pid-")
  script <- tempfile("termr-cancel-tree-child-", fileext = ".R")
  descendant_code <- paste0(
    "writeLines(as.character(Sys.getpid()), ",
    paste(deparse(descendant_pid_file), collapse = ""),
    "); Sys.sleep(60)"
  )
  writeLines(c(
    sprintf(
      "descendant <- processx::process$new(%s, c('--vanilla', '-e', %s), stdin = NULL, stdout = '', stderr = '', cleanup = FALSE, cleanup_tree = FALSE, env = c('current', R_TESTS = ''))",
      paste(deparse(lifecycle_rscript()), collapse = ""),
      paste(deparse(descendant_code), collapse = "")
    ),
    sprintf("writeLines(as.character(Sys.getpid()), %s)",
            paste(deparse(direct_pid_file), collapse = "")),
    'cat("READY\\n"); flush(stdout())',
    "Sys.sleep(60)"
  ), script)
  on.exit(unlink(c(direct_pid_file, descendant_pid_file, script), force = TRUE), add = TRUE)

  application <- app(label("x"))
  pilot <- test_app(application, 20, 2)
  on.exit(pilot$stop(), add = TRUE)
  worker <- lifecycle_start_process(application, args = c("--vanilla", script))
  on.exit({
    if (worker$is_running()) worker$cancel(grace = 0)
    pids <- c(direct_pid_file, descendant_pid_file)
    for (path in pids[file.exists(pids)]) lifecycle_kill_pid(readLines(path, warn = FALSE)[[1]])
  }, add = TRUE)

  lifecycle_wait_for_output(pilot, worker, "READY")
  pilot$wait_for(function(app) file.exists(direct_pid_file) && file.exists(descendant_pid_file),
                 timeout = 10)
  direct_pid <- readLines(direct_pid_file, warn = FALSE)[[1]]
  descendant_pid <- readLines(descendant_pid_file, warn = FALSE)[[1]]
  expect_true(lifecycle_pid_running(direct_pid))
  expect_true(lifecycle_pid_running(descendant_pid))

  expect_true(worker$request_cancel(grace = 0))
  pilot$wait_for(function(app) !worker$is_running(), timeout = 10)
  expect_identical(worker$state, "cancelled")
  expect_false(lifecycle_pid_running(direct_pid))
  expect_false(lifecycle_pid_running(descendant_pid))
})

test_that("opt-in app exit drains workers and restores the driver", {
  skip_on_cran()
  attempted_new_work <- FALSE
  worker <- NULL
  application <- app(
    label("x"),
    bind("q", function(app) app$exit("done", worker_grace = 0.2)),
    on("worker.cancelled", function(event, app) {
      attempted_new_work <<- TRUE
      expect_error(app$run_worker(function() 1L), "graceful worker shutdown")
    })
  )
  worker <- lifecycle_start_process(application, args = c("--vanilla", "-e", "Sys.sleep(60)"))
  driver <- HeadlessDriver$new(20, 2)
  driver$press("q")

  expect_identical(run(application, driver = driver), "done")
  expect_identical(worker$state, "cancelled")
  expect_true(attempted_new_work)
  expect_false(driver$started)
  expect_length(application$workers(), 0L)
})

test_that("parent supervision is opt-in and registers the direct child", {
  skip_on_cran()
  skip_if_not(isTRUE(processx_supports_supervision()),
              "The installed processx does not provide its documented supervisor option.")
  application <- app(label("x"))
  pilot <- test_app(application, 20, 2)
  on.exit(pilot$stop(), add = TRUE)

  ordinary <- lifecycle_start_process(application, args = c("--vanilla", "-e", "Sys.sleep(60)"))
  on.exit(if (ordinary$is_running()) ordinary$cancel(grace = 0), add = TRUE)
  expect_false(ordinary$.__enclos_env__$private$process$is_supervised())
  ordinary$cancel(grace = 0)

  supervised <- lifecycle_start_process(
    application, args = c("--vanilla", "-e", "Sys.sleep(60)"), supervision = "parent"
  )
  on.exit(if (supervised$is_running()) supervised$cancel(grace = 0), add = TRUE)
  expect_true(supervised$.__enclos_env__$private$process$is_supervised())
  supervised$cancel(grace = 0)
  expect_identical(supervised$state, "cancelled")
})

test_that("processx supervision cleans the direct child after parent signals", {
  skip_on_cran()
  skip_on_os("windows")
  skip_if_not_installed("pkgload")
  skip_if_not(isTRUE(processx_supports_supervision()),
              "The installed processx does not provide its documented supervisor option.")

  repo <- normalizePath(testthat::test_path("../.."), winslash = "/")
  pid_file <- tempfile("termr-supervised-pid-")
  parent_script <- tempfile("termr-supervised-parent-", fileext = ".R")
  on.exit(unlink(c(pid_file, parent_script), force = TRUE), add = TRUE)
  repo_expr <- paste(deparse(repo), collapse = "")
  pid_expr <- paste(deparse(pid_file), collapse = "")
  child_expr <- paste(deparse(lifecycle_rscript()), collapse = "")
  writeLines(c(
    sprintf("pkgload::load_all(%s, quiet = TRUE)", repo_expr),
    "application <- termr::app(termr::label('supervised'))",
    sprintf("worker <- application$run_process(%s, c('--vanilla', '-e', 'Sys.sleep(60)'), supervision = 'parent')", child_expr),
    sprintf("writeLines(as.character(worker$pid()), %s)", pid_expr),
    "flush.console()",
    "Sys.sleep(60)"
  ), parent_script)

  signals <- c(SIGINT = 2L, SIGTERM = 15L, SIGHUP = 1L, SIGKILL = 9L)
  for (signal_name in names(signals)) {
    script <- tempfile("termr-supervised-parent-", fileext = ".R")
    file.copy(parent_script, script, overwrite = TRUE)
    parent <- tryCatch(processx::process$new(
      lifecycle_rscript(), c("--vanilla", script), stdout = "|", stderr = "|",
      cleanup = TRUE, cleanup_tree = TRUE
    ), error = identity)
    if (inherits(parent, "error") &&
        grepl("Access is denied", conditionMessage(parent), fixed = TRUE) &&
        !identical(tolower(Sys.getenv("CI")), "true")) {
      skip("The sandbox blocks processx child-process pipes.")
    }
    if (inherits(parent, "error")) stop(parent)
    on.exit(try(parent$kill_tree(), silent = TRUE), add = TRUE)

    deadline <- now_seconds() + 20
    while (!file.exists(pid_file) && parent$is_alive() && now_seconds() < deadline) {
      parent$poll_io(50)
    }
    expect_true(file.exists(pid_file), info = paste(parent$read_all_error_lines(), collapse = "\n"))
    child_pid <- as.integer(readLines(pid_file, warn = FALSE)[[1]])
    child_handle <- ps::ps_handle(child_pid)
    expect_true(ps::ps_is_running(child_handle))

    parent$signal(signals[[signal_name]])
    parent_deadline <- now_seconds() + 10
    while (parent$is_alive() && now_seconds() < parent_deadline) Sys.sleep(0.05)
    expect_false(parent$is_alive(), info = paste("parent survived", signal_name))

    child_deadline <- now_seconds() + 10
    while (isTRUE(tryCatch(ps::ps_is_running(child_handle), error = function(e) FALSE)) &&
           now_seconds() < child_deadline) Sys.sleep(0.05)
    expect_false(tryCatch(ps::ps_is_running(child_handle), error = function(e) FALSE),
                 info = paste("supervised child survived", signal_name))
    unlink(pid_file, force = TRUE)
    unlink(script, force = TRUE)
  }
})

test_that("parent supervision cleans its direct child after abnormal parent termination", {
  skip_on_cran()
  skip_if_not_installed("pkgload")
  skip_if_not(isTRUE(processx_supports_supervision()),
              "The installed processx does not provide its documented supervisor option.")

  repo <- normalizePath(testthat::test_path("../.."), winslash = "/")
  pid_file <- tempfile("termr-supervised-child-pid-")
  parent_script <- tempfile("termr-supervised-parent-kill-", fileext = ".R")
  on.exit(unlink(c(pid_file, parent_script), force = TRUE), add = TRUE)
  writeLines(c(
    sprintf("pkgload::load_all(%s, quiet = TRUE)", paste(deparse(repo), collapse = "")),
    "application <- termr::app(termr::label('supervised'))",
    sprintf(
      "worker <- application$run_process(%s, c('--vanilla', '-e', 'Sys.sleep(60)'), supervision = 'parent')",
      paste(deparse(lifecycle_rscript()), collapse = "")
    ),
    sprintf("writeLines(as.character(worker$pid()), %s)",
            paste(deparse(pid_file), collapse = "")),
    "flush.console()",
    "Sys.sleep(60)"
  ), parent_script)

  parent <- tryCatch(processx::process$new(
    lifecycle_rscript(), c("--vanilla", parent_script), stdout = "|", stderr = "|",
    cleanup = FALSE, cleanup_tree = FALSE
  ), error = identity)
  if (inherits(parent, "error") &&
      grepl("Access is denied", conditionMessage(parent), fixed = TRUE) &&
      !identical(tolower(Sys.getenv("CI")), "true")) {
    skip("The sandbox blocks processx child-process pipes.")
  }
  if (inherits(parent, "error")) stop(parent)

  child_pid <- NULL
  on.exit({
    if (parent$is_alive()) try(parent$kill(grace = 0), silent = TRUE)
    if (!is.null(child_pid)) lifecycle_kill_pid(child_pid)
  }, add = TRUE)

  deadline <- now_seconds() + 20
  while (!file.exists(pid_file) && parent$is_alive() && now_seconds() < deadline) {
    parent$poll_io(50)
  }
  expect_true(file.exists(pid_file), info = paste(parent$read_all_error_lines(), collapse = "\n"))
  child_pid <- readLines(pid_file, warn = FALSE)[[1]]
  expect_true(lifecycle_pid_running(child_pid))

  parent$kill(grace = 0)
  parent_deadline <- now_seconds() + 10
  while (parent$is_alive() && now_seconds() < parent_deadline) Sys.sleep(0.05)
  expect_false(parent$is_alive())

  child_deadline <- now_seconds() + 20
  while (lifecycle_pid_running(child_pid) && now_seconds() < child_deadline) Sys.sleep(0.1)
  expect_false(lifecycle_pid_running(child_pid),
               info = "processx parent supervision should terminate its registered direct child")
})
