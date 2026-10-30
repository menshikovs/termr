suppressMessages(pkgload::load_all(".", quiet = TRUE))
ncells <- function() { invisible(gc(full = TRUE)); invisible(gc(full = TRUE)); gc()[1, 1] }
test <- function(name, setup, op, n = 4000) {
  e <- setup(); p <- e$p; for (i in 1:200) op(e, i); m0 <- ncells(); for (i in seq_len(n)) op(e, i); m1 <- ncells()
  cat(sprintf("%-34s %+6.2f cons cells/op\n", name, (m1 - m0) / n)); p$stop() }
mk <- function(focus = "#a") function() { a <- app(vertical(button("a", id = "a"), button("b", id = "b"), id = "root")); p <- test_app(a, 40, 8); a$query_one(focus)$focus(); list(a = a, p = p) }
feed <- function(k, step_every = 1) function(e, i) { e$p$driver$feed(KeyEvent$new(k)); if (i %% step_every == 0) e$p$step() }
test("step only (no events)", mk(), function(e, i) e$p$step())
test("key 'left' (ignored by button)", mk(), feed("left"))
test("key 'tab' (focus ping-pong)", mk(), feed("tab"))
test("key 'enter' (press button)", mk(), feed("enter"))
test("key 'tab', step every 10", mk(), feed("tab", 10))
test("focus() call alternating", mk(), function(e, i) { e$a$query_one(if (i %% 2) "#a" else "#b")$focus(); e$p$step() })
test("request_repaint + step", mk(), function(e, i) { e$a$request_repaint(); e$p$step() })
test("label update alternating text", function() { a <- app(vertical(label("x", id = "l"))); p <- test_app(a, 40, 8); list(a = a, p = p) }, function(e, i) { e$a$query_one("#l")$update(if (i %% 2) "aa" else "bbb"); e$p$step() })
cat("--- same, but letting simulated time pass so timers fire ---\n")
test("key 'enter' + advance(0.2)", mk(), function(e, i) { e$p$driver$feed(KeyEvent$new("enter")); e$p$step(); e$p$advance(0.2) })
e <- mk()(); for (i in 1:50) e$p$driver$feed(KeyEvent$new("enter")); e$p$step()
cat("pending timers after 50 presses without time advancing:", length(e$a$.__enclos_env__$private$.timers$timers), "\n"); e$p$advance(1)
cat("pending timers after advancing 1 s:", length(e$a$.__enclos_env__$private$.timers$timers), "\n")
