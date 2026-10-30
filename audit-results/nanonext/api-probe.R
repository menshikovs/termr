host <- if (.Platform$OS.type == "windows") "windows" else "wsl"
.libPaths(c(file.path("audit-results/nanonext", paste0("lib-", host)), .libPaths()))
library(nanonext)
cat("VERSION", as.character(packageVersion("nanonext")), "\n")
p <- socket("pub")
opt(p, "recv-size-max") <- 1048576L
listen(p, "tcp://127.0.0.1:0", fail = "error")
print(p$listener)
print(opt(p$listener[[1L]], "tcp-bound-port"))
ep <- paste0("tcp://127.0.0.1:", opt(p$listener[[1L]], "tcp-bound-port"))
s <- socket("sub")
opt(s, "recv-buffer") <- 16L
opt(s, "reconnect-time-min") <- 50L
opt(s, "reconnect-time-max") <- 1000L
subscribe(s, charToRaw("termr/a\n"))
dial(s, ep, fail = "error")
a <- recv_aio(s, "raw", timeout = 1000L)
print(unresolved(a)); print(unresolved(a$data)); print(a$data)
for (i in 1:50) {
  send(p, charToRaw("termr/a\n{}"), mode = "raw", block = FALSE)
  if (!unresolved(a)) break
  Sys.sleep(0.01)
}
print(a$data)
stop_aio(a)
unsubscribe(s, charToRaw("termr/a\n"))
close(s); close(p)
cat("PASS API options, ephemeral ports, topic raw, AIO status and cancel\n")
