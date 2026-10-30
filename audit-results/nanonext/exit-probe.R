.libPaths(c("audit-results/nanonext/lib-windows", .libPaths()))
args <- commandArgs(trailingOnly = TRUE)
if (length(args)) {
  s <- nanonext::socket("sub", dial = args[[1L]])
  nanonext::subscribe(s, NULL)
  r <- nanonext::socket("req", dial = args[[2L]])
  a <- nanonext::recv_aio(s, "raw", timeout = 1000L)
  start <- proc.time()[["elapsed"]]
  n <- 0L
  while (n < 100L && proc.time()[["elapsed"]] - start < 5) {
    if (!nanonext::unresolved(a)) {
      v <- a$data; nanonext::stop_aio(a)
      if (is.raw(v)) n <- n + 1L
      a <- nanonext::recv_aio(s, "raw", timeout = 1000L)
    }
    Sys.sleep(0.001)
  }
  cat("received", n, "\n", file = stderr())
  nanonext::stop_aio(a)
  nanonext::unsubscribe(s, NULL)
  close(s); close(r)
  cat("closed sockets\n", file = stderr())
  rm(a, s, r); gc()
  cat("GC done\n", file = stderr())
} else {
  s <- nanonext::socket("pub", listen = "tcp://127.0.0.1:0")
  r <- nanonext::socket("rep", listen = "tcp://127.0.0.1:0")
  ep <- function(socket) paste0("tcp://127.0.0.1:", nanonext::opt(socket$listener[[1L]], "tcp-bound-port"))
  p <- processx::process$new(file.path(R.home("bin"), "Rscript"), c("--vanilla",
    "audit-results/nanonext/exit-probe.R", ep(s), ep(r)), stdout = "|", stderr = "|")
  start <- proc.time()[["elapsed"]]
  while (p$is_alive() && proc.time()[["elapsed"]] - start < 10) {
    nanonext::send(s, charToRaw("x"), mode = "raw", block = FALSE)
    Sys.sleep(0.003)
  }
  p$wait(1000)
  cat("EXIT", p$get_exit_status(), "\n", p$read_all_error())
  if (p$is_alive()) p$kill_tree()
  close(s); close(r)
}
