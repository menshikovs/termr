# Bars with several series, and horizontal bars.
#
# One handler for every case other than a plain vertical vector (which keeps
# `handle_bars()` exactly as it was):
#
#   position     single   one value per category (a numeric vector)
#                grouped  one bar per series side by side inside a category
#                stacked  the series accumulated inside a category; positive
#                         values stack away from zero in one direction and
#                         negative values in the other, never on top of each
#                         other
#   orientation  vertical | horizontal
#
# The category axis and the value axis are the only things that swap. Bars
# are drawn on the usual dot surface in whole cells along the category axis (a
# bar is never a fraction of a cell wide or high), and the value axis keeps the
# renderer's resolution. Series are told apart by pattern (the fills of the
# stacked area chart: ASCII fill characters, block shades, Braille dither), so
# the chart reads without colour, and a legend lists them.
#
# Identity: a vector keeps the original integer `index`; a matrix selects a
# (category, series) pair, `c(category = i, series = s)` in source numbers.

# Sparse Braille patterns keep multiple bar series distinguishable without
# requiring terminal colour.
dither_keep <- function(i, j, s) {
  switch((as.integer(s) - 1L) %% 6L + 1L,
         rep(TRUE, length(i)),
         (i + j) %% 2 == 0,
         i %% 2 == 0 & j %% 2 == 0,
         i %% 2 == 0,
         j %% 2 == 0,
         (i + j) %% 4 == 0)
}

sample_ids <- function(ids, limit) {
  if (length(ids) <= limit) ids else
    ids[unique(round(seq(1, length(ids), length.out = limit)))]
}

pattern_glyph <- function(mode, s) {
  switch(mode,
    ascii = ascii_fill[(s - 1L) %% length(ascii_fill) + 1L],
    braille = {
      i <- rep(1:4, 2); j <- rep(1:2, each = 4)
      keep <- dither_keep(i, j, s)
      braille_cell(sum(braille_bits[cbind(i[keep], j[keep])]))
    },
    block_shade[(s - 1L) %% length(block_shade) + 1L])
}

# The (category, series) -> item lookup, items in category-major order.
bar_items <- function(V, valid, shown, stacked) {
  n <- length(shown); S <- ncol(V)
  cat <- integer(); series <- integer(); kpos <- integer(); value <- double()
  lower <- double(); upper <- double()
  for (k in seq_len(n)) {
    c_i <- shown[[k]]
    cum_pos <- 0; cum_neg <- 0
    for (s in seq_len(S)) {
      if (!valid[c_i, s]) next
      v <- V[c_i, s]
      lo <- 0; hi <- v
      if (stacked) {
        if (v > 0) { lo <- cum_pos; hi <- cum_pos + v; cum_pos <- hi }
        else if (v < 0) { hi <- cum_neg; lo <- cum_neg + v; cum_neg <- lo }
      } else if (v < 0) { lo <- v; hi <- 0 }
      cat <- c(cat, c_i); series <- c(series, s); kpos <- c(kpos, k)
      value <- c(value, v); lower <- c(lower, lo); upper <- c(upper, hi)
    }
  }
  list(cat = cat, series = series, kpos = kpos, value = value, lower = lower, upper = upper)
}

handle_bars_multi <- function(spec, W, H, resolved) {
  mode <- resolved$mode
  res <- mode_resolution(mode)
  glyphs <- axis_glyphs(resolved$text)
  d <- spec$data
  horiz <- identical(spec$orientation, "horizontal")
  position <- spec$position %||% "single"
  grouped <- identical(position, "grouped")
  stacked <- identical(position, "stacked")
  multi <- isTRUE(d$multi)
  V <- if (multi) d$matrix else matrix(d$values, ncol = 1L)
  labels <- d$labels
  snames <- if (multi) d$series else "values"
  S <- ncol(V)
  valid <- is.finite(V)
  cats_ok <- which(rowSums(valid) > 0L)
  if (!length(cats_ok)) {
    frame <- plain_frame(spec, W, H)
    return(empty_plan(spec, frame, glyphs, list(note_item(frame, "(no finite data)"))))
  }
  sx <- res[[1L]]; sy <- res[[2L]]

  # The value domain comes from every drawn category, so it does not change
  # when many categories are sampled to fit.
  allv <- V[cats_ok, , drop = FALSE]
  if (stacked) {
    vdom <- range(c(0, rowSums(pmax(allv, 0), na.rm = TRUE), rowSums(pmin(allv, 0), na.rm = TRUE)))
  } else {
    vdom <- range(c(0, allv[is.finite(allv)]))
  }
  if (vdom[[1L]] == vdom[[2L]]) vdom <- c(0, 1)

  cap <- if (horiz) max(1L, H - 3L) else max(1L, W - 9L)
  if (grouped) cap <- max(1L, cap %/% S)
  shown <- sample_ids(cats_ok, cap)

  legend_w <- if (multi && W >= 40L) min(max(measure_width(snames)) + 3L, max(12L, W %/% 3L)) else 0L
  labelw <- 0L
  if (horiz) {
    labelw <- min(max(measure_width(labels[shown])), max(6L, W %/% 3L))
    if (W < 14L) labelw <- 0L
  }
  left_extra <- if (labelw > 0L) labelw + 1L else 0L
  frame <- if (horiz) {
    chart_frame(spec, W, H, res, NULL, vdom, "numeric", legend_w = legend_w, left_extra = left_extra)
  } else {
    chart_frame(spec, W, H, res, vdom, NULL, "category", legend_w = legend_w)
  }
  if (!frame$ok) return(empty_plan(spec, frame, glyphs))
  if (horiz && left_extra > 0L) frame$axis_col <- left_extra
  P <- frame$plot[["cols"]]; R <- frame$plot[["rows"]]
  pr <- frame$plot[["row"]]; pc <- frame$plot[["col"]]
  Pc <- if (horiz) R else P                    # cells along the category axis
  if (grouped && Pc < S) {
    note <- sprintf("(too %s for %d series)", if (horiz) "short" else "narrow", S)
    return(empty_plan(spec, frame, glyphs, list(note_item(frame, note))))
  }
  shown <- sample_ids(shown, if (grouped) max(1L, min(length(shown), Pc %/% S)) else min(length(shown), Pc))

  surf <- surface_new(P, R, mode)
  hd <- surf$hd; wd <- surf$wd
  n <- length(shown)
  c0 <- floor((seq_len(n) - 1L) * Pc / n) + 1L
  c1 <- pmax(c0, floor(seq_len(n) * Pc / n))
  cw <- c1 - c0 + 1L
  gap <- if (grouped) as.integer(cw >= S + 1L & cw >= 3L) else as.integer(cw >= 3L)
  usable <- cw - gap
  band <- if (grouped) usable %/% S else usable

  it <- bar_items(V, valid, shown, stacked)
  m <- length(it$cat)
  cell0 <- cell1 <- integer(m)                 # category cells of each item's band
  for (q in seq_len(m)) {
    k <- it$kpos[[q]]
    if (grouped) {
      cell0[[q]] <- c0[[k]] + (it$series[[q]] - 1L) * band[[k]]
      cell1[[q]] <- cell0[[q]] + band[[k]] - 1L
    } else {
      cell0[[q]] <- c0[[k]]
      cell1[[q]] <- c0[[k]] + usable[[k]] - 1L
    }
  }

  # Rectangles in value-axis dots (p increases with value) and in surface dots.
  nvd <- if (horiz) wd else hd
  pdot <- function(v) dot_from_unit(unit_values(v, vdom[[1L]], vdom[[2L]]), nvd)
  pb <- pdot(0)
  p0 <- p1 <- rep(NA_integer_, m)
  first_pos <- first_neg <- logical(m)
  if (stacked) {
    seen_pos <- seen_neg <- integer()
    for (q in seq_len(m)) {
      key <- it$kpos[[q]]
      v <- it$value[[q]]
      if (v > 0) { first_pos[[q]] <- !(key %in% seen_pos); seen_pos <- c(seen_pos, key) }
      if (v < 0) { first_neg[[q]] <- !(key %in% seen_neg); seen_neg <- c(seen_neg, key) }
    }
  }
  for (q in seq_len(m)) {
    v <- it$value[[q]]
    if (v == 0) next
    if (!stacked) {
      e <- pdot(v); a <- min(e, pb); b <- max(e, pb)
    } else if (v > 0) {
      a <- if (first_pos[[q]]) pb else pdot(it$lower[[q]]) + 1L
      b <- pdot(it$upper[[q]])
    } else {
      a <- pdot(it$lower[[q]])
      b <- if (first_neg[[q]]) pb - 1L else pdot(it$upper[[q]]) - 1L
    }
    if (a <= b) { p0[[q]] <- a; p1[[q]] <- b }
  }
  cat_dots <- if (horiz) sy else sx
  d0 <- (cell0 - 1L) * cat_dots + 1L
  d1 <- cell1 * cat_dots
  ri0 <- if (horiz) d0 else hd + 1L - p1       # surface rows / columns of each rectangle
  ri1 <- if (horiz) d1 else hd + 1L - p0
  cj0 <- if (horiz) p0 else d0
  cj1 <- if (horiz) p1 else d1
  drawn <- !is.na(p0)

  ops <- list()
  for (q in which(drawn)) {
    r <- raster_rect(ri0[[q]], ri1[[q]], cj0[[q]], cj1[[q]])
    ii <- r$i; jj <- r$j
    s <- if (multi) it$series[[q]] else 1L
    if (identical(mode, "braille") && s >= 2L) {
      keep <- dither_keep(ii, jj, s)
      ii <- ii[keep]; jj <- jj[keep]
    }
    ops[[length(ops) + 1L]] <- new_op(dots_idx(ii, jj, hd, wd), mark_of(K_FILL, s))
  }
  if (!horiz && vdom[[1L]] < 0 && vdom[[2L]] > 0) {
    ib <- hd + 1L - pb
    rule <- raster_segments(ib, 1L, ib, wd)
    ops <- c(list(new_op(dots_idx(rule$i, rule$j, hd, wd), mark_of(K_GUIDE))), ops)
  }
  surf$m <- apply_ops(surf$m, ops)

  # Which item owns each dot (exact visible segments, for clicks).
  own <- matrix(0L, hd, wd)
  for (q in which(drawn)) {
    rows <- ri0[[q]]:ri1[[q]]; cols <- cj0[[q]]:cj1[[q]]
    rows <- rows[rows >= 1L & rows <= hd]; cols <- cols[cols >= 1L & cols <= wd]
    if (length(rows) && length(cols)) own[rows, cols] <- q
  }

  id_of <- function(q) if (multi) c(category = it$cat[[q]], series = it$series[[q]]) else it$cat[[q]]
  lookup <- matrix(0L, nrow(V), S)
  lookup[cbind(it$cat, it$series)] <- seq_len(m)
  item_of <- function(selected) {
    if (anyNA(selected)) return(0L)
    cat_i <- if (multi) selected[["category"]] else selected[[1L]]
    s <- if (multi) selected[["series"]] else 1L
    if (cat_i < 1L || cat_i > nrow(V) || s < 1L || s > S) return(0L)
    lookup[[cat_i, s]]
  }

  # Marker cell for an item, on the plot (row, column), clamped inside it.
  clamp <- function(x, hi) max(1L, min(hi, as.integer(x)))
  marker_of <- function(q) {
    mid <- (cell0[[q]] + cell1[[q]]) %/% 2L
    v <- it$value[[q]]
    if (!drawn[[q]]) {
      base <- if (horiz) (pb - 1L) %/% sx + 1L else (hd - pb) %/% sy + 1L
      return(if (horiz) list(row = clamp(mid, R), col = clamp(base, P)) else list(row = clamp(base, R), col = clamp(mid, P)))
    }
    if (horiz) {
      col <- if (stacked) (cj0[[q]] + cj1[[q]]) %/% 2L else if (v >= 0) cj1[[q]] else cj0[[q]]
      cell <- (col - 1L) %/% sx + 1L
      cell <- if (stacked) cell else if (v >= 0) cell + 1L else cell - 1L
      list(row = clamp(mid, R), col = clamp(cell, P))
    } else {
      row <- if (stacked) (ri0[[q]] + ri1[[q]]) %/% 2L else if (v >= 0) ri0[[q]] else ri1[[q]]
      cell <- (row - 1L) %/% sy + 1L
      cell <- if (stacked) cell else if (v >= 0) cell - 1L else cell + 1L
      list(row = clamp(cell, R), col = clamp(mid, P))
    }
  }
  stamp <- function(selected) {
    q <- item_of(selected)
    if (q == 0L) return(NULL)
    ops <- list()
    if (drawn[[q]]) {
      r <- raster_rect(ri0[[q]], ri1[[q]], cj0[[q]], cj1[[q]])
      ops <- list(new_op(dots_idx(r$i, r$j, hd, wd), mark_of(K_SELECTED_FILL)))
    }
    list(ops = ops, marker = marker_of(q))
  }

  # Category labels.
  extras <- list()
  if (horiz) {
    if (labelw > 0L) {
      for (k in seq_len(n)) {
        extras[[length(extras) + 1L]] <- list(row = pr + c0[[k]] - 1L, col = 1L, text = labels[[shown[[k]]]],
                                              kind = K_TICK, width = labelw)
      }
    }
  } else if (frame$xtick_row > 0L) {
    placed <- thin_labels(c0, labels[shown], Pc)
    pos_of <- match(placed$label, labels[shown])
    for (k in seq_along(placed$label)) {
      extras[[length(extras) + 1L]] <- list(row = frame$xtick_row, col = pc + placed$start[[k]] - 1L,
                                            text = placed$label[[k]], kind = K_TICK,
                                            width = Pc - placed$start[[k]] + 1L)
    }
  }
  # Legend: top to bottom in the order the series are stacked on screen.
  legend_rows <- integer(S)
  if (!is.null(frame$legend)) {
    order_top <- if (stacked && !horiz) rev(seq_len(S)) else seq_len(S)
    avail <- frame$plot[["rows"]]
    shown_n <- if (S > avail) max(0L, avail - 1L) else S
    for (r in seq_len(shown_n)) {
      s <- order_top[[r]]
      row <- pr + r - 1L
      legend_rows[[s]] <- row
      extras[[length(extras) + 1L]] <- list(row = row, col = frame$legend[["col"]],
        text = pattern_glyph(mode, s), kind = K_FILL, series = s, width = 1L)
      extras[[length(extras) + 1L]] <- list(row = row, col = frame$legend[["col"]] + 2L,
        text = snames[[s]], kind = K_LEGEND, width = frame$legend[["cols"]] - 2L)
    }
    if (shown_n < S) {
      extras[[length(extras) + 1L]] <- list(row = pr + shown_n, col = frame$legend[["col"]],
        text = sprintf("+%d more", S - shown_n), kind = K_LEGEND, width = frame$legend[["cols"]])
    }
  }

  # Clicks: the visible segment (stacked) or the bar's band (single, grouped,
  # which also reaches zero and tiny bars); a legend row picks a series at the
  # current category.
  hit <- function(row, col, selected) {
    p <- hit_plot_cell(frame, row, col)
    if (is.null(p)) {
      lg <- frame$legend
      if (!multi || is.null(lg) || col < lg[["col"]] || col >= lg[["col"]] + lg[["cols"]]) return(NULL)
      s <- which(legend_rows == row)
      if (!length(s) || anyNA(selected)) return(NULL)
      cat_i <- selected[["category"]]
      if (cat_i < 1L || cat_i > nrow(V) || !valid[cat_i, s[[1L]]]) return(NULL)
      return(c(category = as.integer(cat_i), series = as.integer(s[[1L]])))
    }
    if (stacked) {
      dots <- hit_cell_dots(p, sx, sy)
      for (t in seq_along(dots$i)) {
        q <- own[[dots$i[[t]], dots$j[[t]]]]
        if (q > 0L) return(id_of(q))
      }
      return(NULL)
    }
    cell <- if (horiz) p[["row"]] else p[["col"]]
    q <- which(cell0 <= cell & cell <= cell1)
    if (length(q)) id_of(q[[1L]]) else NULL
  }

  # Keyboard: the primary direction changes category, the secondary the series.
  G <- valid[shown, , drop = FALSE]
  nav <- if (!multi) {
    ids <- it$cat
    nav_linear(ids)
  } else function(key, selected) {
    cat_i <- selected[["category"]]; s <- selected[["series"]]
    k <- match(cat_i, shown)
    if (is.na(k)) k <- which.min(abs(shown - cat_i))
    pick <- function(kk) {
      ok <- which(G[kk, ])
      ok[[which.min(abs(ok - s))]]
    }
    prim <- if (key == "j") 1L else if (key == "k") -1L else if (!horiz) {
      switch(key, left = -1L, right = 1L, 0L)
    } else switch(key, up = -1L, down = 1L, 0L)
    sec <- if (!horiz) switch(key, up = 1L, down = -1L, 0L) else switch(key, right = 1L, left = -1L, 0L)
    has <- which(rowSums(G) > 0L)
    kk <- k; s2 <- s
    if (key %in% c("home", "end")) {
      kk <- if (key == "home") has[[1L]] else has[[length(has)]]
      s2 <- pick(kk)
    } else if (prim != 0L) {
      kk <- k + prim
      while (kk >= 1L && kk <= n && !any(G[kk, ])) kk <- kk + prim
      if (kk < 1L || kk > n) { kk <- k } else s2 <- pick(kk)
    } else if (sec != 0L) {
      ss <- s + sec
      while (ss >= 1L && ss <= S && !G[k, ss]) ss <- ss + sec
      if (ss >= 1L && ss <= S) s2 <- ss
    } else return(NULL)
    c(category = as.integer(shown[[kk]]), series = as.integer(s2))
  }

  ids <- if (multi) lapply(seq_len(m), id_of) else it$cat
  plan <- surface_plan(spec, frame, glyphs, extras, surf, stamp, ids = ids, nav = nav,
                       positions = shown, hit = hit)
  units <- NULL
  if (isTRUE(spec$value_labels)) {
    cell_of <- function(dot, per) ifelse(is.na(dot), NA_integer_, (dot - 1L) %/% per + 1L)
    vr0 <- if (horiz) cell_of(cj0, sx) else cell_of(ri0, sy)
    vr1 <- if (horiz) cell_of(cj1, sx) else cell_of(ri1, sy)
    base_cell <- if (horiz) (pb - 1L) %/% sx + 1L else (hd - pb) %/% sy + 1L
    units <- bar_label_units(format_value_label(it$value), cs = cell0, ce = cell1, vr0 = vr0, vr1 = vr1,
                             base = rep(base_cell, m), sign = sign(it$value), horiz = horiz, stacked = stacked,
                             plot0 = plan$plot(NA_integer_), R = R, P = P, glyphs = glyphs)
  }
  plan$refs <- bar_refs(spec, vdom, horiz, surf, glyphs, mode, plan, units)
  plan$items <- c(it, list(p0 = p0, p1 = p1, rows = cbind(ri0, ri1), cols = cbind(cj0, cj1),
                           cell0 = cell0, cell1 = cell1, drawn = drawn, baseline = pb, vdom = vdom))
  plan$shown <- shown
  # The selection is shown on the bar itself; the legend carries no selection
  # marker, because the selection child must stay a small rectangle (a marker
  # at the legend would stretch it across the plot and repaint all of it).
  plan$overlay <- function(cells, selected) {
    if (horiz && vdom[[1L]] < 0 && vdom[[2L]] > 0) {
      col <- pc + (pb - 1L) %/% sx
      rows <- pr:(pr + R - 1L)
      blank <- cells$glyph[rows, col] == " "
      cells$glyph[rows[blank], col] <- glyphs$v
      cells$mark[rows[blank], col] <- mark_of(K_AXIS)
    }
    cells
  }
  plan
}
