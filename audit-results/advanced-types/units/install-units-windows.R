library_path <- Sys.getenv("TERMR_UNITS_LIB", unset = "")
stopifnot(nzchar(library_path))
dir.create(library_path, recursive = TRUE, showWarnings = FALSE)
install.packages("units", lib = library_path,
                 repos = "https://cloud.r-project.org", type = "binary",
                 dependencies = NA)
stopifnot(requireNamespace("units", quietly = TRUE, lib.loc = library_path))
cat("units ", as.character(packageVersion("units", lib.loc = library_path)),
    " installed in task-local library.\n", sep = "")
