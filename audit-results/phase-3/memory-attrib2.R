suppressMessages(pkgload::load_all(".", quiet = TRUE))
mem <- function() { invisible(gc(full = TRUE)); invisible(gc(full = TRUE)); sum(gc()[, 2]) }
run <- function(name, ui, keys, n = 8000, focus = NULL) {
  a <- app(ui); p <- test_app(a, 80, 24); if (!is.null(focus)) a$query_one(focus)$focus(); set.seed(2)
  for (i in 1:300) { p$driver$feed(KeyEvent$new(sample(keys, 1))); if (i %% 10 == 0) p$step() }; p$step()
  m0 <- mem(); t0 <- Sys.time()
  for (i in seq_len(n)) { p$driver$feed(KeyEvent$new(sample(keys, 1))); if (i %% 10 == 0) p$step() }; p$step(); m1 <- mem()
  cat(sprintf("%-28s %d events: mem delta %+.2f MB (%.0f B/event)  %.1f ms/event\n", name, n, m1 - m0, (m1 - m0) * 1048576 / n, as.numeric(difftime(Sys.time(), t0, units = "secs")) / n * 1000))
  p$stop()
}
nav <- c("tab", "shift+tab", "down", "up", "left", "right", "enter", "home", "end")
typ <- c("a", "b", "backspace", "left", "right", "home", "end")
run("label only (no input)", vertical(label("x")), nav)
run("button + tab/enter", vertical(button("a"), button("b"), button("c")), nav)
run("input editing", vertical(input(id = "in")), typ, focus = "#in")
run("text_area navigation only", vertical(text_area("a\nb\nc d e f", id = "ta")), nav, focus = "#ta")
run("text_area typing", vertical(text_area(id = "ta")), c("a", "backspace", "enter", "left", "up", "down"), focus = "#ta")
run("data_table nav", vertical(data_table(data.frame(a = 1:200, b = "x"), id = "dt")), nav, focus = "#dt")
