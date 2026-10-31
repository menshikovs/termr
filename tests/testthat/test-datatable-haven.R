test_that("labelled metadata exposes raw type, variable label and value labels", {
  skip_if_not_installed("haven")
  source <- haven::labelled(c(1L, 2L, NA_integer_), c(Male = 1L, Female = 2L),
                            label = "Participant sex")
  attr(source, "format.spss") <- "F8.0"
  attr(source, "display_width") <- 8L
  table <- data_table(data.frame(sex = source), show_types = TRUE, row_names = FALSE)
  info <- table$column_info()

  expect_match(info$type[[1L]], "int\\+lbl")
  expect_identical(info$base_type[[1L]], "integer")
  expect_identical(info$variable_label[[1L]], "Participant sex")
  expect_identical(info$value_labels[[1L]], attr(source, "labels"))
  expect_null(info$na_values[[1L]])
  expect_null(info$na_range[[1L]])
  expect_identical(info$class[[1L]], paste(class(source), collapse = "/"))
  expect_identical(info$typeof[[1L]], typeof(source))
  expect_identical(info$attributes[[1L]], attributes(info$prototype[[1L]]))
  expect_true(info$editable[[1L]])

  pilot <- test_app(app(table), width = 40, height = 6)
  on.exit(pilot$stop(), add = TRUE)
  expect_match(paste(pilot$screen_text(), collapse = "\n"), "int\\+lbl")
})

test_that("raw and label display modes both retain the source value", {
  skip_if_not_installed("haven")
  source <- haven::labelled(c(1L, 2L, 7L), c(Male = 1L, Female = 2L), label = "Sex")
  original <- source

  expect_identical(table_format_values(source, label_mode = "raw"), c("1", "2", "7"))
  expect_identical(table_format_values(source, label_mode = "labels"),
                   c("Male [1]", "Female [2]", "7"))

  table <- data_table(data.frame(sex = source),
                      columns = list(sex = column(label_mode = "labels")),
                      row_names = FALSE)
  expect_identical(table$.__enclos_env__$private$format_values(1L, 1:3),
                   c("Male [1]", "Female [2]", "7"))
  expect_identical(table$data$sex, original)
})

test_that("integer, double and character labelled columns retain storage type", {
  skip_if_not_installed("haven")
  values <- data.frame(
    integer_value = haven::labelled(c(1L, 2L), c(One = 1L, Two = 2L)),
    double_value = haven::labelled(c(1.5, 2.5), c(Low = 1.5, High = 2.5)),
    character_value = haven::labelled(c("M", "F"), c(Male = "M", Female = "F")),
    stringsAsFactors = FALSE
  )
  original <- values
  table <- data_table(values, editable = TRUE, columns = list(
    integer_value = column(label_mode = "labels"),
    double_value = column(label_mode = "labels"),
    character_value = column(label_mode = "labels")
  ))

  table$set_cell(1L, "integer_value", "Two")
  table$set_cell(1L, "double_value", "2.5")
  table$set_cell(2L, "character_value", "Male")
  table$set_cell(2L, "character_value", "raw:F")

  expect_identical(typeof(table$data$integer_value), "integer")
  expect_identical(typeof(table$data$double_value), "double")
  expect_identical(typeof(table$data$character_value), "character")
  expect_identical(class(table$data$integer_value), class(values$integer_value))
  expect_identical(attributes(table$data$integer_value), attributes(values$integer_value))
  expect_identical(attributes(table$data$double_value), attributes(values$double_value))
  expect_identical(attributes(table$data$character_value), attributes(values$character_value))
  expect_identical(as.vector(table$data$integer_value), c(2L, 2L))
  expect_identical(as.vector(table$data$double_value), c(2.5, 2.5))
  expect_identical(as.vector(table$data$character_value), c("M", "F"))
  expect_identical(values, original)
})

test_that("tagged NA tags, ordinary NA and NaN remain distinct", {
  skip_if_not_installed("haven")
  tagged <- haven::labelled(
    c(1, haven::tagged_na("a"), haven::tagged_na("z"), NA_real_, NaN),
    c(One = 1, Refused = haven::tagged_na("a"), Inapplicable = haven::tagged_na("z")),
    label = "Response"
  )
  original <- tagged

  expect_identical(table_format_values(tagged, label_mode = "raw"),
                   c("1", "NA(a)", "NA(z)", "NA", "NaN"))
  expect_identical(table_format_values(tagged, label_mode = "labels"),
                   c("One [1]", "Refused [NA(a)]", "Inapplicable [NA(z)]", "NA", "NaN"))

  table <- data_table(data.frame(response = tagged), editable = TRUE,
                      columns = list(response = column(label_mode = "labels")))
  table$set_cell(1L, "response", "NA(z)")
  table$set_cell(2L, "response", "NA(a)")
  table$set_cell(3L, "response", "NA")
  table$set_cell(4L, "response", "NaN")
  edited <- table$data$response
  expect_identical(haven::na_tag(edited), c("z", "a", NA_character_, NA_character_, NA_character_))
  expect_true(is.nan(as.vector(edited)[[5L]]))
  expect_true(is.na(as.vector(edited)[[4L]]) && !haven::is_tagged_na(as.vector(edited)[[4L]]))
  expect_identical(attributes(edited), attributes(original))
  expect_identical(haven::na_tag(original), c(NA_character_, "a", "z", NA_character_, NA_character_))

  table$sort("response")
  expect_identical(haven::na_tag(table$data$response), haven::na_tag(edited))
})

test_that("SPSS exact and ranged user missings remain raw values with metadata", {
  skip_if_not_installed("haven")
  exact <- haven::labelled_spss(c(1, 9, NA_real_), c(Valid = 1, Refused = 9),
                                na_values = 9, label = "Exact-missing question")
  ranged <- haven::labelled_spss(c(1, 90, 95, NA_real_), c(Valid = 1),
                                 na_range = c(90, 95), label = "Range-missing question")
  exact_table <- data_table(data.frame(answer = exact), editable = TRUE,
                            columns = list(answer = column(label_mode = "labels")))
  range_table <- data_table(data.frame(answer = ranged), editable = TRUE)
  exact_info <- exact_table$column_info()
  range_info <- range_table$column_info()

  expect_identical(exact_info$na_values[[1L]], 9)
  expect_null(exact_info$na_range[[1L]])
  expect_identical(range_info$na_range[[1L]], c(90, 95))
  expect_null(range_info$na_values[[1L]])
  expect_identical(table_format_values(exact, label_mode = "raw"),
                   c("1", "9 (SPSS missing)", "NA"))
  expect_identical(table_format_values(exact, label_mode = "labels"),
                   c("Valid [1]", "Refused [9] (SPSS missing)", "NA"))
  expect_identical(table_format_values(ranged, label_mode = "raw"),
                   c("1", "90 (SPSS missing)", "95 (SPSS missing)", "NA"))

  exact_attrs <- attributes(exact)
  exact_table$set_cell(1L, "answer", "9")
  expect_identical(as.vector(exact_table$data$answer), c(9, 9, NA_real_))
  expect_identical(is.na(exact_table$data$answer), c(TRUE, TRUE, TRUE))
  expect_identical(attributes(exact_table$data$answer), exact_attrs)
  exact_table$set_cell(1L, "answer", "2")
  expect_identical(as.vector(exact_table$data$answer), c(2, 9, NA_real_))
  expect_identical(attr(exact_table$data$answer, "na_values"), 9)
  expect_false(is.na(exact_table$data$answer[[1L]]))
})

test_that("duplicate labels are rejected and raw escapes are explicit", {
  skip_if_not_installed("haven")
  duplicate <- haven::labelled(c(1L, 2L, 3L),
                               stats::setNames(c(1L, 2L), c("Same", "Same")))
  table <- data_table(data.frame(value = duplicate), editable = TRUE)
  before <- table$data
  expect_error(table$set_cell(1L, "value", "Same"), "ambiguous")
  expect_identical(table$data, before)
  expect_error(table$set_cell(1L, "value", "Unknown label"), "label")
  table$set_cell(1L, "value", "raw:8")
  expect_identical(as.vector(table$data$value), c(8L, 2L, 3L))

  chars <- haven::labelled(c("M", "F"), c(Male = "M", Female = "F"))
  char_table <- data_table(data.frame(value = chars), editable = TRUE)
  before <- char_table$data
  expect_error(char_table$set_cell(1L, "value", "Unknown"), "raw:")
  expect_identical(char_table$data, before)
  char_table$set_cell(1L, "value", "raw:Unknown")
  expect_identical(as.vector(char_table$data$value), c("Unknown", "F"))
  expect_identical(attributes(char_table$data$value), attributes(chars))
})

test_that("label: resolves numeric label collisions explicitly", {
  skip_if_not_installed("haven")
  source <- haven::labelled(c(1L, 2L), c(`2` = 1L, `One` = 2L))
  table <- data_table(data.frame(value = source), editable = TRUE)

  expect_error(table$set_cell(1L, "value", "2"), "explicitly")
  table$set_cell(1L, "value", "label:2")
  expect_identical(as.vector(table$data$value), c(1L, 2L))
  table$set_cell(1L, "value", "raw:2")
  expect_identical(as.vector(table$data$value), c(2L, 2L))
})

test_that("malformed labelled metadata is inspectable but read-only", {
  skip_if_not_installed("haven")
  malformed <- haven::labelled(c(1L, 2L), c(One = 1L))
  attr(malformed, "labels") <- list(One = 1L)
  table <- data_table(data.frame(value = malformed), editable = TRUE)

  expect_false(table$column_info()$editable[[1L]])
  expect_identical(table_format_values(malformed), c("1", "2"))
  expect_error(table$set_cell(1L, "value", "raw:3"), "read-only")
  expect_identical(table$data$value, malformed)
})

test_that("empty, long and Unicode labelled metadata is preserved", {
  skip_if_not_installed("haven")
  empty <- haven::labelled(integer(), c(One = 1L), label = "Empty")
  empty_table <- data_table(data.frame(value = empty), show_types = TRUE)
  expect_identical(empty_table$row_count, 0L)
  expect_identical(empty_table$column_info()$value_labels[[1L]], attr(empty, "labels"))

  long_label <- paste(rep("long label", 20L), collapse = " ")
  unicode <- haven::labelled(c(1L, 2L, 3L),
                             c(stats::setNames(1L, long_label),
                               "M\u00e4dchen \u4e16\u754c" = 2L, "Gar\u00e7on" = 3L),
                             label = long_label)
  table <- data_table(data.frame(value = unicode),
                      columns = list(value = column(label_mode = "labels")),
                      max_column_width = 12L, show_types = TRUE)
  info <- table$column_info()
  expect_identical(info$variable_label[[1L]], long_label)
  expect_identical(info$value_labels[[1L]], attr(unicode, "labels"))
  expect_gt(nchar(names(info$value_labels[[1L]])[[1L]]), 100L)
  expect_true(grepl("M\u00e4dchen \u4e16\u754c", table_format_values(unicode, label_mode = "labels")[[2L]],
                    fixed = TRUE))
  pilot <- test_app(app(table), width = 24, height = 6)
  on.exit(pilot$stop(), add = TRUE)
  expect_true(grepl("M\u00e4dchen", paste(pilot$screen_text(), collapse = "\n"), fixed = TRUE))
})

test_that("fuzzed labelled edits preserve attributes or fail atomically", {
  skip_if_not_installed("haven")
  source <- haven::labelled(c(1L, 2L, 3L, NA_integer_),
                            c(Male = 1L, Female = 2L), label = "Fuzz")
  attr(source, "format.spss") <- "F2.0"
  attr(source, "display_width") <- 2L
  original <- source
  table <- data_table(data.frame(value = source, untouched = 1:4), editable = TRUE)
  inputs <- c("Male", "Female", "raw:3", "raw:8", "NA", "unknown")
  set.seed(22002)

  for (i in seq_len(100L)) {
    before <- table$data
    input <- sample(inputs, 1L)
    result <- tryCatch({
      table$set_cell(sample.int(4L, 1L), "value", input)
      TRUE
    }, error = function(e) FALSE)
    if (result) {
      expect_identical(typeof(table$data$value), typeof(source))
      expect_identical(class(table$data$value), class(source))
      expect_identical(attributes(table$data$value), attributes(source))
      expect_identical(table$data$untouched, before$untouched)
    } else {
      expect_identical(table$data, before)
    }
  }
  expect_identical(source, original)
})
