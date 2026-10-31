Sys.setenv(NOT_CRAN = "false")
testthat::test_local(
  ".",
  filter = "datatable-source|datatable-source-backends|datatable-typed|datatable-custom-classes|datatable-binary|datatable-units|datatable-haven|datatable-sf",
  reporter = "summary"
)