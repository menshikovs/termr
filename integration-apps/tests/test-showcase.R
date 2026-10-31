test_that('workbench global shortcuts avoid DataTable reserved bindings', {
  demo <- workbench_app()
  p <- termr::test_app(demo$app, width = 100, height = 30)
  on.exit({p$stop(); demo$close()}, add = TRUE)
  p$focus('#data'); p$press('alt+s')
  expect_true(demo$state$lazy)
  expect_identical(demo$table$row_count, 10000L)
  p$press('alt+c')
  expect_identical(p$query_one('#pages')$active, 2L)
})

test_that('workbench supports edit, rejection, selection, exports and typed fixtures', {
  demo <- workbench_app()
  p <- termr::test_app(demo$app, width = 100, height = 30)
  on.exit({p$stop(); demo$close()}, add = TRUE)
  original <- demo$table$data
  enter_text(p, 'edit-value', '12.5'); press_button(p, 'apply-edit')
  expect_identical(demo$table$data$value[[1L]], 12.5)
  expect_identical(demo$table$data[-1L, ], original[-1L, ])
  current <- demo$table$data
  enter_text(p, 'edit-value', 'not a number'); press_button(p, 'apply-edit')
  expect_identical(demo$table$data, current)
  enter_text(p, 'find-text', 'Merc'); press_button(p, 'find')
  expect_gt(demo$table$cursor_row, 1L)
  p$press('f7', 'f8')
  expect_identical(demo$state$last_code$status, 'exact')
  expect_true(nzchar(demo$app$clipboard))
  p$press('escape'); p$press('f9')
  expect_true(demo$state$last_code$status %in% c('exact', 'limited'))
  p$press('escape', 'f2', 'f2')
  expect_identical(demo$state$dataset, 'typed')
  expect_s3_class(demo$table$data$date, 'Date')
  expect_s3_class(demo$table$data$instant, 'POSIXct')
  expect_s3_class(demo$table$data$group, 'factor')
  info <- demo$table$column_info()
  expect_false(info$editable[info$name == 'custom'])
})

test_that('workbench narrow layouts, themes, chart modes and cleanup are usable', {
  for (ink in c(FALSE, requireNamespace('inkr', quietly = TRUE))) {
    demo <- workbench_app(use_inkr = ink, chart_mode = 'ascii')
    p <- termr::test_app(demo$app, width = 40, height = 18)
    tryCatch({
      expect_false(p$query_one('#sidebar')$visible)
      p$press('f2', 'f4', 'f10')
      expect_identical(demo$state$dataset, 'iris')
      expect_identical(demo$state$theme, 'light')
      p$resize(100, 30)
      expect_true(p$query_one('#sidebar')$visible)
      expect_length(p$screen_text(), 30L)
      p$press('alt+c')
      for (i in 1:5) {
        p$query_one('#chart-tabs')$activate(i)
        p$step()
        expect_length(p$screen_text(), 30L)
      }
      for (i in 1:80) demo$action('sample')
      p$advance(.02)
      expect_lte(length(demo$stream$history()), 64L)
      p$stop()
      expect_identical(demo$stream$subscriber_count(), 0L)
    }, finally = {p$stop(); demo$close()})
  }
})
