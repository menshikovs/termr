suppressMessages(pkgload::load_all(".", quiet = TRUE))
build <- function(n) app(vertical(lapply(seq_len(n), function(i) horizontal(label(paste("row", i)), input(paste("v", i)), button("b"))), id = "root"))
tm <- function(n) { s <- system.time(x <- build(n)); g <- gc.time(); c(elapsed = s[["elapsed"]]) }
invisible(build(5))
cat("fresh process, building 3001 widgets repeatedly while keeping every tree alive:\n")
keep <- list()
for (k in 1:5) { t0 <- gc.time(); s <- system.time(keep[[k]] <- build(750)); g <- gc.time() - t0
  cat(sprintf("  build #%d: %.2f s elapsed, of which GC %.2f s; live trees: %d; heap used %.0f MB\n", k, s[["elapsed"]], g[[1]] + g[[2]], k, sum(gc()[, 2]))) }
rm(keep); invisible(gc())
cat("after releasing all trees:\n"); for (k in 1:2) { t0 <- gc.time(); s <- system.time(x <- build(750)); g <- gc.time() - t0; cat(sprintf("  build: %.2f s (GC %.2f s)\n", s[["elapsed"]], g[[1]] + g[[2]])) }
cat("small tree (101 widgets) while a 3001-widget tree is alive:\n"); big <- build(750)
for (k in 1:3) { s <- system.time(for (j in 1:30) build(25)); cat(sprintf("  30 x build(101 widgets): %.2f s = %.1f ms each\n", s[["elapsed"]], s[["elapsed"]] / 30 * 1000)) }
rm(big); invisible(gc())
for (k in 1:2) { s <- system.time(for (j in 1:30) build(25)); cat(sprintf("  heap released: 30 x build(101 widgets): %.1f ms each\n", s[["elapsed"]] / 30 * 1000)) }
