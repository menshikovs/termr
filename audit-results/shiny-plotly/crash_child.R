args <- commandArgs(trailingOnly = TRUE)
mode <- args[[1L]]
host <- if (.Platform$OS.type == "windows") "windows" else "wsl"
.libPaths(c(file.path("audit-results/shiny-plotly", paste0("lib-", host)),
  file.path("audit-results/nanonext", paste0("lib-", host)), .libPaths()))
cat(R.version.string, mode, "\n")
if (startsWith(mode, "pkgload")) pkgload::load_all(".", quiet = TRUE, helpers = mode != "pkgload-no-helpers") else library(termr)
if (mode == "pkgload-no-nano") {
  stopifnot(!"nanonext" %in% loadedNamespaces())
  cat("PASS loaded core without nanonext\n")
} else {
  r <- termr_nano_connect(args[[2L]], "crash", args[[3L]], resync_interval = 0.05)
  if (grepl("shiny", mode)) {
    receiver <- termr_shiny_receiver(r)
    shiny::testServer(function(input, output, session) {
      value <- termr_shiny_reactive(receiver, session)
    }, {
      started <- proc.time()[["elapsed"]]
      while (is.null(value()) || value()$n < 100L) {
        receiver$poll(); session$flushReact()
        if (proc.time()[["elapsed"]] - started > 10) stop("Timeout in crash probe")
        Sys.sleep(0.002)
      }
      session$close()
    })
    receiver$close()
  } else {
    started <- proc.time()[["elapsed"]]
    while (is.null(r$latest()) || r$latest()$n < 100L) {
      r$poll()
      if (proc.time()[["elapsed"]] - started > 10) stop("Timeout in crash probe")
      Sys.sleep(0.002)
    }
  }
  cat("received", r$latest()$n, "\n")
  r$close()
  cat("closed native owner\n")
}
