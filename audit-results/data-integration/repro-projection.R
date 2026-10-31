pkgload::load_all('.', quiet = TRUE)
requests <- list()
cn <- paste0("v", seq_len(20))
opts <- stats::setNames(lapply(cn, function(x) termr::column(width = 6L)), cn)
src <- termr::table_source(
  1000L, cn,
  function(start, count, columns = NULL) {
    requests[[length(requests) + 1L]] <<- columns
    as.data.frame(stats::setNames(lapply(columns, function(x) seq.int(start, length.out = count)), columns), check.names = FALSE)
  }
)
tbl <- termr::data_table(src, cursor = "none", columns = opts)
requests <- list()
tbl$scroll_to_row(500L)
invisible(termr::render_widget(tbl, 25L, 8L))
cat("columns requested per paint fetch:\n")
print(requests)
cat("unique columns:", paste(unique(unlist(requests)), collapse = ", "), "\n")