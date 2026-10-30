source("audit-results/shiny-plotly/environment.R")
host <- if (.Platform$OS.type == "windows") "windows" else "wsl"
lib <- file.path("audit-results/shiny-plotly", paste0("lib-", host))
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
lib <- normalizePath(lib, winslash = "/")
install.packages(".", lib = lib, repos = NULL, type = "source")
