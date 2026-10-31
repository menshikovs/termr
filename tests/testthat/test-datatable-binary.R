test_that("raw byte columns use bounded uppercase hex and stay read-only", {
  bytes <- as.raw(c(0x00, 0xFF, 0x1B, 0x80))

  expect_identical(table_format_values(raw()), character())
  expect_identical(table_raw_preview(raw()), "0 bytes")
  expect_identical(table_format_values(bytes), c(
    "1 byte: 00", "1 byte: FF", "1 byte: 1B", "1 byte: 80"
  ))
  expect_identical(table_missing_mask(bytes), rep(FALSE, length(bytes)))

  long <- as.raw(0:31)
  preview <- table_raw_preview(long)
  expect_identical(preview, "32 bytes: 00 01 02 03 04 05 06 07 ...")
  expect_lte(str_width(table_raw_preview(long, width = 12L)), 12L)
  expect_false(grepl("\033", preview, fixed = TRUE))
  expect_false(grepl("[[:cntrl:]]", preview))

  source <- data.frame(payload = bytes)
  table <- data_table(source, editable = TRUE)
  info <- table$column_info()
  expect_identical(info$type, "raw")
  expect_identical(info$class, "raw")
  expect_identical(info$editable, FALSE)
  expect_identical(info$sortable, FALSE)
  expect_identical(info$allows_missing, FALSE)
  expect_error(table$set_cell(1L, "payload", "FF"), "read-only")
  expect_error(table$sort("payload"), "Sorting is not supported")
  expect_identical(table$data$payload, bytes)
  expect_identical(source$payload, bytes)
})

test_that("raw elements in list columns stay bounded and retain missing semantics", {
  payload <- I(list(
    raw(),
    as.raw(c(0xDE, 0xAD, 0xBE, 0xEF)),
    as.raw(0:11),
    NULL,
    NA_real_,
    list(as.raw(c(0x00, 0x1B)))
  ))
  source <- data.frame(payload = payload)
  table <- data_table(source, editable = TRUE)

  expect_identical(table_format_values(source$payload), c(
    "0 bytes",
    "4 bytes: DE AD BE EF",
    "12 bytes: 00 01 02 03 04 05 06 07 ...",
    "<NULL>",
    "NA",
    "<list[1]>"
  ))
  expect_identical(table$column_info()$type, "list<raw>")
  expect_identical(table_missing_mask(source$payload), c(FALSE, FALSE, FALSE, TRUE, TRUE, FALSE))
  expect_identical(table$column_info()$editable, FALSE)
  expect_error(table$set_cell(2L, "payload", "DE AD"), "read-only")

  table$filter_columns(list(payload = table_filter("missing")))
  expect_identical(table$view, c(4L, 5L))
  table$filter_columns(list(payload = table_filter("contains", "DE AD")))
  expect_identical(table$view, 2L)
  expect_identical(source$payload[[2L]], as.raw(c(0xDE, 0xAD, 0xBE, 0xEF)))
})

test_that("blob columns display raw elements without requiring blob for termr", {
  skip_if_not_installed("blob")
  payload <- blob::new_blob(list(
    raw(),
    as.raw(c(0x00, 0xFF, 0x1B, 0xC3)),
    NULL
  ))
  source <- data.frame(payload = payload)
  table <- data_table(source, editable = TRUE, show_types = TRUE)

  expect_identical(table_format_values(payload), c(
    "0 bytes", "4 bytes: 00 FF 1B C3", "<NULL>"
  ))
  info <- table$column_info()
  expect_identical(info$type, "blob")
  expect_true(grepl("^blob", info$class))
  expect_identical(info$editable, FALSE)
  expect_identical(info$sortable, FALSE)
  expect_identical(table_missing_mask(payload), c(FALSE, FALSE, TRUE))
  expect_error(table$set_cell(1L, "payload", "00"), "read-only")
  expect_identical(table$data$payload, source$payload)
  expect_identical(format_metric(payload[2L]), "4 bytes: 00 FF 1B C3")
})

test_that("the blob adapter only relies on its public list-of-raw shape", {
  payload <- structure(list(raw(), as.raw(c(0xCA, 0xFE)), NULL), class = "blob")
  source <- data.frame(payload = I(payload))
  table <- data_table(source, editable = TRUE)

  expect_identical(table_format_values(payload), c("0 bytes", "2 bytes: CA FE", "<NULL>"))
  expect_identical(table$column_info()$type, "blob")
  expect_identical(table$column_info()$editable, FALSE)
  expect_identical(table_missing_mask(payload), c(FALSE, FALSE, TRUE))
  expect_error(table$set_cell(2L, "payload", "00"), "read-only")
  expect_identical(table$data$payload, source$payload)
})

test_that("random binary payloads never leak control bytes or exceed the preview", {
  set.seed(20261030)
  for (i in seq_len(100L)) {
    size <- sample.int(512L, 1L) - 1L
    payload <- as.raw(sample.int(256L, size, replace = TRUE) - 1L)
    before <- payload
    text <- table_raw_preview(payload)

    expect_length(text, 1L)
    if (!size) {
      expect_identical(text, "0 bytes")
    } else {
      expect_match(text, "^[0-9]+ bytes?: (?:[0-9A-F]{2}(?: [0-9A-F]{2}){0,7})(?: ...)?$")
    }
    expect_false(grepl("[[:cntrl:]]", text))
    preview <- sub("^[0-9]+ bytes?: ", "", text)
    tokens <- strsplit(preview, " ", fixed = TRUE)[[1L]]
    expect_lte(sum(grepl("^[0-9A-F]{2}$", tokens)), 8L)
    expect_identical(payload, before)
  }
})

test_that("the rendered table and row details do not emit raw terminal bytes", {
  payload <- as.raw(c(0x1B, 0x00, 0xFF, 0xC3))
  table <- data_table(data.frame(payload = payload), show_types = TRUE)
  pilot <- test_app(app(table), width = 48L, height = 6L)
  on.exit(pilot$stop(), add = TRUE)

  screen <- paste(pilot$screen_text(), collapse = "\n")
  expect_match(screen, "1 byte: 1B")
  expect_false(grepl("\033", screen, fixed = TRUE))
  expect_match(format_metric(payload[[1L]]), "1 byte: 1B")
})
