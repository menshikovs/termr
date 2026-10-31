pkgload::load_all(".", quiet = TRUE)
if (!requireNamespace("inkr", quietly = TRUE)) stop("Install inkr to run this benchmark.")

sheet_a <- inkr::ink_compile(inkr::ink_parse(
  ".root { color: white; } .root .item { padding: 0; } Button:focus { color: yellow; }"
))
sheet_b <- inkr::ink_compile(inkr::ink_parse(
  ".root { color: cyan; } .root .item { padding: 0 1; } Button:focus { color: bright-yellow; }"
))

measure <- function(fn) {
  path <- tempfile()
  Rprofmem(path, threshold = 0)
  on.exit(Rprofmem(NULL), add = TRUE)
  time <- unname(system.time(fn())["elapsed"])
  Rprofmem(NULL)
  entries <- readLines(path, warn = FALSE)
  unlink(path)
  bytes <- suppressWarnings(as.numeric(sub(":.*$", "", entries)))
  list(elapsed_s = time, alloc_bytes = sum(bytes, na.rm = TRUE), alloc_events = sum(!is.na(bytes)))
}

elapsed <- function(expr) unname(system.time(force(expr))["elapsed"])

allocation <- function(fn) {
  path <- tempfile()
  Rprofmem(path, threshold = 0)
  on.exit(Rprofmem(NULL), add = TRUE)
  fn()
  Rprofmem(NULL)
  entries <- readLines(path, warn = FALSE)
  unlink(path)
  bytes <- suppressWarnings(as.numeric(sub(":.*$", "", entries)))
  list(bytes = sum(bytes, na.rm = TRUE), events = sum(!is.na(bytes)))
}

make_tree <- function(n) {
  leaves <- lapply(seq_len(n), function(i) {
    label(sprintf("Row %05d", i), classes = "item")
  })
  do.call(vertical, c(leaves, list(classes = "root")))
}

make_nested_tree <- function(n, group_size = 10L) {
  groups <- split(seq_len(n), ceiling(seq_len(n) / group_size))
  containers <- lapply(seq_along(groups), function(i) {
    rows <- lapply(groups[[i]], function(j) label(sprintf("Row %05d", j), classes = "item"))
    do.call(vertical, c(rows, list(classes = "group")))
  })
  do.call(vertical, c(containers, list(classes = "root")))
}

cache_stats <- function(app) {
  cache <- app$.__enclos_env__$private$.inkr_cache
  entries <- as.list(cache, all.names = TRUE)
  list(entries = length(entries), bytes = as.numeric(object.size(entries)))
}

render_scale <- function(n, use_inkr) {
  root <- make_tree(n)
  x <- if (use_inkr) app(root, inkr_stylesheet = sheet_a) else app(root)
  first <- measure(function() render_widget(x, 80L, 24L))
  warm <- measure(function() render_widget(x, 80L, 24L))
  cache <- if (use_inkr) cache_stats(x) else list(entries = 0L, bytes = 0)
  data.frame(
    widgets = n, inkr = use_inkr, first_render_s = first$elapsed_s, warm_render_s = warm$elapsed_s,
    first_alloc_bytes = first$alloc_bytes, warm_alloc_bytes = warm$alloc_bytes,
    cache_entries = cache$entries, cache_bytes = cache$bytes
  )
}

cat("render scales (base R elapsed; allocation is Rprofmem total bytes)\n")
render_results <- do.call(rbind, lapply(c(10L, 100L, 1000L, 10000L), function(n) {
  rbind(render_scale(n, FALSE), render_scale(n, TRUE))
}))
print(render_results, row.names = FALSE)

cat("\nnested render (1000 leaves, groups of ten)\n")
nested <- app(make_nested_tree(1000L), inkr_stylesheet = inkr::ink_compile(inkr::ink_parse(
  ".root { color: white; } .root .group .item { padding: 0; }"
)))
nested_first <- measure(function() render_widget(nested, 80L, 24L))
nested_warm <- measure(function() render_widget(nested, 80L, 24L))
print(data.frame(first_render_s = nested_first$elapsed_s, warm_render_s = nested_warm$elapsed_s,
                 cache_entries = cache_stats(nested)$entries, cache_bytes = cache_stats(nested)$bytes),
      row.names = FALSE)

cat("\nstate churn (100 focus or class transitions on 100 widgets)\n")
buttons <- lapply(seq_len(100L), function(i) button(as.character(i), classes = "item"))
focus_app <- app(do.call(vertical, buttons), inkr_stylesheet = sheet_a)
invisible(render_widget(focus_app, 80L, 24L))
focus_elapsed <- elapsed(for (i in seq_len(100L)) {
  target <- buttons[[(i - 1L) %% length(buttons) + 1L]]
  focus_app$set_focus(target)
  invisible(target$computed_style())
})
class_elapsed <- elapsed(for (i in seq_len(100L)) {
  target <- buttons[[(i - 1L) %% length(buttons) + 1L]]
  target$add_class("active")
  invisible(target$computed_style())
  target$remove_class("active")
  invisible(target$computed_style())
})
reload_elapsed <- elapsed(for (i in seq_len(20L)) {
  focus_app$set_inkr_stylesheet(if (i %% 2L) sheet_b else sheet_a)
  invisible(buttons[[1L]]$computed_style())
})
theme_elapsed <- elapsed(for (i in seq_len(20L)) {
  focus_app$theme <- if (i %% 2L) "dark" else "light"
  invisible(buttons[[1L]]$computed_style())
})
print(data.frame(operation = c("focus", "class toggle", "sheet replacement", "theme change"),
                 iterations = c(100L, 100L, 20L, 20L),
                 elapsed_s = c(focus_elapsed, class_elapsed, reload_elapsed, theme_elapsed)),
      row.names = FALSE)

cat("\nscrolling with 10000 mounted rows\n")
scroll <- scroll_view(lapply(seq_len(10000L), function(i) label(sprintf("Row %05d", i), classes = "item")),
                      scrollbars = FALSE)
scroll_app <- app(scroll, inkr_stylesheet = sheet_a)
scroll_first <- elapsed(render_widget(scroll_app, 80L, 24L))
scroll_first_cache <- cache_stats(scroll_app)
scroll_elapsed <- elapsed(for (i in seq_len(20L)) {
  scroll$scroll_by(dy = 100L)
  invisible(render_widget(scroll_app, 80L, 24L))
})
scroll_cache <- cache_stats(scroll_app)
before_remove <- cache_stats(scroll_app)$entries
scroll$remove()
after_remove <- cache_stats(scroll_app)$entries
print(data.frame(first_render_s = scroll_first, first_cache_entries = scroll_first_cache$entries,
                 first_cache_bytes = scroll_first_cache$bytes,
                 twenty_scroll_renders_s = scroll_elapsed, cache_entries_after_scroll = scroll_cache$entries,
                 cache_entries_before_unmount = before_remove, cache_entries_after_unmount = after_remove),
      row.names = FALSE)

cat("\nnative chart + DataTable render (one cold / one warm frame)\n")
chart <- line_chart(1:100, sin(1:100 / 5), classes = "item", interactive = FALSE)
table <- data_table(data.frame(i = seq_len(100L), value = sin(seq_len(100L))),
                    show_types = TRUE, row_names = FALSE)
dashboard <- app(vertical(chart, table, classes = "root"), inkr_stylesheet = sheet_a)
chart_first <- elapsed(render_widget(dashboard, 100L, 30L))
chart_warm <- elapsed(render_widget(dashboard, 100L, 30L))
print(data.frame(first_render_s = chart_first, warm_render_s = chart_warm,
                 cache_entries = cache_stats(dashboard)$entries,
                 cache_bytes = cache_stats(dashboard)$bytes),
      row.names = FALSE)
