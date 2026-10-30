# usage: Rscript bench-keypress.R <label> ; writes CSV to phase-3/logs/bench-<label>.csv
suppressMessages(pkgload::load_all(Sys.getenv("PKG", "."), quiet = TRUE))
label_ <- commandArgs(TRUE)[1]
build <- function(n) app(vertical(lapply(seq_len(n), function(i) horizontal(label(paste("row", i)), input(paste("v", i)), button("b"))), id = "root"))
rows <- list()
for (w in c(10, 30, 100, 300, 500, 1000, 1500)) {
  n <- max(1L, w %/% 3L)
  t_create <- median(vapply(1:3, function(i) system.time(build(n))[["elapsed"]], 0))
  a <- build(n); p <- test_app(a, 120, 40); a$query("Input")[[1]]$focus()
  for (i in 1:3) p$press("a")
  reps <- if (w >= 1000) 12 else 30
  keys <- vapply(seq_len(reps), function(i) system.time(p$press(if (i %% 2) "a" else "backspace"))[["elapsed"]], 0)
  full <- vapply(1:5, function(i) system.time({ a$request_repaint(); p$step() })[["elapsed"]], 0)
  rows[[length(rows) + 1]] <- data.frame(label = label_, widgets = n * 4 + 1, create_ms = t_create * 1e3,
    key_median_ms = median(keys) * 1e3, key_min_ms = min(keys) * 1e3, key_max_ms = max(keys) * 1e3, full_repaint_ms = median(full) * 1e3)
  p$stop()
}
df <- do.call(rbind, rows); print(df, digits = 4)
write.csv(df, file.path("audit-results/phase-3/logs", paste0("bench-", label_, ".csv")), row.names = FALSE)
cat("R", R.version.string, "| cores", parallel::detectCores(), "| date", format(Sys.time()), "\n")
