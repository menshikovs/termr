# Reproducible in-memory rendering and allocation probe for A2.4.
# Run from the repository root with:
#   Rscript audit-results/advanced-types/blob/bench-blob.R

suppressPackageStartupMessages(pkgload::load_all(".", quiet = TRUE))

# Keep one-time namespace and renderer setup out of per-size timings.
invisible(render_widget(data_table(data.frame(value = 1L)), 40L, 8L))
invisible(table_raw_preview(as.raw(0:7)))
invisible(render_widget(
  data_table(data.frame(payload = I(list(as.raw(0:7)))),
             columns = list(payload = column(width = 28L))),
  80L, 24L
))

elapsed_ms <- function(code, iterations = 1L) {
  expr <- substitute(code)
  env <- parent.frame()
  start <- proc.time()[["elapsed"]]
  for (i in seq_len(iterations)) eval(expr, env)
  (proc.time()[["elapsed"]] - start) * 1000 / iterations
}

median_ms <- function(code, iterations = 5L, repetitions = 1L) {
  expr <- substitute(code)
  env <- parent.frame()
  times <- numeric(iterations)
  for (i in seq_len(iterations)) {
    start <- proc.time()[["elapsed"]]
    for (j in seq_len(repetitions)) eval(expr, env)
    times[[i]] <- (proc.time()[["elapsed"]] - start) * 1000 / repetitions
  }
  stats::median(times)
}

measure_column <- function(n, make_blob = FALSE) {
  values <- lapply(seq_len(n), function(i) {
    as.raw(c(i %% 256L, (i + 1L) %% 256L, 0x00, 0xFF, 0x1B, 0x41, 0xC3, 0x28))
  })
  if (make_blob) class(values) <- "blob"
  source <- data.frame(payload = I(values))
  table <- data_table(source, editable = TRUE,
                      columns = list(payload = column(width = 28L)))
  first_render_tables <- lapply(seq_len(5L), function(i) {
    data_table(source, columns = list(payload = column(width = 28L)))
  })
  visible_rows <- seq_len(min(20L, n))

  first_render <- stats::median(vapply(first_render_tables, function(current) {
    elapsed_ms(render_widget(current, 80L, 24L))
  }, numeric(1)))
  scrolling <- median_ms({
    if (n > 20L) table$move_cursor(row = min(n, 100L))
    render_widget(table, 80L, 24L)
  }, iterations = 5L, repetitions = 10L)
  visible_format <- median_ms(
    table_format_values(table_slice(source$payload, visible_rows), width = 28L),
    iterations = 5L, repetitions = 100L
  )
  edit_reject <- median_ms(
    tryCatch(table$set_cell(1L, "payload", "FF"), error = function(e) NULL),
    iterations = 5L, repetitions = 100L
  )

  list(
    rows = n,
    class = if (make_blob) "blob-shaped list-of-raw" else "list<raw>",
    first_render_ms = first_render,
    scrolling_render_ms = scrolling,
    visible_20_format_ms = visible_format,
    read_only_edit_rejection_ms = edit_reject
  )
}

measure_allocations <- function(expr) {
  path <- tempfile(fileext = ".Rprofmem")
  on.exit(unlink(path), add = TRUE)
  on.exit(Rprofmem(NULL), add = TRUE)
  Rprofmem(path, threshold = 0)
  force(expr)
  Rprofmem(NULL)
  lines <- readLines(path, warn = FALSE)
  sizes <- suppressWarnings(as.numeric(sub(" .*", "", lines)))
  sum(sizes[is.finite(sizes)], na.rm = TRUE)
}

results <- do.call(rbind, lapply(c(100L, 10000L, 100000L), function(n) {
  rbind(measure_column(n), measure_column(n, make_blob = TRUE))
}))

large <- raw(10L * 1024L * 1024L)
large[[1L]] <- as.raw(0x1B)
large[[2L]] <- as.raw(0xFF)
preview_ms <- median_ms(table_raw_preview(large), iterations = 5L, repetitions = 1000L)
preview_allocated <- measure_allocations(table_raw_preview(large))
preview_object <- table_raw_preview(large)
large_results <- data.frame(
  bytes = length(large),
  preview_ms = preview_ms,
  profmem_recorded_bytes = preview_allocated,
  preview_object_bytes = as.numeric(object.size(preview_object))
)

print(results, row.names = FALSE)
cat("\nLarge raw payload preview:\n")
print(large_results, row.names = FALSE)
cat("\n10 MiB preview:\n", table_raw_preview(large), "\n", sep = "")

write.csv(results, "audit-results/advanced-types/blob/performance-results.csv", row.names = FALSE)
write.csv(large_results, "audit-results/advanced-types/blob/performance-large-raw.csv", row.names = FALSE)
