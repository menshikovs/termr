host <- if (.Platform$OS.type == "windows") "windows" else "wsl"
lib <- file.path("audit-results/shiny-plotly", paste0("lib-", host))
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(normalizePath(lib), file.path("audit-results/nanonext", paste0("lib-", host)), .libPaths()))
needed <- c("shiny", "ggplot2", "plotly")
needed <- needed[!vapply(needed, requireNamespace, logical(1), quietly = TRUE)]
if (length(needed)) install.packages(needed, lib = lib, repos = "https://cloud.r-project.org")
stopifnot(all(vapply(c("shiny", "ggplot2", "plotly"), requireNamespace, logical(1), quietly = TRUE)))
source("audit-results/shiny-plotly/environment.R")
