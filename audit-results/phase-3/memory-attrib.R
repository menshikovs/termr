suppressMessages(pkgload::load_all(".", quiet = TRUE))
mem <- function() { invisible(gc(full = TRUE)); invisible(gc(full = TRUE)); sum(gc()[, 2]) }
keys <- c("a", "b", "backspace", "tab", "down", "up", "enter", "shift+tab", "left", "right", "你", "home", "end")
run <- function(write_log, n = 6000) {
  a <- app(vertical(label("status", id = "s"), input(id = "in"), text_area(id = "ta"), button("go", id = "b"), log_view(id = "log"), id = "root"))
  presses <- 0L
  a$on("button.pressed", "#b", function(ev, app) { presses <<- presses + 1L; if (write_log) app$query_one("#log")$write("line") })
  p <- test_app(a, 80, 24); a$query_one("#in")$focus(); set.seed(1)
  for (i in 1:300) p$driver$feed(KeyEvent$new(sample(keys, 1))); p$step()
  m0 <- mem()
  for (i in seq_len(n)) { p$driver$feed(KeyEvent$new(sample(keys, 1))); if (i %% 20 == 0) p$step() }
  p$step(); m1 <- mem()
  cat(sprintf("write_log=%-5s events=%d button presses=%d  mem delta=%+.2f MB  text_area chars=%d  input chars=%d\n", write_log, n, presses, m1 - m0,
              nchar(paste(a$query_one("#ta")$value, collapse = "")), nchar(a$query_one("#in")$value)))
  p$stop()
}
run(TRUE); run(FALSE)
