lib <- 'integration-apps/.deps/R-windows'
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(normalizePath(lib), .libPaths()))
options(repos = c(CRAN = 'https://cloud.r-project.org'), timeout = 240)
packages <- c('shiny', 'ggplot2', 'plotly', 'mirai', 'nanonext')
missing <- packages[!vapply(packages, requireNamespace, TRUE, quietly = TRUE)]
if (length(missing)) install.packages(missing, lib = lib, type = 'win.binary')
print(vapply(packages, requireNamespace, TRUE, quietly = TRUE))
if (!all(vapply(packages, requireNamespace, TRUE, quietly = TRUE))) quit(status = 1L)
