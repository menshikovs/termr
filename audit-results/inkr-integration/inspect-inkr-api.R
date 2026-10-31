source_root <- normalizePath("C:/programming_pj/ink-for-r", winslash = "/")
installed <- requireNamespace("inkr", quietly = TRUE)
if (!installed) {
  if (!requireNamespace("pkgload", quietly = TRUE)) stop("pkgload is needed to inspect the local inkr source.")
  pkgload::load_all(source_root, quiet = TRUE)
}

cat("installed:", installed, "\n")
cat("source version:", as.character(utils::packageVersion("inkr")), "\n")
exports <- getNamespaceExports("inkr")
requested <- c(
  "ink_parse", "ink_read", "ink_compile", "ink_registry", "ink_register_property",
  "ink_element", "ink_match", "ink_compute", "ink_explain", "ink_session",
  "ink_session_compute", "ink_session_set", "ink_session_remove",
  "ink_session_stats", "ink_terminal_capabilities", "ink_terminal_style"
)
for (name in requested) {
  cat("\n", name, ": ", if (name %in% exports) "exported" else "NOT EXPORTED", "\n", sep = "")
  if (name %in% exports) print(formals(getExportedValue("inkr", name)))
}

registry <- inkr::ink_registry()
cat("\nregistry class:", paste(class(registry), collapse = "/"), "\n")
cat("registry properties:\n")
print(names(registry$properties))
cat("\n", utils::capture.output(str(utils::head(registry$properties))), sep = "\n")
