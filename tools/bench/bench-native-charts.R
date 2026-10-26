# Native chart comparison benchmark.
#
# Run each mode in a fresh R process:
#   Rscript tools/bench/bench-native-charts.R baseline
#   Rscript tools/bench/bench-native-charts.R development
# Baseline mode needs TERMRCHARTS_SOURCE pointing to the audited termrcharts
# checkout. Both runs use deterministic inputs, 80x24 initial paint, 100x30
# resize, and the same headless termr driver. Baseline update is a full widget
# replacement because termrcharts has no in-place update method.

args <- commandArgs(trailingOnly = TRUE)
mode <- if (length(args)) args[[1L]] else stop("Choose baseline or development.")
if (!mode %in% c("baseline", "development")) stop("Choose baseline or development.")

if (identical(mode, "baseline")) {
  source_path <- Sys.getenv("TERMRCHARTS_SOURCE")
  if (!nzchar(source_path)) stop("Set TERMRCHARTS_SOURCE to a termrcharts checkout.")
  suppressPackageStartupMessages(library(termr))
  suppressMessages(pkgload::load_all(source_path, quiet = TRUE, export_all = TRUE))
  package <- "termrcharts"
} else {
  suppressMessages(pkgload::load_all(".", quiet = TRUE, export_all = TRUE))
  package <- "termr"
}

constructor <- function(name) getExportedValue(package, name)
test_app_fn <- getExportedValue("termr", "test_app")

make_case <- function(name, offset = 0) {
  n <- 5000L
  switch(name,
    line = constructor("line_chart")(seq_len(n), sin(seq_len(n) / 41) + offset),
    bar = constructor("bar_chart")(paste0("c", seq_len(100)), (seq_len(100) %% 17) + offset),
    scatter = constructor("scatter_chart")(seq_len(n), cos(seq_len(n) / 37) + offset),
    histogram = constructor("histogram")((seq_len(n) %% 101) / 10 + offset),
    heatmap = constructor("heatmap_chart")(matrix((seq_len(10000) %% 97) + offset, 100, 100))
  )
}

update_case <- function(chart, name, offset) {
  n <- 5000L
  if (name == "line") chart$update_data(x = seq_len(n), y = sin(seq_len(n) / 41) + offset)
  if (name == "bar") chart$update_data(labels = paste0("c", seq_len(100)), values = (seq_len(100) %% 17) + offset)
  if (name == "scatter") chart$update_data(x = seq_len(n), y = cos(seq_len(n) / 37) + offset)
  if (name == "histogram") chart$update_data(x = (seq_len(n) %% 101) / 10 + offset)
  if (name == "heatmap") chart$update_data(z = matrix((seq_len(10000) %% 97) + offset, 100, 100))
}

ms <- function(expr) {
  start <- proc.time()[["elapsed"]]
  force(expr)
  1000 * (proc.time()[["elapsed"]] - start)
}
median_ms <- function(n, fun) median(vapply(seq_len(n), function(i) ms(fun(i)), numeric(1)))

results <- list()
for (name in c("line", "bar", "scatter", "histogram", "heatmap")) {
  build <- median_ms(5L, function(i) invisible(make_case(name)))
  initial <- median_ms(3L, function(i) {
    pilot <- test_app_fn(make_case(name), width = 80, height = 24)
    pilot$stop()
  })
  chart <- make_case(name)
  pilot <- test_app_fn(chart, width = 80, height = 24)
  resize <- median_ms(4L, function(i) {
    if (i %% 2L) pilot$resize(100, 30) else pilot$resize(80, 24)
  })
  if (identical(mode, "development")) {
    update <- median_ms(4L, function(i) {
      update_case(chart, name, i %% 2L)
      pilot$step()
    })
    update_label <- "update_data + repaint"
  } else {
    update <- median_ms(3L, function(i) {
      replacement <- test_app_fn(make_case(name, 1), width = 80, height = 24)
      replacement$stop()
    })
    update_label <- "replacement app (no update API)"
  }
  pilot$stop()
  invisible(gc(reset = TRUE))
  chart <- make_case(name)
  pilot <- test_app_fn(chart, width = 80, height = 24)
  heap <- sum(gc()[, 6L])
  pilot$stop()
  results[[name]] <- c(build_ms = build, initial_app_ms = initial,
                       resize_ms = resize, update_ms = update, max_heap_mb = heap)
}
cat(sprintf("mode=%s, R=%s, OS=%s, update=%s\n", mode, as.character(getRversion()),
            Sys.info()[["sysname"]], update_label))
print(round(do.call(rbind, results), 2))

