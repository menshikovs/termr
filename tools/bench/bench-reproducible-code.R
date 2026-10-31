pkgload::load_all(".", quiet = TRUE)

measure_allocated_bytes <- function(fn) {
  path <- tempfile("termr-rprofmem-")
  on.exit(unlink(path), add = TRUE)
  Rprofmem(path, threshold = 1)
  tryCatch(fn(), finally = Rprofmem(NULL))
  lines <- readLines(path, warn = FALSE)
  bytes <- suppressWarnings(as.numeric(sub("[[:space:]].*$", "", lines)))
  sum(bytes, na.rm = TRUE)
}

measure_seconds <- function(fn, iterations = 10L, trials = 3L) {
  times <- replicate(trials, {
    elapsed <- system.time(for (i in seq_len(iterations)) fn())[["elapsed"]]
    unname(elapsed / iterations)
  })
  stats::median(times)
}

measure_table_size <- function(n) {
  data <- data.frame(
    id = seq_len(n),
    group = rep(letters[1:4], length.out = n),
    value = seq_len(n) / 7,
    flag = seq_len(n) %% 2L == 0L,
    stringsAsFactors = FALSE
  )
  table <- data_table(data)
  table$filter_columns(list(group = table_filter("equals", "b")))
  table$sort("value", decreasing = TRUE)
  table$select_range(1L, min(10L, table$row_count))

  pipeline <- function() table$reproducible_code("pipeline")
  selection_table <- data_table(data)
  selection_table$select_range(1L, min(25L, selection_table$row_count))
  value <- function() selection_table$reproducible_code("value")

  cell_table <- data_table(data, cursor = "cell")
  cell_table$move_cursor(row = 1L, column = "value")
  cell <- function() cell_table$reproducible_code("value")

  results <- list(pipeline = pipeline(), value = value(), cell = cell())
  data.frame(
    rows = n,
    selected_cells = min(25L, n) * ncol(data),
    pipeline_seconds = measure_seconds(pipeline),
    pipeline_allocated_bytes = measure_allocated_bytes(pipeline),
    pipeline_code_bytes = nchar(results$pipeline$code %||% "", type = "bytes"),
    pipeline_status = results$pipeline$status,
    selection_seconds = measure_seconds(value),
    selection_allocated_bytes = measure_allocated_bytes(value),
    selection_code_bytes = nchar(results$value$code %||% "", type = "bytes"),
    selection_status = results$value$status,
    cell_seconds = measure_seconds(cell),
    cell_allocated_bytes = measure_allocated_bytes(cell),
    cell_code_bytes = nchar(results$cell$code %||% "", type = "bytes"),
    cell_status = results$cell$status
  )
}

measure_special_case <- function(label, data, row = 1L, column = names(data)[[1L]]) {
  table <- data_table(data, cursor = "cell")
  table$move_cursor(row = row, column = column)
  run <- function() table$reproducible_code("value")
  result <- run()
  data.frame(
    case = label,
    rows = nrow(data),
    columns = ncol(data),
    elapsed_seconds = measure_seconds(run),
    allocated_bytes = measure_allocated_bytes(run),
    code_bytes = nchar(result$code %||% "", type = "bytes"),
    status = result$status
  )
}

size_results <- do.call(rbind, lapply(c(100L, 1000L, 10000L, 100000L, 1000000L), measure_table_size))
print(size_results, row.names = FALSE)

payloads <- replicate(1000L, as.raw(c(0L, 27L, 255L, 1L:32L)), simplify = FALSE)
list_data <- data.frame(id = seq_along(payloads))
list_data$payload <- payloads
wide_data <- as.data.frame(matrix(seq_len(10000L), nrow = 10L, ncol = 1000L))
names(wide_data) <- paste0("column ", seq_len(ncol(wide_data)))
long_data <- data.frame(text = rep(paste(rep("x", 100000L), collapse = ""), 10L))

special_results <- rbind(
  measure_special_case("list-column raw payload", list_data, column = "payload"),
  measure_special_case("1000 columns", wide_data, column = names(wide_data)[[1000L]]),
  measure_special_case("100 KB character value", long_data, column = "text")
)
print(special_results, row.names = FALSE)
