source("audit-results/mirai/environment.R")
install.packages("mirai", lib = lib, repos = "https://cloud.r-project.org")
cat("Installed mirai", as.character(packageVersion("mirai", lib.loc = lib)), "\n")
