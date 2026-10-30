source("audit-results/shiny-plotly/environment.R")
for (fn in c("plotlyProxy", "plotlyProxyInvoke")) {
  print(getExportedValue("plotly", fn))
}
for (topic in c("invalidateLater", "observe", "onSessionEnded")) {
  h <- help(topic, package = "shiny")
  if (length(h)) cat(tools::Rd2txt(utils:::.getHelpFile(h)))
}
