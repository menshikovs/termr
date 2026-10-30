suppressMessages(pkgload::load_all(".", quiet = TRUE))
for (w in 1:3) for (txt in c("你好", "a你", "😀")) for (cur in 0:2) {
  i <- input(txt)
  a <- app(i); p <- test_app(a, 10, 3); i$focus(); i$cursor_position <- min(cur, 2)
  r <- tryCatch({ i$render_lines(w); "ok" }, error=function(e) conditionMessage(e))
  if (r != "ok") cat("width", w, deparse(txt), "cursor", cur, "->", r, "\n")
  p$stop()
}
