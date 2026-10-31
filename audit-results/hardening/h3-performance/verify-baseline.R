pkgload::load_all('audit-results/hardening/h3-performance/baseline', quiet = TRUE)
stopifnot(is.null(termr:::EventQueue$public_methods$initialize))
stopifnot(grepl('path <- rev', paste(deparse(termr:::inkr_element_for_widget), collapse = '\n'), fixed = TRUE))
cat('Snapshot namespace loaded: pre-H3 R sources verified\n')
