host <- if (.Platform$OS.type == "windows") "windows" else "wsl"
.libPaths(c(file.path("audit-results/nanonext", paste0("lib-", host)), .libPaths()))
Sys.setenv(NOT_CRAN = "true")
args <- commandArgs(trailingOnly = TRUE)
res <- testthat::test_local(".", filter = if (length(args)) args[[1L]] else "nanonext", reporter = "summary", stop_on_failure = FALSE)
df <- as.data.frame(res)
cat("\nTOTAL", sum(df$nb), "expectations;", sum(df$failed), "failures;", sum(df$error), "errors;", sum(df$skipped), "skips\n")
if (any(df$failed > 0 | df$error)) quit(status = 1L)
