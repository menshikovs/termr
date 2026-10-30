host <- if (.Platform$OS.type == "windows") "windows" else "wsl"
lib <- file.path("audit-results", "data-streams", paste0("lib-", host))
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
install.packages(".", repos = NULL, type = "source", lib = lib)
