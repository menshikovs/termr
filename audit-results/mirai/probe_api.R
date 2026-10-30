source("audit-results/mirai/environment.R")
library(mirai)
for (name in c("daemons", "mirai", "try_mirai", "stop_mirai", "status", "info", "everywhere", "launch_local")) {
  if (name %in% getNamespaceExports("mirai")) {cat("API", name, "\n"); print(args(getExportedValue("mirai", name)))}
}
for (topic in c("daemons", "stop_mirai", "status", "everywhere")) {
  cat("HELP", topic, "\n")
  cat(tools::Rd2txt(utils:::.getHelpFile(help(topic, package = "mirai"))))
}
cat("SHINY ExtendedTask\n"); print(shiny::ExtendedTask$public_methods)
