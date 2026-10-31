# Install and load termr with only its Imports and their dependencies visible.
# Run from a package checkout: Rscript audit-results/typed-data/optional-free-install.R
root <- normalizePath(".")
description <- read.dcf(file.path(root, "DESCRIPTION"))
imports <- trimws(strsplit(description[1L, "Imports"], ",", fixed = TRUE)[[1L]])
imports <- sub("\\s*\\(.*$", "", imports)
installed <- installed.packages()
closure <- tools::package_dependencies(
  imports, db = installed, which = c("Depends", "Imports", "LinkingTo"), recursive = TRUE
)
needed <- unique(c(imports, unlist(closure, use.names = FALSE)))
available <- unique(installed[, "Package"])
missing <- setdiff(needed, available)
if (length(missing)) stop("Missing required Imports: ", paste(missing, collapse = ", "), call. = FALSE)

scratch <- tempfile("termr-optional-free-")
dir.create(scratch)
dependency_lib <- file.path(scratch, "deps")
install_lib <- file.path(scratch, "install")
dir.create(dependency_lib)
dir.create(install_lib)
base_library <- normalizePath(.Library, winslash = "/", mustWork = TRUE)
library_paths <- normalizePath(installed[, "LibPath"], winslash = "/", mustWork = TRUE)
base_packages <- rownames(installed)[library_paths == base_library]
copy <- setdiff(needed, base_packages)
for (package in copy) {
  row <- installed[installed[, "Package"] == package, , drop = FALSE][1L, ]
  from <- file.path(row[["LibPath"]], package)
  to <- file.path(dependency_lib, package)
  dir.create(to)
  files <- list.files(from, all.files = TRUE, full.names = TRUE, no.. = TRUE)
  copied <- file.copy(files, to, recursive = TRUE)
  if (length(copied) && any(!copied)) stop("Could not copy required package ", package, call. = FALSE)
}

Sys.setenv(R_LIBS_USER = dependency_lib, R_LIBS_SITE = "", R_LIBS = "")
if (.Platform$OS.type == "windows") {
  r_cmd <- file.path(R.home("bin"), "Rcmd.exe")
  install_args <- c("INSTALL", "--no-test-load", "-l", shQuote(install_lib), shQuote(root))
} else {
  r_cmd <- file.path(R.home("bin"), "R")
  install_args <- c("CMD", "INSTALL", "--no-test-load", "-l", shQuote(install_lib), shQuote(root))
}
output <- system2(r_cmd, install_args, stdout = TRUE, stderr = TRUE)
status <- attr(output, "status")
if (is.null(status)) status <- 0L
cat(paste(output, collapse = "\n"), "\n")
if (status != 0L) stop("R CMD INSTALL failed with status ", status, call. = FALSE)
if (!dir.exists(file.path(install_lib, "termr"))) stop("termr was not installed into the isolated library.", call. = FALSE)

.libPaths(c(install_lib, dependency_lib, .Library))
optional <- c("vctrs", "pillar", "tibble", "dplyr", "hms", "bit64")
present <- vapply(optional, requireNamespace, logical(1), quietly = TRUE)
if (any(present)) stop("Optional packages unexpectedly visible: ", paste(optional[present], collapse = ", "), call. = FALSE)
cat("Optional packages visible: none (", paste(optional, collapse = ", "), ")\n", sep = "")
ns <- loadNamespace("termr")
table <- getExportedValue("termr", "data_table")(
  data.frame(count = c(1L, 2L), day = as.Date(c("2026-10-29", "2026-10-30"))), editable = TRUE
)
table$set_cell(1L, "count", "9")
stopifnot(identical(table$data$count, c(9L, 2L)), inherits(table$data$day, "Date"))
cat("PASS: install and typed table load without optional packages.\n")
