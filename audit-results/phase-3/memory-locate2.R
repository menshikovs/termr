suppressMessages(pkgload::load_all(".", quiet = TRUE))
a <- app(vertical(button("a", id = "a"), button("b", id = "b"), id = "root"))
p <- test_app(a, 40, 8); set.seed(2); keys <- c("tab", "shift+tab", "down", "up", "enter", "left", "right")
go <- function(n) { for (i in seq_len(n)) { p$driver$feed(KeyEvent$new(sample(keys, 1))); if (i %% 10 == 0) p$step() }; p$step() }
skip <- c(".parent", ".children", ".app", "app", "parent", "children", "self", "private", ".__enclos_env__", "super")
fields <- function(w) { pr <- w$.__enclos_env__$private; out <- list()
  for (n in setdiff(ls(pr, all.names = TRUE), skip)) { v <- get(n, pr); if (!is.function(v)) out[[paste0("priv.", n)]] <- as.numeric(lobstr::obj_size(v)) }
  for (n in setdiff(ls(w, all.names = TRUE), skip)) { v <- tryCatch(get(n, w), error = function(e) NULL); if (!is.function(v) && !is.environment(v)) out[[paste0("pub.", n)]] <- as.numeric(lobstr::obj_size(v)) }
  unlist(out) }
targets <- list(screen = a$screen, root = a$query_one("#root"), a = a$query_one("#a"))
go(500); b0 <- lapply(targets, fields); go(6000); b1 <- lapply(targets, fields)
for (n in names(targets)) { d <- b1[[n]] - b0[[n]][names(b1[[n]])]; d <- d[!is.na(d) & d != 0]; cat(n, ":\n"); print(sort(d, decreasing = TRUE)[1:5]) }
cat("app public fields growth:\n")
afields <- function() { out <- sapply(setdiff(ls(a, all.names = TRUE), skip), function(n) { v <- tryCatch(get(n, a), error = function(e) NULL); if (is.function(v) || is.environment(v)) 0 else as.numeric(lobstr::obj_size(v)) }); out }
x0 <- afields(); go(3000); x1 <- afields(); dd <- x1 - x0[names(x1)]; print(sort(dd[dd != 0], decreasing = TRUE)[1:6])
