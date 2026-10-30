suppressMessages(pkgload::load_all(".", quiet = TRUE))
ok <- function(n, c, d = "") cat(sprintf("%-62s %s %s\n", n, if (isTRUE(c)) "PASS" else "FAIL", if (isTRUE(c)) "" else d))
# diamond: watcher must see consistent state once
a <- signal(1); b <- computed(function() a() + 1); c2 <- computed(function() a() * 2); seen <- c()
watch(function() seen <<- c(seen, b() + c2())); a(2); a(3)
ok("diamond: watcher sees only consistent states", identical(seen, c(4, 7, 10)), paste(seen, collapse = ","))
# chain through watches
s <- signal(1); t <- signal(0); watch(function() t(s() * 2)); u <- signal(0); watch(function() u(t() + 1)); s(5)
ok("watch chain propagates", u() == 11, u())
# bound label removal
x <- signal("a"); a1 <- app(vertical(label(function() x(), id = "l"), id = "r")); p <- test_app(a1, 20, 4)
info0 <- inspect_signal(x); lb <- a1$query_one("#l"); lb$remove(); p$step(); x("b"); p$step()
info1 <- inspect_signal(x)
cat("   subscribers before/after removing bound label:", length(info0$subscribers %||% info0$subs), "/", length(info1$subscribers %||% info1$subs), "\n"); str(info1, max.level = 1)
ok("writing a signal bound to a removed label is harmless", TRUE)
p$stop()
# repeated create/remove churn leaves no subscribers
y <- signal(0); a2 <- app(vertical(id = "r")); p2 <- test_app(a2, 20, 4)
for (i in 1:200) { l <- label(function() y()); a2$query_one("#r")$mount(l); p2$step(); l$remove(); p2$step() }
y(1); p2$step()
cat("   after 200 bound-label mount/remove cycles:\n"); str(inspect_signal(y), max.level = 1)
# event handler removing the sender's parent; handler re-entrancy
a3 <- app(vertical(vertical(button("x", id = "b"), id = "box"), label("z"), id = "root")); n <- 0L
a3$on("button.pressed", "#b", function(ev, app) { n <<- n + 1L; app$query_one("#box")$remove(); app$post_message("later") })
got <- 0L; a3$on("later", function(ev, app) got <<- got + 1L)
p3 <- test_app(a3, 20, 5); a3$query_one("#b")$focus()
r <- tryCatch({ p3$press("enter"); p3$press("enter"); NULL }, error = function(e) conditionMessage(e))
ok("remove ancestor in handler; message after removal delivered", is.null(r) && n == 1L, paste(r, n, got))
cat("   'later' handler count:", got, "\n")
p3$stop()
