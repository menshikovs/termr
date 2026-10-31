# Reproducible native chart comparison benchmark.
#
# Run the two source trees in separate R processes so package namespace/cache
# state is comparable:
#   Rscript tools/bench/bench-native-charts.R <source-root> <label>
# Example:
#   Rscript tools/bench/bench-native-charts.R C:/src/termr-feature feature
#   Rscript tools/bench/bench-native-charts.R . termr-2.0

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2L) stop("Supply a package source root and run label.")
root <- normalizePath(args[[1L]], winslash = "/", mustWork = TRUE)
label <- args[[2L]]
suppressMessages(pkgload::load_all(root, quiet = TRUE, export_all = TRUE))

chart_fn <- function(name) getExportedValue("termr", name)
make_xy <- function(kind, n, offset = 0) {
  x <- seq_len(n)
  y <- if (kind == "line") sin(x / 41) + offset else cos(x / 37) + offset
  if (kind == "line") chart_fn("line_chart")(x, y, mode = "ascii") else
    chart_fn("scatter_chart")(x, y, mode = "ascii")
}
elapsed_ms <- function(fun) {
  started <- proc.time()[["elapsed"]]
  force(fun())
  (proc.time()[["elapsed"]] - started) * 1000
}
median_ms <- function(reps, fun) median(vapply(seq_len(reps), function(i) elapsed_ms(function() fun(i)), numeric(1)))
median_batch_ms <- function(reps, batch, fun) {
  median(vapply(seq_len(reps), function(i) {
    elapsed_ms(function() for (j in seq_len(batch)) fun(i, j)) / batch
  }, numeric(1)))
}
allocated_mb <- function(fun) {
  path <- tempfile("termr-chart-rprofmem-")
  on.exit(unlink(path), add = TRUE)
  Rprofmem(path, threshold = 0)
  tryCatch(fun(), finally = Rprofmem(NULL))
  entries <- readLines(path, warn = FALSE)
  bytes <- suppressWarnings(as.numeric(sub(" .*", "", entries)))
  sum(bytes, na.rm = TRUE) / 1024^2
}

point_results <- list()
for (kind in c("line", "scatter")) {
  for (n in c(100L, 1000L, 10000L, 100000L)) {
    build_ms <- median_batch_ms(3L, 20L, function(i, j) make_xy(kind, n, (i + j) / 100))
    first_render_ms <- median_ms(7L, function(i) {
      termr::render_widget(make_xy(kind, n, i / 10), width = 80L, height = 24L)
    })
    app_start_ms <- median_ms(5L, function(i) {
      pilot <- termr::test_app(make_xy(kind, n, i / 10), width = 80L, height = 24L)
      pilot$stop()
    })
    allocation_mb <- allocated_mb(function() {
      termr::render_widget(make_xy(kind, n), width = 80L, height = 24L)
    })
    chart <- make_xy(kind, n)
    update_ms <- median_batch_ms(3L, 50L, function(i, j) {
      offset <- (i + j) / 100
      if (kind == "line") chart$update_data(x = seq_len(n), y = sin(seq_len(n) / 41 + offset)) else
        chart$update_data(x = seq_len(n), y = cos(seq_len(n) / 37 + offset))
    })
    pilot <- termr::test_app(chart, width = 80L, height = 24L)
    selection_ms <- median_batch_ms(3L, 10L, function(i, j) {
      pilot$press(if (j %% 2L) "right" else "left")
      pilot$step()
    })
    full_repaint_ms <- median_batch_ms(3L, 10L, function(i, j) {
      chart$invalidate()
      pilot$step()
    })
    resize_ms <- median_ms(4L, function(i) {
      if (i %% 2L) pilot$resize(100L, 30L) else pilot$resize(80L, 24L)
    })
    pilot$stop()
    point_results[[length(point_results) + 1L]] <- data.frame(
      type = kind, n = n, build_ms = build_ms, render_widget_ms = first_render_ms,
      headless_app_start_ms = app_start_ms,
      update_data_ms = update_ms, selection_repaint_ms = selection_ms,
      full_repaint_ms = full_repaint_ms, resize_ms = resize_ms,
      render_alloc_mb = allocation_mb
    )
  }
}

shape_results <- list()
for (side in c(10L, 100L, 1000L)) {
  z <- matrix(seq_len(side * side) %% 97, nrow = side)
  shape_results[[length(shape_results) + 1L]] <- data.frame(
    type = "heatmap", size = paste0(side, "x", side),
    render_widget_ms = median_ms(if (side == 1000L) 1L else 5L, function(i) {
      termr::render_widget(chart_fn("heatmap_chart")(z, mode = "ascii"), 80L, 24L)
    }), object_mb = as.numeric(object.size(z)) / 1024^2
  )
}
categories <- paste0("c", seq_len(1000L))
multi <- matrix(seq_len(8000L) %% 71, nrow = 1000L, dimnames = list(NULL, paste0("s", 1:8)))
shape_results[[length(shape_results) + 1L]] <- data.frame(
  type = "grouped-bars-8-series", size = "1000x8",
  render_widget_ms = median_ms(9L, function(i) {
    termr::render_widget(chart_fn("bar_chart")(categories, multi, position = "grouped", mode = "ascii"), 80L, 24L)
  }), object_mb = as.numeric(object.size(multi)) / 1024^2
)

stream_results <- data.frame(type = character(), max_points = integer(),
                              emit_ms = numeric(), dispatch_10000_ms = numeric(),
                              drain_100_ms = numeric(), first_turn_ms = numeric(),
                              followup_turn_ms = numeric(), burst_100_ms = numeric(),
                              burst_turns = integer())
if ("bind_stream" %in% names(chart_fn("line_chart")(1, 1))) {
  source <- termr::termr_stream("benchmark", history = 1000L)
  chart <- chart_fn("line_chart")(numeric(), numeric(), mode = "ascii")
  chart$bind_stream(source, function(event) event$x, function(event) event$y,
                    max_points = 600L)
  pilot <- termr::test_app(chart, width = 80L, height = 24L)
  state <- chart$.__enclos_env__$private$.stream_state
  sequence <- 0L
  emit <- function(i) {
    sequence <<- sequence + 1L
    source$emit(list(source_id = "bench", sequence = sequence, x = sequence, y = sin(sequence / 10)))
  }
  source$emit(list(source_id = "bench", sequence = 1L, x = 1, y = sin(0.1)))
  pilot$step()
  drain_stream <- function() {
    initial_flush_count <- state$flush_count
    iterations <- 0L
    turn_ms <- numeric()
    repeat {
      started <- proc.time()[["elapsed"]]
      if (iterations == 0L) pilot$step() else pilot$advance(0.002)
      iterations <- iterations + 1L
      turn_ms[[iterations]] <- (proc.time()[["elapsed"]] - started) * 1000
      if (!state$queue$size) break
      if (iterations > 1000L) stop("Stream benchmark queue did not drain.")
    }
    list(turns = state$flush_count - initial_flush_count,
         first_turn_ms = turn_ms[[1L]],
         followup_turn_ms = if (length(turn_ms) > 1L) sum(turn_ms[-1L]) else 0,
         total_ms = sum(turn_ms))
  }
  dispatch_source <- termr::termr_stream("dispatch-benchmark", history = 10000L)
  dispatch_chart <- chart_fn("line_chart")(numeric(), numeric(), mode = "ascii")
  dispatch_chart$bind_stream(dispatch_source, function(event) event$x,
                             function(event) event$y, max_points = 10000L)
  dispatch_pilot <- termr::test_app(dispatch_chart, width = 80L, height = 24L)
  dispatch_state <- dispatch_chart$.__enclos_env__$private$.stream_state
  dispatch_ms <- elapsed_ms(function() {
    for (i in seq_len(10000L)) {
      dispatch_source$emit(list(source_id = "dispatch", sequence = i, x = i, y = i))
    }
  })
  stopifnot(dispatch_state$queue$size == 10000L, !dispatch_state$queue$dropped)
  dispatch_chart$unbind_stream()
  dispatch_pilot$stop()
  dispatch_source$close()
  dispatch_times <- numeric(3L)
  drain_times <- numeric(3L)
  burst_turns <- integer(3L)
  drain_results <- vector("list", 3L)
  for (i in seq_along(dispatch_times)) {
    dispatch_times[[i]] <- elapsed_ms(function() {
      for (j in seq_len(100L)) emit(j)
    })
    drain_times[[i]] <- elapsed_ms(function() {
      drain_results[[i]] <<- drain_stream()
      burst_turns[[i]] <<- drain_results[[i]]$turns
    })
  }
  stream_results <- data.frame(
    type = "line-stream", max_points = 600L,
    emit_ms = dispatch_ms / 10000,
    dispatch_10000_ms = dispatch_ms,
    drain_100_ms = median(drain_times),
    first_turn_ms = median(vapply(drain_results, `[[`, numeric(1), "first_turn_ms")),
    followup_turn_ms = median(vapply(drain_results, `[[`, numeric(1), "followup_turn_ms")),
    burst_100_ms = median(dispatch_times + drain_times),
    burst_turns = as.integer(median(burst_turns))
  )
  pilot$stop()
  source$close()
}

cat(sprintf("label=%s\nsource=%s\nR=%s\nOS=%s\nviewport=80x24 (resize 100x30)\n",
            label, root, as.character(getRversion()), Sys.info()[["sysname"]]))
cat("\npoint charts (median elapsed ms; update/selection/repaint are per operation):\n")
print(do.call(rbind, point_results), row.names = FALSE, digits = 4)
cat("\nheatmap and multiple-series bar shapes:\n")
print(do.call(rbind, shape_results), row.names = FALSE, digits = 4)
if (nrow(stream_results)) {
  cat("\nstream updates (synchronous dispatch; burst spans bounded event-loop turns):\n")
  print(stream_results, row.names = FALSE, digits = 4)
}
