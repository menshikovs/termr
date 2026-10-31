# Composition: place text and axes around the packed plot, then compact the
# cells into styled segments.
#
# Measured cost model (termr 1.0.1):
#   * Painting a widget into termr's buffer costs about 0.4 ms per styled
#     *segment* (put_text and style resolution per segment). This is the cost
#     of every repaint, including each cursor move, so the composer works on a
#     full W x H glyph matrix and a matching mark matrix and merges every
#     horizontal run of identically styled cells into one segment.
#   * termr's headless test driver additionally interprets the ANSI stream
#     one character at a time, which costs about 0.16 ms per printed cell
#     (twice that when coloured or non-ASCII). That cost exists only in
#     tests; a real terminal does not pay it.
# Blank cells beside a run whose style is invisible on blanks are absorbed
# into it (see compact_lines), trading a few more printed cells in the test
# driver for roughly ten times fewer segments in real repaints.

# Static text and axes of a frame (everything except the plot cells).
compose_static <- function(spec, frame, glyphs, extras = list()) {
  H <- frame$H; W <- frame$W
  g <- matrix(" ", H, W)
  m <- matrix(0L, H, W)
  if (H == 0L || W == 0L) return(list(glyph = g, mark = m))
  put <- function(row, col, text, kind, series = 1L, width = NULL) {
    out <- put_text(g, m, row, col, text, kind, series, width, glyphs$ellipsis)
    g <<- out$glyph; m <<- out$mark
  }
  if (frame$single) {
    put(1L, 1L, spec$title %||% fallback_label(spec), K_TITLE, 1L, W)
    return(list(glyph = g, mark = m))
  }
  if (frame$title_row > 0L) put(frame$title_row, 1L, spec$title, K_TITLE, 1L, W)
  if (frame$ylab_row > 0L) put(frame$ylab_row, 1L, paste0("y: ", spec$y_label), K_LABEL, 1L, W)
  if (frame$xlab_row > 0L) put(frame$xlab_row, 1L, paste0("x: ", spec$x_label), K_LABEL, 1L, W)
  if (frame$ok) {
    pr <- frame$plot[["row"]]; pc <- frame$plot[["col"]]
    rows <- frame$plot[["rows"]]; cols <- frame$plot[["cols"]]
    if (frame$axis_col > 0L) {
      ax <- frame$axis_col
      g[pr:(pr + rows - 1L), ax] <- glyphs$v
      m[pr:(pr + rows - 1L), ax] <- mark_of(K_AXIS)
      if (!is.null(frame$ytick)) {
        yt <- frame$ytick
        g[yt$row, ax] <- glyphs$tick_y
        for (k in seq_along(yt$row)) {
          put(yt$row[[k]], ax - measure_width(yt$label[[k]]), yt$label[[k]], K_TICK, 1L, ax - 1L)
        }
      }
    }
    if (frame$axis_row > 0L) {
      ar <- frame$axis_row
      from <- if (frame$axis_col > 0L) frame$axis_col else pc
      g[ar, from:(pc + cols - 1L)] <- glyphs$h
      m[ar, from:(pc + cols - 1L)] <- mark_of(K_AXIS)
      if (frame$axis_col > 0L) g[ar, frame$axis_col] <- glyphs$corner
      if (!is.null(frame$xtick)) g[ar, pc + frame$xtick$col - 1L] <- glyphs$tick_x
    }
    if (!is.null(frame$xtick) && frame$xtick_row > 0L) {
      xt <- frame$xtick
      for (k in seq_along(xt$label)) {
        put(frame$xtick_row, pc + xt$start[[k]] - 1L, xt$label[[k]], K_TICK, 1L, cols)
      }
    }
  }
  for (item in extras) {
    put(item$row, item$col, item$text, item$kind, item$series %||% 1L, item$width)
  }
  list(glyph = g, mark = m)
}

# Merge the packed plot into the static layer.
compose_plot <- function(base, frame, plot) {
  g <- base$glyph; m <- base$mark
  if (frame$ok && length(plot$glyph)) {
    pr <- frame$plot[["row"]]; pc <- frame$plot[["col"]]
    rr <- pr:(pr + nrow(plot$glyph) - 1L); cc <- pc:(pc + ncol(plot$glyph) - 1L)
    g[rr, cc] <- plot$glyph
    m[rr, cc] <- plot$mark
  }
  list(glyph = g, mark = m)
}

# Merge horizontal runs of identically styled cells into segments. Blank cells
# next to a run whose style is invisible on blanks are absorbed into it, so a
# sparse row of same-series dots is one segment rather than many.
#
# `rows` and `cols` (first and last column) restrict the result to part of the
# frame for a partial repaint: runs are still found over whole rows, so the
# segments inside the part are exactly those of a full repaint, and only the
# requested columns are emitted. The result has one line per requested row.
compact_lines <- function(glyph, mark, rows = NULL, cols = NULL) {
  H <- nrow(glyph); W <- ncol(glyph)
  rows <- rows %||% seq_len(H)
  cols <- cols %||% c(1L, W)
  lines <- vector("list", length(rows))
  if (!H || !W || !length(rows)) return(lines)
  keys <- matrix(style_key(mark[rows, , drop = FALSE]), length(rows), W)
  for (i in seq_along(rows)) {
    k <- keys[i, ]
    g <- glyph[rows[[i]], ]
    blank <- g == " " & k == 0L
    if (any(blank) && !all(blank)) {
      last <- cummax(ifelse(blank, 0L, seq_len(W)))
      carry <- ifelse(last > 0L, k[pmax(last, 1L)], 0L)
      absorb <- blank & last > 0L & carry != 0L & style_inert(carry)
      k[absorb] <- carry[absorb]
    }
    run <- rle(k)
    ends <- cumsum(run$lengths)
    starts <- ends - run$lengths + 1L
    keep <- which(ends >= cols[[1L]] & starts <= cols[[2L]])
    lines[[i]] <- lapply(keep, function(j) {
      seg <- segment_template(run$values[[j]])
      seg$text <- paste0(g[max(starts[[j]], cols[[1L]]):min(ends[[j]], cols[[2L]])], collapse = "")
      seg
    })
  }
  lines
}

# Plain text of composed lines (used by tests and benchmarks).
lines_text <- function(lines) {
  vapply(lines, function(line) paste0(vapply(line, function(s) s$text, character(1)), collapse = ""),
         character(1))
}
