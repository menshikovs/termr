native_chart_factories <- function(mode = "auto") {
  x <- seq_len(40)
  y <- 3 + sin(x / 5)
  list(
    line = function() line_chart(x, y, title = "Line", mode = mode),
    scatter = function() scatter_chart(x, y, title = "Scatter", mode = mode),
    bar = function() bar_chart(letters[1:8], c(3, -2, 4, 1, 5, 0, 2, 6), title = "Bars", mode = mode),
    histogram = function() histogram((seq_len(300) %% 53) / 10, title = "Histogram", mode = mode),
    heatmap = function() heatmap_chart(matrix(seq_len(48), 6, dimnames = list(letters[1:6], LETTERS[1:8])),
                                       title = "Heatmap", mode = mode)
  )
}

native_chart_spec <- function(name, mode = "ascii") {
  base <- list(title = NULL, x_label = NULL, y_label = NULL, mode = mode)
  x <- seq_len(40)
  y <- 3 + sin(x / 5)
  switch(name,
    line = , scatter = c(list(type = name, data = normalize_xy(x, y), refs = NULL), base),
    bar = c(list(type = "bar", data = normalize_bar_data(letters[1:8], c(3, -2, 4, 1, 5, 0, 2, 6),
                                                           "single", TRUE)$data,
             orientation = "vertical", position = "single", value_labels = FALSE, refs = NULL), base),
    histogram = c(list(type = "histogram", data = histogram_data((seq_len(300) %% 53) / 10, "Sturges"),
                       breaks = "Sturges"), base),
    heatmap = c(list(type = "heatmap", data = normalize_matrix(matrix(seq_len(48), 6,
                        dimnames = list(letters[1:6], LETTERS[1:8])))), base)
  )
}

test_that("the five native chart constructors render in every supported mode", {
  for (mode in c("auto", "ascii", "block", "braille")) {
    for (name in names(native_chart_factories(mode))) {
      chart <- native_chart_factories(mode)[[name]]()
      buffer <- render_widget(chart, width = 60, height = 18)
      text <- buffer$to_text()
      expect_length(text, 18L)
      expect_true(any(nzchar(trimws(text))), info = paste(name, mode))
      if (identical(mode, "ascii")) {
        chars <- strsplit(paste(text, collapse = ""), "", fixed = TRUE)[[1L]]
        expect_true(all(vapply(chars, function(ch) all(utf8ToInt(ch) < 128L), logical(1))),
                    info = paste(name, mode))
      }
    }
  }
})

test_that("chart inputs validate and empty or non-finite data render safely", {
  expect_error(line_chart(1:2, 1:3), "equal lengths")
  expect_error(scatter_chart(1:2, c(1, 2), x_scale = "bad"), "x_scale")
  expect_error(bar_chart(c("a", "b"), 1:3), "one label per value")
  expect_error(bar_chart(c("a", "b"), cbind(x = 1:2, y = 3:4), position = "single"), "needs one series")
  expect_error(histogram(1:4, breaks = c(3, 2, 1)), "Invalid histogram")
  expect_error(heatmap_chart(matrix(letters[1:4], 2)), "numeric matrix")

  empty <- list(
    line_chart(numeric(), numeric(), mode = "ascii"),
    scatter_chart(c(NA_real_, Inf), c(1, 2), mode = "ascii"),
    bar_chart(c("a", "b"), c(NA_real_, Inf), mode = "ascii"),
    histogram(c(NA_real_, Inf), mode = "ascii"),
    heatmap_chart(matrix(c(NA_real_, Inf), 1), mode = "ascii")
  )
  for (chart in empty) invisible(render_widget(chart, width = 45, height = 14))
})

test_that("line and scatter charts retain scale, gap, time and dense-data behavior", {
  dated <- as.Date("2026-01-01") + 0:3
  chart <- line_chart(dated, c(1, NA, 3, 4), mode = "ascii")
  seen <- list()
  chart$on("termrcharts.line.selected", function(event, app) seen[[length(seen) + 1L]] <<- event$data)
  pilot <- test_app(chart, width = 60, height = 18)
  on.exit(pilot$stop(), add = TRUE)
  pilot$press("right", "enter")
  expect_identical(seen[[1L]]$index, 3L)
  expect_s3_class(seen[[1L]]$x, "Date")

  log_chart <- scatter_chart(10^(0:4), 10^(0:4), x_scale = "log10", y_scale = "log10", mode = "ascii")
  invisible(render_widget(log_chart, width = 60, height = 18))
  dense <- seq_len(10000)
  invisible(render_widget(line_chart(dense, sin(dense / 51), mode = "ascii"), 80, 24))
  invisible(render_widget(scatter_chart(dense, cos(dense / 47), mode = "ascii"), 80, 24))
})

test_that("bars retain negative, grouped, stacked, horizontal and histogram semantics", {
  cases <- list(
    bar_chart(letters[1:4], c(-3, 0, 2, 4), mode = "ascii"),
    bar_chart(letters[1:4], cbind(north = 1:4, south = 4:1), position = "grouped", mode = "ascii"),
    bar_chart(letters[1:4], cbind(north = 1:4, south = -(4:1)), position = "stacked",
              orientation = "horizontal", mode = "ascii"),
    histogram((seq_len(500L) %% 37L) / 5, breaks = 10, mode = "ascii")
  )
  for (chart in cases) invisible(render_widget(chart, width = 70, height = 20))

  hist <- histogram(c(1, 2, 3, 4), breaks = c(0, 2, 5), mode = "ascii")
  payload <- list()
  hist$on("termrcharts.histogram.selected", function(event, app) payload[[1L]] <<- event$data)
  pilot <- test_app(hist, width = 60, height = 18)
  on.exit(pilot$stop(), add = TRUE)
  pilot$press("enter")
  expect_identical(names(payload[[1L]]), c("index", "lower", "upper", "count"))
  expect_equal(payload[[1L]]$count, 2)
})

test_that("heatmap selection reports source matrix identity and values", {
  z <- matrix(seq_len(100), 10, dimnames = list(paste0("r", 1:10), paste0("c", 1:10)))
  chart <- heatmap_chart(z, mode = "block")
  payload <- list()
  chart$on("termrcharts.heatmap.selected", function(event, app) payload[[1L]] <<- event$data)
  pilot <- test_app(chart, width = 35, height = 12)
  on.exit(pilot$stop(), add = TRUE)
  pilot$press("right", "enter")
  expect_identical(names(payload[[1L]]), c("row", "column", "value"))
  expect_equal(payload[[1L]]$value, z[payload[[1L]]$row, payload[[1L]]$column])
  invisible(render_widget(heatmap_chart(matrix(seq_len(10000), 100), mode = "ascii"), 80, 24))
})

test_that("chart event callbacks keep their ordering, payload shape and invocation count", {
  chart <- line_chart(1:10, (1:10)^2, mode = "ascii")
  order <- character()
  payloads <- list()
  for (event_name in c("cursor_changed", "selected", "activated")) local({
    name <- event_name
    chart$on(paste0("termrcharts.line.", name), function(event, app) {
      order <<- c(order, name)
      payloads[[name]] <<- c(payloads[[name]], list(event$data))
    })
  })
  pilot <- test_app(chart, width = 60, height = 18)
  on.exit(pilot$stop(), add = TRUE)
  pilot$press("right", "enter")
  expect_identical(order, c("cursor_changed", "selected", "activated"))
  expect_identical(names(payloads$selected[[1L]]), c("index", "x", "y"))
  expect_identical(payloads$selected[[1L]], payloads$activated[[1L]])
  expect_identical(payloads$selected[[1L]], payloads$cursor_changed[[1L]])
})

test_that("each chart emits one selected and activated callback with its data payload", {
  cases <- list(
    line = list(chart = line_chart(1:5, 1:5, mode = "ascii"), fields = c("index", "x", "y")),
    scatter = list(chart = scatter_chart(1:5, 5:1, mode = "ascii"), fields = c("index", "x", "y")),
    bar = list(chart = bar_chart(letters[1:4], 1:4, mode = "ascii"), fields = c("index", "label", "value")),
    histogram = list(chart = histogram(1:20, breaks = 4, mode = "ascii"), fields = c("index", "lower", "upper", "count")),
    heatmap = list(chart = heatmap_chart(matrix(1:9, 3), mode = "ascii"), fields = c("row", "column", "value"))
  )
  for (name in names(cases)) {
    chart <- cases[[name]]$chart
    selected <- activated <- list()
    chart$on(paste0("termrcharts.", name, ".selected"), function(event, app) {
      selected[[length(selected) + 1L]] <<- event$data
    })
    chart$on(paste0("termrcharts.", name, ".activated"), function(event, app) {
      activated[[length(activated) + 1L]] <<- event$data
    })
    pilot <- test_app(chart, width = 60, height = 18)
    on.exit(pilot$stop(), add = TRUE)
    pilot$press("right", "enter")
    expect_length(selected, 1L)
    expect_length(activated, 1L)
    expect_identical(names(selected[[1L]]), cases[[name]]$fields)
    expect_identical(selected[[1L]], activated[[1L]])
    pilot$stop()
  }
})

test_that("mouse hit testing selects source items for every chart type", {
  for (name in names(native_chart_factories("ascii"))) {
    chart <- native_chart_factories("ascii")[[name]]()
    events <- list()
    chart$on(paste0("termrcharts.", name, ".cursor_changed"), function(event, app) {
      events[[length(events) + 1L]] <<- event$data
    })
    pilot <- test_app(chart, width = 60, height = 18)
    spec <- native_chart_spec(name)
    plan <- chart_plan(spec, 60, 18)
    target <- if (identical(name, "heatmap")) c(row = 6L, column = 8L) else plan$ids[[length(plan$ids)]]
    target_cell <- NULL
    for (row in seq_len(plan$H)) for (col in seq_len(plan$W)) {
      hit <- plan$hit(row, col, 1L)
      if (!is.null(hit) && identical(unname(as.integer(hit)), unname(as.integer(target)))) {
        target_cell <- c(row, col)
        break
      }
    }
    expect_false(is.null(target_cell))
    pilot$click(target_cell[[2L]], target_cell[[1L]])
    if (identical(name, "heatmap")) {
      expect_identical(c(events[[1L]]$row, events[[1L]]$column), unname(as.integer(target)))
    } else {
      expect_identical(events[[1L]]$index, as.integer(target))
    }
    pilot$stop()
  }
})

test_that("charts update data in place, invalidate plans, and survive resize", {
  updates <- list(
    line = list(chart = line_chart(1:8, 1:8, mode = "ascii"), args = list(x = 1:8, y = 8:1)),
    scatter = list(chart = scatter_chart(1:8, 1:8, mode = "ascii"), args = list(x = 1:8, y = c(1, 8, 2, 7, 3, 6, 4, 5))),
    bar = list(chart = bar_chart(letters[1:4], 1:4, mode = "ascii"), args = list(labels = letters[1:4], values = c(4, 3, 2, 1))),
    histogram = list(chart = histogram(1:40, breaks = 5, mode = "ascii"), args = list(x = 100:139)),
    heatmap = list(chart = heatmap_chart(matrix(1:16, 4), mode = "ascii"), args = list(z = matrix(16:1, 4)))
  )
  for (name in names(updates)) {
    chart <- updates[[name]]$chart
    pilot <- test_app(chart, width = 60, height = 18)
    before <- pilot$screen_text()
    do.call(chart$update_data, updates[[name]]$args)
    pilot$step()
    after <- pilot$screen_text()
    expect_false(identical(before, after), info = name)
    pilot$resize(80, 24)
    expect_length(pilot$screen_text(), 24L)
    expect_error(chart$update_data(unexpected = 1), "requires")
    pilot$stop()
  }
})

test_that("updates reject invalid data without changing the current chart", {
  chart <- line_chart(1:4, 1:4, mode = "ascii")
  pilot <- test_app(chart, width = 50, height = 14)
  before <- pilot$screen_text()
  expect_error(chart$update_data(x = 1:2, y = 1:3), "equal lengths")
  expect_identical(pilot$screen_text(), before)
  pilot$stop()
})

test_that("charts mount and unmount as ordinary themed widgets", {
  chart <- bar_chart(letters[1:4], 1:4, mode = "block")
  ui <- app(chart, theme = "high-contrast")
  pilot <- test_app(ui, width = 60, height = 18)
  expect_false(is.null(chart$parent))
  expect_true(any(nzchar(trimws(pilot$screen_text()))))
  chart$remove()
  expect_null(chart$parent)
  pilot$stop()
  for (i in seq_len(10L)) invisible(line_chart(1:5, 1:5, interactive = FALSE))
})

