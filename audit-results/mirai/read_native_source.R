path <- "audit-results/mirai/native-source"
dir.create(path, recursive = TRUE, showWarnings = FALSE)
file <- file.path(path, "nanonext_1.10.3.tar.gz")
download.file("https://cloud.r-project.org/src/contrib/nanonext_1.10.3.tar.gz", file, mode = "wb")
untar(file, files = c("nanonext/src/dispatcher.c", "nanonext/src/aio.c"), exdir = path)
