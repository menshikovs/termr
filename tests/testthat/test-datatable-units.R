test_that("units columns expose their unit metadata and compact header", {
  skip_if_not_installed("units")
  distance <- units::set_units(c(1.25, 2.5), "m", mode = "standard")
  table <- data_table(data.frame(distance = distance), show_types = TRUE,
                      row_names = FALSE)
  info <- table$column_info()

  expect_match(info$type[[1L]], "\\[m\\]")
  expect_identical(info$class[[1L]], paste(class(distance), collapse = "/"))
  expect_identical(info$typeof[[1L]], typeof(distance))
  expect_true(info$editable[[1L]])
  expect_identical(base::units(info$prototype[[1L]]), base::units(distance))
  expect_identical(info$attributes[[1L]], attributes(info$prototype[[1L]]))

  pilot <- test_app(app(table), width = 32, height = 6)
  on.exit(pilot$stop(), add = TRUE)
  expect_match(paste(pilot$screen_text(), collapse = "\n"), "\\[m\\]")
})

test_that("temperature unit metadata preserves Unicode display labels", {
  skip_if_not_installed("units")
  temperature <- units::set_units(c(20, 21), "degC", mode = "standard")
  table <- data_table(data.frame(temperature = temperature), show_types = TRUE)
  info <- table$column_info()

  expect_true(grepl("\u00b0C", info$type[[1L]], fixed = TRUE))
  pilot <- test_app(app(table), width = 40, height = 6)
  on.exit(pilot$stop(), add = TRUE)
  expect_true(grepl("\u00b0C", paste(pilot$screen_text(), collapse = "\n"), fixed = TRUE))
})

test_that("units formatting preserves special values and stays slice bounded", {
  skip_if_not_installed("units")
  values <- units::set_units(c(NA_real_, NaN, Inf, -Inf, 1.25, 2.5),
                             "m/s^2", mode = "standard")
  selected <- table_slice(values, c(2L, 4L, 5L))
  formatted <- table_format_values(selected, width = 12L)

  expect_length(formatted, 3L)
  expect_identical(formatted[1L], "NaN")
  expect_identical(formatted[2L], "-Inf")
  expect_identical(as.numeric(formatted[[3L]]), 1.25)
  expect_false(any(grepl("\\[m", formatted)))
  expect_identical(class(selected), class(values))
  expect_identical(base::units(selected), base::units(values))
})

test_that("units edits convert compatible input and preserve the column prototype", {
  skip_if_not_installed("units")
  source <- data.frame(
    distance = units::set_units(c(1, 2), "m", mode = "standard"),
    count = c(3L, 4L)
  )
  original <- source
  original_attributes <- attributes(source$distance)
  table <- data_table(source, editable = TRUE)

  table$set_cell(1L, "distance", "12.5")
  table$set_cell(2L, "distance", "125 cm")
  expect_identical(class(table$data$distance), class(source$distance))
  expect_identical(attributes(table$data$distance), original_attributes)
  expect_equal(as.numeric(units::drop_units(table$data$distance)), c(12.5, 1.25),
               tolerance = 1e-12)
  expect_identical(table$data$count, source$count)
  expect_identical(source, original)

  table$set_cell(1L, "distance", "NA")
  expect_true(is.na(table$data$distance[[1L]]))
  expect_identical(attributes(table$data$distance), original_attributes)
  before <- table$data
  expect_error(table$set_cell(2L, "distance", "2 kg"), "incompatible")
  expect_identical(table$data, before)
  expect_error(table$set_cell(2L, "distance", "2 termr_unknown_unit"), "unit")
  expect_identical(table$data, before)
  expect_error(table$set_cell(2L, "distance", "1e308 km"), "range")
  expect_identical(table$data, before)

  tiny <- data_table(data.frame(distance = units::set_units(c(1, 2), "km", mode = "standard")),
                     editable = TRUE)
  tiny_before <- tiny$data
  expect_error(tiny$set_cell(1L, "distance", "4.9406564584124654e-324 m"), "precision")
  expect_identical(tiny$data, tiny_before)
})

test_that("units parser keeps NA, NaN and infinities as typed measurements", {
  skip_if_not_installed("units")
  template <- units::set_units(1, "m", mode = "standard")
  expected <- list(NA_real_, NaN, Inf, -Inf)
  input <- c("NA", "NaN", "Inf", "-Inf")
  for (i in seq_along(input)) {
    parsed <- parse_cell(input[[i]], template)
    expect_null(parsed$error)
    expect_identical(class(parsed$value), class(template))
    expect_identical(base::units(parsed$value), base::units(template))
    actual <- as.numeric(units::drop_units(parsed$value))
    if (is.nan(expected[[i]])) expect_true(is.nan(actual)) else expect_identical(actual, expected[[i]])
  }
  formatted <- table_format_values(units::set_units(unlist(expected), "m", mode = "standard"))
  expect_identical(formatted, c("NA", "NaN", "Inf", "-Inf"))
})

test_that("compatible unit conversions satisfy seeded round-trip properties", {
  skip_if_not_installed("units")
  groups <- list(
    c("m", "km", "cm"),
    c("kg", "g"),
    c("m/s", "km/h"),
    c("m^2", "km^2"),
    c("m^3", "L"),
    c("degC", "degF", "K"),
    c("1", "%")
  )
  set.seed(21001)
  for (group in groups) {
    for (i in seq_len(20L)) {
      from <- sample(group, 1L)
      to <- sample(group, 1L)
      amount <- stats::runif(1L, -100, 100)
      if (all(group %in% c("degC", "degF", "K"))) amount <- stats::runif(1L, -50, 250)
      target <- units::set_units(1, to, mode = "standard")
      source <- units::set_units(amount, from, mode = "standard")
      expected <- units::set_units(source, base::units(target), mode = "standard")
      parsed <- parse_cell(sprintf("%.17g %s", amount, from), target)

      expect_null(parsed$error, info = paste(from, "to", to))
      expect_identical(class(parsed$value), class(target))
      expect_identical(base::units(parsed$value), base::units(target))
      expect_equal(as.numeric(units::drop_units(parsed$value)),
                   as.numeric(units::drop_units(expected)), tolerance = 1e-10,
                   info = paste(from, "to", to))
    }
  }
})

test_that("registered custom units format and convert through units APIs", {
  skip_if_not_installed("units")
  symbol <- "termrtestunit"
  units::install_unit(symbol = symbol, def = "201.168 m", name = symbol)
  on.exit(units::remove_unit(symbol = symbol, name = symbol), add = TRUE)

  template <- units::set_units(1, "m", mode = "standard")
  parsed <- parse_cell(paste("1", symbol), template)
  expect_null(parsed$error)
  expect_equal(as.numeric(units::drop_units(parsed$value)), 201.168,
               tolerance = 1e-12)

  custom <- units::set_units(1, symbol, mode = "standard")
  info <- data_table(data.frame(measure = custom))$column_info()
  expect_match(info$type[[1L]], symbol, fixed = TRUE)
})

test_that("units edits retain representable double precision", {
  skip_if_not_installed("units")
  input <- "12.500000000000002"
  source <- data.frame(quantity = units::set_units(c(1, 2), "m", mode = "standard"))
  table <- data_table(source, editable = TRUE)
  table$set_cell(1L, "quantity", input)
  expect_type(table$data$quantity, "double")
  expect_identical(as.numeric(units::drop_units(table$data$quantity[[1L]])),
                   as.double(input))

  before <- table$data
  expect_error(table$set_cell(1L, "quantity", "not-a-number"), "number")
  expect_identical(table$data, before)
})
