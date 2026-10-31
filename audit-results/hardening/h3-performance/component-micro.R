args <- commandArgs(TRUE)
phase <- args[[1L]]
out <- 'audit-results/hardening/h3-performance'
pkgload::load_all(Sys.getenv('TERMR_H3_PACKAGE', '.'), quiet = TRUE)
ns <- asNamespace('termr')
sheet <- inkr::ink_compile(inkr::ink_parse('.root {color: cyan;} .root .item {padding: 0;}'))
w <- label('one', classes = 'item')
a <- app(vertical(w, classes = 'root'), inkr_stylesheet = sheet)
element <- termr:::inkr_element_for_widget(w)
computed <- inkr::ink_compute(sheet, element)
# Extract the actual checked-out adapter statements, without maintaining a
# second adapter implementation in this benchmark.
parts <- as.list(body(termr:::inkr_style_for_widget))[-1L]
text <- vapply(parts, function(x) paste(deparse(x), collapse = ' '), '')
start <- grep('^properties <-', text)
end <- grep('^inkr_store_style_cache', text)
stopifnot(length(start) == 1L, length(end) == 1L)
mapping <- function(computed, explicit_ancestors) NULL
body(mapping) <- as.call(c(list(as.name('{')), parts[start:(end - 1L)], list(as.name('adapted'))))
environment(mapping) <- ns
private <- a$.__enclos_env__$private
rows <- list()
for (op in c('match', 'mapping', 'cache-insert', 'cache-invalidation', 'class-change', 'sheet-swap')) {
  work <- function() {
    for (i in seq_len(if (op %in% c('class-change', 'sheet-swap')) 100L else 1000L)) {
      switch(op,
        match = inkr::ink_match(sheet, element),
        mapping = mapping(computed, list()),
        `cache-insert` = termr:::inkr_store_style_cache(private, paste0('micro_', i), list(style = NULL, explicit = logical())),
        `cache-invalidation` = termr:::inkr_reset_style_cache(a),
        `class-change` = {w$classes <- c('item', if (i %% 2) 'odd' else 'even'); w$computed_style()},
        `sheet-swap` = {a$set_inkr_stylesheet(sheet); w$computed_style()})
    }
  }
  work()
  for (rep in 1:3) {
    gc(); file <- tempfile(); Rprofmem(file)
    elapsed <- system.time(work())[['elapsed']]
    Rprofmem(NULL)
    bytes <- suppressWarnings(as.numeric(sub(':.*$', '', readLines(file, warn = FALSE))))
    unlink(file)
    rows[[length(rows) + 1L]] <- data.frame(op, rep, elapsed, allocated = sum(bytes, na.rm = TRUE))
  }
}
write.csv(do.call(rbind, rows), file.path(out, paste0(phase, '-components.csv')), row.names = FALSE)
