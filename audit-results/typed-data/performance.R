# Reproducible in-memory DataTable measurements for baseline and working tree.
# Run from a package checkout: Rscript audit-results/typed-data/performance.R out.csv
args <- commandArgs(trailingOnly = TRUE)
if (!length(args)) stop("Pass the output CSV path.", call. = FALSE)
suppressPackageStartupMessages(pkgload::load_all(".", quiet = TRUE))

sizes <- c(0L, 10L, 1000L, 100000L, 1000000L)
measure <- function(expr, reps = 5L, batch = 1L) {
  expression <- substitute(expr)
  environment <- parent.frame()
  stats::median(replicate(reps, {
    gc(verbose = FALSE)
    elapsed <- system.time(for (i in seq_len(batch)) {
      eval(expression, envir = environment)
    })[["elapsed"]]
    unname(elapsed / batch)
  }))
}

rows <- list()
for (n in sizes) {
  index <- seq_len(n)
  data <- data.frame(
    id = as.integer(index),
    amount = as.double(index) / 10,
    day = as.Date("2020-01-01") + index,
    label = sprintf("row-%07d", index),
    stringsAsFactors = FALSE
  )
  build_seconds <- measure(data_table(data, editable = TRUE, cursor = "none"), batch = 10L)
  tbl <- data_table(data, editable = TRUE, cursor = "none")
  render_seconds <- measure(render_widget(tbl, 100L, 30L), batch = 5L)
  table_data_bytes <- as.numeric(object.size(tbl$data))
  table_object_bytes <- as.numeric(object.size(tbl))
  gc()
  before_gc <- gc()[, "used"]
  retained <- data_table(data, editable = TRUE, cursor = "none")
  after_gc <- gc()[, "used"]
  retained_vcells_kb <- unname(after_gc[["Vcells"]] - before_gc[["Vcells"]])
  if (n > 0L) {
    edit_seconds <- measure(tbl$set_cell(1L, "id", "7"), batch = 10L)
    sort_seconds <- measure(tbl$sort("id"), batch = 5L)
    filter_seconds <- measure(tbl$filter_columns(list(
      id = table_filter("range", min = max(1L, n %/% 4L), max = max(1L, n %/% 2L))
    )), batch = 5L)
    scroll_seconds <- measure(tbl$scroll_to_row(n), batch = 20L)
  } else {
    edit_seconds <- sort_seconds <- filter_seconds <- scroll_seconds <- NA_real_
  }
  rows[[length(rows) + 1L]] <- data.frame(
    rows = n, build_ms = build_seconds * 1000, render_ms = render_seconds * 1000,
    edit_ms = edit_seconds * 1000, sort_ms = sort_seconds * 1000,
    filter_ms = filter_seconds * 1000, scroll_ms = scroll_seconds * 1000,
    data_bytes = table_data_bytes, table_object_bytes = table_object_bytes,
    retained_vcells_delta_kb = retained_vcells_kb
  )
  rm(data, tbl, retained)
  gc()
}
result <- do.call(rbind, rows)
utils::write.csv(result, args[[1L]], row.names = FALSE)
print(result, row.names = FALSE)
