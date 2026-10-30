test_that("a Shiny session receives an independent publisher and releases its lease", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("nanonext", "1.10.0")
  skip_if_not_installed("jsonlite")
  if (!any(vapply(file.path(.libPaths(), "termr", "NAMESPACE"), function(path) {
    file.exists(path) && any(grepl("export(termr_shiny_receiver)", readLines(path), fixed = TRUE))
  }, logical(1)))) skip("Install the current checkout for the independent-process test.")
  directory <- withr::local_tempdir()
  config <- list(libraries = .libPaths(), endpoint = "tcp://127.0.0.1:0",
    snapshot_endpoint = "tcp://127.0.0.1:0", rate = 10, duration = 1.5, timeout = 20,
    ready = file.path(directory, "ready.json"), report = file.path(directory, "report.json"),
    go = file.path(directory, "GO"), stop = file.path(directory, "STOP"))
  path <- file.path(directory, "config.json")
  jsonlite::write_json(config, path, auto_unbox = TRUE)
  child <- tryCatch(processx::process$new(file.path(R.home("bin"), "Rscript"),
    c("--vanilla", normalizePath(test_path("fixtures", "shiny_stream_child.R"), winslash = "/"), path),
    env = c("current", R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep), R_TESTS = ""),
    stdout = file.path(directory, "stdout"), stderr = file.path(directory, "stderr"), cleanup_tree = TRUE),
    error = function(e) {
      if (.Platform$OS.type == "windows" && !nzchar(Sys.getenv("CI")) &&
          grepl("Access is denied", conditionMessage(e), fixed = TRUE)) skip("Windows sandbox denies processx pipes.")
      stop(e)
    })
  on.exit(if (child$is_alive()) child$kill_tree(), add = TRUE)
  read_json <- function(file) {
    if (!file.exists(file)) return(NULL)
    tryCatch(jsonlite::read_json(file, simplifyVector = TRUE), error = function(e) NULL)
  }
  deadline <- proc.time()[["elapsed"]] + 20
  wait <- function(predicate, tick = function() NULL) {
    while (!isTRUE(predicate())) {
      tick()
      if (proc.time()[["elapsed"]] > deadline) stop("Independent Shiny process test timed out")
      Sys.sleep(.005)
    }
  }
  wait(function() !is.null(read_json(config$ready)))
  address <- read_json(config$ready)
  source <- termr_nano_connect(address$endpoint, "shiny.bench", address$snapshot_endpoint)
  receiver <- termr_shiny_receiver(source, max_points = 8L, close_source = TRUE)
  on.exit(receiver$close(), add = TRUE)
  shiny::testServer(function(input, output, session) {
    value <- termr_shiny_reactive(receiver, session)
    history <- termr_shiny_history(receiver, session, max_points = 8L)
    output$n <- shiny::renderText(if (is.null(value())) "waiting" else value()$n)
  }, {
    file.create(config$go)
    wait(function() !is.null(shiny::isolate(value())) && shiny::isolate(value())$n >= 8,
      function() {receiver$poll(); session$flushReact()})
    expect_gte(as.numeric(output$n), 8)
    expect_lte(length(shiny::isolate(history())), 8L)
    expect_identical(receiver$diagnostics()$sessions, 1L)
    expect_identical(source$subscriber_count(), 1L)
    expect_identical(receiver$status()$state, "live")
  })
  expect_identical(receiver$diagnostics()$sessions, 0L)
  file.create(config$stop); child$wait(10000)
  expect_identical(child$get_exit_status(), 0L,
    info = paste(readLines(file.path(directory, "stderr"), warn = FALSE), collapse = "\n"))
  receiver$close()
  expect_identical(source$status()$pending, 0L)
})
