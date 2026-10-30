source("audit-results/mirai/environment.R")
args <- commandArgs(trailingOnly = TRUE)
tag <- if (length(args)) args[[1L]] else "first"
result <- tryCatch(processx::run(file.path(R.home("bin"), "Rscript"),
  c("--vanilla", "tests/testthat/fixtures/mirai_shutdown_child.R"), timeout = 120,
  env = c("current", R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep), R_TESTS = ""),
  error_on_status = FALSE), error = function(e) list(status = "timeout", stdout = e$stdout, stderr = conditionMessage(e)))
jsonlite::write_json(result, file.path("audit-results/mirai", paste0("shutdown-", host, "-", tag, ".json")),
  auto_unbox = TRUE, null = "null", pretty = TRUE)
cat("STATUS", result$status, "\n", tail(strsplit(if (is.null(result$stdout)) "" else result$stdout, "\n")[[1L]], 4L), sep = "\n")
