# Reference annotations (private): lines, bands and line labels, all in data
# space. `hline` and `vline` are values of y and x; `x_band` and `y_band` are a
# lower and an upper value; `hline_label` and `vline_label` name the lines.
# They go through the same axis scales as the data (`scale_forward()`), so a log
# axis takes original values and a Date or POSIXct x takes a Date or POSIXct.
#
# Annotations are guides, not data geometry, and are drawn as terminal cells in
# every renderer. Order, from the back: bands, reference lines, data, selection,
# with labels written last into cells that are still free:
#   * a band is a sparse pattern (a checkerboard of one light glyph) that fills
#     only empty cells, so data, fills and the selection hide it;
#   * a line is a line glyph that shows in empty, banded, filled or zero-rule
#     cells, never over curves, points, frames or the selection;
#   * a label is text on or beside its line; it is placed once per size into free
#     cells (one nearby alternative row or column, else omitted) and is skipped
#     whole at any moment a selection covers one of its cells. The plot is never
#     shrunk to make room for a label.
# Everything is computed once per size with the plan and merged into the cells
# for each selection, which costs a pass over the annotation cells. A value
# outside the domain is not drawn, a band that is partly outside is clipped, and
# nothing enlarges the domain. Annotations are not selectable and take no part
# in hit-testing.

# Validate the annotation arguments against the axis scales of the chart data.
# Returns list(hline, vline, hlabel, vlabel, x_band, y_band) in source space
# (days or seconds for Date/POSIXct), lines sorted and unique with their labels
# following them, or NULL when there is nothing to draw.
normalize_refs <- function(data, hline = NULL, vline = NULL, allow_h = TRUE, allow_v = TRUE,
                           hline_label = NULL, vline_label = NULL, x_band = NULL, y_band = NULL,
                           allow_y_band = TRUE, arg_names = NULL) {
  nm <- list(hline = "hline", vline = "vline", hline_label = "hline_label", vline_label = "vline_label")
  nm[names(arg_names)] <- arg_names
  if (!allow_h && !is.null(hline)) stop("This chart does not take `hline`.", call. = FALSE)
  if (!allow_v && !is.null(vline)) stop("This chart does not take `vline`.", call. = FALSE)
  if (!allow_y_band && !is.null(y_band)) stop("This chart does not take `y_band`.", call. = FALSE)
  h <- ref_lines(hline, hline_label, nm$hline, nm$hline_label, data$yscale)
  v <- ref_lines(vline, vline_label, nm$vline, nm$vline_label, data$xscale)
  xb <- ref_band(x_band, "x_band", data$xscale)
  yb <- ref_band(y_band, "y_band", data$yscale)
  if (!length(h$value) && !length(v$value) && is.null(xb) && is.null(yb)) return(NULL)
  list(hline = h$value, vline = v$value, hlabel = h$label, vlabel = v$label, x_band = xb, y_band = yb)
}

# Validated numbers of annotation values (source space), in input order.
ref_numbers <- function(value, name, scale) {
  if (is.null(value)) return(numeric())
  if (is.logical(value) && all(is.na(value))) value <- as.double(value)
  type <- if (is.null(scale)) "linear" else scale$type
  if (inherits(value, "POSIXlt")) value <- as.POSIXct(value)
  if (identical(type, "date")) {
    if (!inherits(value, "Date")) stop(sprintf("`%s` must be a Date, like the x axis.", name), call. = FALSE)
  } else if (identical(type, "datetime")) {
    if (!inherits(value, "POSIXct")) stop(sprintf("`%s` must be a POSIXct, like the x axis.", name), call. = FALSE)
  } else if (is.object(value) || !is.numeric(value)) {
    stop(sprintf("`%s` must be a plain numeric vector.", name), call. = FALSE)
  }
  num <- as.double(unclass(value))
  if (!all(is.finite(num))) stop(sprintf("`%s` must be finite (no NA or Inf).", name), call. = FALSE)
  if (identical(type, "log10") && any(num <= 0)) {
    stop(sprintf("`%s` must be positive on a log10 axis; %d value%s %s not (the smallest is %s).",
                 name, sum(num <= 0), if (sum(num <= 0) == 1L) "" else "s",
                 if (sum(num <= 0) == 1L) "is" else "are", format(min(num))), call. = FALSE)
  }
  num
}

# Lines sorted by value, duplicates removed. A label follows its value; for equal
# values the first label given (in input order) that is not NA is kept.
ref_lines <- function(value, label, name, label_name, scale) {
  num <- ref_numbers(value, name, scale)
  if (!is.null(label)) {
    if (!is.character(label) && !all(is.na(label))) {
      stop(sprintf("`%s` must be a character vector.", label_name), call. = FALSE)
    }
    label <- as.character(label)
    if (!length(num)) stop(sprintf("`%s` needs `%s`.", label_name, name), call. = FALSE)
    if (length(label) != length(num)) {
      stop(sprintf("`%s` must have one label per `%s` value (%d), not %d.", label_name, name,
                   length(num), length(label)), call. = FALSE)
    }
    label[!is.na(label)] <- clean_text(label[!is.na(label)])
    label[!is.na(label) & !nzchar(label)] <- NA_character_
  }
  if (!length(num)) return(list(value = numeric(), label = character()))
  # Stable order: by value, then by position in the input.
  o <- order(num, seq_along(num))
  num <- num[o]
  lab <- if (is.null(label)) rep(NA_character_, length(num)) else label[o]
  keep <- !duplicated(num)
  first_label <- vapply(split(lab, match(num, num[keep])), function(l) {
    l <- l[!is.na(l)]
    if (length(l)) l[[1L]] else NA_character_
  }, "")
  list(value = num[keep], label = unname(first_label[as.character(seq_len(sum(keep)))]))
}

# A band: two values, sorted so a reversed pair means the same band.
ref_band <- function(value, name, scale) {
  if (is.null(value)) return(NULL)
  if (length(value) != 2L) stop(sprintf("`%s` must be two values, a lower and an upper end.", name), call. = FALSE)
  sort(ref_numbers(value, name, scale))
}

# The glyph of a band pattern, by renderer.
band_glyph <- function(mode) {
  switch(mode, braille = braille_cell(2L), block = block_shade[[4L]], ".")
}

# Cell pieces of the annotations of a chart.
#   refs$idx, glyph, mark   the line cells (linear indices into the plot's rows x
#                           cols cell matrices), refs$rows / refs$cols the cell
#                           rows and columns the lines occupy
#   refs$band               list(idx, glyph, mark) of the band pattern cells
#   refs$labels             a list of units, each list(idx, glyph, mark)
# or NULL when nothing is drawn. `xdom`/`ydom` are the transformed domains the
# data were mapped on and `surf` is the dot surface. `plot0` are the packed plot
# cells without a selection (needed to place labels in free cells).
ref_cells <- function(refs, xs, ys, xdom, ydom, surf, glyphs, mode = "ascii", plot0 = NULL) {
  if (is.null(refs)) return(NULL)
  R <- surf$rows; P <- surf$cols
  if (R < 1L || P < 1L) return(NULL)
  inside <- function(t, dom) {
    slack <- 1e-9 * max(1, abs(dom))
    is.finite(t) & t >= dom[[1L]] - slack & t <= dom[[2L]] + slack
  }
  idx_h <- integer(); idx_v <- integer(); rows <- integer(); cols <- integer()
  h_at <- rep(NA_integer_, length(refs$hline)); v_at <- rep(NA_integer_, length(refs$vline))
  if (length(refs$hline)) {
    t <- scale_forward(ys, refs$hline)
    ok <- inside(t, ydom)
    if (any(ok)) {
      i <- dot_row_from_unit(unit_values(t[ok], ydom[[1L]], ydom[[2L]]), surf$hd)
      h_at[ok] <- (i - 1L) %/% surf$sy + 1L
      rows <- sort(unique(h_at[ok]))
      idx_h <- as.integer(rep(rows, each = P) + (rep(seq_len(P), times = length(rows)) - 1L) * R)
    }
  }
  if (length(refs$vline)) {
    t <- scale_forward(xs, refs$vline)
    ok <- inside(t, xdom)
    if (any(ok)) {
      j <- dot_from_unit(unit_values(t[ok], xdom[[1L]], xdom[[2L]]), surf$wd)
      v_at[ok] <- (j - 1L) %/% surf$sx + 1L
      cols <- sort(unique(v_at[ok]))
      idx_v <- as.integer(rep(seq_len(R), times = length(cols)) + (rep(cols, each = R) - 1L) * R)
    }
  }
  idx <- unique(c(idx_h, idx_v))
  glyph <- character()
  if (length(idx)) {
    both <- idx %in% idx_h & idx %in% idx_v
    glyph <- ifelse(both, glyphs$cross, ifelse(idx %in% idx_h, glyphs$h, glyphs$v))
  }

  # Bands, clipped to the domain: a checkerboard of cells.
  band_rows <- integer(); band_cols <- integer()
  clip <- function(b, scale, dom) {
    if (is.null(b)) return(NULL)
    t <- scale_forward(scale, b)
    lo <- max(t[[1L]], dom[[1L]]); hi <- min(t[[2L]], dom[[2L]])
    if (lo > hi) NULL else c(lo, hi)
  }
  xb <- clip(refs$x_band, xs, xdom)
  yb <- clip(refs$y_band, ys, ydom)
  if (!is.null(xb)) {
    j <- dot_from_unit(unit_values(xb, xdom[[1L]], xdom[[2L]]), surf$wd)
    band_cols <- seq.int((j[[1L]] - 1L) %/% surf$sx + 1L, (j[[2L]] - 1L) %/% surf$sx + 1L)
  }
  if (!is.null(yb)) {
    i <- dot_row_from_unit(unit_values(yb, ydom[[1L]], ydom[[2L]]), surf$hd)      # i[[2]] is the top
    band_rows <- seq.int((i[[2L]] - 1L) %/% surf$sy + 1L, (i[[1L]] - 1L) %/% surf$sy + 1L)
  }
  band <- NULL
  if (length(band_cols) || length(band_rows)) {
    inband <- matrix(FALSE, R, P)
    if (length(band_cols)) inband[, band_cols] <- TRUE
    if (length(band_rows)) inband[band_rows, ] <- TRUE
    check <- outer(seq_len(R), seq_len(P), "+") %% 2L == 0L
    bidx <- which(inband & check)
    if (length(bidx)) {
      band <- list(idx = bidx, glyph = band_glyph(mode), mark = mark_of(K_REF, 2L),
                   rows = if (length(band_rows)) band_rows else seq_len(R),
                   cols = if (length(band_cols)) band_cols else seq_len(P))
    }
  }

  labels <- ref_label_units(refs, h_at, v_at, idx_h, idx_v, rows, cols, R, P, plot0, glyphs)
  if (!length(idx) && is.null(band) && !length(labels)) return(NULL)
  list(idx = idx, glyph = glyph, mark = mark_of(K_REF), rows = rows, cols = cols,
       band = band, labels = labels)
}

# Text of one label as cells in an R x P matrix: list(idx, glyph) or NULL.
label_cells <- function(text, row, col, width, R, P, ellipsis) {
  g <- matrix(" ", R, P); m <- matrix(0L, R, P)
  out <- put_text(g, m, row, col, text, K_LABEL, 1L, width, ellipsis)
  at <- which(out$mark != 0L)
  if (!length(at)) return(NULL)
  list(idx = at, glyph = out$glyph[at])
}

# Place the labels of the lines that are drawn. Lines are taken in value order,
# horizontal first. A label is tried at its preferred spot and then one
# alternative; it needs free cells (nothing of the chart's data and nothing
# already used) and is omitted otherwise. Needs a plot of at least 12 x 4 cells.
ref_label_units <- function(refs, h_at, v_at, idx_h, idx_v, hrows, vcols, R, P, plot0, glyphs) {
  have <- c(refs$hlabel, refs$vlabel)
  if (is.null(plot0) || !length(have) || all(is.na(have)) || P < 12L || R < 4L) return(list())
  kind0 <- mark_kind(plot0$mark)
  free0 <- (kind0 == 0L & plot0$glyph == " ") | kind0 == K_GUIDE
  ell <- glyphs$ellipsis
  taken <- logical(R * P)
  units <- list()
  usable <- function(cells, allowed_rows = integer()) {
    if (is.null(cells)) return(FALSE)
    rr <- (cells$idx - 1L) %% R + 1L; cc <- (cells$idx - 1L) %/% R + 1L
    if (any(cc %in% vcols)) return(FALSE)
    if (any(rr %in% hrows & !(rr %in% allowed_rows))) return(FALSE)
    all(free0[cells$idx]) && !any(taken[cells$idx])
  }
  take <- function(cells) {
    taken[cells$idx] <<- TRUE
    units[[length(units) + 1L]] <<- list(idx = cells$idx, glyph = cells$glyph, mark = mark_of(K_LABEL))
  }
  for (k in seq_along(refs$hline)) {
    text <- refs$hlabel[[k]]; r <- h_at[[k]]
    if (is.na(text) || is.na(r)) next
    w <- min(measure_width(text), P)
    for (row in c(r - 1L, r + 1L, r)) {
      if (row < 1L || row > R) next
      cells <- label_cells(text, row, P - w + 1L, w, R, P, ell)
      if (usable(cells, allowed_rows = r)) { take(cells); break }
    }
  }
  for (k in seq_along(refs$vline)) {
    text <- refs$vlabel[[k]]; c0 <- v_at[[k]]
    if (is.na(text) || is.na(c0)) next
    w <- measure_width(text)
    tries <- list()
    for (full in c(TRUE, FALSE)) for (row in 1:2) for (side in c("right", "left")) {
      avail <- if (side == "right") P - c0 else c0 - 1L
      if (avail < 3L || (full && w > avail)) next
      wl <- min(w, avail)
      col <- if (side == "right") c0 + 1L else c0 - wl
      tries[[length(tries) + 1L]] <- list(row = row, col = col, width = wl)
    }
    for (t in tries) {
      cells <- label_cells(text, t$row, t$col, t$width, R, P, ell)
      if (usable(cells)) { take(cells); break }
    }
  }
  units
}

# Merge annotations into packed plot cells, from the back: bands into empty
# cells, lines into empty / banded / filled / guide cells, then each label whole
# into cells still free of data and selection.
apply_refs <- function(plot, refs) {
  if (is.null(refs) || is.null(plot) || !length(plot$glyph)) return(plot)
  band <- refs$band
  if (!is.null(band)) {
    empty <- plot$glyph[band$idx] == " " & mark_kind(plot$mark[band$idx]) == 0L
    plot$glyph[band$idx[empty]] <- band$glyph
    plot$mark[band$idx[empty]] <- band$mark
  }
  idx <- refs$idx
  if (length(idx)) {
    kind <- mark_kind(plot$mark[idx])
    # Bars put their reference lines behind the fill; other charts show them over it.
    over <- if (isTRUE(refs$behind_fill)) c(0L, K_GUIDE, K_REF) else c(0L, K_GUIDE, K_FILL, K_REF)
    open <- plot$glyph[idx] == " " | kind %in% over
    open <- open & !(kind %in% c(K_STROKE, K_FRAME, K_POINT, K_SELECTED, K_SELECTED_FILL))
    plot$glyph[idx[open]] <- refs$glyph[open]
    plot$mark[idx[open]] <- refs$mark
  }
  for (u in refs$labels) {
    kind <- mark_kind(plot$mark[u$idx])
    ok <- kind %in% c(0L, K_GUIDE, K_REF)
    # Data labels may also sit on a bar's fill, on a selected fill and
    # on the selection marker, so a value stays readable while its bar is selected.
    if ("fill" %in% u$allow) ok <- ok | kind == K_FILL
    if ("selected" %in% u$allow) ok <- ok | kind == K_SELECTED_FILL
    if ("marker" %in% u$allow && !is.null(u$marker)) ok <- ok | (kind == K_SELECTED_FILL & plot$glyph[u$idx] == u$marker)
    if (all(ok)) {
      plot$glyph[u$idx] <- u$glyph
      plot$mark[u$idx] <- u$mark
    }
  }
  plot
}
