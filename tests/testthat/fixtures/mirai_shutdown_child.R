# Isolate native shutdown regressions so a backend deadlock has a hard timeout.
library(termr)
for (iteration in 1:30) {
  pool <- termr_mirai_pool(2L, history = 16L)
  for (i in 1:3) pool$submit(function(progress) {
    for (j in 1:100) {Sys.sleep(.005); progress(j / 100)}
    TRUE
  }, progress = TRUE)
  for (i in 1:3) {pool$poll(); Sys.sleep(.005)}
  cat("closing", iteration, "\n"); flush.console()
  pool$close()
  stopifnot(pool$diagnostics()$pending == 0L)
  cat("closed", iteration, "\n"); flush.console()
}
cat("PASS repeated active shutdown\n")
