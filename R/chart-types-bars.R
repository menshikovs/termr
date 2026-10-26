# Bar charts and histograms.
#
# Bars are drawn as filled rectangles on the dot surface, so the block
# renderer gets eighth-cell heights and Braille gets 2 x 4 resolution. A
# histogram wider than the plot merges adjacent bins (counts add) rather
# than dropping bins; a bar chart with more finite bars than columns shows
# an even sample of them.

hist_label <- function(lower, upper) {
  paste0(format(lower, trim = TRUE, scientific = FALSE, decimal.mark = ".", big.mark = ""), "-",
         format(upper, trim = TRUE, scientific = FALSE, decimal.mark = ".", big.mark = ""))
}

# Group bins for display: group g covers bins first[g]..last[g].
hist_groups <- function(nbins, limit) {
  if (nbins <= limit) return(list(first = seq_len(nbins), last = seq_len(nbins)))
  grp <- floor((seq_len(nbins) - 1L) * limit / nbins) + 1L
  first <- tapply(seq_len(nbins), grp, min)
  last <- tapply(seq_len(nbins), grp, max)
  list(first = as.integer(first), last = as.integer(last))
}

histogram_payload <- function(spec, id, plan = NULL) {
  d <- spec$data
  last <- id
  if (!is.null(plan$groups)) {
    g <- match(id, plan$groups$first)
    if (!is.na(g)) last <- plan$groups$last[[g]]
  }
  list(index = id, lower = d$breaks[[id]], upper = d$breaks[[last + 1L]],
       count = sum(d$values[id:last]))
}

handle_bars <- function(spec, W, H, resolved) {
  type <- spec$type
  # Several series and horizontal bars have their own handler; a plain vertical
  # vector keeps the geometry below unchanged.
  if (identical(type, "bar") && (isTRUE(spec$data$multi) || identical(spec$orientation, "horizontal"))) {
    return(handle_bars_multi(spec, W, H, resolved))
  }
  mode <- resolved$mode
  res <- mode_resolution(mode)
  glyphs <- axis_glyphs(resolved$text)
  d <- spec$data
  finite <- which(is.finite(d$values))
  if (!length(finite)) {
    frame <- plain_frame(spec, W, H)
    return(empty_plan(spec, frame, glyphs, list(note_item(frame, "(no finite data)"))))
  }
  # Number of bars shown. The left margin never exceeds 9 columns, so this is
  # a bound on the plot width that does not depend on the y-axis labels.
  limit <- max(1L, W - 9L)
  groups <- NULL
  if (identical(type, "histogram")) {
    groups <- hist_groups(length(d$values), limit)
    shown <- groups$first
    value <- vapply(seq_along(shown), function(g) sum(d$values[groups$first[[g]]:groups$last[[g]]]), 0)
    label <- hist_label(d$breaks[groups$first], d$breaks[groups$last + 1L])
  } else {
    shown <- if (length(finite) <= limit) finite else
      finite[unique(round(seq(1, length(finite), length.out = limit)))]
    value <- d$values[shown]
    label <- d$labels[shown]
  }
  ydom <- range(c(0, value))
  if (ydom[[1L]] == ydom[[2L]]) ydom <- c(0, 1)
  frame <- chart_frame(spec, W, H, res, ydom, NULL, "category")
  if (!frame$ok) return(empty_plan(spec, frame, glyphs))
  P <- frame$plot[["cols"]]; R <- frame$plot[["rows"]]
  surf <- surface_new(P, R, mode)
  hd <- surf$hd; wd <- surf$wd
  n <- length(shown)
  c0 <- floor((seq_len(n) - 1L) * P / n) + 1L
  c1 <- pmax(c0, floor(seq_len(n) * P / n))
  gap <- if (identical(type, "bar") && any(c1 - c0 + 1L >= 3L)) 1L else 0L
  gap <- ifelse(c1 - c0 + 1L >= 3L, gap, 0L)
  j0 <- (c0 - 1L) * surf$sx + 1L
  j1 <- (c1 - gap) * surf$sx
  u <- function(v) dot_row_from_unit(unit_values(v, ydom[[1L]], ydom[[2L]]), hd)
  ib <- u(0)
  iv <- u(value)
  ops <- list()
  if (ydom[[1L]] < 0 && ydom[[2L]] > 0) {
    rule <- raster_segments(ib, 1L, ib, wd)
    ops[[1L]] <- new_op(dots_idx(rule$i, rule$j, hd, wd), mark_of(K_GUIDE))
  }
  bar_rect <- function(k) {
    if (value[[k]] == 0) return(list(i = numeric(), j = numeric()))
    raster_rect(min(iv[[k]], ib), max(iv[[k]], ib), j0[[k]], j1[[k]])
  }
  for (k in seq_len(n)) {
    r <- bar_rect(k)
    ops[[length(ops) + 1L]] <- new_op(dots_idx(r$i, r$j, hd, wd), mark_of(K_FILL))
  }
  surf$m <- apply_ops(surf$m, ops)

  extras <- list()
  if (frame$xtick_row > 0L && identical(type, "histogram")) {
    # Numeric x axis: label bin edges at their boundary columns.
    edges <- c(d$breaks[groups$first], d$breaks[groups$last[[length(groups$last)]] + 1L])
    placed <- place_xticks(edges, format_tick_labels(edges, 10L), c(c0, P), P)
    for (k in seq_along(placed$label)) {
      extras[[length(extras) + 1L]] <- list(
        row = frame$xtick_row, col = frame$plot[["col"]] + placed$start[[k]] - 1L,
        text = placed$label[[k]], kind = K_TICK, width = P)
    }
  } else if (frame$xtick_row > 0L) {
    for (k in seq_len(n)) {
      extras[[length(extras) + 1L]] <- list(
        row = frame$xtick_row, col = frame$plot[["col"]] + c0[[k]] - 1L, text = label[[k]],
        kind = K_TICK, width = c1[[k]] - c0[[k]] + 1L)
    }
  }
  stamp <- function(selected) {
    k <- match(selected, shown)
    if (is.na(k)) return(NULL)
    r <- bar_rect(k)
    top_cell <- (min(iv[[k]], ib) - 1L) %/% surf$sy + 1L
    bottom_cell <- (max(iv[[k]], ib) - 1L) %/% surf$sy + 1L
    row <- if (value[[k]] >= 0) max(1L, top_cell - 1L) else min(R, bottom_cell + 1L)
    list(ops = list(new_op(dots_idx(r$i, r$j, hd, wd), mark_of(K_SELECTED_FILL))),
         marker = list(row = row, col = (c0[[k]] + c1[[k]] - gap[[k]] + 1L) %/% 2L))
  }
  # A bar owns its whole column strip of the plot, so zero and tiny bars can
  # be clicked; a histogram bucket is the displayed (possibly merged) bin.
  hit <- function(row, col, selected) {
    p <- hit_plot_cell(frame, row, col)
    k <- if (is.null(p)) NULL else hit_slot(c0, c1, p[["col"]])
    if (is.null(k)) NULL else shown[[k]]
  }
  plan <- surface_plan(spec, frame, glyphs, extras, surf, stamp, ids = shown,
                       nav = nav_linear(shown), positions = shown, hit = hit)
  plan$groups <- groups
  units <- NULL
  if (isTRUE(spec$value_labels) && identical(type, "bar")) {
    drawn <- value != 0
    top_cell <- (pmin(iv, ib) - 1L) %/% surf$sy + 1L
    bot_cell <- (pmax(iv, ib) - 1L) %/% surf$sy + 1L
    units <- bar_label_units(format_value_label(value), cs = c0, ce = c1 - gap,
                             vr0 = ifelse(drawn, top_cell, NA_integer_), vr1 = ifelse(drawn, bot_cell, NA_integer_),
                             base = rep((ib - 1L) %/% surf$sy + 1L, n), sign = sign(value),
                             horiz = FALSE, stacked = FALSE, plot0 = plan$plot(NA_integer_), R = R, P = P, glyphs = glyphs)
  }
  if (identical(type, "bar")) plan$refs <- bar_refs(spec, ydom, FALSE, surf, glyphs, mode, plan, units)
  plan
}
