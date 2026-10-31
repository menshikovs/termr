pkgload::load_all('.', quiet = TRUE)
out <- 'audit-results/hardening/h3-performance'
rows <- list()
sheet <- if (requireNamespace('inkr', quietly = TRUE)) 'Label {color: cyan;}' else NULL
for (i in 1:100) {
  w <- label('resource cycle')
  t <- data_table(data.frame(x = 1:100))
  a <- app(vertical(w, t), inkr_stylesheet = sheet)
  p <- test_app(a, width = 50, height = 10)
  for (j in 1:5) {
    src <- table_source(10000000L, 'x', function(start, count, columns) data.frame(x = seq.int(start, length.out = count)))
    t$set_data(src); t$scroll_to_row(j * 10000L); p$step()
    stopifnot(length(ls(t$.__enclos_env__$private$.source_cache, all.names = TRUE)) <= 32L)
    if (!is.null(sheet)) {a$set_inkr_stylesheet(sheet); w$computed_style(); a$clear_inkr_stylesheet()}
  }
  stopifnot(length(ls(a$.__enclos_env__$private$.inkr_cache, all.names = TRUE)) == 0L)
  p$stop()
  rm(p, a, w, t, src)
  if (i %% 10L == 0L) {
    g <- gc()
    rss <- if (requireNamespace('ps', quietly = TRUE)) unname(ps::ps_memory_info()[['rss']]) else NA_real_
    rows[[length(rows) + 1L]] <- data.frame(cycles = i, ncells = g[1, 'used'], vcells = g[2, 'used'],
      rss_bytes = rss, connections = nrow(showConnections(all = TRUE)))
    write.csv(do.call(rbind, rows), file.path(out, paste0('resource-cycles-', .Platform$OS.type, '.csv')), row.names = FALSE)
  }
}
if (requireNamespace('DBI', quietly = TRUE) && requireNamespace('RSQLite', quietly = TRUE)) {
  for (i in 1:100) {
    con <- DBI::dbConnect(RSQLite::SQLite(), ':memory:')
    src <- db_table_source(con, 'sqlite_master', owned = TRUE)
    src$close()
    stopifnot(!DBI::dbIsValid(con))
  }
  cat('DBI owned connection cycles: 100 passed\n')
} else cat('DBI connection cycles: SKIP (DBI/RSQLite absent)\n')
cat('Source/style cycles: 100 passed\n')
