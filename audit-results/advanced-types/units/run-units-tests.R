library_path <- Sys.getenv("TERMR_UNITS_LIB", unset = "")
if (nzchar(library_path) && dir.exists(library_path)) {
  .libPaths(c(library_path, .libPaths()))
}
testthat::test_local(".", filter = "datatable-units", reporter = "summary")
