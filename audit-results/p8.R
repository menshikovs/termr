suppressMessages(pkgload::load_all(".", quiet = TRUE))
mk <- function() app(vertical(input(id="in"), text_area(id="ta"), button("OK"), id="root"))
for (focus in c("#in","#ta")) {
 p <- test_app(mk(), 80, 24); p$app$query_one(focus)$focus()
 for (n in c(200, 800)) {
  t <- system.time(for (i in 1:n) { p$driver$feed(KeyEvent$new(if (i%%2) "a" else "down")) ; p$step() })[["elapsed"]]
  cat(focus, n, "keys:", round(t/n*1000,2), "ms/key\n")
 }
 p$stop()
}
# batched: feed all then one step
p <- test_app(mk(), 80, 24); p$app$query_one("#in")$focus()
for (i in 1:1000) p$driver$feed(KeyEvent$new("a"))
t <- system.time(p$step())[["elapsed"]]; cat("1000 batched 'a' keys into input: ", round(t,2), "s\n")
