testthat::test_that("DataTable state machine preserves invariants across random sequences", {
  set.seed(42)
  initial_df <- data.frame(
    id = 1:20,
    name = paste0("Item_", letters[1:20]),
    val = round(runif(20, 10, 100), 1),
    category = rep(c("A", "B", "C", "D"), 5),
    stringsAsFactors = FALSE
  )

  dt <- data_table(initial_df, editable = TRUE)
  app_obj <- app(dt)
  pilot <- test_app(app_obj)

  actions <- c("sort_asc", "sort_desc", "filter_rows", "filter_clear",
               "edit_cell", "scroll_row", "goto_row",
               "select_row", "fail_source_switch", "ok_source_switch", "repro_export")

  # Perform 40 pseudo-random state transitions
  for (step in 1:40) {
    act <- sample(actions, 1)

    if (act == "sort_asc") {
      dt$sort("val", decreasing = FALSE)
    } else if (act == "sort_desc") {
      dt$sort("val", decreasing = TRUE)
    } else if (act == "filter_rows") {
      n_raw <- nrow(dt$data)
      pick_n <- max(1L, sample.int(n_raw, 1))
      chosen <- sample.int(n_raw, pick_n)
      dt$filter(chosen)
    } else if (act == "filter_clear") {
      dt$filter(NULL)
    } else if (act == "edit_cell") {
      priv <- dt$.__enclos_env__$private
      vr <- if (!is.null(priv$.view)) length(priv$.view) else nrow(dt$data)
      if (vr > 0) {
        row_target <- min(vr, max(1L, priv$.state$cursor_row))
        dt$set_cell(row_target, "name", paste0("Edit_", step))
      }
    } else if (act == "scroll_row") {
      priv <- dt$.__enclos_env__$private
      vr <- if (!is.null(priv$.view)) length(priv$.view) else nrow(dt$data)
      if (vr > 0) dt$scroll_to_row(sample.int(vr, 1))
    } else if (act == "goto_row") {
      priv <- dt$.__enclos_env__$private
      vr <- if (!is.null(priv$.view)) length(priv$.view) else nrow(dt$data)
      if (vr > 0) dt$goto_row(sample.int(vr, 1))
    } else if (act == "select_row") {
      priv <- dt$.__enclos_env__$private
      vr <- if (!is.null(priv$.view)) length(priv$.view) else nrow(dt$data)
      if (vr > 0) {
        r <- sample.int(vr, 1)
        dt$select_range(r, r)
      }
    } else if (act == "fail_source_switch") {
      bad_source <- table_source(
        column_names = c("id", "name", "val", "category"),
        get_rows = function(offset, limit) stop("Simulated backend crash"),
        row_count = function() stop("Simulated backend crash")
      )
      suppressWarnings(tryCatch(dt$set_data(bad_source), error = function(e) NULL))
    } else if (act == "ok_source_switch") {
      new_df <- data.frame(
        id = 101:115,
        name = paste0("New_", letters[1:15]),
        val = 1:15 * 1.5,
        category = rep(c("X", "Y", "Z"), 5),
        stringsAsFactors = FALSE
      )
      dt$set_data(new_df)
    } else if (act == "repro_export") {
      code_info <- dt$reproducible_code("pipeline")
      testthat::expect_true(code_info$status %in% c("exact", "unsupported"))
    }

    # Invariants check after every step
    priv <- dt$.__enclos_env__$private
    total_rows <- if (!is.null(priv$.view)) length(priv$.view) else nrow(dt$data)

    testthat::expect_true(is.data.frame(dt$data), info = paste("Step", step, act))
    testthat::expect_true(nrow(dt$data) > 0L, info = paste("Step", step, act))
    testthat::expect_true(priv$.state$cursor_row >= 1L, info = paste("Step", step, act))
    testthat::expect_true(priv$.state$cursor_col >= 0L, info = paste("Step", step, act))

    if (total_rows > 0) {
      testthat::expect_lte(priv$.state$cursor_row, total_rows, label = paste("Step", step, act))
    }

    # Render invariant: rendering the widget should not throw
    render_out <- tryCatch(dt$render(), error = function(e) e)
    testthat::expect_false(inherits(render_out, "error"), info = paste("Step", step, act))
  }
})

testthat::test_that("App widget tree dynamic lifecycle transitions maintain consistency", {
  c1 <- vertical(id = "c1")
  b1 <- button("B1", id = "b1")
  b2 <- button("B2", id = "b2")
  in1 <- input("initial", id = "in1")
  c1$mount(b1, b2, in1)

  a <- app(c1)
  p <- test_app(a)

  # Initial focus should be on b1
  testthat::expect_identical(a$focused, b1)

  # Dynamic removal of currently focused widget
  b1$remove()
  testthat::expect_null(b1$app)
  testthat::expect_false(identical(a$focused, b1))

  # Ensure event queue processes blur and moves focus
  p$step()
  testthat::expect_identical(a$focused, b2)

  # Reparenting: mount b1 back under another container
  c2 <- vertical(id = "c2")
  c1$mount(c2)
  c2$mount(b1)
  testthat::expect_identical(b1$app, a)
  testthat::expect_identical(b1$parent, c2)

  # Disable container and verify focus escapes disabled branch
  a$set_focus(b1)
  testthat::expect_identical(a$focused, b1)
  c2$disabled <- TRUE
  testthat::expect_false(b1$is_enabled())

  # Next key navigation should skip disabled branch
  p$press("tab")
  testthat::expect_false(identical(a$focused, b1))
  testthat::expect_true(a$focused$is_enabled())

  # Timer lifecycle: widget timer cancelled when removed
  timer_fired <- FALSE
  b2_timer <- b2$set_timeout(0.01, function(w, app) {
    timer_fired <<- TRUE
  })
  b2$remove()
  p$advance(0.05)
  # Timer attached to b2 must not fire after removal
  testthat::expect_false(timer_fired)
})

testthat::test_that("Adversarial nested focus transfers and disabled subtree handling", {
  b_top <- button("Top", id = "top")
  b_mid1 <- button("Mid1", id = "m1", disabled = TRUE)
  b_mid2 <- button("Mid2", id = "m2", disabled = TRUE)
  v_mid <- vertical(b_mid1, b_mid2, id = "mid")
  b_bot <- button("Bot", id = "bot")
  root <- vertical(b_top, v_mid, b_bot)
  a <- app(root)
  p <- test_app(a)

  testthat::expect_identical(a$focused, b_top)

  # Pressing Tab should skip all disabled buttons in v_mid and reach b_bot directly
  p$press("tab")
  testthat::expect_identical(a$focused, b_bot)

  # Pressing Tab from b_bot should wrap around to b_top, skipping disabled mid
  p$press("tab")
  testthat::expect_identical(a$focused, b_top)

  # Dynamically enable b_mid2
  b_mid2$disabled <- FALSE
  p$press("tab")
  testthat::expect_identical(a$focused, b_mid2)
})
