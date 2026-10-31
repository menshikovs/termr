root <- normalizePath(".", winslash = "/")
out <- file.path(root, "audit-results/hardening/h1-architecture")
h1tmp <- tempfile("termr-h1-runner-")
dir.create(h1tmp)
h1tmp <- normalizePath(h1tmp, winslash = "/")
stopifnot(startsWith(h1tmp, paste0(normalizePath(tempdir(), winslash = "/"), "/")))
on.exit_cleanup <- function() unlink(h1tmp, recursive = TRUE)
main <- function() {
  on.exit(on.exit_cleanup(), add = TRUE)
  dir.create(file.path(h1tmp, "R"))
  dir.create(file.path(h1tmp, "tools"))
  dir.create(file.path(h1tmp, "tests", "testthat"), recursive = TRUE)
  writeLines(c("Package: termrh1runner", "Title: Audit Test Runner", "Version: 0.0.0",
    "Authors@R: person('Audit', 'Probe', email='audit@example.test', role=c('aut','cre'))",
    "Description: Isolated fixture for test runner exit status.", "License: MIT",
    "Encoding: UTF-8", "Suggests: testthat", "Config/testthat/edition: 3"), file.path(h1tmp, "DESCRIPTION"))
  file.create(file.path(h1tmp, "NAMESPACE"))
  file.copy(file.path(root, "tools/dev.R"), file.path(h1tmp, "tools/dev.R"))
  script <- file.path(h1tmp, "tests/testthat/test-runner.R")
  run <- function(name, code) {
    writeLines(code, script)
    result <- processx::run(file.path(R.home("bin"), if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript"),
      c("--vanilla", "tools/dev.R", "test"), wd = h1tmp, timeout = 30000L, error_on_status = FALSE)
    writeLines(c(result$stdout, result$stderr), file.path(out, paste0("runner-", name, ".log")))
    data.frame(case = name, status = result$status)
  }
  results <- rbind(
    run("failure", "testthat::test_that('failure', testthat::expect_true(FALSE))"),
    run("error", "testthat::test_that('error', stop('controlled error'))"),
    run("success", "testthat::test_that('success', testthat::expect_true(TRUE))"))
  write.csv(results, file.path(out, "runner-exit-status.csv"), row.names = FALSE)
  print(results, row.names = FALSE)
  stopifnot(identical(results$status, c(1L, 1L, 0L)))
}
main()
