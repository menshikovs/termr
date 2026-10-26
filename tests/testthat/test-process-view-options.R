test_that("process_view keeps its defaults and validates opt-in lifecycle options", {
  view <- process_view("Rscript", autostart = FALSE)
  expect_identical(view$stop_grace, NULL)
  expect_identical(view$supervision, "none")
  expect_identical(view$state, "pending")
  expect_null(view$exit_status)
  expect_error(process_view("Rscript", stop_grace = Inf), "finite, non-negative")
  expect_error(process_view("Rscript", stop_grace = -1), "finite, non-negative")
  expect_error(process_view("Rscript", supervision = "tree"), "must be.*none.*parent")

  async <- process_view("Rscript", autostart = FALSE, stop_grace = 1.5)
  expect_identical(async$stop_grace, 1.5)
  supervised <- process_view("Rscript", autostart = FALSE, supervision = "parent")
  expect_identical(supervised$supervision, "parent")
})

test_that("ProcessView status and output clearing remain public operations", {
  view <- process_view("Rscript", autostart = FALSE)
  expect_false(view$running)
  expect_identical(view$state, "pending")
  expect_null(view$exit_status)
  expect_identical(view$clear_output(), view)
  expect_length(view$output, 0L)
})
process_view_test_rscript <- function() {
  file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
}

process_view_test_capture <- function(expr) {
  tryCatch(force(expr), error = function(e) {
    if (!identical(tolower(Sys.getenv("CI")), "true") &&
        grepl("system error 5, Access is denied", conditionMessage(e), fixed = TRUE)) {
      skip("The local sandbox denies processx child pipes.")
    }
    e
  })
}

process_view_test_pilot <- function(app) {
  tryCatch(test_app(app, 60, 8), error = function(e) {
    if (!identical(tolower(Sys.getenv("CI")), "true") &&
        grepl("system error 5, Access is denied", conditionMessage(e), fixed = TRUE)) {
      skip("The local sandbox denies processx child pipes.")
    }
    stop(e)
  })
}

test_that("opt-in ProcessView cancellation is non-blocking and reports one finish", {
  skip_on_cran()
  finished <- list()
  expression <- "cat('READY\\n'); flush.console(); Sys.sleep(60)"
  view <- process_view(process_view_test_rscript(), c("--vanilla", "-e", expression), stop_grace = 0.2)
  application <- app(view, on("process.finished", function(event, app) {
    finished[[length(finished) + 1L]] <<- event$data
  }))
  pilot <- process_view_test_pilot(application)
  on.exit(pilot$stop(), add = TRUE)

  pilot$wait_for(function(app) "READY" %in% view$output, timeout = 10)
  expect_true("READY" %in% view$output)
  started <- proc.time()[["elapsed"]]
  view$cancel()
  expect_lt(proc.time()[["elapsed"]] - started, 1)
  expect_identical(view$state, "stopping")
  repeated <- proc.time()[["elapsed"]]
  view$cancel()
  expect_lt(proc.time()[["elapsed"]] - repeated, 1)
  expect_identical(view$state, "stopping")
  pilot$wait_for(function(app) identical(view$state, "cancelled"), timeout = 10)
  expect_identical(view$state, "cancelled")
  pilot$step()
  expect_length(finished, 1L)
  expect_identical(finished[[1]]$state, "cancelled")
  expect_identical(finished[[1]]$status, NA_integer_)
  expect_identical(view$exit_status, NA_integer_)
})

test_that("opt-in restart waits for the old worker before starting the next run", {
  skip_on_cran()
  marker <- tempfile("termr-process-view-restart-")
  marker_literal <- encodeString(marker, quote = "\"")
  expression <- paste0(
    "if (!file.exists(", marker_literal, ")) { writeLines('first', ", marker_literal,
    "); cat('READY\\n'); flush.console(); Sys.sleep(60) } else cat('SECOND\\n')"
  )
  finished <- list()
  view <- process_view(process_view_test_rscript(), c("--vanilla", "-e", expression), stop_grace = 0.2)
  application <- app(view, on("process.finished", function(event, app) {
    finished[[length(finished) + 1L]] <<- event$data
  }))
  pilot <- process_view_test_pilot(application)
  on.exit({
    if (view$running) view$worker$cancel(grace = 0)
    pilot$stop()
    unlink(marker)
  }, add = TRUE)

  pilot$wait_for(function(app) file.exists(marker), timeout = 10)
  expect_true(file.exists(marker))
  expect_true("READY" %in% view$output)
  view$restart()
  expect_identical(view$state, "stopping")
  pilot$wait_for(function(app) identical(view$state, "completed"), timeout = 15)
  expect_identical(view$state, "completed")
  pilot$step()
  expect_true(any(grepl("SECOND", view$output, fixed = TRUE)))
  expect_length(finished, 2L)
  expect_identical(vapply(finished, `[[`, character(1), "state"), c("cancelled", "completed"))
  expect_identical(finished[[2]]$status, 0L)
  expect_identical(view$exit_status, 0L)
})

test_that("ProcessView forwards optional parent supervision and bounds its output", {
  skip_on_cran()
  view <- process_view(
    process_view_test_rscript(),
    c("--vanilla", "-e", "writeLines(as.character(seq_len(10)))"),
    max_lines = 3L, supervision = "parent"
  )
  pilot <- process_view_test_pilot(app(view))
  on.exit(pilot$stop(), add = TRUE)
  pilot$wait_for(function(app) identical(view$state, "completed"), timeout = 15)
  expect_identical(view$state, "completed")
  expect_identical(view$output, c("8", "9", "10"))
  expect_identical(view$exit_status, 0L)
  view$clear_output()
  expect_length(view$output, 0L)
})

test_that("a missing executable returns an informative startup error", {
  skip_on_cran()
  missing <- file.path(tempdir(), paste0("termr-missing-executable-", Sys.getpid()))
  view <- process_view(missing, autostart = FALSE)
  pilot <- test_app(app(view), 40, 4)
  on.exit(pilot$stop(), add = TRUE)
  result <- process_view_test_capture(view$start())
  expect_s3_class(result, "error")
  expect_match(conditionMessage(result), "Could not start")
  expect_identical(view$state, "pending")
})
