suppressMessages(pkgload::load_all(".", quiet = TRUE))
res <- list(); note <- function(n, ok, d = "") { cat(sprintf("%-60s %s %s\n", n, if (ok) "PASS" else "FAIL", if (ok) "" else d)); res[[n]] <<- ok }
safe <- function(expr) tryCatch({ force(expr); NULL }, error = function(e) conditionMessage(e))

# 1 remove widget from its own handler
a <- app(vertical(button("x", id = "b"), label("l", id = "l")))
a$on("button.pressed", "#b", function(ev, app) app$query_one("#b")$remove())
p <- test_app(a, 20, 5); a$query_one("#b")$focus()
note("remove focused widget in its handler", is.null(safe({ p$press("enter"); p$press("tab"); p$press("enter") })))
note("  app still renders consistent", identical(p$screen_text(), compose_frame(a$screen, 20L, 5L)$to_text()))
p$stop()

# 2 handler that raises: app policy?
a <- app(button("x", id = "b")); a$on("button.pressed", "#b", function(ev, app) stop("handler boom"))
p <- test_app(a, 20, 5); a$query_one("#b")$focus()
r <- safe(p$press("enter")); cat("   handler error ->", r %||% "swallowed", "\n")
p$stop()

# 3 events after exit
a <- app(label("x")); p <- test_app(a, 10, 3); a$exit("bye")
p$step()
note("press after exit errors cleanly or is ignored", { r <- safe(p$press("a")); TRUE })
r <- safe(a$post_message("late")); cat("   post after exit ->", r %||% "ok", "\n")
r <- safe(a$exit("again")); cat("   exit twice ->", r %||% "ok", "\n")
r <- safe(p$stop()); cat("   stop after exit ->", r %||% "ok", "\n")
r <- safe(p$stop()); cat("   stop twice ->", r %||% "ok", "\n")

# 4 timers: cancel inside own callback, many timers, repeating
a <- app(label("x")); p <- test_app(a, 10, 3); n <- 0
t <- NULL; t <- a$set_interval(0.1, function(app) { n <<- n + 1; if (n == 3) t$cancel() })
p$advance(2)
note("interval cancelled from own callback stops at 3", n == 3, paste("n =", n))
p$stop()

# 5 mount/unmount churn and memory
a <- app(vertical(id = "root")); p <- test_app(a, 40, 10); root <- a$query_one("#root")
gc(); m0 <- sum(gc()[, 2])
for (i in 1:300) { w <- label(paste("row", i)); root$mount(w); p$step(); w$remove(); p$step() }
gc(); m1 <- sum(gc()[, 2])
cat(sprintf("   memory after 300 mount/remove cycles: %+.1f MB; children now %d\n", m1 - m0, length(root$children)))
note("no leftover children", length(root$children) == 0L)
p$stop()

# 6 screens push/pop churn
a <- app(label("base")); p <- test_app(a, 20, 5)
ok <- is.null(safe(for (i in 1:50) { a$push_screen(Screen$new(label(paste("s", i)))); p$step() }))
ok2 <- is.null(safe(for (i in 1:50) { a$pop_screen(); p$step() }))
note("push/pop 50 screens", ok && ok2)
note("  base screen restored", any(grepl("base", p$screen_text())))
r <- safe(a$pop_screen()); cat("   pop last screen ->", r %||% "ok", "\n")
p$stop()

# 7 reactive: update during render, recursion
x <- signal(0L)
a <- app(label(function() paste("v", x())))
p <- test_app(a, 10, 3)
note("reactive update", is.null(safe({ x(5L); p$step() })) && any(grepl("v 5", p$screen_text())))
p$stop()

# 8 workers
a <- app(label("w")); p <- test_app(a, 10, 3)
w <- a$run_worker(function() stop("child fail"))
r <- safe(p$wait_for_workers(10)); cat("   failing worker ->", r %||% "ok", "\n")
p$stop()
cat("workers left after stop:", length(a$workers()), "\n")
cat("FAILS:", sum(!unlist(res)), "\n")
