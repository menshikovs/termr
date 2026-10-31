pkgload::load_all(".", quiet = TRUE)
warm <- termr::data_table(data.frame(measure = seq_len(20L) / 10),
                          editable = TRUE, show_types = TRUE, row_names = FALSE)
warm_pilot <- termr::test_app(termr::app(warm), width = 80, height = 24)
warm_pilot$stop()
rm(warm, warm_pilot)
invisible(gc())

elapsed <- function(expr) unname(system.time(force(expr))["elapsed"])
profile_bytes <- function(expr) {
  path <- tempfile(fileext = ".Rprofmem")
  Rprofmem(path, threshold = 1)
  force(expr)
  Rprofmem(NULL)
  sizes <- suppressWarnings(as.double(sub(" .*", "", readLines(path, warn = FALSE))))
  unlink(path)
  sum(sizes[is.finite(sizes)], na.rm = TRUE)
}

run_size <- function(n) {
  frame <- data.frame(measure = seq_len(n) / 10)
  table <- termr::data_table(frame, editable = TRUE, show_types = TRUE,
                             row_names = FALSE)
  pilot <- termr::test_app(termr::app(table), width = 80, height = 24)
  on.exit(pilot$stop(), add = TRUE)
  scroll <- elapsed(for (i in seq_len(40L)) pilot$press("down"))
  private <- table$.__enclos_env__$private
  format_elapsed <- median(replicate(5L, elapsed(
    for (i in seq_len(100L)) private$format_values(1L, seq_len(min(20L, n)))
  )))
  table$set_cell(1L, "measure", "1")
  edit_elapsed <- median(replicate(5L, elapsed(
    for (i in seq_len(50L)) table$set_cell(1L, "measure", "1.25")
  ))) / 50
  edit_alloc <- profile_bytes(table$set_cell(1L, "measure", "1.5"))
  data.frame(rows = n, scroll_40_down_ms = round(scroll * 1000, 3),
             format_20_visible_cells_100x_ms = round(format_elapsed * 1000, 3),
             edit_cell_ms = round(edit_elapsed * 1000, 3),
             edit_cell_alloc_bytes = edit_alloc)
}

results <- do.call(rbind, lapply(c(100L, 10000L, 100000L), run_size))
write.csv(results, "audit-results/advanced-types/units/performance-numeric-control.csv",
          row.names = FALSE)
print(results, row.names = FALSE)
