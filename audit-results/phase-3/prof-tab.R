suppressMessages(pkgload::load_all(".", quiet = TRUE))
a <- app(vertical(horizontal(label("r"), input("v"), button("b")), horizontal(label("r"), input("v"), button("b")), horizontal(label("r"), input("v"), button("b"))))
p <- test_app(a, 120, 40); for (i in 1:5) p$press("tab")
t1 <- system.time(for (i in 1:20) p$press("tab"))[["elapsed"]] / 20 * 1000
t2 <- system.time(for (i in 1:20) p$press("a"))[["elapsed"]] / 20 * 1000
t3 <- system.time(for (i in 1:20) { p$driver$feed(KeyEvent$new("tab")); p$app$.__enclos_env__$private$tick(wait = FALSE) })[["elapsed"]] / 20 * 1000
cat(sprintf("press(tab) %.1f ms | press(a) %.1f ms | feed+tick(tab) %.1f ms\n", t1, t2, t3))
Rprof("audit-results/phase-3/logs/tab.prof", interval = 0.005); for (i in 1:30) p$press("tab"); Rprof(NULL)
s <- summaryRprof("audit-results/phase-3/logs/tab.prof"); print(head(s$by.total, 14)); cat("sampling.time", s$sampling.time, "\n")
print(body(p$press))
