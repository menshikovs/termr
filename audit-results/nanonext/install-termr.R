host <- if (.Platform$OS.type == "windows") "windows" else "wsl"
lib <- normalizePath(file.path("audit-results/nanonext", paste0("lib-", host)), winslash = "/")
.libPaths(c(lib, .libPaths()))
install.packages(".", repos = NULL, type = "source", lib = lib)
