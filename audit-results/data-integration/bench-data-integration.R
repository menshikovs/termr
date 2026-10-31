pkgload::load_all(".", quiet = TRUE)

time_elapsed <- function(expr) unname(system.time(force(expr))[['elapsed']])
time_n <- function(n, expr) {
  expression <- substitute(expr)
  environment <- parent.frame()
  start <- proc.time()[['elapsed']]
  for (i in seq_len(n)) eval(expression, envir = environment)
  (proc.time()[['elapsed']] - start) / n
}
allocation_bytes <- function(expr) {
  path <- tempfile("termr-a35-mem-")
  Rprofmem(path, threshold = 1024L)
  tryCatch(force(expr), finally = Rprofmem(NULL))
  lines <- readLines(path, warn = FALSE)
  unlink(path)
  sizes <- suppressWarnings(as.numeric(sub(":.*$", "", lines)))
  sum(sizes, na.rm = TRUE)
}

local_rows <- c(1000L, 100000L, 1000000L)
local_results <- lapply(local_rows, function(n) {
  data <- data.frame(id = seq_len(n), value = as.double(seq_len(n)) / 10,
                     stringsAsFactors = FALSE)
  input_bytes <- as.numeric(object.size(data))
  # Load widget/render paths before timing so the smallest case is not charged
  # for one-time method and formatter initialization.
  warm_table <- data_table(data[seq_len(min(n, 50L)), , drop = FALSE],
                           cursor = "none", row_names = FALSE)
  render_widget(warm_table, 80L, 20L)
  init_s <- time_n(5L, table <- data_table(data, cursor = "none", row_names = FALSE))
  table <- data_table(data, cursor = "none", row_names = FALSE)
  render_s <- time_n(20L, render_widget(table, 80L, 20L))
  scroll_i <- 0L
  scroll_s <- time_n(20L, {
    scroll_i <<- scroll_i + 1L
    table$scroll_to_row(max(1L, n - 20L * scroll_i))
    render_widget(table, 80L, 20L)
  })
  edit_table <- data_table(data, cursor = "none", row_names = FALSE, editable = TRUE)
  edit_started <- proc.time()[["elapsed"]]
  for (edit_i in seq_len(10L)) {
    edit_table$set_cell(edit_i, "id", as.integer(n - edit_i))
  }
  edit_s_mean10 <- (proc.time()[["elapsed"]] - edit_started) / 10
  edit_alloc <- allocation_bytes(edit_table$set_cell(10L, "id", as.integer(n - 10L)))
  alloc <- allocation_bytes(render_widget(table, 80L, 20L))
  data.frame(rows = n, input_bytes = input_bytes, init_s_mean5 = init_s,
             render_s_mean20 = render_s, scroll_render_s = scroll_s,
             edit_s_mean10 = edit_s_mean10,
             edit_alloc_bytes_over_1k = edit_alloc,
             render_alloc_bytes_over_1k = alloc)
})
local_results <- do.call(rbind, local_results)
write.csv(local_results, "audit-results/data-integration/performance-local.csv", row.names = FALSE)
print(local_results, row.names = FALSE)

state <- new.env(parent = emptyenv())
state$calls <- list()
columns <- paste0("field", seq_len(40L))
column_options <- stats::setNames(lapply(columns, function(name) column(width = 6L)), columns)
column_options$field1 <- column(width = 6L, editable = TRUE)
state$edit <- NULL
source <- table_source(
  row_count = 10000000L,
  column_names = columns,
  get_rows = function(start, count, columns = NULL) {
    out <- as.data.frame(stats::setNames(
      lapply(columns, function(name) seq.int(start, length.out = count)), columns
    ), check.names = FALSE)
    state$calls[[length(state$calls) + 1L]] <- list(
      start = start, count = count, columns = columns, bytes = as.numeric(object.size(out))
    )
    out
  },
  set_value = function(row, column, value) {
    state$edit <- list(row = row, column = column, value = value)
    TRUE
  }
)
source_init_s <- time_elapsed(source_table <- data_table(
  source, cursor = "none", columns = column_options, editable = TRUE
))
init_rows <- sum(vapply(state$calls, `[[`, integer(1), "count"))
state$calls <- list() # exclude the bounded schema sample
source_scroll_s <- time_elapsed({
  source_table$scroll_to_row(5000000L)
  render_widget(source_table, 80L, 20L)
})
full_page <- as.data.frame(stats::setNames(
  lapply(columns, function(name) seq_len(100L)), columns
), check.names = FALSE)
baseline_page_bytes <- as.numeric(object.size(full_page)) * length(state$calls)
projected_bytes <- sum(vapply(state$calls, `[[`, numeric(1), "bytes"))
source_results <- data.frame(
  total_rows = 10000000L, init_rows = init_rows,
  scroll_rows = sum(vapply(state$calls, `[[`, integer(1), "count")),
  max_rows_per_fetch = max(vapply(state$calls, `[[`, integer(1), "count")),
  visible_columns = length(unique(unlist(lapply(state$calls, `[[`, "columns")))),
  total_columns = length(columns),
  all_column_payload_bytes_before = baseline_page_bytes,
  projected_payload_bytes_after = projected_bytes,
  payload_reduction_percent = 100 * (1 - projected_bytes / baseline_page_bytes),
  init_s = source_init_s, distant_scroll_render_s = source_scroll_s
)
state$calls <- list()
source_edit_s <- time_elapsed(source_table$set_cell(9000000L, "field1", 9000000L))
source_edit_request <- state$calls[[1L]]
source_results$source_edit_s <- source_edit_s
source_results$source_edit_fetch_rows <- source_edit_request$count
source_results$source_edit_columns <- length(source_edit_request$columns)
source_results$source_edit_callback_row <- state$edit$row
write.csv(source_results, "audit-results/data-integration/performance-source-10m.csv", row.names = FALSE)
print(source_results, row.names = FALSE)
