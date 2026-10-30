host <- if (.Platform$OS.type == "windows") "windows" else "wsl"
lib <- normalizePath(file.path("audit-results", "nanonext"), winslash = "/")
lib <- file.path(lib, paste0("lib-", host))
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(lib, .libPaths()))
if (!requireNamespace("nanonext", quietly = TRUE)) {
  install.packages("nanonext", lib = lib, repos = "https://cloud.r-project.org")
}
stopifnot(requireNamespace("nanonext", quietly = TRUE))
source("audit-results/nanonext/probe.R")
