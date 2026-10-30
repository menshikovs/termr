suppressMessages(pkgload::load_all(".", quiet = TRUE))
build <- function(n) app(vertical(lapply(seq_len(n), function(i) horizontal(label(paste("row", i)), input(paste("v", i)), button("b"))), id = "root"))
invisible(test_app(build(5))$stop())
for (n in c(250, 500, 750)) {
  t_build <- system.time(a <- build(n))[["elapsed"]]
  Rprof(tmp <- tempfile(), interval = 0.01); t_start <- system.time(p <- test_app(a, 120, 40))[["elapsed"]]; Rprof(NULL)
  s <- summaryRprof(tmp)$by.total
  pick <- function(k) { v <- s[rownames(s) == sprintf('"%s"', k), "total.pct"]; if (length(v)) v else NA }
  t_resize <- system.time({ p$resize(100, 30) })[["elapsed"]]
  cat(sprintf("%4d widgets: build %.2fs | test_app (mount+layout+paint+VT) %.2fs | resize repaint %.2fs | profile share: refresh_screen %s%%, layout_tree %s%%, print_char %s%%, mount/dispatch %s%%\n",
              n * 4 + 1, t_build, t_start, t_resize, pick("private$refresh_screen"), pick("layout_tree"), pick("private$print_char"), pick("private$dispatch")))
  p$stop()
}
