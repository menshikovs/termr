root <- Sys.getenv('TERMR_PROJECT_ROOT', getwd())
root <- normalizePath(root, winslash = '/')
Sys.setenv(TERMR_PROJECT_ROOT = root)
args <- commandArgs(TRUE)
filter <- if (length(args) && args[[1L]] != 'all') args[[1L]] else NULL
result <- testthat::test_dir(file.path(root, 'integration-apps/tests'), filter = filter,
  reporter = 'summary', stop_on_failure = FALSE)
df <- as.data.frame(result)
totals <- list(expectations = sum(df$nb), failed = sum(df$failed), errors = sum(df$error),
  skipped = sum(df$skipped), warnings = sum(df$warning))
out <- Sys.getenv('TERMR_E_ARTIFACTS', file.path(root, 'audit-results/real-world-apps'))
dir.create(out, recursive = TRUE, showWarnings = FALSE)
jsonlite::write_json(totals, file.path(out, paste0('app-test-summary-', .Platform$OS.type, '.json')), auto_unbox = TRUE, pretty = TRUE)
cat('APP TOTAL:', jsonlite::toJSON(totals, auto_unbox = TRUE), '\n')
if (totals$failed || totals$errors) quit(status = 1L)
