suppressMessages(pkgload::load_all(".", quiet = TRUE))
build <- function(n) app(vertical(lapply(seq_len(n), function(i) horizontal(label(paste("row", i)), input(paste("v", i)), button("b"))), id = "root"))
invisible(test_app(build(5))$stop())
a <- build(750)
t1 <- system.time(layout_tree(a$screen, rect(1L, 1L, 120L, 40L)))[["elapsed"]]
t2 <- system.time(layout_tree(a$screen, rect(1L, 1L, 120L, 40L)))[["elapsed"]]
cat(sprintf("first layout_tree on a fresh 3001-widget tree: %.2fs (screen not yet mounted); second: %.2fs\n", t1, t2))
a <- build(750); Rprof(f <- tempfile(), interval = 0.01); layout_tree(a$screen, rect(1L, 1L, 120L, 40L)); Rprof(NULL)
s <- summaryRprof(f); print(head(s$by.total, 18))
