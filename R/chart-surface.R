# The logical plot surface.
#
# A surface is an integer matrix of marks with one entry per addressable dot:
# `rows * sy` by `cols * sx` for a plot of `cols x rows` terminal cells, where
# (sx, sy) is the renderer's dot grid per cell (ASCII 1x1, block 1x8,
# Braille 2x4). Row 1 is the top. Chart geometry draws into the surface in
# dot coordinates; a renderer later packs dots into glyph cells.
#
# Rasterizers return dot coordinates (i = row, j = column, both 1-based) and
# never write to the matrix themselves; `dots_idx()` clips them to the surface
# so a primitive that leaves the plot is dropped, not wrapped or errored.

surface_new <- function(cols, rows, mode) {
  res <- mode_resolution(mode)
  cols <- max(0L, as.integer(cols)); rows <- max(0L, as.integer(rows))
  list(cols = cols, rows = rows, sx = res[[1L]], sy = res[[2L]], mode = mode,
       wd = cols * res[[1L]], hd = rows * res[[2L]],
       m = matrix(0L, rows * res[[2L]], cols * res[[1L]]))
}

# Linear matrix indices of in-range dots. Indices are doubles so very large
# terminals cannot overflow the integer range.
dots_idx <- function(i, j, hd, wd) {
  keep <- !is.na(i) & !is.na(j) & i >= 1 & i <= hd & j >= 1 & j <= wd
  (as.double(j[keep]) - 1) * hd + as.double(i[keep])
}

# Dots width and height in "width units" (one terminal cell is one unit wide
# and `cell_aspect` units tall), so shapes can be made round.
dot_size <- function(surf) c(w = 1 / surf$sx, h = cell_aspect / surf$sy)

new_op <- function(idx, mark) list(idx = idx, mark = as.integer(mark))

apply_ops <- function(m, ops) {
  for (op in ops) if (length(op$idx)) m[op$idx] <- op$mark
  m
}

# Points on the straight segments (i0,j0)-(i1,j1), endpoints included.
raster_segments <- function(i0, j0, i1, j1) {
  if (!length(i0)) return(list(i = numeric(), j = numeric()))
  di <- i1 - i0
  dj <- j1 - j0
  n <- pmax(abs(di), abs(dj))
  cnt <- n + 1
  seg <- rep.int(seq_along(n), cnt)
  k <- sequence(cnt) - 1
  ns <- n[seg]
  f <- ifelse(ns == 0, 0, k / ns)
  list(i = floor(i0[seg] + di[seg] * f + 0.5), j = floor(j0[seg] + dj[seg] * f + 0.5))
}

# Connect consecutive points that share a run id; a run of one point is a dot.
raster_polyline <- function(i, j, run) {
  n <- length(i)
  if (!n) return(list(i = numeric(), j = numeric()))
  linked <- which(run[-1L] == run[-n])
  out <- raster_segments(i[linked], j[linked], i[linked + 1L], j[linked + 1L])
  alone <- setdiff(seq_len(n), c(linked, linked + 1L))
  list(i = c(out$i, i[alone]), j = c(out$j, j[alone]))
}

# All dots of the rectangle [i0:i1] x [j0:j1].
raster_rect <- function(i0, i1, j0, j1) {
  if (i1 < i0 || j1 < j0) return(list(i = numeric(), j = numeric()))
  ii <- seq.int(i0, i1)
  jj <- seq.int(j0, j1)
  list(i = rep.int(ii, length(jj)), j = rep(jj, each = length(ii)))
}

raster_rect_outline <- function(i0, i1, j0, j1) {
  if (i1 < i0 || j1 < j0) return(list(i = numeric(), j = numeric()))
  top <- raster_segments(i0, j0, i0, j1)
  bottom <- raster_segments(i1, j0, i1, j1)
  left <- raster_segments(i0, j0, i1, j0)
  right <- raster_segments(i0, j1, i1, j1)
  list(i = c(top$i, bottom$i, left$i, right$i), j = c(top$j, bottom$j, left$j, right$j))
}

# Dots whose centre lies within `radius` (width units) of the centre
# (ci, cj), given in fractional dot coordinates. The nearest dot is always
# included so very small radii still draw something.
raster_disc <- function(ci, cj, radius, size) {
  hi <- ceiling(radius / size[["h"]]) + 1
  hj <- ceiling(radius / size[["w"]]) + 1
  ii <- seq.int(floor(ci - hi), ceiling(ci + hi))
  jj <- seq.int(floor(cj - hj), ceiling(cj + hj))
  d2 <- outer((ii - ci)^2 * size[["h"]]^2, (jj - cj)^2 * size[["w"]]^2, "+")
  hit <- which(d2 <= radius^2, arr.ind = FALSE)
  out <- list(i = ii[(hit - 1) %% length(ii) + 1], j = jj[(hit - 1) %/% length(ii) + 1])
  c1 <- floor(ci + 0.5); c2 <- floor(cj + 0.5)
  list(i = c(out$i, c1), j = c(out$j, c2))
}

# Slice number (0 = outside the disc) for every dot in the disc of radius
# `radius` centred on (ci, cj). Slices start at 12 o'clock and run
# clockwise; `bounds` are the cumulative slice fractions (last value 1).
raster_wedges <- function(ci, cj, radius, size, bounds) {
  disc <- raster_disc(ci, cj, radius, size)
  dy <- (disc$i - ci) * size[["h"]]
  dx <- (disc$j - cj) * size[["w"]]
  turn <- (atan2(dx, -dy) / (2 * pi)) %% 1
  slice <- findInterval(turn, c(0, bounds[-length(bounds)]), rightmost.closed = TRUE)
  slice <- pmin(pmax(slice, 1L), length(bounds))
  list(i = disc$i, j = disc$j, slice = slice)
}

# Keep one dot per source point per surface cell, in input order.
reduce_scatter_cells <- function(px, py, width) {
  if (!length(px)) return(integer())
  width <- max(1L, as.integer(width)[1L])
  # A double key avoids integer overflow for large terminal dimensions.
  # Input order makes the selected source observation deterministic and does
  # not prefer either y extreme.
  cell <- (as.double(py) - 1) * as.double(width) + as.double(px)
  which(!duplicated(cell))
}
