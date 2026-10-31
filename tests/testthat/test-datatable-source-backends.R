test_that("dbplyr lazy tables are rejected without calling collect", {
  skip_if_not_installed("dbplyr")

  lazy <- dbplyr::tbl_lazy(
    data.frame(id = 1:3),
    con = dbplyr::simulate_sqlite()
  )

  expect_s3_class(lazy, "tbl_lazy")
  expect_error(data_table(lazy), "must be a data frame or a matrix")
})

test_that("Arrow tables and datasets require an explicit table_source adapter", {
  skip_if_not_installed("arrow")

  arrow_table <- arrow::Table$create(data.frame(id = 1:3))
  expect_error(data_table(arrow_table), "must be a data frame or a matrix")

  path <- tempfile(fileext = ".parquet")
  on.exit(unlink(path), add = TRUE)
  arrow::write_parquet(data.frame(id = 1:3), path)
  dataset <- arrow::open_dataset(path)
  expect_error(data_table(dataset), "must be a data frame or a matrix")
})
