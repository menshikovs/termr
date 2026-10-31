# Reproducible DataTable code: copied values are standalone, while pipelines
# and edits use the symbolic source variable `data`.
library(termr)

data <- data.frame(
  id = 1:5,
  region = factor(c("West", "East", "West", "North", "East")),
  score = c(1.25, 3.5, NA_real_, 8.0, 2.75),
  day = as.Date("2026-10-01") + 0:4,
  stringsAsFactors = FALSE
)
table <- data_table(data, cursor = "row", editable = TRUE)
table$filter_columns(list(region = table_filter("equals", "East")))
table$sort("score", decreasing = TRUE)
table$select_range(1L, min(2L, table$row_count))

# This is a self-contained typed frame and can be pasted into an R script.
value_code <- table$reproducible_code("value")
stopifnot(identical(value_code$status, "exact"))
cat(value_code$code, "\n")

# This uses `data` as its source binding and reproduces the final supported
# local view. DataTable does not claim this is a historical action log.
pipeline_code <- table$reproducible_code("pipeline")
stopifnot(identical(pipeline_code$status, "exact"), pipeline_code$requires_source_binding)
cat(pipeline_code$code, "\n")

# Edit export uses original local row numbers even when the view is sorted.
table$set_cell(2L, "score", 3.75)
edit_code <- table$reproducible_code("edits")
stopifnot(identical(edit_code$status, "exact"), edit_code$requires_source_binding)
cat(edit_code$code, "\n")

# Direct dbplyr/DuckDB and Arrow Dataset objects are not DataTable source
# adapters. These helpers show a bounded local sample workflow; generated code
# binds to that sample and does not preserve its database query or dataset path.
duckdb_sample_example <- function() {
  required <- c("DBI", "duckdb", "dplyr", "dbplyr")
  missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) {
    message("DuckDB sample example needs optional packages: ", paste(missing, collapse = ", "))
    return(invisible(NULL))
  }
  local({
    connection <- DBI::dbConnect(duckdb::duckdb(), dbdir = ":memory:")
    on.exit(DBI::dbDisconnect(connection, shutdown = TRUE), add = TRUE)
    DBI::dbWriteTable(connection, "iris", datasets::iris)
    data <- dplyr::collect(dplyr::tbl(connection, "iris"), n = 1000L)
    table <- data_table(data)
    table$sort("Sepal.Length", decreasing = TRUE)
    table$reproducible_code("pipeline")
  })
}

arrow_sample_example <- function() {
  required <- c("arrow", "dplyr")
  missing <- required[!vapply(required, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) {
    message("Arrow sample example needs optional packages: ", paste(missing, collapse = ", "))
    return(invisible(NULL))
  }
  local({
    path <- tempfile("termr-arrow-")
    dir.create(path)
    on.exit(unlink(path, recursive = TRUE), add = TRUE)
    arrow::write_dataset(datasets::iris, path)
    dataset <- arrow::open_dataset(path)
    data <- dplyr::collect(dplyr::slice_head(dataset, n = 1000L))
    table <- data_table(data)
    table$sort("Sepal.Length", decreasing = TRUE)
    table$reproducible_code("pipeline")
  })
}
