test_that("DataTable records compact typed column metadata", {
  data <- data.frame(
    count = 1:2,
    status = factor(c("new", "done"), levels = c("new", "done", "blocked")),
    day = as.Date(c("2024-01-01", "2024-01-02")),
    stringsAsFactors = FALSE
  )
  table <- data_table(data)
  info <- table$column_info()

  expect_identical(info$type, c("int", "fct", "date"))
  expect_identical(info$typeof, c("integer", "integer", "double"))
  expect_identical(info$class, c("integer", "factor", "Date"))
  expect_true(all(info$allows_missing))
  expect_true(all(info$editable))
  expect_identical(class(info$prototype[[3L]]), "Date")
  expect_identical(levels(info$prototype[[2L]]), levels(data$status))
  expect_identical(info$attributes[[3L]], attributes(info$prototype[[3L]]))
})

test_that("type headers use pillar summaries without replacing the table renderer", {
  data <- data.frame(count = 1:2, day = as.Date(c("2024-01-01", "2024-01-02")))
  table <- data_table(data, show_types = TRUE, row_names = FALSE)
  pilot <- test_app(app(table), width = 32, height = 7)
  on.exit(pilot$stop(), add = TRUE)

  screen <- paste(pilot$screen_text(), collapse = "\n")
  expect_match(screen, "int")
  expect_match(screen, "date")
  expect_match(screen, "2024-01-01")
  expect_false(grepl("\\033\\[", screen))
  expect_identical(data, table$data)
})

test_that("pillar formatting is bounded to the visible typed slice", {
  values <- as.Date("2000-01-01") + 0:1000000
  selected <- table_slice(values, c(1L, 500000L, 1000001L))
  formatted <- table_format_values(selected, width = 12L)

  expect_length(formatted, 3L)
  expect_true(all(str_width(formatted) <= 12L))
  expect_identical(values[c(1L, 500000L, 1000001L)], selected)
  expect_false(any(grepl("\\033\\[", formatted)))
})

test_that("base, factor, Date, POSIXct and difftime parsers keep their types", {
  expect_identical(parse_cell("42", 1L)$value, 42L)
  expect_match(parse_cell("3.14", 1L)$error, "whole number")
  expect_identical(parse_cell("-2147483647", 1L)$value, -2147483647L)
  expect_match(parse_cell("-2147483648", 1L)$error, "integer range")
  expect_true(is.nan(parse_cell("NaN", 1.0)$value))
  expect_identical(parse_cell("Inf", 1.0)$value, Inf)
  expect_identical(parse_cell("-Inf", 1.0)$value, -Inf)
  expect_identical(parse_cell("NA", 1.0)$value, NA_real_)
  expect_identical(parse_cell("TRUE", TRUE)$value, TRUE)
  expect_identical(parse_cell("NA", TRUE)$value, NA)
  expect_identical(parse_cell("", "text")$value, "")
  expect_identical(parse_cell(NA_character_, "text")$value, NA_character_)

  factor_template <- factor(c("low", "high"), levels = c("low", "high", "other"))
  parsed_factor <- parse_cell("high", factor_template)$value
  expect_identical(parsed_factor, factor("high", levels = levels(factor_template)))
  expect_match(parse_cell("unknown", factor_template)$error, "existing|one of")
  ordered_template <- ordered(c("low", "high"), levels = c("low", "high"))
  expect_identical(parse_cell("high", ordered_template)$value, ordered("high", levels = levels(ordered_template)))

  expect_identical(parse_cell("2024-02-29", as.Date("2024-01-01"))$value, as.Date("2024-02-29"))
  expect_match(parse_cell("2023-02-29", as.Date("2024-01-01"))$error, "real date")

  duration <- parse_cell("1.5", as.difftime(1, units = "mins"))$value
  expect_identical(class(duration), "difftime")
  expect_identical(attr(duration, "units"), "mins")
  expect_equal(as.numeric(duration, units = "mins"), 1.5)
})

test_that("POSIXct editing preserves timezone and rejects invalid DST wall times", {
  template <- as.POSIXct("2024-01-01 12:00:00", tz = "America/New_York")
  gap <- parse_cell("2024-03-10 02:30:00", template)
  ambiguous <- parse_cell("2024-11-03 01:30:00", template)
  explicit <- parse_cell("2024-11-03 01:30:00-0400", template)

  expect_match(gap$error, "real local timestamp|does not exist")
  expect_match(ambiguous$error, "ambiguous")
  expect_null(explicit$error)
  expect_identical(attr(explicit$value, "tzone"), "America/New_York")
  expect_equal(as.numeric(explicit$value), as.numeric(as.POSIXct("2024-11-03 05:30:00", tz = "UTC")))
  expect_equal(as.numeric(parse_cell(edit_text(explicit$value), template)$value), as.numeric(explicit$value))
})

test_that("hms columns use the optional duration adapter", {
  skip_if_not_installed("hms")
  time <- hms::as_hms(c(1, 2))
  parsed_time <- parse_cell("25:10:01.5", time)
  expect_null(parsed_time$error)
  expect_identical(class(parsed_time$value), class(time))
  expect_identical(attr(parsed_time$value, "units"), attr(time, "units"))
  expect_equal(as.numeric(parsed_time$value), 25 * 3600 + 10 * 60 + 1.5)

})

test_that("integer64 uses an optional exact adapter without a double round trip", {
  skip_if_not_installed("bit64")
  large <- bit64::as.integer64(c("9007199254740993", "9223372036854775807"))
  parsed <- parse_cell("9007199254740995", large)
  expect_null(parsed$error)
  expect_identical(as.character(parsed$value), "9007199254740995")
  expect_match(parse_cell("9223372036854775808", large)$error, "range")
  expect_identical(trimws(table_format_values(large)), as.character(large))
})

test_that("one-cell edits preserve type and attributes and failures are atomic", {
  source <- data.frame(
    count = c(1L, 2L),
    status = ordered(c("low", "high"), levels = c("low", "high")),
    day = as.Date(c("2024-01-01", "2024-01-02")),
    instant = as.POSIXct(c("2024-01-01 10:00:00", "2024-01-02 10:00:00"), tz = "UTC"),
    elapsed = as.difftime(c(1, 2), units = "mins"),
    stringsAsFactors = FALSE
  )
  original <- source
  table <- data_table(source, editable = TRUE)
  table$set_cell(1L, "count", "42")
  table$set_cell(2L, "status", "low")
  table$set_cell(1L, "day", "2024-02-29")
  table$set_cell(2L, "instant", "2024-01-02 12:30:00+0000")
  table$set_cell(1L, "elapsed", "4.5")

  expect_identical(typeof(table$data$count), typeof(source$count))
  expect_identical(attributes(table$data$status), attributes(source$status))
  expect_identical(attributes(table$data$day), attributes(source$day))
  expect_identical(attributes(table$data$instant), attributes(source$instant))
  expect_identical(attributes(table$data$elapsed), attributes(source$elapsed))
  expect_identical(source, original)
  expect_identical(table$data$count, c(42L, 2L))
  expect_equal(as.numeric(table$data$elapsed, units = "mins"), c(4.5, 2))

  before <- table$data
  expect_error(table$set_cell(1L, "count", "3.14"), "whole number")
  expect_error(table$set_cell(1L, "day", "2023-02-29"), "real date")
  expect_identical(table$data, before)
})

test_that("list columns stay read-only, bounded, and filterable by summaries", {
  data <- data.frame(items = I(list(NULL, c(1, 2), "世界")), stringsAsFactors = FALSE)
  table <- data_table(data, editable = TRUE)

  expect_identical(table$column_info()$editable, FALSE)
  expect_identical(table$column_info()$allows_missing, TRUE)
  expect_identical(table_format_values(data$items), c("<NULL>", "<dbl[2]>", "世界"))
  expect_error(table$set_cell(1L, "items", "changed"), "read-only")
  expect_error(table$sort("items"), "Sorting is not supported")
  table$filter_columns(list(items = table_filter("contains", "世界")))
  expect_identical(table$view, 3L)
  table$filter_columns(list(items = table_filter("missing")))
  expect_identical(table$view, 1L)
  expect_null(data$items[[1L]])
})

test_that("empty frames and tibbles retain their class and schema", {
  skip_if_not_installed("tibble")
  empty <- tibble::tibble(count = integer(), day = as.Date(character()))
  table <- data_table(empty)
  expect_s3_class(table$data, "tbl_df")
  expect_identical(table$column_info()$type, c("int", "date"))
  expect_identical(table$row_count, 0L)

  no_columns <- data.frame(row.names = integer())
  expect_no_error(data_table(no_columns))
})

test_that("workflow profiles and compact inspectors preserve special types", {
  instant <- as.POSIXct(c("2024-01-01 12:00:00", "2024-01-03 12:00:00"),
                        tz = "America/New_York")
  time_stats <- data_profile(as.difftime(c(60, 180), units = "mins"))$summary$stats
  expect_identical(time_stats$Type, "difftime")
  expect_identical(attr(time_stats$Min, "units"), "mins")
  expect_equal(as.numeric(time_stats$Median, units = "mins"), 120)
  posix_stats <- data_profile(instant)$summary$stats
  expect_identical(attr(posix_stats$Median, "tzone"), "America/New_York")
  expect_match(format_compact_value(as.difftime(90, units = "mins")), "01:30:00|90")

  if (requireNamespace("hms", quietly = TRUE)) {
    hms_value <- hms::as_hms(3661)
    expect_match(format_compact_value(hms_value), "01:01:01")
    hms_stats <- data_profile(hms::as_hms(c(60, 120)))$summary$stats
    expect_identical(class(hms_stats$Median), class(hms::as_hms(0)))
  }

  if (requireNamespace("bit64", quietly = TRUE)) {
    int64 <- bit64::as.integer64(c("9007199254740993", "9007199254740995"))
    stats <- data_profile(int64)$summary$stats
    expect_identical(stats$Type, "integer64")
    expect_match(as.character(unlist(stats[grep("^Top", names(stats))])), "900719925474099")
    expect_identical(format_compact_value(int64[[1L]]), "9007199254740993")
  }
})

test_that("optional dplyr table classes and grouping metadata survive table operations", {
  skip_if_not_installed("dplyr")
  skip_if_not_installed("tibble")
  input <- tibble::tibble(group = c("a", "b", "a"), value = c(3L, 1L, 2L))
  grouped <- dplyr::group_by(input, group)
  table <- data_table(grouped)

  expect_s3_class(table$data, "grouped_df")
  expect_identical(attr(table$data, "groups"), attr(grouped, "groups"))
  table$sort("value")
  table$filter(c(1L, 3L))
  expect_identical(attr(table$data, "groups"), attr(grouped, "groups"))

  outputs <- list(
    dplyr::select(grouped, value),
    dplyr::filter(grouped, value > 1L),
    dplyr::arrange(grouped, value),
    dplyr::mutate(grouped, next_value = value + 1L),
    dplyr::group_by(input, group),
    dplyr::ungroup(grouped),
    dplyr::rowwise(input)
  )
  for (value in outputs) {
    view <- data_table(value)
    expect_identical(view$data, value)
    expect_identical(class(view$data), class(value))
  }

  editable_grouped <- data_table(grouped, editable = TRUE)
  editable_grouped$set_cell(1L, "group", "b")
  expected_grouped <- dplyr::group_by(
    tibble::tibble(group = c("b", "b", "a"), value = c(3L, 1L, 2L)),
    group
  )
  expect_identical(dplyr::group_data(editable_grouped$data), dplyr::group_data(expected_grouped))

  rowwise <- dplyr::rowwise(input)
  editable_rowwise <- data_table(rowwise, editable = TRUE)
  editable_rowwise$set_cell(1L, "value", "9")
  expected_rowwise <- dplyr::rowwise(
    tibble::tibble(group = c("a", "b", "a"), value = c(9L, 2L, 3L))
  )
  expect_identical(class(editable_rowwise$data), class(rowwise))
  expect_identical(dplyr::group_data(editable_rowwise$data), dplyr::group_data(expected_rowwise))
})

test_that("seeded typed-table operations preserve source values", {
  set.seed(20261030)
  source <- data.frame(
    id = seq_len(80L),
    amount = runif(80L, -100, 100),
    active = sample(c(TRUE, FALSE, NA), 80L, replace = TRUE),
    state = factor(sample(c("α", "界", "plain"), 80L, replace = TRUE)),
    day = as.Date("2020-01-01") + sample.int(1000L, 80L),
    stringsAsFactors = FALSE
  )
  original <- source
  table <- data_table(source, editable = TRUE, cursor = "cell")
  for (i in seq_len(60L)) {
    rows <- sample.int(nrow(source), 5L)
    cols <- sample(c("id", "amount", "active", "state", "day"), 1L)
    before <- table$data
    expect_length(table_format_values(table_slice(table$data[[cols]], rows), width = 16L), 5L)
    expect_identical(table$data, before)
    row <- sample.int(nrow(source), 1L)
    expect_error(table$set_cell(row, "id", "not-an-integer"), "whole number")
    expect_identical(table$data$id, before$id)
  }
  expect_identical(source, original)
})
