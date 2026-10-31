cat(R.version.string, "\n")
pkgs <- c("testthat", "vctrs", "pillar", "tibble", "bit64", "units", "haven", "lubridate", "blob", "sf", "dbplyr", "DBI", "RSQLite", "duckdb", "arrow", "mirai", "shiny")
for (p in pkgs) cat(p, requireNamespace(p, quietly = TRUE), if (requireNamespace(p, quietly = TRUE)) as.character(packageVersion(p)) else "", "\n")