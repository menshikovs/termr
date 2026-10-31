chart_stream_event <- function(source_id, sequence, x, y) {
  list(source_id = source_id, sequence = sequence, x = x, y = y)
}

chart_selected_payload <- function(chart, pilot) {
  selected <- new.env(parent = emptyenv())
  chart$on("termrcharts.line.selected", function(event, app) {
    selected$value <- event$data
  })
  pilot$press("end", "enter")
  selected$value
}

test_that("line charts bind bounded stream history and consume later events", {
  source <- termr_stream("chart", history = 10L)
  for (i in 1:3) source$emit(chart_stream_event("boot-1", i, i, i * 10))
  chart <- line_chart(0, 0, mode = "ascii")
  chart$bind_stream(source, x = function(event) event$x,
                    y = function(event) event$y, max_points = 2L)
  expect_identical(source$subscriber_count(), 1L)

  pilot <- test_app(chart, width = 50, height = 14)
  on.exit(pilot$stop(), add = TRUE)
  first <- chart_selected_payload(chart, pilot)
  expect_identical(first$index, 2L)
  expect_identical(first$x, 3)
  expect_identical(first$y, 30)

  source$emit(chart_stream_event("boot-1", 4, 4, 40))
  second <- chart_selected_payload(chart, pilot)
  expect_identical(second$index, 2L)
  expect_identical(second$x, 4)
  expect_identical(second$y, 40)
  expect_true(any(nzchar(trimws(pilot$screen_text()))))
})

test_that("scatter charts use the same stream update and selection contract", {
  source <- termr_stream("scatter", history = 5L)
  chart <- scatter_chart(0, 0, mode = "ascii")
  chart$bind_stream(source, function(event) event$x, function(event) event$y,
                    max_points = 3L)
  pilot <- test_app(chart, width = 50, height = 14)
  on.exit(pilot$stop(), add = TRUE)

  source$emit(chart_stream_event("boot-1", 1, 10, 100))
  source$emit(chart_stream_event("boot-1", 2, 20, 200))
  selected <- new.env(parent = emptyenv())
  chart$on("termrcharts.scatter.selected", function(event, app) {
    selected$value <- event$data
  })
  pilot$press("end", "enter")
  expect_identical(selected$value$index, 2L)
  expect_identical(selected$value$x, 20)
  expect_identical(selected$value$y, 200)
  expect_null(chart$stream_error)
})

test_that("streamed Date and POSIXct axes retain their classes and time zones", {
  date <- as.Date("2026-04-01") + 0:1
  clock <- as.POSIXct("2026-11-01 00:30:00", tz = "America/New_York") + 0:1 * 3600
  cases <- list(
    list(x = date, expected = date[[2L]], classes = class(date), zone = NULL),
    list(x = clock, expected = clock[[2L]], classes = class(clock), zone = "America/New_York")
  )
  for (case in cases) {
    source <- termr_stream(history = 5L)
    for (i in seq_along(case$x)) {
      source$emit(chart_stream_event("time-source", i, case$x[[i]], i * 2))
    }
    chart <- line_chart(1, 1, mode = "ascii")
    chart$bind_stream(source, function(event) event$x, function(event) event$y)
    pilot <- test_app(chart, width = 56, height = 15)
    selected <- chart_selected_payload(chart, pilot)
    pilot$stop()

    expect_identical(class(selected$x), case$classes)
    expect_identical(selected$x, case$expected)
    if (!is.null(case$zone)) expect_identical(attr(selected$x, "tzone"), case$zone)
    expect_identical(source$subscriber_count(), 0L)
  }
})

test_that("invalid stream records preserve the last valid chart data", {
  source <- termr_stream(history = 5L)
  source$emit(chart_stream_event("boot-1", 1, 1, 10))
  source$emit(chart_stream_event("boot-1", 2, 2, 20))
  chart <- line_chart(0, 0, mode = "ascii")
  chart$bind_stream(source, function(event) event$x, function(event) event$y)
  pilot <- test_app(chart, width = 50, height = 14)
  on.exit(pilot$stop(), add = TRUE)

  expect_silent(source$emit(chart_stream_event("boot-1", 3, "not numeric", 30)))
  pilot$step()
  expect_match(chart$stream_error, "x.*numeric|numeric.*x")
  unchanged <- chart_selected_payload(chart, pilot)
  expect_identical(unchanged$x, 2)
  expect_identical(unchanged$y, 20)

  expect_silent(source$emit(chart_stream_event("boot-1", 3, 3, 30)))
  pilot$step()
  expect_null(chart$stream_error)
  updated <- chart_selected_payload(chart, pilot)
  expect_identical(updated$x, 3)
  expect_identical(updated$y, 30)
})

test_that("source replacement and sequence rollback begin a fresh chart history", {
  source <- termr_stream(history = 10L)
  chart <- line_chart(0, 0, mode = "ascii")
  chart$bind_stream(source, function(event) event$x, function(event) event$y,
                    max_points = 10L)
  pilot <- test_app(chart, width = 50, height = 14)
  on.exit(pilot$stop(), add = TRUE)

  source$emit(chart_stream_event("boot-1", 1, 1, 10))
  source$emit(chart_stream_event("boot-1", 2, 2, 20))
  source$emit(chart_stream_event("boot-2", 1, 8, 80))
  changed <- chart_selected_payload(chart, pilot)
  expect_identical(changed$index, 1L)
  expect_identical(changed$x, 8)

  source$emit(chart_stream_event("boot-2", 0, 9, 90))
  restarted <- chart_selected_payload(chart, pilot)
  expect_identical(restarted$index, 1L)
  expect_identical(restarted$x, 9)
  expect_identical(restarted$y, 90)
})

test_that("mounted chart bursts are bounded and mark dropped points as gaps", {
  source <- termr_stream("burst", history = 10L)
  source$emit(chart_stream_event("boot-1", 1, 0, 0))
  chart <- line_chart(numeric(), numeric(), mode = "ascii")
  chart$bind_stream(source, function(event) event$x, function(event) event$y,
                    max_points = 2L)
  pilot <- test_app(chart, width = 50, height = 14)
  on.exit(pilot$stop(), add = TRUE)
  state <- chart$.__enclos_env__$private$.stream_state

  for (i in 1:4) source$emit(chart_stream_event("boot-1", i + 1, i, i * 10))
  expect_identical(state$queue$size, 2L)
  expect_true(state$queue$dropped)
  expect_true(state$flush_scheduled)
  pilot$step()
  expect_identical(state$queue$size, 0L)
  expect_false(state$flush_scheduled)
  selected <- chart_selected_payload(chart, pilot)
  expect_identical(selected$x, 4)
  expect_identical(selected$y, 40)
  expect_identical(selected$index, 2L)
})

test_that("large mounted bursts yield between bounded update chunks", {
  source <- termr_stream("chunked-burst", history = 100L)
  chart <- line_chart(numeric(), numeric(), mode = "ascii")
  chart$bind_stream(source, function(event) event$x, function(event) event$y,
                    max_points = 100L)
  pilot <- test_app(chart, width = 50, height = 14)
  on.exit(pilot$stop(), add = TRUE)
  state <- chart$.__enclos_env__$private$.stream_state

  for (i in 1:90) source$emit(chart_stream_event("boot-1", i, i, i * 10))
  expect_identical(state$queue$size, 90L)
  pilot$step()
  expect_identical(state$queue$size, 74L)
  expect_true(state$flush_scheduled)
  expect_identical(state$flush_count, 1L)
  expect_false(state$pending_render)
  expect_length(chart$.__enclos_env__$private$.spec$data$x, 16L)

  pilot$advance(0.01)
  expect_identical(state$queue$size, 0L)
  expect_false(state$flush_scheduled)
  expect_identical(state$flush_count, 6L)
  expect_false(state$pending_render)
  expect_length(chart$.__enclos_env__$private$.spec$data$x, 90L)
  selected <- chart_selected_payload(chart, pilot)
  expect_identical(selected$x, 90)
  expect_identical(selected$y, 900)
})

test_that("bindings are independent, replaceable and explicitly disposable", {
  source <- termr_stream(history = 5L)
  first <- line_chart(1, 1, mode = "ascii")
  second <- line_chart(1, 1, mode = "ascii")
  bind <- function(chart) chart$bind_stream(
    source, function(event) event$x, function(event) event$y
  )
  bind(first)
  bind(second)
  expect_identical(source$subscriber_count(), 2L)

  first$unbind_stream()
  expect_identical(source$subscriber_count(), 1L)
  expect_false(source$is_closed())
  expect_silent(source$emit(chart_stream_event("boot-1", 1, "bad", 1)))
  expect_null(first$stream_error)
  expect_match(second$stream_error, "x.*numeric|numeric.*x")

  replacement <- termr_stream(history = 5L)
  second$bind_stream(replacement, function(event) event$x, function(event) event$y)
  expect_identical(source$subscriber_count(), 0L)
  expect_identical(replacement$subscriber_count(), 1L)
  second$unbind_stream()
  expect_identical(replacement$subscriber_count(), 0L)
  expect_false(replacement$is_closed())
})

test_that("removing a mounted chart unsubscribes without closing its stream", {
  source <- termr_stream()
  chart <- line_chart(1, 1, mode = "ascii")
  chart$bind_stream(source, function(event) event$x, function(event) event$y)
  pilot <- test_app(vertical(chart), width = 50, height = 14)
  expect_identical(source$subscriber_count(), 1L)

  chart$remove()
  expect_identical(source$subscriber_count(), 0L)
  expect_false(source$is_closed())
  expect_silent(source$emit(chart_stream_event("boot-1", 1, 1, 1)))
  pilot$stop()
})
