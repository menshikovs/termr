library_path <- Sys.getenv("TERMR_UNITS_LIB", unset = "")
if (nzchar(library_path) && dir.exists(library_path)) {
  .libPaths(c(library_path, .libPaths()))
}
pkgload::load_all(".", quiet = TRUE)
warm_table <- termr::data_table(
  data.frame(measure = units::set_units(seq_len(20L), "m", mode = "standard")),
  editable = TRUE, show_types = TRUE, row_names = FALSE
)
warm_pilot <- termr::test_app(termr::app(warm_table), width = 80, height = 24)
warm_pilot$stop()
rm(warm_pilot, warm_table)
invisible(gc())

profile_bytes <- function(expr) {
  path <- tempfile(fileext = ".Rprofmem")
  Rprofmem(path, threshold = 1)
  force(expr)
  Rprofmem(NULL)
  lines <- readLines(path, warn = FALSE)
  unlink(path)
  sizes <- suppressWarnings(as.double(sub(" .*", "", lines)))
  sum(sizes[is.finite(sizes)], na.rm = TRUE)
}

measure_time_and_bytes <- function(expr) {
  path <- tempfile(fileext = ".Rprofmem")
  Rprofmem(path, threshold = 1)
  start <- proc.time()[["elapsed"]]
  value <- force(expr)
  elapsed <- proc.time()[["elapsed"]] - start
  Rprofmem(NULL)
  lines <- readLines(path, warn = FALSE)
  unlink(path)
  sizes <- suppressWarnings(as.double(sub(" .*", "", lines)))
  list(value = value, elapsed = elapsed, bytes = sum(sizes[is.finite(sizes)], na.rm = TRUE))
}

elapsed <- function(expr) unname(system.time(force(expr))["elapsed"])

run_size <- function(n) {
  values <- units::set_units(seq_len(n) / 10, "m", mode = "standard")
  frame <- data.frame(measure = values)
  constructor <- median(replicate(20L, elapsed(
    termr::data_table(frame, editable = TRUE, show_types = TRUE, row_names = FALSE)
  )))
  table <- termr::data_table(frame, editable = TRUE, show_types = TRUE,
                             row_names = FALSE)
  first <- measure_time_and_bytes(pilot <- termr::test_app(termr::app(table),
                                                           width = 80, height = 24))
  first_alloc <- first$bytes
  first_render <- first$elapsed
  on.exit(pilot$stop(), add = TRUE)
  scroll <- elapsed(for (i in seq_len(40L)) pilot$press("down"))
  rows <- seq_len(min(20L, n))
  private <- table$.__enclos_env__$private
  format_elapsed <- median(replicate(5L, elapsed(
    for (i in seq_len(100L)) private$format_values(1L, rows)
  )))
  table$set_cell(1L, "measure", "1 m")
  edit_elapsed <- median(replicate(5L, elapsed(
    for (i in seq_len(50L)) table$set_cell(1L, "measure", "1.25 m")
  ))) / 50
  edit_alloc <- profile_bytes(table$set_cell(1L, "measure", "1.5 m"))
  data.frame(
    rows = n,
    construction_ms = round(constructor * 1000, 3),
    first_render_ms = round(first_render * 1000, 3),
    first_render_alloc_bytes = first_alloc,
    scroll_40_down_ms = round(scroll * 1000, 3),
    format_20_visible_cells_100x_ms = round(format_elapsed * 1000, 3),
    edit_cell_ms = round(edit_elapsed * 1000, 3),
    edit_cell_alloc_bytes = edit_alloc,
    data_size_bytes = as.numeric(object.size(values))
  )
}

results <- do.call(rbind, lapply(c(100L, 10000L, 100000L), run_size))
write.csv(results, "audit-results/advanced-types/units/performance.csv", row.names = FALSE)
print(results, row.names = FALSE)
