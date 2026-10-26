# Frame layout.
#
# The frame divides a W x H widget into: a title row, an optional "y: label"
# row, the plot rectangle, an optional x-axis row with tick labels, and an
# optional "x: label" row. Every rectangle is in terminal cells (1-based, row
# 1 at the top). The frame is a pure function of the size, the labels, the
# axis domains and the renderer's dot grid, so it is recomputed on resize and
# never cached across sizes.

frame_blank <- function(W, H) {
  list(W = W, H = H, ok = FALSE, single = FALSE, title_row = 0L, ylab_row = 0L,
       xlab_row = 0L, plot = c(row = 1L, col = 1L, rows = 0L, cols = 0L),
       axis_col = 0L, axis_row = 0L, xtick_row = 0L, ytick = NULL, xtick = NULL,
       legend = NULL)
}

# Place numeric x tick labels so neighbours never touch (one blank column).
place_xticks <- function(ticks, labels, tick_cols, plot_cols) {
  keep <- logical(length(ticks))
  last_end <- -Inf
  starts <- integer(length(ticks))
  widths <- measure_width(labels)
  for (k in seq_along(ticks)) {
    start <- tick_cols[[k]] - widths[[k]] %/% 2L
    start <- max(1L, min(start, plot_cols - widths[[k]] + 1L))
    if (start > last_end + 1L && start + widths[[k]] - 1L <= plot_cols) {
      keep[[k]] <- TRUE; starts[[k]] <- start; last_end <- start + widths[[k]] - 1L
    }
  }
  list(value = ticks[keep], label = labels[keep], col = tick_cols[keep], start = starts[keep])
}


# Largest "nice" tick set whose labels land at least two cells apart (so
# neighbouring labels never touch and the spacing stays regular). Falls back
# to greedy thinning of the coarsest candidate.
spaced_ticks <- function(lo, hi, cells, res, max_n, scale = NULL) {
  best <- list(ticks = numeric(), cells = integer(), labels = NULL)
  linear <- scale_is_linear(scale)
  for (n in seq.int(max_n, 2L)) {
    labels <- NULL
    if (linear) {
      ticks <- tick_values(lo, hi, n)
    } else {
      tk <- scale_ticks(scale, lo, hi, n)
      ticks <- tk$value; labels <- tk$label
    }
    if (!length(ticks)) next
    where <- tick_cells(ticks, lo, hi, cells, res, flip = TRUE)
    if (length(where) < 2L || (!anyDuplicated(where) && all(diff(sort(where)) >= 2L))) {
      return(list(ticks = ticks, cells = where, labels = labels))
    }
    best <- list(ticks = ticks, cells = where, labels = labels)
  }
  keep <- logical(length(best$cells)); last <- -Inf
  for (k in order(best$cells)) if (best$cells[[k]] - last >= 2L) { keep[[k]] <- TRUE; last <- best$cells[[k]] }
  list(ticks = best$ticks[keep], cells = best$cells[keep], labels = best$labels[keep])
}

# x ticks of a log or time axis: the most ticks (at most `max_n`) whose labels
# all fit without touching; failing that, the placement that keeps the most.
fitted_xticks <- function(scale, xdom, max_n, P, res_x) {
  best <- NULL
  for (n in seq.int(max_n, 2L)) {
    tk <- scale_ticks(scale, xdom[[1L]], xdom[[2L]], n, 10L)
    if (!length(tk$value)) next
    cols <- tick_cells(tk$value, xdom[[1L]], xdom[[2L]], P, res_x, flip = FALSE)
    placed <- place_xticks(tk$value, tk$label, cols, P)
    if (length(placed$value) == length(tk$value)) return(placed)
    if (is.null(best) || length(placed$value) > length(best$value)) best <- placed
  }
  best
}

# Frame for charts with a plot, an optional y axis (`ydom`) and an optional x
# axis: "numeric" (domain `xdom`), "category" (labels supplied by the chart)
# or "none".
chart_frame <- function(spec, W, H, res, ydom = NULL, xdom = NULL,
                        xaxis = "numeric", legend_w = 0L, left_extra = 0L,
                        bottom_extra = 0L, xscale = NULL, yscale = NULL) {
  W <- max(0L, as.integer(W)); H <- max(0L, as.integer(H))
  fr <- frame_blank(W, H)
  if (W == 0L || H == 0L) return(fr)
  if (H == 1L) { fr$single <- TRUE; return(fr) }
  top <- 1L
  if (nzchar(spec$title %||% "")) { fr$title_row <- 1L; top <- 2L }
  if (H - top + 1L >= 4L && nzchar(spec$y_label %||% "")) { fr$ylab_row <- top; top <- top + 1L }
  bottom <- H
  if (H >= 4L && nzchar(spec$x_label %||% "")) { fr$xlab_row <- H; bottom <- H - 1L }
  avail <- bottom - top + 1L - bottom_extra
  axis_rows <- if (identical(xaxis, "numeric")) 1L else 0L
  label_rows <- switch(xaxis, numeric = as.integer(avail - 1L >= 5L),
                       category = as.integer(avail >= 4L), 0L)
  R <- avail - axis_rows - label_rows
  if (R < 1L) return(fr)

  # y axis: tick labels left of the axis column (needs enough width).
  left <- if (is.null(ydom)) as.integer(left_extra) else 0L
  yt <- NULL
  if (!is.null(ydom)) {
    left <- 1L
    if (W >= 12L) {
      sel <- spaced_ticks(ydom[[1L]], ydom[[2L]], R, res[[2L]], max(2L, (R + 1L) %/% 2L), yscale)
      ticks <- sel$ticks; cells <- sel$cells
      if (length(ticks)) {
        labels <- sel$labels %||% format_tick_labels(ticks, 8L)
        left <- min(9L, max(3L, max(measure_width(labels)) + 1L))
        yt <- list(value = ticks, label = labels, row = top + cells - 1L)
      }
    }
  }
  if (legend_w > 0L && W - left - legend_w < 12L) legend_w <- 0L
  P <- W - left - legend_w
  if (P < 1L) return(fr)
  fr$ok <- P >= 2L
  fr$plot <- c(row = top, col = left + 1L, rows = R, cols = P)
  fr$axis_col <- if (is.null(ydom)) 0L else left
  fr$axis_row <- if (axis_rows) top + R else 0L
  fr$xtick_row <- if (label_rows) top + R + axis_rows else 0L
  fr$ytick <- yt
  if (identical(xaxis, "numeric") && !is.null(xdom) && P >= 8L) {
    max_n <- max(2L, P %/% 8L)
    if (scale_is_linear(xscale)) {
      ticks <- tick_values(xdom[[1L]], xdom[[2L]], max_n)
      if (length(ticks)) {
        cols <- tick_cells(ticks, xdom[[1L]], xdom[[2L]], P, res[[1L]], flip = FALSE)
        fr$xtick <- place_xticks(ticks, format_tick_labels(ticks, 10L), cols, P)
      }
    } else {
      fr$xtick <- fitted_xticks(xscale, xdom, max_n, P, res[[1L]])
    }
  }
  # The first legend column is a gap between the plot and the legend text.
  if (legend_w > 1L) fr$legend <- c(col = left + P + 2L, cols = legend_w - 1L)
  fr
}

# Frame for charts without numeric axes (heatmap): title, optional legend column,
# and the plot rectangle. `left` and `bottom` reserve columns/rows for row and
# column labels or a scale bar.
plain_frame <- function(spec, W, H, left = 0L, bottom = 0L, legend_w = 0L) {
  W <- max(0L, as.integer(W)); H <- max(0L, as.integer(H))
  fr <- frame_blank(W, H)
  if (W == 0L || H == 0L) return(fr)
  if (H == 1L) { fr$single <- TRUE; return(fr) }
  top <- 1L
  if (nzchar(spec$title %||% "")) { fr$title_row <- 1L; top <- 2L }
  R <- H - top + 1L - bottom
  if (legend_w > 0L && W - left - legend_w < 8L) legend_w <- 0L
  P <- W - left - legend_w
  if (R < 1L || P < 1L) return(fr)
  fr$ok <- TRUE
  fr$plot <- c(row = top, col = left + 1L, rows = R, cols = P)
  if (legend_w > 1L) fr$legend <- c(col = left + P + 2L, cols = legend_w - 1L)
  fr$xtick_row <- if (bottom > 0L) top + R else 0L
  fr
}
