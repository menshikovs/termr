pkgload::load_all(".", quiet = TRUE)
out <- "audit-results/hardening/h1-architecture"
results <- lapply(c(100L, 1000L), function(n) {
  root <- do.call(vertical, lapply(seq_len(n), function(i) label(as.character(i))))
  application <- app(root)
  path <- tempfile()
  Rprofmem(path)
  elapsed <- unname(system.time(root$remove_children())["elapsed"])
  Rprofmem(NULL)
  lines <- readLines(path, warn = FALSE)
  unlink(path)
  bytes <- suppressWarnings(as.numeric(sub(":.*$", "", lines)))
  inkr <- grepl("inkr_reset_style_cache", lines, fixed = TRUE)
  data.frame(widgets = n, elapsed_s = elapsed, gross_alloc_bytes = sum(bytes, na.rm = TRUE),
    inkr_cache_reset_alloc_bytes = sum(bytes[inkr], na.rm = TRUE), inkr_stylesheet_present = !is.null(application$inkr_stylesheet))
})
results <- do.call(rbind, results)
write.csv(results, file.path(out, "optional-free-unmount-profile.csv"), row.names = FALSE)
print(results, row.names = FALSE)
