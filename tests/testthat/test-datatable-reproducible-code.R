eval_reproducible_code <- function(result, bindings = list()) {
  expect_true(is.character(result$code))
  expect_true(length(parse(text = result$code)) >= 1L)
  env <- list2env(bindings, parent = globalenv())
  eval(parse(text = result$code), envir = env)
}

test_that("selected values are copied as bounded, typed R expressions", {
  data <- data.frame(
    logical = c(TRUE, NA), integer = c(1L, NA_integer_),
    double = c(1 / 3, NaN), character = c("µ", "line\nbreak"),
    factor = factor(c("a", NA), levels = c("a", "b")),
    date = as.Date(c("2024-02-29", NA)),
    time = structure(c(1700000000.1234567, NA_real_), class = c("POSIXct", "POSIXt"), tzone = "UTC")
  )
  table <- data_table(data)
  table$select_range(1, 2)
  result <- table$reproducible_code("value")
  expect_identical(result$status, "exact")
  expect_identical(eval_reproducible_code(result), table$selected_data())
  expect_identical(table$data, data)

  one_cell <- data_table(data, cursor = "cell")
  one_cell$move_cursor(row = 1, column = "double")
  cell_result <- one_cell$reproducible_code("value")
  expect_identical(eval_reproducible_code(cell_result), table_slice(data$double, 1L))

  expect_identical(table$reproducible_code("value", max_rows = 1L)$status, "limited")
  expect_identical(table$reproducible_code("value", max_bytes = 32L)$status, "limited")
  expect_error(table$reproducible_code("value", max_rows = 5001L), "internal limit")

  empty <- data_table(data, cursor = "none")$reproducible_code("value")
  expect_identical(empty$status, "limited")
})

test_that("raw bytes, nested list values and randomized doubles round-trip", {
  bytes <- as.raw(c(0L, 27L, 255L))
  raw_table <- data_table(data.frame(payload = bytes), cursor = "cell")
  raw_table$move_cursor(row = 2L, column = "payload")
  raw_result <- raw_table$reproducible_code("value")
  expect_identical(eval_reproducible_code(raw_result), bytes[[2L]])

  nested <- structure(list(payload = list(bytes, raw(), NULL)), class = "data.frame",
                      row.names = c(NA_integer_, -3L))
  nested_table <- data_table(nested, cursor = "none")
  nested_table$select_range(1L, 3L)
  nested_result <- nested_table$reproducible_code("value")
  expect_identical(nested_result$status, "exact")
  expect_identical(eval_reproducible_code(nested_result), nested_table$selected_data())

  set.seed(90210)
  for (i in seq_len(40L)) {
    values <- runif(12L, -1e9, 1e9)
    values[sample.int(length(values), 2L)] <- NA_real_
    values[[sample.int(length(values), 1L)]] <- NaN
    values[[sample.int(length(values), 1L)]] <- Inf
    data <- data.frame(value = values)
    table <- data_table(data, cursor = "none")
    table$select_range(1L, nrow(data))
    result <- table$reproducible_code("value")
    expect_identical(eval_reproducible_code(result), table$selected_data())
  }
})

test_that("generated code safely escapes hostile and Unicode names", {
  hostile <- "x`); system('should-not-run'); `"
  data <- data.frame(setNames(list(c(4L, 2L, 3L)), hostile), check.names = FALSE)
  table <- data_table(data)
  result <- table$reproducible_code("pipeline")
  expect_identical(result$status, "exact")
  expect_true(result$requires_source_binding)
  expect_identical(eval_reproducible_code(result, list(data = data)), data)
  expect_false(file.exists("should-not-run"))
})

test_that("pipeline reproduces final filter, sort, selection and column state", {
  data <- data.frame(
    group = c("a", "b", "a", "a", "a"),
    score = c(5, 1, 8, NA, 3),
    secret = c("s1", "s2", "s3", "s4", "s5"),
    stringsAsFactors = FALSE
  )
  table <- data_table(data)
  table$filter_columns(list(group = table_filter("equals", "a")))
  table$sort(c("group", "score"), decreasing = c(FALSE, TRUE))
  table$set_column_visible("secret", FALSE)
  table$reorder_column("score", 1L)
  table$select_range(2L, 3L)

  result <- table$reproducible_code("pipeline")
  expect_identical(result$status, "exact")
  expect_true(result$requires_source_binding)
  expect_false(result$model$operation_history$available)
  actual <- eval_reproducible_code(result, list(data = data))
  expected <- table$selected_data()[, c("score", "group"), drop = FALSE]
  expect_identical(actual, expected)
  expect_identical(data$score, c(5, 1, 8, NA, 3))

  indexed <- data_table(data)
  indexed$filter(c(5L, 3L, 1L))
  indexed$sort("score", decreasing = TRUE)
  indexed_result <- indexed$reproducible_code("pipeline")
  expect_identical(eval_reproducible_code(indexed_result, list(data = data)),
                   data[indexed$view, names(data), drop = FALSE])
})

test_that("pipeline handles missing, text and range filters without user-code parsing", {
  data <- data.frame(name = c("one", "two", "three", NA), value = c(1, 2, 3, 4))
  cases <- list(
    list(name = table_filter("contains", "t", case_sensitive = FALSE)),
    list(name = table_filter("regex", "^t", case_sensitive = FALSE)),
    list(name = table_filter("missing")),
    list(value = table_filter("range", min = 2, max = 4, inclusive = FALSE))
  )
  for (filters in cases) {
    table <- data_table(data)
    table$filter_columns(filters)
    code <- table$reproducible_code("pipeline")
    expect_identical(code$status, "exact")
    expect_identical(eval_reproducible_code(code, list(data = data)),
                     data[table$view, names(data), drop = FALSE])
  }
})

test_that("unsupported filters and custom classes are reported explicitly", {
  data <- data.frame(x = 1:3)
  table <- data_table(data)
  table$filter_columns(list(x = function(x) x > 1))
  result <- table$reproducible_code("pipeline")
  expect_identical(result$status, "unsupported")
  expect_match(result$reason, "Function filters")

  custom <- data_table(data.frame(x = structure(1:3, class = "private_measure")))
  custom_result <- custom$reproducible_code("value")
  expect_identical(custom_result$status, "unsupported")
  expect_match(custom_result$reason, "whitelist")
})

test_that("local edits export with original row identities and never mutate the input", {
  source_data <- data.frame(id = 1:4, value = c(10L, 20L, 30L, 40L))
  table <- data_table(source_data, editable = TRUE)
  table$sort("id", decreasing = TRUE)
  table$filter_columns(list(value = table_filter("range", min = 10L, max = 40L)))
  table$set_cell(2L, "value", 25L)
  table$set_cell(2L, "value", 26L)
  result <- table$reproducible_code("edits")
  expect_identical(result$status, "exact")
  expect_match(result$code, '\\[\\[2L?\\]\\]')
  patched <- eval_reproducible_code(result, list(data = source_data))
  expected <- source_data
  expected$value[[2L]] <- 26L
  expect_identical(patched, expected)
  expect_identical(source_data$value, c(10L, 20L, 30L, 40L))
  expect_identical(table$reproducible_code("edits")$model$mutations$recorded_local_cells, 1L)

  table$set_cell(2L, "value", 20L)
  expect_identical(table$reproducible_code("edits")$model$mutations$recorded_local_cells, 0L)
  table$data <- source_data
  expect_identical(table$reproducible_code("edits")$model$mutations$recorded_local_cells, 0L)
})

test_that("source-aware exports avoid query details and source write callbacks", {
  calls <- 0L
  source <- table_source(
    row_count = function() 3L, column_names = function() "x",
    get_rows = function(start, count, columns) data.frame(x = seq.int(start, length.out = count)),
    set_value = function(row, column, value) { calls <<- calls + 1L; TRUE }
  )
  table <- data_table(source, editable = TRUE)
  pipeline <- table$reproducible_code("pipeline")
  edits <- table$reproducible_code("edits")
  expect_identical(pipeline$status, "unsupported")
  expect_identical(edits$status, "unsupported")
  expect_false(grepl("password=|sqlite:|SELECT[[:space:]]+", paste(pipeline$code, pipeline$reason), ignore.case = TRUE))
  expect_identical(calls, 0L)
})

test_that("integer64 export keeps exact 64-bit values", {
  skip_if_not_installed("bit64")
  integer64 <- bit64::as.integer64(c("9223372036854775807", "-9007199254740993", NA))
  table <- data_table(data.frame(value = integer64))
  table$select_range(1L, 3L)
  result <- table$reproducible_code("value")
  expect_identical(result$status, "exact")
  expect_identical(eval_reproducible_code(result), table$selected_data())
})

test_that("haven export preserves labels and tagged NA tags", {
  skip_if_not_installed("haven")
  labelled <- haven::labelled(c(1, haven::tagged_na("a"), NA_real_, NaN),
                              labels = c(Male = 1), label = "Sex")
  labelled_table <- data_table(data.frame(value = labelled))
  labelled_table$select_range(1L, 4L)
  labelled_result <- labelled_table$reproducible_code("value")
  expect_identical(labelled_result$status, "exact")
  restored <- eval_reproducible_code(labelled_result)
  expect_identical(restored, labelled_table$selected_data())
  expect_identical(haven::na_tag(restored$value), haven::na_tag(labelled))

  spss <- haven::labelled_spss(c(1, 9, 99, NA_real_), c(No = 1, Yes = 2),
                               label = "Answer", na_values = 99, na_range = c(90, 99))
  spss_table <- data_table(data.frame(value = spss), cursor = "none")
  spss_table$select_range(1L, 4L)
  spss_result <- spss_table$reproducible_code("value")
  expect_identical(spss_result$status, "exact")
  expect_identical(eval_reproducible_code(spss_result), spss_table$selected_data())
})

test_that("units export preserves unit metadata", {
  skip_if_not_installed("units")
  measured <- units::set_units(c(1.25, NA_real_), "m")
  measured_table <- data_table(data.frame(value = measured))
  measured_table$select_range(1L, 2L)
  measured_result <- measured_table$reproducible_code("value")
  expect_identical(measured_result$status, "exact")
  expect_identical(eval_reproducible_code(measured_result), measured_table$selected_data())
})

test_that("lubridate, blob, hms and sf values use their validated class structures", {
  available <- c("lubridate", "hms", "blob", "sf")
  skip_if(!any(vapply(available, requireNamespace, logical(1), quietly = TRUE)),
          "optional typed packages are not installed")
  if (requireNamespace("lubridate", quietly = TRUE)) {
    values <- list(
      period = lubridate::period(month = 1L, day = 2L),
      duration = lubridate::duration(3600, units = "seconds"),
      interval = lubridate::interval(lubridate::ymd("2024-01-01", tz = "UTC"),
                                     lubridate::ymd("2024-01-03", tz = "UTC"))
    )
    for (value in values) {
      table <- data_table(data.frame(value = value))
      result <- table$reproducible_code("value")
      expect_identical(result$status, "exact")
      expect_identical(eval_reproducible_code(result), table$selected_data())
    }
  }
  if (requireNamespace("hms", quietly = TRUE)) {
    table <- data_table(data.frame(value = hms::as_hms(c(1.25, NA_real_))))
    table$select_range(1L, 2L)
    result <- table$reproducible_code("value")
    expect_identical(result$status, "exact")
    expect_identical(eval_reproducible_code(result), table$selected_data())
  }
  if (requireNamespace("blob", quietly = TRUE)) {
    table <- data_table(data.frame(value = blob::blob(as.raw(c(0L, 255L)), raw(), NULL)))
    table$select_range(1L, 3L)
    result <- table$reproducible_code("value")
    expect_identical(result$status, "exact")
    expect_identical(eval_reproducible_code(result), table$selected_data())
  }
  if (requireNamespace("sf", quietly = TRUE)) {
    spatial <- sf::st_as_sf(data.frame(id = 1:2, x = c(0, 1), y = c(1, 2)),
                            coords = c("x", "y"), crs = 4326)
    table <- data_table(spatial)
    table$select_range(1L, 2L)
    result <- table$reproducible_code("value")
    expect_identical(result$status, "exact")
    expect_identical(eval_reproducible_code(result), table$selected_data())
  }
})

test_that("reproducible code entry points are offered in the command palette", {
  table <- data_table(data.frame(x = 1:2))
  labels <- vapply(table$commands(), `[[`, "", "label")
  expect_setequal(labels, c("Copy selection as R value", "Copy current R pipeline", "Copy local R edits"))
  expect_true(all(vapply(table$commands(), function(x) is.null(x$shortcut), logical(1))))

  a <- app(table)
  pilot <- test_app(a, 60, 12)
  pilot$press("ctrl+p")
  pilot$type("copy selection as r value")
  pilot$press("enter")
  expect_match(a$clipboard, "structure|list\\(")
  expect_match(help_markdown(a), "Copy current R pipeline", fixed = TRUE)
})
