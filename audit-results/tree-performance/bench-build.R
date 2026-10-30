# usage: Rscript bench-build.R <tag>   (PKG env var = source tree)
suppressMessages(pkgload::load_all(Sys.getenv("PKG", "."), quiet = TRUE))
tag <- commandArgs(TRUE)[1]
build <- function(n) app(vertical(lapply(seq_len(n), function(i) horizontal(label(paste("row", i)), input(paste("v", i)), button("b"))), id = "root"))
flat <- function(n) app(vertical(lapply(seq_len(n), function(i) label(paste("row", i))), id = "root"))
rows <- list()
for (w in c(100, 300, 500, 1000, 2000, 3000)) {
  n <- w %/% 4L; reps <- if (w >= 2000) 2 else 3
  tm <- function(f) { gc(); median(vapply(seq_len(reps), function(i) system.time(f())[["elapsed"]], 0)) }
  t_widgets <- tm(function() lapply(seq_len(n), function(i) horizontal(label("r"), input("v"), button("b"))))
  t_build <- tm(function() build(n))
  t_flat <- tm(function() flat(w))
  gc(reset = TRUE); a <- build(n); g <- gc(); mb <- sum(g[, 6])  # max used MB since reset
  a2 <- build(n); t_pilot <- system.time(p <- test_app(a2, 120, 40))[["elapsed"]]; p$stop()
  rows[[length(rows) + 1]] <- data.frame(tag = tag, widgets = n * 4 + 1, make_widgets_s = t_widgets, build_app_s = t_build, flat_labels_s = t_flat, test_app_first_render_s = t_pilot,
                                         obj_mb = as.numeric(lobstr::obj_size(a)) / 1048576, peak_mb = mb)
}
df <- do.call(rbind, rows); print(round(df[-1], 3), row.names = FALSE)
write.csv(df, sprintf("audit-results/tree-performance/logs/build-%s.csv", tag), row.names = FALSE)
