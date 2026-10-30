plot_demo <- function() {
  env <- new.env(parent = globalenv())
  path <- system.file("examples", "system-monitor-live", "visualization.R", package = "termr")
  if (!nzchar(path)) path <- test_path("..", "..", "inst", "examples", "system-monitor-live", "visualization.R")
  source(path, local = env)
  env
}

plot_frame <- function(sequence = 1:5, source = "one") {
  rows <- lapply(sequence, function(i) list(timestamp = as.numeric(Sys.time()) + i,
    source_id = source, sequence = i, cpu = as.numeric(i), ram = 50))
  termr_stream_data(rows)
}

test_that("Plotly plans distinguish append from history replacement and noops", {
  demo <- plot_demo()
  status <- list(state = "live", generation = 1L)
  first <- demo$monitor_plotly_plan(NULL, plot_frame(1:3), status)
  expect_identical(first$type, "replace")
  same <- demo$monitor_plotly_plan(first, plot_frame(1:3), status)
  expect_identical(same$type, "noop")
  next_plan <- demo$monitor_plotly_plan(first, plot_frame(1:5), status)
  expect_identical(next_plan$type, "extend")
  expect_identical(next_plan$data$sequence, c(4, 5))
  gap <- demo$monitor_plotly_plan(first, plot_frame(c(1, 2, 3, 5)), status)
  expect_identical(gap$type, "replace")
  expect_identical(gap$reason, "gap")
  source <- demo$monitor_plotly_plan(next_plan, plot_frame(1:2, "two"), list(state = "live", generation = 2L))
  expect_identical(source$reason, "source")
  invalid <- demo$monitor_plotly_plan(next_plan, plot_frame(1:5), list(state = "invalid", generation = 1L))
  expect_equal(nrow(invalid$data), 0)
  expect_identical(invalid$type, "replace")
  recovered <- demo$monitor_plotly_plan(invalid, plot_frame(1:5), status)
  expect_identical(recovered$type, "replace")
})

test_that("Plotly proxy arrays have two traces, bounded arrays and gap separators", {
  demo <- plot_demo()
  data <- plot_frame(c(1, 2, 4, 5))
  arrays <- demo$monitor_plotly_arrays(data, 4L)
  expect_length(arrays$x, 2L)
  expect_length(arrays$y, 2L)
  expect_length(arrays$x[[1]], 4L)
  expect_true(anyNA(unlist(arrays$y[[1]])))
  one <- demo$monitor_plotly_arrays(data[4, , drop = FALSE], 100L)
  expect_type(one$x[[1]], "list")
  expect_length(one$x[[1]], 1L)
  expect_match(one$x[[1]][[1]], "Z$")
  empty <- demo$monitor_plotly_arrays(data[0, ], 100L)
  expect_identical(empty$x, list(list(), list()))
})

test_that("installed Plotly supports the actual proxy method, indices and maxPoints", {
  skip_if_not_installed("plotly")
  skip_if_not_installed("shiny")
  demo <- plot_demo()
  messages <- list(); flushes <- list()
  session <- list(ns = function(id) if (is.null(id)) "" else id,
    sendCustomMessage = function(type, message) messages[[length(messages) + 1L]] <<- list(type = type, message = message),
    onFlushed = function(fun, once) {flushes[[length(flushes) + 1L]] <<- fun; invisible(function() NULL)})
  plan <- list(type = "extend", data = plot_frame(1))
  demo$monitor_plotly_send(session, "live", plan, 600L)
  expect_length(messages, 0L)
  expect_length(flushes, 1L)
  flushes[[1L]]()
  msg <- messages[[1L]]
  expect_identical(msg$type, "plotly-calls")
  expect_identical(msg$message$method, "extendTraces")
  expect_identical(msg$message$args[[2L]], list(0L, 1L))
  expect_identical(msg$message$args[[3L]], 600L)
  expect_length(msg$message$args[[1L]]$x, 2L)
  built <- plotly::plotly_build(demo$monitor_plotly_widget())
  expect_length(built$x$data, 2L)
  expect_identical(vapply(built$x$data, `[[`, "", "name"), c("CPU", "RAM"))
  expect_false("typedarray" %in% vapply(built$dependencies, `[[`, "", "name"))
})

test_that("ggplot2 consumes ordinary frames with explicit discontinuity groups", {
  skip_if_not_installed("ggplot2")
  demo <- plot_demo()
  data <- plot_frame(c(1, 2, 4, 5))
  charts <- demo$monitor_ggplots(data)
  expect_named(charts, c("cpu", "ram", "compare"))
  expect_s3_class(charts$cpu, "ggplot")
  expect_equal(length(unique(charts$cpu$data$segment)), 2)
  expect_s3_class(charts$compare$data, "data.frame")
})

test_that("dashboard observer retains its cursor and sends incremental updates", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("plotly")
  skip_if_not_installed("jsonlite")
  env <- new.env(parent = globalenv())
  path <- system.file("examples", "system-monitor-live", "dashboard.R", package = "termr")
  if (!nzchar(path)) path <- test_path("..", "..", "inst", "examples", "system-monitor-live", "dashboard.R")
  source(path, local = env)
  directory <- withr::local_tempdir()
  writer <- env$monitor_writer(directory, min_interval = 0)
  on.exit(writer$close(), add = TRUE)
  fixture <- function(sequence) list(schema_version = 1L, source_id = "dashboard-test", sequence = sequence,
    timestamp = as.numeric(Sys.time()), collected_at = as.numeric(Sys.time()),
    metrics = list(cpu = 20, ram = 50, processes = list(), unavailable = list()))
  writer$publish(fixture(1))
  demo <- env$monitor_dashboard(directory, mode = "plotly", max_points = 10L, transport = "file")
  on.exit(demo$close(), add = TRUE)
  shiny::testServer(demo$app$serverFuncSource(), {
    messages <- list()
    session$sendCustomMessage <- function(type, message) {
      if (type == "plotly-calls") messages[[length(messages) + 1L]] <<- message
    }
    session$setInputs(view = "plotly", window = 10, live_ready = 1)
    demo$receiver$poll(); session$flushReact()
    expect_identical(tail(messages, 1L)[[1L]]$method, "restyle")
    before <- length(messages)
    writer$publish(fixture(2))
    demo$receiver$poll(); session$flushReact()
    expect_length(messages, before) # browser still rendering: no queued command
    session$setInputs(live_ack = list(ready = 1, count = 1))
    expect_identical(tail(messages, 1L)[[1L]]$method, "extendTraces")
    session$setInputs(live_ack = list(ready = 1, count = 2))
    before <- length(messages)
    demo$receiver$poll(); session$flushReact()
    expect_length(messages, before)
    writer$publish(fixture(4))
    demo$receiver$poll(); session$flushReact()
    expect_identical(tail(messages, 1L)[[1L]]$method, "restyle")
  })
})
