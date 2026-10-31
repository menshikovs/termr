library_path <- Sys.getenv("TERMR_UNITS_LIB", unset = "")
if (nzchar(library_path) && dir.exists(library_path)) {
  .libPaths(c(library_path, .libPaths()))
}
result <- testthat::test_local(".", reporter = "summary")
summary <- as.data.frame(result)
cat(sprintf("\nTOTAL: %d expectations, %d failed, %d errors, %d skipped, %d warnings\n",
            sum(summary$nb), sum(summary$failed), sum(summary$error),
            sum(summary$skipped), sum(summary$warning)))
