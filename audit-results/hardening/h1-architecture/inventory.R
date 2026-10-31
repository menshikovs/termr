pkgload::load_all(".", quiet = TRUE)
out <- "audit-results/hardening/h1-architecture"
namespace <- readLines("NAMESPACE", warn = FALSE)
exports <- sub("^export\\((.*)\\)$", "\\1", grep("^export\\(", namespace, value = TRUE))
exports <- gsub('^"|"$', "", exports)
old_namespace <- system2("git", c("show", "HEAD:NAMESPACE"), stdout = TRUE)
old_exports <- sub("^export\\((.*)\\)$", "\\1", grep("^export\\(", old_namespace, value = TRUE))
old_exports <- gsub('^"|"$', "", old_exports)
inventory <- data.frame(name = exports, exists = vapply(exports, function(name) exists(name, asNamespace("termr"), inherits = FALSE), logical(1)),
  additive_to_HEAD = !exports %in% old_exports)
write.csv(inventory, file.path(out, "exports.csv"), row.names = FALSE)
collect_signatures <- function(expressions, file) {
  rows <- lapply(expressions, function(expr) {
    if (!is.call(expr) || !identical(expr[[1L]], as.name("<-")) || length(expr) != 3L ||
        !is.symbol(expr[[2L]]) || !is.call(expr[[3L]]) || !identical(expr[[3L]][[1L]], as.name("function"))) return(NULL)
    data.frame(name = as.character(expr[[2L]]), file = file,
               signature = paste(deparse(expr[[3L]][[2L]], width.cutoff = 500L), collapse = " "))
  })
  do.call(rbind, rows)
}
current <- old <- list()
for (file in list.files("R", full.names = TRUE, pattern = "\\.R$")) {
  current[[file]] <- collect_signatures(parse(file, keep.source = FALSE), file)
  prior <- suppressWarnings(system2("git", c("show", paste0("HEAD:", file)), stdout = TRUE, stderr = FALSE))
  if (!is.null(attr(prior, "status"))) next
  old[[file]] <- collect_signatures(parse(text = prior, keep.source = FALSE), file)
}
current <- do.call(rbind, current); old <- do.call(rbind, old)
comparison <- merge(current[current$name %in% exports, ], old[old$name %in% old_exports, ], by = "name", all = TRUE, suffixes = c("_current", "_HEAD"))
comparison$changed <- with(comparison, is.na(signature_current) | is.na(signature_HEAD) | signature_current != signature_HEAD)
write.csv(comparison, file.path(out, "function-signatures.csv"), row.names = FALSE)
deps <- unique(c("inkr", "vctrs", "pillar", "tibble", "dplyr", "units", "haven", "lubridate", "bit64", "sf", "blob", "DBI", "RSQLite", "dbplyr", "duckdb", "arrow", "mirai", "nanonext", "shiny", "plotly", "promises", "roxygen2", "testthat", "processx"))
packages <- data.frame(package = deps, available = vapply(deps, requireNamespace, logical(1), quietly = TRUE))
packages$version <- vapply(deps, function(p) if (requireNamespace(p, quietly = TRUE)) as.character(utils::packageVersion(p)) else NA_character_, character(1))
write.csv(packages, file.path(out, paste0("packages-", .Platform$OS.type, ".csv")), row.names = FALSE)
cat("Exports:", nrow(inventory), "missing:", sum(!inventory$exists), "new:", sum(inventory$additive_to_HEAD), "\n")
print(comparison[comparison$changed %in% TRUE, c("name", "signature_current", "signature_HEAD")], row.names = FALSE)
print(packages, row.names = FALSE)
