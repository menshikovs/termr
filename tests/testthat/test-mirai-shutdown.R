test_that("repeated active shutdown is bounded and never resets a foreign profile", {
  skip_on_cran()
  skip_if_not_installed("mirai", "2.7.3")
  current <- any(vapply(file.path(.libPaths(), "termr", "NAMESPACE"), function(path) {
    file.exists(path) && any(grepl("export(termr_mirai_pool)", readLines(path), fixed = TRUE))
  }, logical(1)))
  if (!current) skip("Install current checkout for the isolated shutdown regression.")
  result <- processx::run(file.path(R.home("bin"), "Rscript"),
    c("--vanilla", normalizePath(test_path("fixtures", "mirai_shutdown_child.R"), winslash = "/")),
    timeout = 120, error_on_status = FALSE,
    env = c("current", R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep), R_TESTS = ""))
  expect_identical(result$status, 0L, info = paste(result$stdout, result$stderr))
  expect_match(result$stdout, "closed 30", fixed = TRUE)
  expect_match(result$stdout, "PASS repeated active shutdown", fixed = TRUE)
})
