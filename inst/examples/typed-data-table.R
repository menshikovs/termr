# Typed columns stay typed in the table and in its edit results.
typed_data <- data.frame(
  active = c(TRUE, NA),
  count = c(3L, 5L),
  score = c(1.25, NaN),
  status = factor(c("ready", "queued"), levels = c("ready", "queued", "done")),
  day = as.Date(c("2026-10-29", "2026-10-30")),
  recorded_at = as.POSIXct(c("2026-10-29 09:00:00", "2026-10-30 09:00:00"), tz = "UTC"),
  elapsed = as.difftime(c(30, 90), units = "mins"),
  stringsAsFactors = FALSE
)

table <- data_table(typed_data, editable = TRUE, show_types = TRUE, row_names = FALSE)
table$column_info()[c("name", "type", "class", "typeof", "editable")]

# Type-correct edits preserve storage and attributes.
table$set_cell(1L, "count", "8")
table$set_cell(2L, "status", "done")
table$set_cell(1L, "day", "2026-11-01")
stopifnot(is.integer(table$data$count), is.factor(table$data$status), inherits(table$data$day, "Date"))

# Optional adapters are available when their packages are installed.
if (requireNamespace("hms", quietly = TRUE)) {
  typed_data$clock <- hms::as_hms(c(9 * 3600, 10 * 3600))
}
if (requireNamespace("bit64", quietly = TRUE)) {
  typed_data$sequence <- bit64::as.integer64(c("9007199254740993", "9007199254740995"))
}
