suppressMessages(pkgload::load_all(".", quiet = TRUE))
sizes <- function(env) { nm <- ls(env, all.names = TRUE); out <- vapply(nm, function(n) { v <- tryCatch(get(n, env), error = function(e) NULL); if (is.environment(v)) length(ls(v, all.names = TRUE)) else if (is.function(v)) -1L else length(v) }, 1L); out[out >= 0] }
a <- app(vertical(button("a", id = "a"), button("b", id = "b"), button("c", id = "c")))
p <- test_app(a, 40, 8); set.seed(2); keys <- c("tab", "shift+tab", "down", "up", "enter")
step <- function(n) for (i in seq_len(n)) { p$driver$feed(KeyEvent$new(sample(keys, 1))); if (i %% 10 == 0) p$step() }
step(500); s0 <- sizes(a$.__enclos_env__$private); step(5000); s1 <- sizes(a$.__enclos_env__$private)
d <- s1 - s0[names(s1)]; print(d[d != 0])
tm <- a$.__enclos_env__$private$.timers; st0 <- sizes(tm$.__enclos_env__$private); cat("timer private sizes:\n"); print(st0[st0 > 0])
fm <- a$.__enclos_env__$private$.focus; cat("focus private sizes:\n"); print(sizes(fm$.__enclos_env__$private))
w <- a$query_one("#a"); wp <- sizes(w$.__enclos_env__$private); cat("widget private sizes:\n"); print(wp[wp > 5])
