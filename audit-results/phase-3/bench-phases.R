suppressMessages(pkgload::load_all(Sys.getenv("PKG", "."), quiet = TRUE))
build <- function(n) app(vertical(lapply(seq_len(n), function(i) horizontal(label(paste("row", i)), input(paste("v", i)), button("b"))), id = "root"))
med <- function(f, n = 5) median(vapply(seq_len(n), function(i) system.time(f())[["elapsed"]], 0)) * 1000
rows <- list()
for (w in c(10, 30, 100, 300, 500, 1000, 1500, 3000)) {
  n <- max(1L, w %/% 4L); a <- build(n); p <- test_app(a, 120, 40); inp <- a$query("Input")[[1]]; inp$focus()
  tree <- med(function() build(n), 3)
  lay <- med(function() layout_tree(a$screen, rect(1L, 1L, 120L, 40L)))
  paint <- med(function() { b <- ScreenBuffer$new(120L, 40L); paint_tree(a$screen, b) })
  snap <- med(function() layout_snapshot(list(a$screen)))
  reps <- if (w >= 1000) 10 else 25
  l0 <- a$frame_stats[["layouts"]]
  key <- med(function() p$press("a"), reps); lay_key <- a$frame_stats[["layouts"]] - l0
  tab <- med(function() p$press("tab"), reps)
  rows[[length(rows) + 1]] <- data.frame(widgets = n * 4 + 1, create_tree_ms = tree, layout_ms = lay, paint_ms = paint, snapshot_ms = snap,
                                         key_ms = key, layouts_per_key = lay_key / (reps + 1), tab_ms = tab)
  p$stop()
}
df <- do.call(rbind, rows); print(round(df, 1), row.names = FALSE)
write.csv(df, paste0("audit-results/phase-3/logs/phases-", Sys.getenv("TAG", "current"), ".csv"), row.names = FALSE)
