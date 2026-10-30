root <- normalizePath(".", winslash = "/")
host <- if (.Platform$OS.type == "windows") "windows" else "wsl"
lib <- file.path(root, "audit-results/mirai", paste0("lib-", host))
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(lib, file.path(root, "audit-results/shiny-plotly", paste0("lib-", host)),
  file.path(root, "audit-results/nanonext", paste0("lib-", host)), .libPaths()))
cat(R.version.string, "\n")
for (package in c("mirai", "nanonext", "promises", "shiny", "later")) {
  path <- find.package(package, quiet = TRUE)
  cat(package, if (length(path)) as.character(packageVersion(package)) else "ABSENT", "\n")
}
