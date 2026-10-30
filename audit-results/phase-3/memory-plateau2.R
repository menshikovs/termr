suppressMessages(pkgload::load_all(".", quiet = TRUE))
mem <- function() { invisible(gc(full = TRUE)); invisible(gc(full = TRUE)); gc()[1, 1] }
for (case in c("text_area_nav", "input_edit")) {
  ui <- switch(case, buttons = vertical(button("a", id = "a"), button("b", id = "b")), text_area_nav = vertical(text_area("a\nb\nc d e f", id = "ta")),
               input_edit = vertical(input(id = "in")), mixed = vertical(input(id = "in"), text_area(id = "ta"), button("x"), log_view(), data_table(data.frame(a = 1:30), id = "dt")))
  a <- app(ui); p <- test_app(a, 60, 16); foc <- switch(case, text_area_nav = "#ta", input_edit = "#in", mixed = "#in", NULL); if (!is.null(foc)) a$query_one(foc)$focus()
  keys <- c("down", "up", "left", "right", "home", "end", "pagedown", "pageup"); set.seed(3)
  run <- function(n) { for (i in seq_len(n)) { p$driver$feed(KeyEvent$new(sample(keys, 1))); if (i %% 10 == 0) { p$step(); p$advance(0.25) } }; p$step() }
  run(1000); m0 <- mem(); run(6000); m1 <- mem(); run(6000); m2 <- mem()
  cat(sprintf("%-14s cons cells: +%.2f/event (events 1k-7k), +%.2f/event (7k-13k)\n", case, (m1 - m0) / 6000, (m2 - m1) / 6000)); p$stop()
}
