# Chart-type registry. Types are looked up at call time (not stored in a
# list built at load) so file collation order never matters.

chart_handler <- function(type) {
  switch(type,
    line = , scatter = handle_xy,
    bar = , histogram = handle_bars,
    heatmap = handle_heatmap,
    NULL)
}

chart_event_name <- function(spec, event) paste("termrcharts", spec$type, event, sep = ".")

# First selectable item of a chart, before any size is known.
chart_initial_selection <- function(spec) {
  d <- spec$data
  switch(spec$type,
    line = , scatter = if (length(d$source)) d$source[[1L]] else NA_integer_,
    bar = , histogram = if (isTRUE(d$multi)) {
      ok <- is.finite(d$matrix)
      r <- which(rowSums(ok) > 0L)
      if (length(r)) c(category = as.integer(r[[1L]]), series = as.integer(which(ok[r[[1L]], ])[[1L]]))
      else NA_integer_
    } else {
      finite <- which(is.finite(d$values))
      if (length(finite)) finite[[1L]] else NA_integer_
    },
    heatmap = {
      ok <- which(is.finite(d$z), arr.ind = FALSE)
      if (length(ok)) {
        rc <- arrayInd(ok[[1L]], dim(d$z))
        c(row = rc[[1L]], column = rc[[2L]])
      } else NA_integer_
    },
    NA_integer_)
}

# The original x of retained item `p`: a Date or POSIXct keeps its class and time zone.
xy_x <- function(d, p) if (is.null(d$x_orig)) d$x[[p]] else d$x_orig[[p]]

# The payload of an event for item `id`. Payloads hold logical data identity
# only: never screen coordinates or widget internals.
chart_event_payload <- function(spec, id, plan = NULL) {
  d <- spec$data
  switch(spec$type,
    line = , scatter = {
      p <- match(id, d$source)
      if (is.na(p)) stop("Selected chart index is not in the source data.", call. = FALSE)
      list(index = id, x = xy_x(d, p), y = d$y[[p]])
    },
    histogram = histogram_payload(spec, id, plan),
    bar = if (isTRUE(d$multi)) {
      list(category_index = as.integer(id[["category"]]), category = d$labels[[id[["category"]]]],
           series_index = as.integer(id[["series"]]), series = d$series[[id[["series"]]]],
           value = d$matrix[[id[["category"]], id[["series"]]]])
    } else list(index = id, label = d$labels[[id]], value = d$values[[id]]),
    heatmap = heatmap_payload(spec, id, plan),
    stop(sprintf("Unknown chart type `%s`.", spec$type), call. = FALSE))
}

# Legacy helpers kept for tests and benchmarks: the retained display positions
# and item ids of a chart at a widget size.
chart_selectable_positions <- function(spec, width, height = 24L) {
  chart_plan(spec, width, height)$positions
}

chart_selectable_indices <- function(spec, width, height = 24L) {
  chart_plan(spec, width, height)$ids
}
