# Data labels (private): value labels on bars and text labels on points.
#
# Labels are visual-only text in terminal cells. They are placed once per size
# with the plan, against the cells of the unselected plot, and merged into the
# cells for each selection exactly like the annotation labels in
# annotations.R (see `apply_refs()`), so selection-only repaint stays small and
# hit-testing, keys and events are untouched.
#
# Placement is deliberately simple and deterministic. Labels are tried in a
# fixed priority order; each one tries its preferred cells, then a short fixed
# list of alternatives, and is omitted if none is free (nothing already drawn in
# the plot, no earlier label). Nothing moves farther than that, nothing is
# optimised, and a label never leaves the plot rectangle.

# Compact text for a number: 0, 1.2, 42, 1.5k, 2.3M, 4B, and 1e12 or 1.2e-6 only
# when the magnitude needs it. Three significant digits, never cut afterwards.
format_value_label <- function(v) {
  vapply(v, function(x) {
    if (!is.finite(x)) return(NA_character_)
    if (x == 0) return("0")
    sgn <- if (x < 0) "-" else ""
    a <- signif(abs(x), 3)
    if (a < 1e-3 || a >= 1e12) {
      e <- floor(log10(a) + 1e-12)
      m <- signif(a / 10^e, 3)
      return(paste0(sgn, format(m, scientific = FALSE, trim = TRUE), "e", e))
    }
    unit <- if (a >= 1e9) c(1e9, "B") else if (a >= 1e6) c(1e6, "M") else if (a >= 1e3) c(1e3, "k") else NULL
    if (!is.null(unit)) {
      return(paste0(sgn, format(signif(a / as.numeric(unit[[1L]]), 3), scientific = FALSE, trim = TRUE), unit[[2L]]))
    }
    paste0(sgn, format(a, scientific = FALSE, digits = 3, trim = TRUE))
  }, "", USE.NAMES = FALSE)
}

# Cells (plot-local row/col) occupied by anything the plot draws without a
# selection, as a logical R x P matrix.
label_occupancy <- function(plot0, R, P) {
  if (is.null(plot0) || !length(plot0$mark)) return(matrix(FALSE, R, P))
  matrix(plot0$mark != 0L | plot0$glyph != " ", R, P)
}

# A label unit for text placed at (row, col) of the plot, or NULL.
label_unit <- function(text, row, col, width, R, P, ellipsis, allow = character(), marker = NULL) {
  cells <- label_cells(text, row, col, width, R, P, ellipsis)
  if (is.null(cells)) return(NULL)
  list(idx = cells$idx, glyph = cells$glyph, mark = mark_of(K_LABEL), allow = allow, marker = marker)
}

# Value labels of bars. Every argument is aligned by item, in priority order
# (category order, then series order):
#   text      the formatted value, NA for no label
#   cs, ce    cells of the bar's band along the category axis (columns for
#             vertical bars, rows for horizontal ones)
#   vr0, vr1  cells of the drawn rectangle along the value axis (rows or
#             columns, first <= last), NA when nothing is drawn
#   base      cell of the zero baseline along the value axis
#   sign      sign of the value (-1, 0, 1)
# `stacked` bars label only inside their own segment; other bars label just past
# the bar's end (above or right for positive values, below or left for negative),
# else inside at the end, else not at all.
bar_label_units <- function(text, cs, ce, vr0, vr1, base, sign, horiz, stacked, plot0, R, P, glyphs) {
  if (R < 2L || P < 4L || !length(text)) return(list())
  occ <- label_occupancy(plot0, R, P)
  taken <- matrix(FALSE, R, P)
  ell <- glyphs$ellipsis
  allow <- c("fill", "selected", "marker")
  units <- list()
  inside_ok <- function(rows, cols, own) {
    all(!occ[cbind(rows, cols)] | own[cbind(rows, cols)]) && !any(taken[cbind(rows, cols)])
  }
  for (q in seq_along(text)) {
    tx <- text[[q]]
    if (is.na(tx) || (stacked && sign[[q]] == 0)) next
    w <- measure_width(tx)
    drawn <- !is.na(vr0[[q]])
    if (stacked && !drawn) next
    mid <- (cs[[q]] + ce[[q]]) %/% 2L
    band <- ce[[q]] - cs[[q]] + 1L
    own <- matrix(FALSE, R, P)
    if (drawn) {
      if (horiz) own[cs[[q]]:ce[[q]], vr0[[q]]:vr1[[q]]] <- TRUE else own[vr0[[q]]:vr1[[q]], cs[[q]]:ce[[q]]] <- TRUE
    }
    cands <- list()
    add <- function(row, col, is_inside) cands[[length(cands) + 1L]] <<- list(row = row, col = col, inside = is_inside)
    if (!horiz) {
      col_mid <- mid - (w - 1L) %/% 2L
      if (stacked) {
        if (band >= w) add((vr0[[q]] + vr1[[q]]) %/% 2L, cs[[q]] + (band - w) %/% 2L, TRUE)
      } else if (sign[[q]] >= 0) {
        top <- if (drawn) vr0[[q]] else base[[q]]
        add(top - 1L, col_mid, FALSE)
        if (drawn && band >= w) add(vr0[[q]], cs[[q]] + (band - w) %/% 2L, TRUE)
      } else {
        add(vr1[[q]] + 1L, col_mid, FALSE)
        if (drawn && band >= w) add(vr1[[q]], cs[[q]] + (band - w) %/% 2L, TRUE)
      }
    } else {
      row <- mid
      if (stacked) {
        len <- vr1[[q]] - vr0[[q]] + 1L
        if (len >= w) add(row, vr0[[q]] + (len - w) %/% 2L, TRUE)
      } else if (sign[[q]] >= 0) {
        end <- if (drawn) vr1[[q]] else base[[q]]
        add(row, end + 1L, FALSE)
        if (drawn && vr1[[q]] - vr0[[q]] + 1L >= w) add(row, vr1[[q]] - w + 1L, TRUE)
      } else {
        add(row, vr0[[q]] - w, FALSE)
        if (drawn && vr1[[q]] - vr0[[q]] + 1L >= w) add(row, vr0[[q]], TRUE)
      }
    }
    for (cd in cands) {
      cols <- cd$col + seq_len(w) - 1L
      if (cd$row < 1L || cd$row > R || cd$col < 1L || max(cols) > P) next
      rows <- rep(cd$row, w)
      if (!inside_ok(rows, cols, if (cd$inside) own else matrix(FALSE, R, P))) next
      unit <- label_unit(tx, cd$row, cd$col, w, R, P, ell, allow, glyphs$marker)
      if (is.null(unit)) next
      taken[cbind(rows, cols)] <- TRUE
      units[[length(units) + 1L]] <- unit
      break
    }
  }
  units
}

# Text labels of retained points. Placement tries right, left, above and below
# the point in free cells; labels are clipped to 16 cells and omitted when none
# of those positions fits.
point_label_units <- function(text, row, col, plot0, R, P, glyphs, occupied = NULL) {
  if (R < 2L || P < 4L || !length(text) || all(is.na(text))) return(list())
  occ <- label_occupancy(plot0, R, P)
  if (!is.null(occupied)) occ[occupied] <- TRUE
  taken <- matrix(FALSE, R, P)
  ell <- glyphs$ellipsis
  units <- list()
  for (q in which(!is.na(text))) {
    tx <- text[[q]]
    w <- min(measure_width(tx), 16L, P)
    cands <- list(list(row[[q]], col[[q]] + 1L), list(row[[q]], col[[q]] - w),
                  list(row[[q]] - 1L, col[[q]] - (w - 1L) %/% 2L),
                  list(row[[q]] + 1L, col[[q]] - (w - 1L) %/% 2L))
    for (cd in cands) {
      rr <- cd[[1L]]; cc <- cd[[2L]]
      if (rr < 1L || rr > R || cc < 1L || cc + w - 1L > P) next
      cells <- cbind(rr, cc + seq_len(w) - 1L)
      free <- !occ[cells] & !taken[cells]
      if (!all(free)) next
      unit <- label_unit(tx, rr, cc, w, R, P, ell)
      if (is.null(unit)) next
      taken[cells] <- TRUE
      units[[length(units) + 1L]] <- unit
      break
    }
  }
  units
}

# Validate `point_labels` against the number of observations and align it
# with the retained (finite) ones.
validate_point_labels <- function(labels, n) {
  if (is.null(labels)) return(NULL)
  if (!is.character(labels) && !(is.logical(labels) && all(is.na(labels)))) {
    stop("`point_labels` must be a character vector with one label per observation.", call. = FALSE)
  }
  if (length(labels) != n) {
    stop(sprintf("`point_labels` must have one label per observation (%d), not %d.", n, length(labels)), call. = FALSE)
  }
  # Cheap, vectorised checks only: the text is cleaned when (and if) a label is
  # placed, so a label for every one of a million source points costs nothing
  # per point beyond this.
  labels <- as.character(labels)
  labels[!is.na(labels) & !nzchar(labels)] <- NA_character_
  labels
}

# Add label units to a plan's annotation cells (creating them if there are none).
with_label_units <- function(refs, units) {
  if (!length(units)) return(refs)
  if (is.null(refs)) {
    refs <- list(idx = integer(), glyph = character(), mark = mark_of(K_REF), rows = integer(),
                 cols = integer(), band = NULL, labels = list())
  }
  refs$labels <- c(refs$labels, units)
  refs
}

# Annotation cells of a bar plan: the value-axis reference lines (hline for
# vertical bars, vline for horizontal ones) with their labels, then the value
# labels. The value-label cells are known first and count as occupied, so a
# reference label yields to a data label and data labels never move for it.
bar_refs <- function(spec, vdom, horiz, surf, glyphs, mode, plan, units) {
  refs <- spec$refs
  out <- NULL
  if (!is.null(refs)) {
    plot0 <- NULL
    if (any(!is.na(c(refs$hlabel, refs$vlabel)))) {
      plot0 <- plan$plot(NA_integer_)
      for (u in units) {
        plot0$glyph[u$idx] <- "?"
        plot0$mark[u$idx] <- mark_of(K_LABEL)
      }
    }
    out <- ref_cells(refs, scale_linear, scale_linear, if (horiz) vdom else c(0, 1), if (horiz) c(0, 1) else vdom,
                     surf, glyphs, mode, plot0)
  }
  if (!is.null(out)) out$behind_fill <- TRUE
  with_label_units(out, units)
}
