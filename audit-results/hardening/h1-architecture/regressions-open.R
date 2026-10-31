# Expected to fail until the corresponding H2 findings are addressed.
# This file is outside tests/testthat so unresolved audit findings do not
# silently change the package's passing regression suite.
testthat::test_that("H1-F01 failed source replacement preserves the active source", {
  table <- data_table(data.frame(x = 1:3))
  old_source <- table$.__enclos_env__$private$.source
  bad <- table_source(function() NA_real_, "x", function(...) data.frame(x = integer()))
  testthat::expect_error(table$set_data(bad), "row_count")
  testthat::expect_identical(table$.__enclos_env__$private$.source, old_source)
})

testthat::test_that("H1-F02 an exact pipeline reproduces the displayed post-edit order", {
  table <- data_table(data.frame(x = 1:3), editable = TRUE)
  table$sort("x")
  table$set_cell(1L, "x", "10")
  result <- table$reproducible_code("pipeline")
  expected <- table$data[table$view, , drop = FALSE]
  actual <- eval(parse(text = result$code), list2env(list(data = table$data), parent = globalenv()))
  testthat::expect_identical(actual, expected)
})

# F03 tests a proposed stronger liveness contract than the documented drain-only policy.
testthat::test_that("H1-F03 chart display advances while a bounded backlog persists", {
  source <- termr_stream(history = 0L)
  chart <- line_chart(numeric(), numeric(), interactive = FALSE)
  pilot <- test_app(app(chart))
  on.exit({pilot$stop(); source$close()}, add = TRUE)
  chart$bind_stream(source, function(e) e$x, function(e) e$y, max_points = 100L)
  sequence <- 0L
  emit <- function(n) for (i in seq_len(n)) {
    sequence <<- sequence + 1L
    source$emit(list(x = sequence, y = sequence))
  }
  emit(64L); pilot$step()
  for (i in seq_len(8L)) { emit(16L); pilot$advance(.001) }
  testthat::expect_gt(length(chart$.__enclos_env__$private$.spec$data$x), 0L)
})

# F04 records a candidate mid-dispatch lifecycle policy; current docs do not settle it.
testthat::test_that("H1-F04 detached ancestors do not receive ordinary bubbled messages", {
  child <- button("Child")
  parent <- vertical(child)
  pilot <- test_app(app(parent))
  on.exit(pilot$stop(), add = TRUE)
  delivered <- 0L
  child$on("audit.probe", function(...) parent$remove())
  parent$on("audit.probe", function(...) delivered <<- delivered + 1L)
  child$post_message("audit.probe")
  pilot$step()
  testthat::expect_identical(delivered, 0L)
})

testthat::test_that("H1-F08 an unmounted owned SQL connection is eventually released", {
  testthat::skip_if_not_installed("DBI")
  testthat::skip_if_not_installed("RSQLite")
  con <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
  on.exit(if (DBI::dbIsValid(con)) DBI::dbDisconnect(con), add = TRUE)
  editor <- sql_editor("SELECT 1", connection = db_connection(con, owned = TRUE))
  pilot <- test_app(app(editor))
  editor$remove(); pilot$stop()
  testthat::expect_false(DBI::dbIsValid(con))
})

testthat::test_that("H1-F09 log capacity rejects non-finite input before app startup", {
  application <- app(label("x"))
  testthat::expect_error(suppressWarnings(application$log_events(size = Inf)), "size")
})
