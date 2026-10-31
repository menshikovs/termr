# Invoke with phase and group `extra`; shared frozen harness defines measure().
source('audit-results/hardening/h3-performance/benchmark-frozen.R')
if (identical(Sys.getenv('TERMR_H3_RESUME'), '1')) {
  previous <- read.csv(file.path(out, paste0(phase, '-extra.csv')))
  rows <- lapply(seq_len(nrow(previous)), function(i) previous[i, , drop = FALSE])
  original_measure <- measure
  measure <- function(id, n, setup, run, cleanup = function(x) NULL) {
    if (sum(previous$id == id & previous$n == n) == 3L) {
      cat('Resume: retain three completed repetitions of', id, '\n')
      return(invisible(NULL))
    }
    original_measure(id, n, setup, run, cleanup)
  }
}
factories <- list(line = function() line_chart(1:1000, sin((1:1000)/10)),
  scatter = function() scatter_chart(1:1000, sin((1:1000)/10)),
  bar = function() bar_chart(letters, 1:26), histogram = function() histogram(sin(1:1000)),
  heatmap = function() heatmap_chart(matrix(sin(1:10000), 100)))
for (name in names(factories)) for (op in c('update', 'partial', 'full', 'hit')) {
  measure(paste0('chart-', name, '-', op), 1000L, function() {
    chart <- factories[[name]]()
    p <- test_app(app(chart), width = 80, height = 24)
    list(c = chart, p = p)
  }, function(x) {
    switch(op,
      update = {switch(name,
        line =, scatter = x$c$update_data(x = 1:1000, y = cos((1:1000)/10)),
        bar = x$c$update_data(labels = letters, values = 26:1),
        histogram = x$c$update_data(x = cos(1:1000)),
        heatmap = x$c$update_data(z = matrix(cos(1:10000), 100))); x$p$step()},
      partial = x$p$press('right'),
      full = {x$p$app$request_repaint(full = TRUE); x$p$step()},
      hit = {
        private <- x$c$.__enclos_env__$private
        plan <- private$ensure_plan(private$.paint_size)
        for (i in 1:1000) if (is.function(plan$hit)) plan$hit(10L, 20L, private$.selected)
      })
    capture.output(x$p$app$last_paint, file = file.path(out, paste0(phase, '-chart-', name, '-', op, '-paint.txt')))
  }, function(x) x$p$stop())
}
for (n in c(1L, 100L, 10000L)) for (op in c('dispatch', 'enqueue-frame')) {
  measure(paste0('app-events-', op), n, function() {
    w <- label('zero')
    p <- test_app(app(w), width = 30, height = 8)
    count <- new.env(); count$n <- 0L
    w$on('h3.event', function(event) {count$n <- count$n + 1L; w$text <- as.character(count$n)})
    list(w = w, p = p, count = count, events = lapply(seq_len(n), function(i) Event$new('h3.event', sender = w)))
  }, function(x) {
    if (op == 'dispatch') {
      for (e in x$events) x$p$app$.__enclos_env__$private$dispatch(e)
    } else {
      for (e in x$events) x$p$app$post(e)
      x$p$step()
    }
    stopifnot(x$count$n == n)
  }, function(x) x$p$stop())
}
measure('app-warm-startup', 100L, function() {
  a <- app(do.call(vertical, lapply(1:100, function(i) label(as.character(i)))))
  p <- test_app(a); p$stop(); a
}, function(a) {p <- test_app(a); p$stop()})
for (op in c('mount', 'focus', 'paint-change', 'full-layout')) {
  measure(paste0('tree-', op), 1000L, function() {
    x <- make_tree(1000L)
    if (op == 'mount') {x$parent <- vertical(); x$app <- app(x$parent)} else x$p <- test_app(x$a)
    x
  }, function(x) switch(op,
    mount = x$parent$mount(x$root),
    focus = {for (i in 1:100) x$p$press('tab')},
    `paint-change` = {w <- x$root$children[[1L]]; w$style <- style(foreground = 'red'); x$p$step()},
    `full-layout` = {x$p$app$request_repaint(full = TRUE, layout = TRUE); x$p$step()}),
    function(x) if (!is.null(x[["p"]])) x[["p"]]$stop())
}
