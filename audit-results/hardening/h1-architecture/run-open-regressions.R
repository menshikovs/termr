pkgload::load_all(".", quiet = TRUE)
result <- testthat::test_file("audit-results/hardening/h1-architecture/regressions-open.R",
  reporter = "summary", stop_on_failure = FALSE)
frame <- as.data.frame(result)
write.csv(frame[, setdiff(names(frame), "result"), drop = FALSE],
  paste0("audit-results/hardening/h1-architecture/open-regressions-", .Platform$OS.type, ".csv"), row.names = FALSE)
cat("OPEN REGRESSIONS:", sum(frame$failed), "failed,", sum(frame$error), "errors,", sum(frame$skipped), "skipped\n")
quit(status = if (sum(frame$failed) + sum(frame$error)) 1L else 0L)
