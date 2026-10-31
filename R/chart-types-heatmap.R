# Heatmaps: a numeric matrix shown as shaded cells.
#
# Cell-based rather than dot-based: every displayed cell is one glyph with a
# level. A matrix larger than the plot is aggregated to viewport resolution
# first (mean of the finite values of each block), so a 1000 x 1000 input
# never creates a styled segment per source cell. A smaller matrix is
# replicated so each source cell fills a block of display cells. The colour
# scale spans the finite values that are *displayed* (block means once
# aggregated, so a lone hot spot is not diluted into the background and the
# legend always describes what is drawn); levels are also encoded as a glyph
# ramp, so the chart reads without colour.

heat_ramp_ascii <- c(" ", ".", ":", "-", "=", "+", "*", "#", "%", "@")
heat_ramp_block <- c(" ", "\u2591", "\u2591", "\u2592", "\u2592", "\u2593", "\u2593",
                     "\u2588", "\u2588", "\u2588")

# Source index of every display position along an axis, and (for axes that
# need aggregation) the display group of every source index.
axis_map <- function(n_src, n_disp) {
  if (n_src > n_disp) {
    group <- floor((seq_len(n_src) - 1L) * n_disp / n_src) + 1L
    list(aggregate = TRUE, group = as.integer(group),
         rep = as.integer(match(seq_len(n_disp), group)))
  } else {
    src <- as.integer(floor((seq_len(n_disp) - 1L) * n_src / n_disp) + 1L)
    list(aggregate = FALSE, src = src, rep = seq_len(n_src))
  }
}

# Mean of the finite values in each block, resampled to n_rows x n_cols.
heat_resample <- function(z, n_rows, n_cols) {
  rmap <- axis_map(nrow(z), n_rows)
  cmap <- axis_map(ncol(z), n_cols)
  ok <- is.finite(z)
  sum_z <- z; sum_z[!ok] <- 0
  cnt <- matrix(as.numeric(ok), nrow(z), ncol(z))
  if (rmap$aggregate) {
    sum_z <- rowsum(sum_z, rmap$group, reorder = TRUE)
    cnt <- rowsum(cnt, rmap$group, reorder = TRUE)
  }
  if (cmap$aggregate) {
    sum_z <- t(rowsum(t(sum_z), cmap$group, reorder = TRUE))
    cnt <- t(rowsum(t(cnt), cmap$group, reorder = TRUE))
  }
  mean_z <- sum_z / cnt
  mean_z[cnt == 0] <- NA_real_
  rows <- if (rmap$aggregate) seq_len(n_rows) else rmap$src
  cols <- if (cmap$aggregate) seq_len(n_cols) else cmap$src
  out <- mean_z[rows, cols, drop = FALSE]
  dim(out) <- c(length(rows), length(cols))
  list(value = out, rmap = rmap, cmap = cmap)
}

# Level 1..HEAT_LEVELS of each value on the source range; NA stays NA.
heat_levels <- function(value, lo, hi) {
  u <- unit_values(value, lo, hi)
  level <- 1L + as.integer(floor(u * (HEAT_LEVELS - 1L) + 0.5))
  level[!is.finite(value)] <- NA_integer_
  dim(level) <- dim(value)
  level
}

# Choose which labels to draw along an axis `width` cells wide. `starts` are
# the ascending first cells of the candidates and `labels` their text. The
# first candidate is always kept and the others follow greedily, at least one
# blank cell after the previous label, so the stride is regular when the
# candidates are. The last candidate is kept too (right-aligned to the axis
# end) when that does not touch the label before it, replacing the labels it
# would overlap. Returns list(start, label); labels never overlap and always
# fit inside `width`.
thin_labels <- function(starts, labels, width) {
  n <- length(starts)
  if (!n || width < 1L) return(list(start = integer(), label = character()))
  w <- pmin(measure_width(labels), width)
  keep <- integer(); end <- 0L
  for (k in seq_len(n)) {
    if (starts[[k]] > end && starts[[k]] + w[[k]] - 1L <= width) {
      keep <- c(keep, k); end <- starts[[k]] + w[[k]]       # one blank follows
    }
  }
  if (!length(keep)) keep <- 1L
  at <- starts[keep]
  if (n > 1L && !(n %in% keep)) {
    last_start <- max(1L, width - w[[n]] + 1L)
    clash <- at + w[keep] - 1L >= last_start - 1L
    keep <- keep[!clash]; at <- at[!clash]
    keep <- c(keep, n); at <- c(at, last_start)
  }
  list(start = as.integer(at), label = labels[keep])
}

heat_label <- function(x) format_tick_labels(x, 10L)

# Neighbouring item for 2-D keys; `rows`/`cols` are the navigable source
# indices on each axis (ascending).
nav_grid <- function(rows, cols) {
  function(key, selected) {
    row <- selected[["row"]]; col <- selected[["column"]]
    step <- function(axis, at, by) {
      pos <- match(at, axis)
      if (is.na(pos)) pos <- which.min(abs(axis - at))
      axis[[max(1L, min(length(axis), pos + by))]]
    }
    new <- switch(key,
      left = c(row, step(cols, col, -1L)), right = c(row, step(cols, col, 1L)),
      up = , k = c(step(rows, row, -1L), col), down = , j = c(step(rows, row, 1L), col),
      home = c(row, cols[[1L]]), end = c(row, cols[[length(cols)]]),
      return(NULL))
    c(row = as.integer(new[[1L]]), column = as.integer(new[[2L]]))
  }
}

heatmap_payload <- function(spec, id, plan = NULL) {
  z <- spec$data$z
  r <- as.integer(id[["row"]]); c <- as.integer(id[["column"]])
  if (r < 1L || r > nrow(z) || c < 1L || c > ncol(z)) {
    stop("Selected heatmap cell is outside the matrix.", call. = FALSE)
  }
  list(row = r, column = c, value = z[[r, c]])
}

handle_heatmap <- function(spec, W, H, resolved) {
  mode <- resolved$mode
  glyphs <- axis_glyphs(resolved$text)
  d <- spec$data
  nr <- nrow(d$z); nc <- ncol(d$z)
  if (!d$n_finite) {
    frame <- plain_frame(spec, W, H)
    return(empty_plan(spec, frame, glyphs, list(note_item(frame, "(no finite data)"))))
  }
  ramp <- if (identical(mode, "ascii")) heat_ramp_ascii else heat_ramp_block
  # Row labels take at most 8 columns; column labels are thinned to fit.
  row_w <- 0L
  if (!is.null(d$row_labels) && W >= 20L) {
    row_w <- min(8L, max(measure_width(d$row_labels))) + 1L
  }
  show_rows <- row_w > 0L
  show_cols <- !is.null(d$col_labels) && W - row_w >= 6L
  show_bar <- H >= 6L
  xaxis <- if (show_cols) "category" else "none"
  frame <- chart_frame(spec, W, H, c(1L, 1L), NULL, NULL, xaxis,
                       left_extra = row_w, bottom_extra = as.integer(show_bar))
  if (!frame$ok) return(empty_plan(spec, frame, glyphs))
  P <- frame$plot[["cols"]]; R <- frame$plot[["rows"]]
  pr <- frame$plot[["row"]]; pc <- frame$plot[["col"]]
  res <- heat_resample(d$z, R, P)
  shown <- res$value[is.finite(res$value)]
  lo <- min(shown); hi <- max(shown)
  level <- heat_levels(res$value, lo, hi)
  glyph <- matrix(ramp[level], R, P)
  mark <- matrix(mark_of(K_HEAT, level), R, P)
  na <- is.na(level)
  glyph[na] <- "?"; mark[na] <- mark_of(K_LABEL)

  extras <- list()
  add <- function(row, col, text, kind, series = 1L, width = NULL) {
    extras[[length(extras) + 1L]] <<- list(row = row, col = col, text = text, kind = kind,
                                           series = series, width = width)
  }
  # First display row/column of each source index (for labels and selection).
  disp_range <- function(map, n_src, n_disp) {
    lapply(seq_len(n_src), function(s) {
      if (map$aggregate) as.integer(map$group[[s]]) else which(map$src == s)
    })
  }
  if (show_rows) {
    # One label per display row: the source row it shows (the first row of the
    # block when rows are aggregated).
    first_row <- if (res$rmap$aggregate) res$rmap$rep else vapply(seq_len(nr), function(s) which(res$rmap$src == s)[[1L]], 1L)
    at <- if (res$rmap$aggregate) seq_len(R) else first_row
    src <- if (res$rmap$aggregate) res$rmap$rep else seq_len(nr)
    for (k in seq_along(at)) add(pr + at[[k]] - 1L, 1L, d$row_labels[[src[[k]]]], K_TICK, width = row_w - 1L)
  }
  if (show_cols && frame$xtick_row > 0L) {
    # Candidate labels: the first display column of every source column (every
    # display column when aggregated). Thinning keeps labels one blank apart.
    if (res$cmap$aggregate) {
      starts <- seq_len(P); src <- res$cmap$rep
    } else {
      starts <- vapply(seq_len(nc), function(s) which(res$cmap$src == s)[[1L]], 1L)
      src <- seq_len(nc)
    }
    placed <- thin_labels(starts, d$col_labels[src], P)
    for (k in seq_along(placed$label)) {
      add(frame$xtick_row, pc + placed$start[[k]] - 1L, placed$label[[k]], K_TICK,
          width = P - placed$start[[k]] + 1L)
    }
  }
  if (show_bar) {
    bar_row <- pr + R + as.integer(frame$xtick_row > 0L)
    lo_t <- heat_label(lo); hi_t <- heat_label(hi)
    if (lo == hi) {
      add(bar_row, pc, paste0("all values = ", lo_t), K_LABEL, width = P)
    } else {
      n_ramp <- min(HEAT_LEVELS, P - measure_width(lo_t) - measure_width(hi_t) - 2L)
      if (n_ramp >= 3L) {
        add(bar_row, pc, lo_t, K_LABEL)
        start <- pc + measure_width(lo_t) + 1L
        shown <- unique(round(seq(1, HEAT_LEVELS, length.out = n_ramp)))
        for (k in seq_along(shown)) add(bar_row, start + k - 1L, ramp[[shown[[k]]]], K_HEAT, shown[[k]])
        add(bar_row, start + length(shown) + 1L, hi_t, K_LABEL)
      }
    }
  }
  base <- compose_static(spec, frame, glyphs, extras)

  axis_ids <- function(map, n_src) if (map$aggregate) map$rep else seq_len(n_src)
  rows_nav <- axis_ids(res$rmap, nr); cols_nav <- axis_ids(res$cmap, nc)
  cells_of <- function(sel) {
    r <- sel[["row"]]; c <- sel[["column"]]
    ri <- if (res$rmap$aggregate) res$rmap$group[[r]] else which(res$rmap$src == r)
    ci <- if (res$cmap$aggregate) res$cmap$group[[c]] else which(res$cmap$src == c)
    list(rows = ri, cols = ci)
  }
  plot <- function(selected) {
    out <- list(glyph = glyph, mark = mark)
    if (length(selected) == 2L && !anyNA(selected)) {
      where <- cells_of(selected)
      if (length(where$rows) && length(where$cols)) {
        out$mark[where$rows, where$cols] <- mark_of(K_SELECTED)
        centre_r <- where$rows[[(length(where$rows) + 1L) %/% 2L]]
        centre_c <- where$cols[[(length(where$cols) + 1L) %/% 2L]]
        out$glyph[centre_r, centre_c] <- glyphs$marker
        out$mark[centre_r, centre_c] <- mark_of(K_SELECTED_FILL)
      }
    }
    out
  }
  # The displayed block's representative source cell: the same one keyboard
  # navigation uses (the first source row/column of an aggregated block).
  hit <- function(row, col, selected) {
    p <- hit_plot_cell(frame, row, col)
    if (is.null(p)) return(NULL)
    r <- if (res$rmap$aggregate) res$rmap$rep[[p[["row"]]]] else res$rmap$src[[p[["row"]]]]
    c <- if (res$cmap$aggregate) res$cmap$rep[[p[["col"]]]] else res$cmap$src[[p[["col"]]]]
    c(row = as.integer(r), column = as.integer(c))
  }
  list(frame = frame, glyphs = glyphs, base = base, surf = NULL, plot = plot,
       ids = NULL, positions = NULL, nav = nav_grid(rows_nav, cols_nav), hit = hit,
       rows = rows_nav, cols = cols_nav, display = list(level = level, glyph = glyph))
}

normalize_matrix <- function(z) {
  if (is.data.frame(z) || !is.matrix(z) || !is.numeric(z)) {
    stop("`z` must be a numeric matrix.", call. = FALSE)
  }
  storage.mode(z) <- "double"
  finite <- is.finite(z)
  list(z = z,
       row_labels = if (!is.null(rownames(z))) clean_text(rownames(z)) else NULL,
       col_labels = if (!is.null(colnames(z))) clean_text(colnames(z)) else NULL,
       n_finite = sum(finite),
       lo = if (any(finite)) min(z[finite]) else NA_real_,
       hi = if (any(finite)) max(z[finite]) else NA_real_)
}
