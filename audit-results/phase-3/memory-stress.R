suppressMessages(pkgload::load_all(".", quiet = TRUE))
mem <- function() { invisible(gc(full = TRUE)); invisible(gc(full = TRUE)); g <- gc(); c(mb = sum(g[, 2]), cells = sum(g[, 1])) }
count_envs <- function() length(ls(globalenv()))  # placeholder
ui <- function() app(vertical(label("status", id = "s"), input(id = "in"), text_area(id = "ta"), button("go", id = "b"),
                              log_view(id = "log"), data_table(data.frame(a = 1:50, b = letters[rep(1:26, length.out = 50)]), id = "dt"), id = "root"))
keys <- c("a", "b", "backspace", "tab", "down", "up", "enter", "shift+tab", "left", "right", "你", "home", "end")
for (n in c(1000, 10000, 100000)) {
  a <- ui(); p <- test_app(a, 80, 24); a$query_one("#in")$focus()
  a$on("button.pressed", "#b", function(ev, app) { app$query_one("#s")$update(format(runif(1))); app$query_one("#log")$write("line") })
  for (i in 1:200) p$press(sample(keys, 1))        # warm up
  m0 <- mem(); t0 <- Sys.time(); set.seed(1)
  half <- n %/% 2; m_half <- NULL
  for (i in seq_len(n)) { p$driver$feed(KeyEvent$new(sample(keys, 1))); if (i %% 20 == 0 || i == n) p$step(); if (i == half) m_half <- mem() }
  m1 <- mem(); el <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  cat(sprintf("events=%6d  time=%6.1fs (%.2f ms/ev)  mem MB: start %.1f half %.1f end %.1f  | delta(end-start)=%+.2f MB, delta(end-half)=%+.2f MB\n", n, el, el / n * 1000, m0[1], m_half[1], m1[1], m1[1] - m0[1], m1[1] - m_half[1]))
  p$stop()
  if (n >= 10000) break_after <- TRUE
}
