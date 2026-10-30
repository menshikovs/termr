cat(R.version.string, "\n")
for (p in c("nanonext", "jsonlite", "shiny", "roxygen2", "bench")) {
  cat(p, if (requireNamespace(p, quietly = TRUE)) as.character(packageVersion(p)) else "ABSENT", "\n")
}
if (requireNamespace("nanonext", quietly = TRUE)) {
  for (f in c("socket", "subscribe", "unsubscribe", "send", "recv", "send_aio", "recv_aio", "close", "stop_aio", "unresolved", "opt", "listen", "dial", "status")) {
    cat("\n", f, ":\n"); if (f %in% getNamespaceExports("nanonext")) print(args(getExportedValue("nanonext", f)))
  }
}
