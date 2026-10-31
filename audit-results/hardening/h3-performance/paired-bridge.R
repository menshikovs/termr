pkgload::load_all('.', quiet = TRUE)
out <- 'audit-results/hardening/h3-performance'
ns <- asNamespace('termr')
old <- new.env(parent = ns)
sys.source(file.path(out, 'baseline/R/inkr-integration.R'), envir = old)
sheet <- inkr::ink_compile(inkr::ink_parse('.root {color: cyan;} .root .item {padding: 0;}'))
make <- function(n, deep = FALSE) {
  w <- label('leaf', classes = 'item')
  root <- w
  if (deep) for (i in 1:100) root <- vertical(root, classes = 'root') else
    root <- do.call(vertical, c(lapply(seq_len(n), function(i) label(as.character(i), id = paste0('w',i), classes = 'item')), list(classes='root')))
  list(a = app(root, inkr_stylesheet = sheet), w = if (deep) w else root$children[[1L]])
}
results <- list()
for (op in c('render-unique-1000', 'element-1000', 'cache-hit-1000', 'deep-element-100', 'compute-control-1000')) {
  run <- function(phase) {
    x <- make(if (op == 'render-unique-1000') 1000L else 10L, op == 'deep-element-100')
    bridge <- if (phase == 'before') old$inkr_style_for_widget else get('inkr_style_for_widget', ns)
    element <- if (phase == 'before') old$inkr_element_for_widget else get('inkr_element_for_widget', ns)
    if (op == 'cache-hit-1000') bridge(x$a, x$w)
    e <- element(x$w)
    work <- function() switch(op,
      `render-unique-1000` = testthat::with_mocked_bindings(render_widget(x$a, 80, 24),
        inkr_style_for_widget = bridge, .package = 'termr'),
      `element-1000` = {for (i in 1:1000) element(x$w)},
      `deep-element-100` = {for (i in 1:100) element(x$w)},
      `cache-hit-1000` = {for (i in 1:1000) bridge(x$a, x$w)},
      `compute-control-1000` = {for (i in 1:1000) inkr::ink_compute(sheet, e)})
    gc(); mem <- tempfile(); Rprofmem(mem)
    elapsed <- system.time(work())[['elapsed']]
    Rprofmem(NULL)
    bytes <- suppressWarnings(as.numeric(sub(':.*$', '', readLines(mem, warn=FALSE))))
    unlink(mem)
    data.frame(op, phase, elapsed, allocated = sum(bytes, na.rm=TRUE))
  }
  run('before'); run('after')
  for (rep in 1:4) {
    for (phase in if (rep %% 2L) c('before','after') else c('after','before')) {
      row <- run(phase); row$rep <- rep
      results[[length(results)+1L]] <- row
      write.csv(do.call(rbind, results), file.path(out,'paired-bridge.csv'), row.names=FALSE)
    }
  }
}
