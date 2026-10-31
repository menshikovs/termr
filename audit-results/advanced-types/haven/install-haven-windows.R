lib <- Sys.getenv("TERMR_HAVEN_LIB")
stopifnot(nzchar(lib))
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
utils::install.packages("haven", lib = lib, repos = "https://cloud.r-project.org",
                        type = "binary")
cat("haven:", as.character(utils::packageVersion("haven", lib.loc = lib)), "\n")
