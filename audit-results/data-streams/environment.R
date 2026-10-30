cat(R.version.string, "\n")
for (p in c("testthat", "roxygen2", "pkgload", "ps", "shiny", "bench", "jsonlite", "rcmdcheck")) {
  cat(p, requireNamespace(p, quietly = TRUE), "\n")
}
cat("libraries:", .libPaths(), "\n")
cat("ps CPU:\n"); print(ps::ps_cpu_times())
cat("CPU exports:\n"); print(grep("cpu", getNamespaceExports("ps"), value = TRUE))
cat("ps RAM:\n"); print(ps::ps_system_memory())
cat("ps processes:\n"); print(utils::head(ps::ps()))
