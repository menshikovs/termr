test_that("task monitor responds to keys while independent daemons compute", {
  skip_if_not_installed("mirai", "2.7.3")
  skip_if_not_installed("jsonlite")
  env <- mirai_example("tui.R")
  demo <- env$task_monitor(workers = 2L, initial = 3L, chunks = 400L)
  on.exit(demo$close(), add = TRUE)
  pilot <- test_app(demo$app, 100, 16)
  on.exit(pilot$stop(), add = TRUE)
  pilot$press("i", "i", "i")
  expect_match(pilot$query_one("#inputs")$text, "3")
  expect_gt(demo$model$pool$diagnostics()$pending, 0)
  pilot$press("c")
  expect_gte(demo$model$pool$diagnostics()$counters$cancelled, 1)
  pilot$advance(.1)
  expect_true(any(grepl("cancelled", pilot$screen_text(), fixed = TRUE)))
  demo$close()
  expect_equal(demo$model$pool$diagnostics()$pending, 0)
})

test_that("ExtendedTask uses native promises and a session releases only its own tasks", {
  skip_if_not_installed("mirai", "2.7.3")
  skip_if_not_installed("shiny", "1.8.1")
  skip_if_not_installed("promises")
  env <- mirai_example("shiny.R")
  demo <- env$task_shiny("direct")
  on.exit(demo$close(), add = TRUE)
  shiny::testServer(demo$app$serverFuncSource(), {
    session$setInputs(chunks = 120, submit = 1)
    expect_identical(shiny::isolate(computation$status()), "running")
    expect_equal(demo$pool$diagnostics()$workers, 2)
    expect_gt(demo$pool$diagnostics()$pending, 0)
    clock <- output$clock
    deadline <- proc.time()[["elapsed"]] + 5
    while (identical(output$clock, clock) && proc.time()[["elapsed"]] < deadline) {
      session$elapse(100); later::run_now(0); Sys.sleep(.02)
    }
    expect_false(identical(output$clock, clock))
    session$setInputs(cancel = 1)
    expect_gte(demo$pool$diagnostics()$counters$cancelled, 1)
  })
  expect_false(demo$pool$is_closed())
  expect_equal(demo$receiver$diagnostics()$sessions, 0)
  expect_equal(demo$pool$diagnostics()$pending, 0)
  expect_no_warning(for (i in 1:10) later::run_now(.01))
})

test_that("an independent task producer reaches Shiny through existing stream adapters", {
  skip_if_not_installed("mirai", "2.7.3")
  skip_if_not_installed("shiny")
  skip_if_not_installed("jsonlite")
  current <- any(vapply(file.path(.libPaths(), "termr", "NAMESPACE"), function(path) {
    file.exists(path) && any(grepl("export(termr_mirai_pool)", readLines(path), fixed = TRUE))
  }, logical(1)))
  if (!current) skip("Install the current checkout for the independent peer.")
  directory <- withr::local_tempdir()
  producer <- test_path("..", "..", "inst", "examples", "mirai-tasks", "producer.R")
  if (!file.exists(producer)) producer <- system.file("examples", "mirai-tasks", "producer.R", package = "termr")
  config <- list(libraries = .libPaths(), producer = normalizePath(producer, winslash = "/"),
    ready = file.path(directory, "ready.json"), stop = file.path(directory, "STOP"))
  file <- file.path(directory, "config.json")
  jsonlite::write_json(config, file, auto_unbox = TRUE)
  child <- processx::process$new(file.path(R.home("bin"), "Rscript"),
    c("--vanilla", normalizePath(test_path("fixtures", "mirai_producer_child.R"), winslash = "/"), file),
    env = c("current", R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep), R_TESTS = ""),
    stdout = file.path(directory, "stdout"), stderr = file.path(directory, "stderr"), cleanup_tree = TRUE)
  on.exit(if (child$is_alive()) child$kill_tree(), add = TRUE)
  read_ready <- function() {
    if (!file.exists(config$ready)) return(NULL)
    tryCatch(jsonlite::read_json(config$ready, simplifyVector = TRUE), error = function(e) NULL)
  }
  deadline <- proc.time()[["elapsed"]] + 25
  while (is.null(address <- read_ready())) {
    if (!child$is_alive() || proc.time()[["elapsed"]] > deadline) stop("Producer startup failed")
    Sys.sleep(.01)
  }
  remote <- termr_nano_connect(address$endpoint, "task.state", address$snapshot_endpoint)
  receiver <- termr_shiny_receiver(remote, max_points = 20L, close_source = TRUE)
  on.exit(receiver$close(), add = TRUE)
  shiny::testServer(function(input, output, session) {
    value <- termr_shiny_reactive(receiver, session)
    output$completed <- shiny::renderText(if (is.null(value())) 0 else value()$counts$completed)
  }, {
    while (as.numeric(output$completed) < 1 && proc.time()[["elapsed"]] < deadline) {
      receiver$poll(); session$flushReact(); Sys.sleep(.02)
    }
    expect_gte(as.numeric(output$completed), 1)
    expect_lte(length(receiver$latest()$tasks), 12)
    expect_lte(length(receiver$history()), 20)
  })
  expect_equal(receiver$diagnostics()$sessions, 0)
  file.create(config$stop); child$wait(10000)
  expect_identical(child$get_exit_status(), 0L,
    info = paste(readLines(file.path(directory, "stderr"), warn = FALSE), collapse = "\n"))
})

test_that("a finite producer returns terminal task state at shutdown", {
  skip_if_not_installed("mirai", "2.7.3")
  env <- mirai_example("producer.R")
  final <- env$task_producer(seconds = .1, endpoint = "tcp://127.0.0.1:0", snapshot_endpoint = "tcp://127.0.0.1:0")
  expect_true(all(vapply(final$tasks, function(task) task$status == "cancelled", logical(1))))
  expect_equal(final$counts$cancelled, 4)
  expect_true(any(vapply(final$history, function(event) event$event == "task_cancelled", logical(1))))
})
