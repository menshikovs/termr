# Renderers: pack a dot surface into terminal glyph cells.
#
# Each packer turns a surface matrix `m` into two cols x rows matrices: the
# glyph for every cell and the mark that decides its style (the strongest
# mark among the cell's dots). Axis text and labels are not packed here.

ascii_fill <- c("#", "%", "=", "+", ":", "o", "x", "*", "-", "~")
ascii_point <- c("*", "o", "+", "x", "#", "@")
ascii_stroke <- "."

# ---- ASCII (one dot per cell) ------------------------------------------------

pack_ascii <- function(m) {
  rows <- nrow(m); cols <- ncol(m)
  glyph <- matrix(" ", rows, cols)
  if (!rows || !cols) return(list(glyph = glyph, mark = m))
  kind <- mark_kind(m)
  s <- mark_series(m)
  glyph[kind == K_GUIDE] <- "-"
  hit <- kind == K_FILL
  glyph[hit] <- ascii_fill[(s[hit] - 1L) %% length(ascii_fill) + 1L]
  glyph[kind == K_STROKE] <- ascii_stroke
  hit <- kind == K_POINT
  glyph[hit] <- ascii_point[(s[hit] - 1L) %% length(ascii_point) + 1L]
  glyph[kind == K_SELECTED | kind == K_SELECTED_FILL] <- "X"
  # Line-art for outlines: a frame cell looks at its orthogonal neighbours.
  frame <- kind == K_FRAME
  if (any(frame)) {
    up <- rbind(FALSE, frame[-rows, , drop = FALSE])
    down <- rbind(frame[-1L, , drop = FALSE], FALSE)
    left <- cbind(FALSE, frame[, -cols, drop = FALSE])
    right <- cbind(frame[, -1L, drop = FALSE], FALSE)
    vert <- up | down
    horz <- left | right
    glyph[frame & vert & horz] <- "+"
    glyph[frame & vert & !horz] <- "|"
    glyph[frame & horz & !vert] <- "-"
    glyph[frame & !vert & !horz] <- "+"
  }
  list(glyph = glyph, mark = m)
}

# ---- Braille (2 x 4 dots per cell) -------------------------------------------

# Bit mask of a cell from a 4 x 2 logical occupancy matrix (row dy, column dx).
braille_mask <- function(occupied) {
  sum(braille_bits[occupied])
}

pack_braille <- function(m) {
  hd <- nrow(m); wd <- ncol(m)
  rows <- hd %/% 4L; cols <- wd %/% 2L
  glyph <- matrix(" ", rows, cols)
  mark <- matrix(0L, rows, cols)
  if (!rows || !cols) return(list(glyph = glyph, mark = mark))
  a <- array(m, c(4L, rows, 2L, cols))
  mask <- matrix(0L, rows, cols)
  for (dx in 1:2) for (dy in 1:4) {
    slice <- matrix(a[dy, , dx, ], rows, cols)
    mask <- mask + (slice > 0L) * braille_bits[dy, dx]
    mark <- pmax(mark, slice)
  }
  glyph[] <- braille_lut()[mask + 1L]
  list(glyph = glyph, mark = mark)
}

# ---- Block (1 x 8 dots per cell) ---------------------------------------------

# For each of the 256 occupancy patterns of an eight-dot column (bit i set =
# dot i from the top is filled) pick a glyph and whether it is drawn reversed.
#  * a filled run touching the bottom is a lower-eighth block;
#  * a run touching the top is the complement block in reverse video;
#  * anything else is approximated by the upper/lower/full half blocks.
block_table <- function() {
  glyph <- character(256L)
  inverse <- logical(256L)
  for (code in 0:255) {
    bits <- bitwAnd(code, as.integer(2^(0:7))) > 0
    k <- sum(bits)
    if (k == 0L) {
      glyph[[code + 1L]] <- " "
    } else if (all(bits[(9L - k):8L])) {
      glyph[[code + 1L]] <- block_lower[[k]]
    } else if (all(bits[seq_len(k)])) {
      if (k == 4L) {
        glyph[[code + 1L]] <- block_half[["upper"]]
      } else {
        glyph[[code + 1L]] <- block_lower[[8L - k]]
        inverse[[code + 1L]] <- TRUE
      }
    } else {
      top <- any(bits[1:4]); bottom <- any(bits[5:8])
      glyph[[code + 1L]] <- if (top && bottom) block_half[["full"]]
        else if (top) block_half[["upper"]] else block_half[["lower"]]
    }
  }
  list(glyph = glyph, inverse = inverse)
}

block_lookup <- local({
  cache <- NULL
  function() {
    if (is.null(cache)) cache <<- block_table()
    cache
  }
})

pack_block <- function(m) {
  hd <- nrow(m); cols <- ncol(m)
  rows <- hd %/% 8L
  glyph <- matrix(" ", rows, cols)
  mark <- matrix(0L, rows, cols)
  if (!rows || !cols) return(list(glyph = glyph, mark = mark))
  a <- array(m, c(8L, rows, cols))
  code <- matrix(0L, rows, cols)
  for (dy in 1:8) {
    slice <- matrix(a[dy, , ], rows, cols)
    code <- code + (slice > 0L) * 2L^(dy - 1L)
    mark <- pmax(mark, slice)
  }
  table <- block_lookup()
  glyph[] <- table$glyph[code + 1L]
  inverse <- matrix(table$inverse[code + 1L], rows, cols)
  mark[inverse] <- mark[inverse] + INVERSE
  # A solid cell of a later series uses a shade so series differ without colour.
  full <- code == 255L & mark_kind(mark) == K_FILL & mark_series(mark) >= 2L
  if (any(full)) {
    glyph[full] <- block_shade[(mark_series(mark[full]) - 1L) %% length(block_shade) + 1L]
  }
  # A selected dot is shown as a solid, recoloured cell. (Reverse video of a
  # half or complement block would paint the wrong part of the cell.)
  sel <- mark_kind(mark) == K_SELECTED
  if (any(sel)) {
    glyph[sel] <- block_half[["full"]]
    mark[sel] <- mark_of(K_SELECTED_FILL)
  }
  list(glyph = glyph, mark = mark)
}

pack_surface <- function(surf) {
  switch(surf$mode,
         braille = pack_braille(surf$m),
         block = pack_block(surf$m),
         pack_ascii(surf$m))
}
