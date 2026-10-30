suppressMessages(pkgload::load_all(".", quiet = TRUE))
for (nm in c("input", "button")) {
  f <- if (nm == "input") function() input("v") else function() button("b")
  for (i in 1:50) f()
  Rprof(sprintf("audit-results/tree-performance/logs/%s.prof", nm), interval = 0.001); for (i in 1:2000) f(); Rprof(NULL)
  s <- summaryRprof(sprintf("audit-results/tree-performance/logs/%s.prof", nm)); cat("==", nm, "sampling", s$sampling.time, "\n"); print(head(s$by.total, 22))
}
