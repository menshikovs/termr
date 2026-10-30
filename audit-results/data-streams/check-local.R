root <- normalizePath(".", winslash = "/", mustWork = TRUE)
host <- if (.Platform$OS.type == "windows") "windows" else "wsl"
args <- commandArgs(trailingOnly = TRUE)
tag <- if (length(args)) args[[1L]] else "verified"
path <- file.path(root, "audit-results", "data-streams", paste0("check-", host, "-", tag))
dir.create(path, recursive = TRUE, showWarnings = FALSE)
source_path <- file.path(path, "source")
dir.create(source_path, showWarnings = FALSE)
# R CMD build copies before applying .Rbuildignore. Stage only allowed root
# entries so ignored audit libraries and large existing tools scratch trees
# are never copied into the build's temporary tree.
patterns <- readLines(file.path(root, ".Rbuildignore"))
patterns <- patterns[nzchar(patterns)]
entries <- list.files(root, all.files = TRUE, no.. = TRUE)
entries <- entries[!startsWith(entries, ".") | entries == ".Rbuildignore"]
entries <- entries[!vapply(entries, function(entry) any(vapply(patterns, grepl, logical(1), x = entry)), logical(1))]
stopifnot(all(file.copy(file.path(root, entries), source_path, recursive = TRUE)))
setwd(path)
Sys.setenv(`_R_CHECK_FORCE_SUGGESTS_` = "false", NOT_CRAN = "true")
r <- file.path(R.home("bin"), "R")
status <- system2(r, c("CMD", "build", "--no-build-vignettes", "--no-manual", shQuote(source_path)))
if (status != 0L) quit(status = status)
tarball <- list.files(pattern = "^termr_.*[.]tar[.]gz$")
stopifnot(length(tarball) == 1L)
files <- utils::untar(tarball, list = TRUE)
stopifnot(!any(grepl("audit-results|[.]pending-|original-docs|[.]new[.]md$|_problems", files)))
cat("PASS: build excludes audit results and temporary artifacts\n")
status <- system2(r, c("CMD", "check", "--no-manual", "--no-build-vignettes", tarball))
quit(status = status)
