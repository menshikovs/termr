exports <- getNamespaceExports("dbplyr")
cat(paste(grep("lazy|simulate|sqlite", exports, value = TRUE, ignore.case = TRUE), collapse = "\n"), "\n")