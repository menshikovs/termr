suppressMessages(pkgload::load_all(".", quiet = TRUE))
a <- app(vertical(button("a", id = "a"), button("b", id = "b"), button("c", id = "c")))
p <- test_app(a, 40, 8); set.seed(2); keys <- c("tab", "shift+tab", "down", "up", "enter", "left", "right")
go <- function(n) { for (i in seq_len(n)) { p$driver$feed(KeyEvent$new(sample(keys, 1))); if (i %% 10 == 0) p$step() }; p$step() }
snap <- function() c(app = as.numeric(lobstr::obj_size(a)), termr_env = as.numeric(lobstr::obj_size(termr_env)), rx = as.numeric(lobstr::obj_size(rx)),
                     pilot = as.numeric(lobstr::obj_size(p)), ns = as.numeric(lobstr::obj_size(asNamespace("termr"))))
go(500); s0 <- snap(); go(10000); s1 <- snap()
print(rbind(after500 = s0, after10500 = s1, delta = s1 - s0))
cat("termr_env fields:\n"); print(sapply(ls(termr_env, all.names = TRUE), function(n) as.numeric(lobstr::obj_size(get(n, termr_env)))))
cat("rx fields:\n"); print(sapply(ls(rx, all.names = TRUE), function(n) length(get(n, rx))))
cat("driver size:", as.numeric(lobstr::obj_size(p$driver)), "\n")
cat("---- per-field growth inside app private ----\n")
priv <- a$.__enclos_env__$private
fs <- function() sapply(ls(priv, all.names = TRUE), function(n) { v <- get(n, priv); if (is.function(v)) 0 else as.numeric(lobstr::obj_size(v)) })
f0 <- fs(); go(5000); f1 <- fs(); d <- f1 - f0[names(f1)]; print(sort(d[d != 0], decreasing = TRUE)[1:8])
cat("---- widgets ----\n")
ws <- function(w) as.numeric(lobstr::obj_size(w))
w0 <- sapply(c("#a", "#b", "#c"), function(i) ws(a$query_one(i))); go(5000); w1 <- sapply(c("#a", "#b", "#c"), function(i) ws(a$query_one(i))); print(w1 - w0)
w <- a$query_one("#a"); wp <- w$.__enclos_env__$private
g <- function() sapply(ls(wp, all.names = TRUE), function(n) { v <- get(n, wp); if (is.function(v)) 0 else as.numeric(lobstr::obj_size(v)) }); x0 <- g(); go(5000); x1 <- g(); dd <- x1 - x0[names(x1)]; print(sort(dd[dd != 0], decreasing = TRUE)[1:6])
