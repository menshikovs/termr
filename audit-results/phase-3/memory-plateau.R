suppressMessages(pkgload::load_all(".", quiet = TRUE))
mem <- function() { invisible(gc(full = TRUE)); invisible(gc(full = TRUE)); g <- gc(); c(mb = sum(g[, 2]), ncells = g[1, 1], vcells = g[2, 1]) }
for (case in c("buttons", "text_area_nav")) {
  ui <- if (case == "buttons") vertical(button("a", id = "a"), button("b", id = "b"), button("c", id = "c")) else vertical(text_area("a\nb\nc d e f", id = "ta"))
  a <- app(ui); p <- test_app(a, 40, 8); if (case != "buttons") a$query_one("#ta")$focus()
  set.seed(2); keys <- c("tab", "shift+tab", "down", "up", "enter", "left", "right")
  tot <- 0L; cat(case, "\n")
  for (chunk in c(500, 1500, 3000, 3000, 6000, 6000)) {
    for (i in seq_len(chunk)) { p$driver$feed(KeyEvent$new(sample(keys, 1))); if (i %% 10 == 0) p$step() }; p$step(); tot <- tot + chunk
    m <- mem(); cat(sprintf("  after %5d events: used %.2f MB  (Ncells %d, Vcells %d)\n", tot, m[["mb"]], m[["ncells"]], m[["vcells"]]))
  }
  p$stop()
}
