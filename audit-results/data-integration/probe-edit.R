pkgload::load_all(".", quiet = TRUE)
data <- data.frame(id = seq_len(1000L), value = seq_len(1000L) / 10)
table <- data_table(data, cursor = "none", editable = TRUE)
stopifnot(table$row_count == 1000L, nrow(table$data) == 1000L)
for (row in seq_len(10L)) table$set_cell(row, "id", as.integer(1000L - row))
stopifnot(identical(table$data$id[[10L]], 990L))
cat("local cell edit probe passed\n")

columns <- paste0("field", seq_len(40L))
column_options <- stats::setNames(lapply(columns, function(name) column(width = 6L)), columns)
column_options$field1 <- column(width = 6L, editable = TRUE)
source <- table_source(
  row_count = 10000000L,
  column_names = columns,
  get_rows = function(start, count, columns = NULL) {
    as.data.frame(stats::setNames(
      lapply(columns, function(name) seq.int(start, length.out = count)), columns
    ), check.names = FALSE)
  },
  set_value = function(row, column, value) TRUE
)
source_table <- data_table(
  source, cursor = "none", columns = column_options, editable = TRUE
)
stopifnot(source_table$row_count == 10000000L)
source_table$set_cell(9000000L, "field1", 9000000L)
cat("10M source cell edit probe passed\n")

invalid_counts <- list(NA_real_, NaN, Inf, 1.5, .Machine$integer.max + 1)
for (count in invalid_counts) {
  invalid_source <- table_source(
    row_count = function() count,
    column_names = "value",
    get_rows = function(start, count, columns = NULL) data.frame(value = integer())
  )
  result <- tryCatch(data_table(invalid_source), error = identity)
  stopifnot(inherits(result, "error"), grepl("row_count", conditionMessage(result)))
}
cat("unknown, non-finite, fractional and over-limit row count probes passed\n")
