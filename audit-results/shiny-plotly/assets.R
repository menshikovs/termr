source("audit-results/shiny-plotly/environment.R")
source("inst/examples/system-monitor-live/visualization.R")
widget <- plotly::plotly_build(monitor_plotly_widget())
for (dep in widget$dependencies) {
  cat("dependency", dep$name, dep$version, "src", unlist(dep$src), "script", unlist(dep$script), "\n")
}
cat("Shiny", system.file(package = "shiny"), "\nPlotly", system.file(package = "plotly"), "\n")
files <- list.files(system.file(package = "shiny"), recursive = TRUE, full.names = TRUE)
cat(grep("strftime", files, value = TRUE), sep = "\n")
files <- list.files(system.file(package = "plotly"), recursive = TRUE, full.names = TRUE)
cat(grep("strftime", files, value = TRUE), sep = "\n")
