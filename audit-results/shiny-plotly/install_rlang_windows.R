.libPaths(c("audit-results/shiny-plotly/lib-windows", "audit-results/nanonext/lib-windows", .libPaths()))
cat("rlang before", as.character(utils::packageVersion("rlang")), system.file(package = "rlang"), "\n")
install.packages("rlang", lib = "audit-results/shiny-plotly/lib-windows", repos = "https://cloud.r-project.org")
