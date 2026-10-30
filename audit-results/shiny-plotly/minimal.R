host <- if (.Platform$OS.type == "windows") "windows" else "wsl"
base <- file.path("audit-results/shiny-plotly", paste0("minimal-", host))
dir.create(base, recursive = TRUE, showWarnings = FALSE)
for (package in c("R6", "processx", "ps")) {
  path <- find.package(package)
  stopifnot(file.copy(path, base, recursive = TRUE))
}
install.packages(".", lib = base, repos = NULL, type = "source")
.libPaths(normalizePath(base), include.site = FALSE)
stopifnot(!requireNamespace("shiny", quietly = TRUE), !requireNamespace("ggplot2", quietly = TRUE),
  !requireNamespace("plotly", quietly = TRUE), !requireNamespace("nanonext", quietly = TRUE))
library(termr)
source <- termr_stream("minimal")
source$emit(list(timestamp = Sys.time(), cpu = NA_real_, ram = 50))
frame <- termr_stream_data(source, c("cpu", "ram"))
stopifnot(is.na(frame$cpu[[1L]]), frame$ram[[1L]] == 50)
pilot <- test_app(app(label("Minimal core")), 30, 5)
stopifnot(any(grepl("Minimal core", pilot$screen_text(), fixed = TRUE)))
pilot$stop()
message <- tryCatch({termr_shiny_receiver(source); "error missing"}, error = conditionMessage)
stopifnot(grepl("optional package 'shiny'", message, fixed = TRUE))
source$close()
cat("PASS core, TUI and data.frame without Shiny/ggplot2/Plotly/nanonext; clear optional error\n")
