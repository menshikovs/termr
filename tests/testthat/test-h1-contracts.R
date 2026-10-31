test_that("failed pilot startup releases its registered app and driver", {
  before <- length(termr_env$apps)
  widget <- label("failure")
  widget$on("mount", function(...) stop("H1 mount error"))
  application <- app(widget)
  private <- application$.__enclos_env__$private
  on.exit(private$shutdown(), add = TRUE)

  expect_error(test_app(application), "H1 mount error")
  expect_false(private$.running)
  expect_null(private$.driver)
  expect_length(termr_env$apps, before)
})

test_that("source projection cache keys distinguish control characters in names", {
  values <- data.frame(a = seq_len(200L), b = 201:400, check.names = FALSE)
  values[["a\rb"]] <- 401:600
  source <- table_source(nrow(values), names(values), function(start, count, columns) {
    values[seq.int(start, length.out = count), columns, drop = FALSE]
  })
  table <- data_table(source, row_names = FALSE)
  application <- app(table)
  table$set_column_visible("a\rb", FALSE)
  table$scroll_to_row(101L)
  expect_no_error(render_widget(application, 70L, 10L))

  table$set_column_visible("a\rb", TRUE)
  table$set_column_visible("a", FALSE)
  table$set_column_visible("b", FALSE)
  expect_no_error(buffer <- render_widget(application, 70L, 10L))
  expect_match(paste(buffer$to_text(), collapse = "\n"), "501", fixed = TRUE)
})
