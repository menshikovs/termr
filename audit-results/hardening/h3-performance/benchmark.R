# Run from repository root: Rscript .../benchmark.R before|after [core|broad]
args <- commandArgs(TRUE)
phase <- args[[1L]]
group <- if (length(args) > 1L) args[[2L]] else "core"
out <- "audit-results/hardening/h3-performance"
pkgload::load_all(Sys.getenv("TERMR_H3_PACKAGE", "."), quiet = TRUE)
set.seed(20261031)
capture.output(sessionInfo(), file = file.path(out, paste0(phase, "-environment.txt")))
ns <- asNamespace("termr")
internal <- function(name) get(name, ns)
rows <- list()
measure <- function(id, n, setup, run, cleanup = function(x) NULL) {
  cat(id, n, "\n"); flush.console()
  warm <- setup(); run(warm); cleanup(warm); rm(warm); gc()
  for (rep in 1:3) {
    x <- setup(); gc()
    mem <- tempfile(); cpu <- tempfile()
    Rprofmem(mem); Rprof(cpu, interval = .005)
    elapsed <- unname(system.time(run(x))[["elapsed"]])
    Rprof(NULL); Rprofmem(NULL)
    lines <- readLines(mem, warn = FALSE)
    bytes <- suppressWarnings(as.numeric(sub(":.*$", "", lines)))
    rows[[length(rows) + 1L]] <<- data.frame(phase, group, id, n, rep, elapsed,
      allocated = sum(bytes, na.rm = TRUE), allocations = sum(!is.na(bytes)),
      inkr_reset_bytes = sum(bytes[grepl("inkr_reset_style_cache", lines, fixed = TRUE)], na.rm = TRUE))
    if (rep == 1L) {
      summary <- summaryRprof(cpu)
      write.csv(summary$by.total, file.path(out, paste0(phase, "-", id, "-", n, "-profile.csv")))
    }
    cleanup(x); unlink(c(mem, cpu)); rm(x)
    write.csv(do.call(rbind, rows), file.path(out, paste0(phase, "-", group, ".csv")), row.names = FALSE)
  }
}
make_tree <- function(n, ids = FALSE, ink = FALSE, deep = FALSE) {
  children <- lapply(seq_len(n), function(i) label(as.character(i),
    id = if (ids) paste0("item_", i) else NULL, classes = "item"))
  root <- if (!deep) do.call(vertical, c(children, list(classes = "root"))) else {
    tree <- children[[1L]]
    for (i in seq_len(n)) tree <- vertical(tree, classes = "root")
    tree
  }
  list(root = root, a = app(root, inkr_stylesheet = if (ink) sheet else NULL))
}
sheet <- if (requireNamespace("inkr", quietly = TRUE))
  inkr::ink_compile(inkr::ink_parse(".root { color: cyan; } .root .item { padding: 0; }")) else NULL
stream_setup <- function() {
  s <- termr_stream(history = 0L)
  chart <- line_chart(numeric(), numeric(), interactive = FALSE)
  p <- test_app(app(chart))
  chart$bind_stream(s, function(v) v$x, function(v) v$y, max_points = 100L)
  list(s = s, chart = chart, p = p)
}
stream_run <- function(x) {
  counter <- 0L
  emit <- function(n) for (i in seq_len(n)) {
    counter <<- counter + 1L; x$s$emit(list(x = counter, y = counter))
  }
  emit(64L); x$p$step()
  for (i in 1:20) { emit(16L); x$p$advance(.001) }
  state <- x$chart$.__enclos_env__$private
  write.csv(data.frame(processed = length(state$.stream_state$x),
    displayed = length(state$.spec$data$x), pending = state$.stream_state$queue$size,
    flushes = state$.stream_state$flush_count),
    file.path(out, paste0(phase, "-stream-freshness.csv")), row.names = FALSE)
}
if (group == "core") {
  for (n in c(100L, 1000L, 5000L))
    measure("unmount-no-sheet", n, function() make_tree(n), function(x) x$root$remove_children())
  for (n in c(100L, 1000L, 10000L)) for (kind in c("none", "repeated", "unique")) {
    if (kind != "none" && is.null(sheet)) next
    measure(paste0("render-", kind), n,
      function() make_tree(n, ids = kind == "unique", ink = kind != "none"),
      function(x) render_widget(x$a, 80L, 24L))
  }
  if (!is.null(sheet)) {
    measure("deep-cold", 100L, function() make_tree(100L, ink = TRUE, deep = TRUE),
      function(x) render_widget(x$a, 80L, 24L))
    for (op in c("element", "hit", "compute", "path")) {
      measure(paste0("micro-", op), 1000L, function() {
        x <- make_tree(100L, ink = TRUE)
        x$w <- x$root$children[[1L]]
        internal("inkr_style_for_widget")(x$a, x$w)
        x$element <- internal("inkr_element_for_widget")(x$w); x
      }, function(x) for (i in 1:1000) switch(op,
        element = internal("inkr_element_for_widget")(x$w),
        hit = internal("inkr_style_for_widget")(x$a, x$w),
        compute = inkr::ink_compute(sheet, x$element), path = x$w$ancestors()))
    }
    for (n in c(100L, 1000L, 2000L)) measure("inkr-session-insert", n,
      function() { s <- inkr::ink_session(sheet); inkr::ink_session_set(s, "root", type = "Vertical"); s },
      function(s) for (i in seq_len(n)) inkr::ink_session_set(s, paste0("child", i),
        type = "Label", classes = "item", parent_key = "root"))
  }
  measure("continuous-stream", 384L, stream_setup, stream_run, function(x) { x$p$stop(); x$s$close() })
}
if (group == "events") {
  for (n in c(1L, 100L, 10000L)) for (op in c("enqueue", "dequeue")) {
    measure(paste0("events-", op), n, function() {
      x <- list(q = internal("EventQueue")$new(), events = lapply(seq_len(n), function(i) Event$new("h3.event")))
      if (op == "dequeue") for (e in x$events) x$q$push(e)
      x
    }, function(x) {
      if (op == "enqueue") for (e in x$events) x$q$push(e)
      else while (!x$q$is_empty()) x$q$pop()
    })
  }
}
if (group == "broad") {
  for (n in c(1000L, 100000L, 1000000L)) {
    values <- data.frame(x = rev(seq_len(n)), y = seq_len(n) / 10, z = rep(letters, length.out = n))
    measure("table-init", n, function() values, function(x) data_table(x, editable = TRUE))
    for (op in c("render", "scroll", "sort", "filter", "resize", "edit", "lookup", "selection", "export"))
      measure(paste0("table-", op), n, function() data_table(values, editable = TRUE), function(t) {
        switch(op, render = render_widget(t, 80, 24),
          scroll = {t$scroll_to_row(n - 20L); render_widget(t, 80, 24)},
          sort = t$sort("x"), filter = t$filter_columns(list(x = function(v) v %% 2L == 0L)),
          resize = t$set_column_width("x", 12L), edit = t$set_cell(2L, "y", "1.25"),
          lookup = t$row_data(n - 1L), selection = t$select_range(1L, 10L),
          export = {t$select_range(1L, 10L); t$reproducible_code("value")})
      })
  }
  measure("virtual-scroll-40-columns", 10000000L, function() {
    columns <- paste0("c", 1:40)
    calls <- new.env(); calls$requests <- list()
    src <- table_source(10000000L, columns, function(start, count, columns) {
      calls$requests[[length(calls$requests) + 1L]] <- list(count = count, columns = length(columns))
      as.data.frame(setNames(lapply(columns, function(z) seq.int(start, length.out = count)), columns))
    })
    list(t = data_table(src, columns = setNames(lapply(columns, function(z) column(width = 8)), columns)), calls = calls)
  }, function(x) {
    for (i in 1:40) { x$t$scroll_to_row(i * 10000L); render_widget(x$t, 109, 14) }
    stopifnot(all(vapply(x$calls$requests, function(r) r$count <= 100L, TRUE)))
    capture.output(x$t$source_stats(), file = file.path(out, paste0(phase, "-source-stats.txt")))
    write.csv(do.call(rbind, lapply(x$calls$requests, as.data.frame)),
      file.path(out, paste0(phase, "-source-requests.csv")), row.names = FALSE)
  })
  factories <- list(line = function() line_chart(1:1000, sin((1:1000)/10)),
    scatter = function() scatter_chart(1:1000, sin((1:1000)/10)),
    bar = function() bar_chart(letters, 1:26), histogram = function() histogram(sin(1:1000)),
    heatmap = function() heatmap_chart(matrix(sin(1:10000), 100)))
  for (name in names(factories)) for (op in c("initial", "warm", "resize"))
    measure(paste0("chart-", name, "-", op), 1000L, function() {
      a <- app(factories[[name]]()); if (op != "initial") render_widget(a, 80, 24); a
    }, function(a) render_widget(a, if (op == "resize") 90 else 80, 24))
  for (op in c("startup", "idle", "update", "focus", "reload", "shutdown"))
    measure(paste0("app-", op), 100L, function() {
      x <- list(a = app(do.call(vertical, lapply(1:100, function(i) button(as.character(i))))))
      if (op != "startup") x$p <- test_app(x$a)
      x
    }, function(x) switch(op, startup = {p <- test_app(x$a); p$stop()}, idle = x$p$step(),
      update = {x$a$screen$children[[1L]]$children[[1L]]$add_class("changed"); x$p$step()},
      focus = x$p$press("tab", "tab", "tab"), reload = x$a$set_inkr_stylesheet(sheet), shutdown = x$p$stop()),
      function(x) if (!is.null(x$p)) x$p$stop())
}
