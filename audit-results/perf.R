suppressMessages(pkgload::load_all(".", quiet = TRUE))
tm <- function(expr, n = 5) { expr <- substitute(expr); expr_env <- parent.frame(); eval(expr, expr_env)
  t <- vapply(seq_len(n), function(i) system.time(eval(expr, expr_env))[["elapsed"]], 0); c(median = median(t) * 1000, min = min(t) * 1000) }
build <- function(n) app(vertical(lapply(seq_len(n), function(i) horizontal(label(paste("row", i)), input(paste("v", i)), button("b"))), id = "root"))
cat("components  create_ms  first_render_ms  key_ms(inc)  full_repaint_ms  resize_ms\n")
for (n in c(10, 50, 200, 500)) {
  c1 <- tm(build(n), 3)[["median"]]
  a <- build(n); p <- test_app(a, 120, 40)
  inp <- a$query("Input")[[1]]; inp$focus()
  k <- tm({ p$press("a") }, 15)[["median"]]
  fr <- tm({ a$request_repaint(); p$step() }, 5)[["median"]]
  rs <- tm({ p$resize(100, 30); p$resize(120, 40) }, 3)[["median"]] / 2
  cat(sprintf("%5d  %10.1f %10.1f %14.1f %14.1f %12.1f\n", n * 3, c1, NA, k, fr, rs))
  p$stop()
}
# state accumulation: 2000 keypresses, memory
a <- build(20); p <- test_app(a, 80, 24); a$query("Input")[[1]]$focus(); gc()
m0 <- sum(gc()[, 2]); t0 <- Sys.time()
for (i in 1:2000) p$press(if (i %% 2) "a" else "backspace")
cat(sprintf("2000 keys: %.1fs, mem delta %+.1f MB, event_log-free\n", as.numeric(difftime(Sys.time(), t0, units = "secs")), sum(gc()[, 2]) - m0))
