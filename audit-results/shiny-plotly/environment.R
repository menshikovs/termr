host <- if (.Platform$OS.type == "windows") "windows" else "wsl"
.libPaths(c(file.path("audit-results/shiny-plotly", paste0("lib-", host)),
  file.path("audit-results/nanonext", paste0("lib-", host)), .libPaths()))
cat(R.version.string, "\n")
for (p in c("shiny", "plotly", "ggplot2", "htmlwidgets", "jsonlite", "nanonext", "roxygen2", "bench")) {
  cat(p, if (requireNamespace(p, quietly = TRUE)) as.character(packageVersion(p)) else "ABSENT", "\n")
}
