# Display width of each string, in terminal columns. Wrapped so tests can
# simulate a locale that measures ambiguous-width glyphs as two columns.
measure_width <- function(x) {
  str_width(x)
}

chart_style <- function(...) style(...)

# Replace control characters so labels can never inject terminal sequences or
# line breaks, and make the string valid UTF-8.
clean_text <- function(x) {
  x <- enc2utf8(as.character(x))
  x <- iconv(x, from = "UTF-8", to = "UTF-8", sub = "?")
  x[is.na(x)] <- "?"
  gsub("[[:cntrl:]]", " ", x)
}

# Truncate to at most `width` display columns without splitting a wide
# character.
substr_cells <- function(x, width) {
  if (is.null(x) || !length(x) || width <= 0L) return("")
  cells <- text_cells(x)
  if (!length(cells$chars)) return("")
  keep <- cumsum(cells$widths) <= width
  paste0(cells$chars[keep], collapse = "")
}

# Place `text` into the glyph/mark matrices starting at (row, col), clipped to
# `max_width` columns. A wide character occupies its cell plus an empty cell
# so that pasting a row reproduces the correct display width. When the text is
# cut and `ellipsis` is given, the last visible cell is the ellipsis, so a
# shortened label reads as shortened (a width of one column has no room for it).
put_text <- function(glyph, mark, row, col, text, kind, series = 1L, max_width = NULL,
                     ellipsis = NULL) {
  nr <- nrow(glyph); nc <- ncol(glyph)
  if (row < 1L || row > nr || col > nc) return(list(glyph = glyph, mark = mark))
  limit <- min(nc - col + 1L, max_width %||% nc)
  cells <- text_cells(text)
  if (!is.null(ellipsis) && limit >= 2L && sum(cells$widths) > limit) {
    keep <- cumsum(cells$widths) <= limit - 1L
    cells <- list(chars = c(cells$chars[keep], ellipsis),
                  widths = c(cells$widths[keep], measure_width(ellipsis)))
  }
  pos <- col
  used <- 0L
  for (k in seq_along(cells$chars)) {
    w <- cells$widths[[k]]
    if (w == 0L) {
      if (pos > col) glyph[row, pos - 1L] <- paste0(glyph[row, pos - 1L], cells$chars[[k]])
      next
    }
    if (used + w > limit || pos < 1L) break
    glyph[row, pos] <- cells$chars[[k]]
    mark[row, pos] <- mark_of(kind, series)
    if (w == 2L) {
      glyph[row, pos + 1L] <- ""
      mark[row, pos + 1L] <- mark_of(kind, series)
    }
    pos <- pos + w
    used <- used + w
  }
  list(glyph = glyph, mark = mark)
}
