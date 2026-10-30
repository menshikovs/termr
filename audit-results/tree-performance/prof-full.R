suppressMessages(pkgload::load_all(".", quiet = TRUE))
invisible(app(vertical(horizontal(label("w"), input("w"), button("w")))))  # warm up
n <- 750
Rprof("audit-results/tree-performance/logs/full.prof", interval = 0.005)
a <- app(vertical(lapply(seq_len(n), function(i) horizontal(label(paste("row", i)), input(paste("v", i)), button("b"))), id = "root"))
Rprof(NULL)
s <- summaryRprof("audit-results/tree-performance/logs/full.prof"); cat("sampling", s$sampling.time, "s\n")
print(head(s$by.total, 40)); cat("--- self ---\n"); print(head(s$by.self, 20))
cat("gc/memory:\n"); print(gc())
