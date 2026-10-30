source("audit-results/mirai/environment.R")
Sys.setenv(R_LIBS = paste(normalizePath(.libPaths(), winslash = "/"), collapse = .Platform$path.sep), R_TESTS = "")
library(mirai)
main <- function() {
  profile <- paste0("termr-probe-", Sys.getpid())
  daemons(1L, .compute = profile)
  on.exit(daemons(0L, .compute = profile), add = TRUE)
  m <- mirai(list(pid = Sys.getpid(), time = as.numeric(Sys.time()), libs = .libPaths()), .compute = profile)
  deadline <- proc.time()[["elapsed"]] + 15
  while (unresolved(m)) {if (proc.time()[["elapsed"]] > deadline) stop("start timeout"); Sys.sleep(.005)}
  print(m$data); print(status(.compute = profile)); print(info(.compute = profile))
  slow <- mirai(Sys.sleep(2), .compute = profile)
  queued <- mirai(42, .timeout = 100L, .compute = profile)
  start <- proc.time()[["elapsed"]]
  while (unresolved(queued) && proc.time()[["elapsed"]] - start < 5) Sys.sleep(.005)
  cat("QUEUED TIMEOUT", proc.time()[["elapsed"]] - start, "\n"); print(queued$data)
  print(stop_mirai(slow)); print(slow$data); print(stop_mirai(slow))
  done <- mirai(42, .compute = profile)
  deadline <- proc.time()[["elapsed"]] + 10
  while (unresolved(done)) {if (proc.time()[["elapsed"]] > deadline) stop("recover timeout"); Sys.sleep(.005)}
  print(done$data); print(stop_mirai(done))
  error <- mirai(stop("probe failure"), .compute = profile)
  while (unresolved(error)) {if (proc.time()[["elapsed"]] > deadline) stop("error timeout"); Sys.sleep(.005)}
  print(error$data); print(class(error$data))
}
main()
