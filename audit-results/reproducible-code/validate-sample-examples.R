repo <- normalizePath(".", winslash = "/", mustWork = TRUE)
pkgload::load_all(repo, quiet = TRUE)
example_env <- new.env(parent = globalenv())
sys.source(file.path(repo, "inst", "examples", "reproducible-code.R"),
           envir = example_env)

example_names <- c("duckdb_sample_example", "arrow_sample_example")
results <- lapply(example_names, function(name) {
  value <- example_env[[name]]()
  if (!is.null(value)) {
    stopifnot(inherits(value, "termr_reproducible_code"),
              identical(value$status, "exact"),
              isTRUE(value$requires_source_binding))
  }
  data.frame(example = name, available = !is.null(value),
             status = if (is.null(value)) "optional packages missing" else value$status,
             stringsAsFactors = FALSE)
})
print(do.call(rbind, results), row.names = FALSE)
