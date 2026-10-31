test_that("H2-F01 atomic table source replacement preserves active source on error", {
  # 1. Base table with data
  original_df <- data.frame(id = 1:5, val = c("a", "b", "c", "d", "e"), stringsAsFactors = FALSE)
  tbl <- data_table(original_df, editable = TRUE)
  tbl$set_cell(1L, "val", "alpha")
  expect_identical(tbl$row_data(1L)$val, "alpha")

  # 2. Candidate source fails at row_count()
  bad_count_src <- table_source(
    row_count = function() NA_real_,
    column_names = function() c("id", "val"),
    get_rows = function(...) original_df
  )
  expect_error(tbl$set_data(bad_count_src), "row_count")
  expect_null(tbl$.__enclos_env__$private$.source)
  expect_identical(tbl$row_data(1L)$val, "alpha")
  expect_identical(tbl$row_count, 5L)

  # 3. Candidate source fails at column_names()
  bad_names_src <- table_source(
    row_count = function() 5L,
    column_names = function() character(),
    get_rows = function(...) original_df
  )
  expect_error(tbl$set_data(bad_names_src), "column_names")
  expect_null(tbl$.__enclos_env__$private$.source)
  expect_identical(tbl$row_data(1L)$val, "alpha")

  # 4. Candidate source fails at seed page fetch (without on_error)
  bad_fetch_src <- table_source(
    row_count = function() 5L,
    column_names = function() c("id", "val"),
    get_rows = function(...) stop("network timeout")
  )
  expect_error(tbl$set_data(bad_fetch_src), "network timeout")
  expect_null(tbl$.__enclos_env__$private$.source)
  expect_identical(tbl$row_data(1L)$val, "alpha")

  # 5. Candidate source returns malformed seed page
  bad_shape_src <- table_source(
    row_count = function() 5L,
    column_names = function() c("id", "val"),
    get_rows = function(...) data.frame(id = 1:2)
  )
  expect_error(tbl$set_data(bad_shape_src), "rows|column")
  expect_null(tbl$.__enclos_env__$private$.source)
  expect_identical(tbl$row_data(1L)$val, "alpha")

  # 6. Candidate source has unknown columns when table options specify column options
  opt_tbl <- data_table(original_df, columns = list(val = column(width = 10L)))
  bad_cols_src <- table_source(
    row_count = function() 5L,
    column_names = function() c("id", "other"),
    get_rows = function(start, count, cols) data.frame(id = seq.int(start, length.out = count), other = 1:count)
  )
  expect_error(opt_tbl$set_data(bad_cols_src), "Unknown column")
  expect_identical(opt_tbl$column_names, c("id", "val"))

  # 7. Successful source replacement followed by a failed replacement (state machine sequence)
  valid_df1 <- data.frame(x = 10:12)
  valid_src1 <- table_source(
    row_count = function() 3L,
    column_names = function() "x",
    get_rows = function(start, count, cols) valid_df1[seq.int(start, length.out = count), cols, drop = FALSE]
  )
  tbl$set_data(valid_src1)
  expect_identical(tbl$.__enclos_env__$private$.source, valid_src1)
  expect_identical(tbl$row_data(1L)$x, 10L)

  # Now switch to failing source
  expect_error(tbl$set_data(bad_count_src), "row_count")
  # Active source must still be valid_src1, NOT bad_count_src or corrupted
  expect_identical(tbl$.__enclos_env__$private$.source, valid_src1)
  expect_identical(tbl$row_data(1L)$x, 10L)
  expect_identical(tbl$row_count, 3L)

  # Now switch to valid source 2
  valid_df2 <- data.frame(y = 100:104)
  valid_src2 <- table_source(
    row_count = function() 5L,
    column_names = function() "y",
    get_rows = function(start, count, cols) valid_df2[seq.int(start, length.out = count), cols, drop = FALSE]
  )
  tbl$set_data(valid_src2)
  expect_identical(tbl$.__enclos_env__$private$.source, valid_src2)
  expect_identical(tbl$column_names, "y")
  expect_identical(tbl$row_data(1L)$y, 100L)
  expect_identical(tbl$row_count, 5L)
})

test_that("H2-F02 exact pipeline reproducibility across sorting and editing scenarios", {
  eval_pipe <- function(tbl, bindings = list(data = tbl$data)) {
    code_res <- tbl$reproducible_code("pipeline")
    expect_identical(code_res$status, "exact")
    expect_true(is.character(code_res$code) && nzchar(code_res$code))
    parsed <- parse(text = code_res$code)
    env <- list2env(bindings, parent = globalenv())
    eval(parsed, envir = env)
  }

  # Scenario 1: Sort -> edit
  t1 <- data_table(data.frame(x = c(3L, 1L, 2L)), editable = TRUE)
  t1$sort("x")
  expect_identical(t1$data$x[t1$view], c(1L, 2L, 3L))
  t1$set_cell(2L, "x", "10")
  expected1 <- t1$data[t1$view, , drop = FALSE]
  actual1 <- eval_pipe(t1)
  expect_identical(actual1, expected1)

  # Scenario 2: Edit -> sort
  t2 <- data_table(data.frame(x = c(3L, 1L, 2L)), editable = TRUE)
  t2$set_cell(2L, "x", "10")
  t2$sort("x")
  expected2 <- t2$data[t2$view, , drop = FALSE]
  actual2 <- eval_pipe(t2)
  expect_identical(actual2, expected2)

  # Scenario 3: Filter -> edit -> sort
  t3 <- data_table(data.frame(cat = c("a", "b", "a", "b"), val = c(10, 20, 30, 40)), editable = TRUE)
  t3$filter_columns(list(cat = table_filter("equals", "a")))
  t3$set_cell(1L, "val", "50")
  t3$sort("val", decreasing = TRUE)
  expected3 <- t3$data[t3$view, , drop = FALSE]
  actual3 <- eval_pipe(t3)
  expect_identical(actual3, expected3)

  # Scenario 4: Sort -> edit -> reverse sort
  t4 <- data_table(data.frame(k = c(1, 2, 3)), editable = TRUE)
  t4$sort("k")
  t4$set_cell(1L, "k", "5")
  t4$sort("k", decreasing = TRUE)
  expected4 <- t4$data[t4$view, , drop = FALSE]
  actual4 <- eval_pipe(t4)
  expect_identical(actual4, expected4)

  # Scenario 5: Edit sort-key column repeatedly
  t5 <- data_table(data.frame(x = 1:4), editable = TRUE)
  t5$sort("x")
  t5$set_cell(1L, "x", "99")
  t5$set_cell(2L, "x", "100")
  expected5 <- t5$data[t5$view, , drop = FALSE]
  actual5 <- eval_pipe(t5)
  expect_identical(actual5, expected5)

  # Scenario 6: Multiple edits to one row
  t6 <- data_table(data.frame(a = c(1L, 2L), b = c(10L, 20L)), editable = TRUE)
  t6$sort("a")
  t6$set_cell(1L, "a", "5")
  t6$set_cell(1L, "b", "50")
  expected6 <- t6$data[t6$view, , drop = FALSE]
  actual6 <- eval_pipe(t6)
  expect_identical(actual6, expected6)

  # Scenario 7: Duplicate sort keys
  t7 <- data_table(data.frame(grp = c(1, 1, 1, 2), v = c("c", "a", "b", "d"), stringsAsFactors = FALSE), editable = TRUE)
  t7$sort(c("grp", "v"))
  t7$set_cell(2L, "v", "z")
  expected7 <- t7$data[t7$view, , drop = FALSE]
  actual7 <- eval_pipe(t7)
  expect_identical(actual7, expected7)

  # Scenario 8: NA sort keys
  t8 <- data_table(data.frame(x = c(2, NA, 1, 3)), editable = TRUE)
  t8$sort("x")
  t8$set_cell(2L, "x", "0")
  expected8 <- t8$data[t8$view, , drop = FALSE]
  actual8 <- eval_pipe(t8)
  expect_identical(actual8, expected8)

  # Scenario 9: Non-syntactic column names
  hostile_df <- data.frame(
    `a b` = c(3, 1, 2),
    `x"y'` = c("m", "n", "o"),
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  t9 <- data_table(hostile_df, editable = TRUE)
  t9$sort("a b")
  t9$set_cell(1L, "a b", "10")
  expected9 <- t9$data[t9$view, , drop = FALSE]
  actual9 <- eval_pipe(t9)
  expect_identical(actual9, expected9)

  # Scenario 10: Edit after column reorder
  t10 <- data_table(data.frame(a = 1:3, b = 4:6), editable = TRUE)
  t10$reorder_column("b", 1L)
  t10$sort("a")
  t10$set_cell(1L, "a", "10")
  vis_cols <- names(t10$data)[t10$.__enclos_env__$private$visible_columns()]
  expected10 <- t10$data[t10$view, vis_cols, drop = FALSE]
  actual10 <- eval_pipe(t10)
  expect_identical(actual10, expected10)
})

test_that("H2-F08 SQLEditor and DatabaseExplorer DBI connection lifecycle", {
  skip_if_not_installed("DBI")
  skip_if_not_installed("RSQLite")

  # 1. Owned connection closed on widget removal
  con1 <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
  ed1 <- sql_editor("SELECT 1", connection = db_connection(con1, owned = TRUE))
  p1 <- test_app(app(ed1))
  expect_true(DBI::dbIsValid(con1))
  ed1$remove()
  expect_false(DBI::dbIsValid(con1))
  p1$stop()
  expect_false(DBI::dbIsValid(con1))

  # 2. Owned connection closed on App shutdown without prior widget removal
  con2 <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
  ed2 <- sql_editor("SELECT 1", connection = db_connection(con2, owned = TRUE))
  p2 <- test_app(app(ed2))
  expect_true(DBI::dbIsValid(con2))
  p2$stop()
  expect_false(DBI::dbIsValid(con2))

  # 3. Borrowed connection survives widget removal and App shutdown
  con3 <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
  on.exit(if (DBI::dbIsValid(con3)) DBI::dbDisconnect(con3), add = TRUE)
  ed3 <- sql_editor("SELECT 1", connection = db_connection(con3, owned = FALSE))
  p3 <- test_app(app(ed3))
  expect_true(DBI::dbIsValid(con3))
  ed3$remove()
  expect_true(DBI::dbIsValid(con3))
  p3$stop()
  expect_true(DBI::dbIsValid(con3))

  # 4. Two editors sharing a borrowed connection
  con4 <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
  on.exit(if (DBI::dbIsValid(con4)) DBI::dbDisconnect(con4), add = TRUE)
  borrowed4 <- db_connection(con4, owned = FALSE)
  ed4a <- sql_editor("SELECT 1", connection = borrowed4)
  ed4b <- sql_editor("SELECT 2", connection = borrowed4)
  p4 <- test_app(app(vertical(ed4a, ed4b)))
  ed4a$remove()
  expect_true(DBI::dbIsValid(con4))
  ed4b$remove()
  expect_true(DBI::dbIsValid(con4))
  p4$stop()
  expect_true(DBI::dbIsValid(con4))

  # 5. DatabaseExplorer owned connection closed on removal
  con5 <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
  DBI::dbWriteTable(con5, "tbl", data.frame(a = 1:3))
  exp5 <- db_explorer(db_connection(con5, owned = TRUE))
  p5 <- test_app(app(exp5))
  expect_true(DBI::dbIsValid(con5))
  exp5$remove()
  expect_false(DBI::dbIsValid(con5))
  p5$stop()
  expect_false(DBI::dbIsValid(con5))

  # 6. Idempotent double close does not throw
  con6 <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
  wrapper6 <- db_connection(con6, owned = TRUE)
  expect_true(wrapper6$disconnect())
  expect_false(wrapper6$disconnect())
  expect_false(wrapper6$is_valid())
})

test_that("H2-F09 check_count boundary parameter validation matrix", {
  expect_null(check_count(NULL, "param"))
  expect_identical(check_count(0, "param"), 0L)
  expect_identical(check_count(0L, "param"), 0L)
  expect_identical(check_count(42, "param"), 42L)
  expect_identical(check_count(42L, "param"), 42L)
  expect_identical(check_count(.Machine$integer.max, "param"), as.integer(.Machine$integer.max))

  # Non-finite and extreme values
  expect_error(check_count(Inf, "param"), "param")
  expect_error(check_count(-Inf, "param"), "param")
  expect_error(check_count(NaN, "param"), "param")
  expect_error(check_count(NA_real_, "param"), "param")
  expect_error(check_count(NA_integer_, "param"), "param")
  expect_error(check_count(-1, "param"), "param")
  expect_error(check_count(-1L, "param"), "param")

  # Fractional
  expect_error(check_count(1.5, "param"), "param")
  expect_error(check_count(0.1, "param"), "param")

  # Overflow > .Machine$integer.max
  expect_error(check_count(2^31, "param"), "param")
  expect_error(check_count(1e15, "param"), "param")

  # Bad types and lengths
  expect_error(check_count("10", "param"), "param")
  expect_error(check_count(c(1, 2), "param"), "param")
  expect_error(check_count(integer(), "param"), "param")

  # App$log_events validation
  application <- app(label("x"))
  expect_error(application$log_events(size = Inf), "size")
  expect_error(application$log_events(size = -5), "size")
  expect_error(application$log_events(size = 1.2), "size")
  expect_no_error(application$log_events(size = 500L))
  expect_no_error(application$log_events(size = NULL))
})

test_that("H2-F03 chart stream drain contract and backlog recovery", {
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

  emit(64L)
  pilot$step()
  state <- chart$.__enclos_env__$private$.stream_state
  expect_true(state$flush_scheduled)
  expect_false(state$pending_render)
  expect_length(chart$.__enclos_env__$private$.spec$data$x, 16L)
  pilot$advance(0.05)
  displayed_pts <- length(chart$.__enclos_env__$private$.spec$data$x)
  expect_gt(displayed_pts, 0L)
  expect_lte(displayed_pts, 100L)
})

test_that("H2-F04 detached ancestors do not receive ordinary bubbled messages", {
  child <- button("Child")
  parent <- vertical(child)
  pilot <- test_app(app(parent))
  on.exit(pilot$stop(), add = TRUE)
  delivered <- 0L
  child$on("audit.probe", function(...) parent$remove())
  parent$on("audit.probe", function(...) delivered <<- delivered + 1L)
  child$post_message("audit.probe")
  pilot$step()
  expect_identical(delivered, 0L)
})
