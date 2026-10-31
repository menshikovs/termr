test_that("haven stays optional and labelled objects are read-only without it", {
  if (requireNamespace("haven", quietly = TRUE)) skip("haven is installed")

  values <- structure(c(1L, 2L), labels = c(Male = 1L), label = "Sex",
                      class = c("haven_labelled", "vctrs_vctr", "integer"))
  table <- data_table(data.frame(value = values), editable = TRUE)

  expect_identical(table_format_values(values), c("1", "2"))
  expect_false(table$column_info()$editable[[1L]])
  expect_error(table$set_cell(1L, "value", "raw:3"), "read-only")
  expect_identical(table$data$value, values)
  expect_identical(table$column_info()$value_labels[[1L]], c(Male = 1L))
})
