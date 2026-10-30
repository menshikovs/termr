stopifnot(requireNamespace("shiny", quietly = TRUE))
root <- normalizePath(".", winslash = "/")
path <- file.path(root, "audit-results", "data-streams", "http-snapshots")
source("inst/examples/system-monitor-live/common.R")
dir.create(path, recursive = TRUE, showWarnings = FALSE)
writer <- monitor_writer(path, min_interval = 0)
collect <- monitor_collector("http-smoke")
writer$publish(collect())
writer$close()
main <- function() {
  p <- processx::process$new(file.path(R.home("bin"), "Rscript"),
    c("--vanilla", "inst/examples/system-monitor-live/shiny-app.R", path),
    env = c(R_LIBS = paste(.libPaths(), collapse = .Platform$path.sep), R_TESTS = ""),
    stdout = "audit-results/data-streams/http.stdout", stderr = "audit-results/data-streams/http.stderr")
  on.exit(if (p$is_alive()) p$kill_tree(), add = TRUE)
  page <- NULL
  for (i in 1:100) {
    page <- tryCatch(readLines("http://127.0.0.1:3838", warn = FALSE), error = function(e) NULL)
    if (length(page)) break
    if (!p$is_alive()) stop("Shiny exited before accepting loopback HTTP.")
    Sys.sleep(0.1)
  }
  stopifnot(any(grepl("termr live system monitor", page, fixed = TRUE)),
            any(grepl('id="history"', page, fixed = TRUE)))
  writeLines(page, "audit-results/data-streams/http-page.html")
  cat("PASS: actual Shiny runApp serves dashboard on 127.0.0.1:3838\n")
}
main()
