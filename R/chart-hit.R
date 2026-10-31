# Hit-testing: from a terminal cell to the logical item drawn there.
#
# Every plan may carry `hit(row, col, selected)`, where `row` and `col` are
# 1-based cells of the chart's content area (the same coordinates the plan is
# drawn in) and `selected` is the current selection. It returns the id of the
# item under that cell, in exactly the form keyboard navigation produces, or
# NULL when nothing is there. Hit-testing works on the geometry the plan
# already holds (retained points, bar slots, display blocks, wedge dots), so
# its cost depends on what is drawn, not on the size of the source data. The
# mouse only ever reports whole cells, so Braille charts are tested at cell
# resolution as well.

# Largest distance, in cell widths (a cell is `cell_aspect` widths tall), at
# which a click still selects a scatter point.
hit_radius <- 2

# Plot-local c(row, col) of a content cell, or NULL when it is outside the
# plot rectangle (axes, labels, legend and margins are not data).
hit_plot_cell <- function(frame, row, col) {
  if (!isTRUE(frame$ok)) return(NULL)
  r <- row - frame$plot[["row"]] + 1L
  c <- col - frame$plot[["col"]] + 1L
  if (r < 1L || c < 1L || r > frame$plot[["rows"]] || c > frame$plot[["cols"]]) return(NULL)
  c(row = as.integer(r), col = as.integer(c))
}

# Squared visual distance between a click at the centre of plot cell `p` and
# points given in cell units; rows count `cell_aspect` columns each.
hit_distance2 <- function(p, kx, ky) {
  (kx - (p[["col"]] - 0.5))^2 + (cell_aspect * (ky - (p[["row"]] - 0.5)))^2
}

# Index of the slot (cells c0..c1 inclusive) holding plot column `col`.
hit_slot <- function(c0, c1, col) {
  k <- which(c0 <= col & col <= c1)
  if (length(k)) k[[1L]] else NULL
}

# Dots (row, column) of plot cell `p`, nearest the cell centre first.
hit_cell_dots <- function(p, sx, sy) {
  i <- (p[["row"]] - 1L) * sy + rep(seq_len(sy), times = sx)
  j <- (p[["col"]] - 1L) * sx + rep(seq_len(sx), each = sy)
  o <- order((i - ((p[["row"]] - 1L) * sy + (sy + 1) / 2))^2 * cell_aspect^2 / sy^2 +
               (j - ((p[["col"]] - 1L) * sx + (sx + 1) / 2))^2 / sx^2, i, j)
  list(i = i[o], j = j[o])
}

# Squared visual distance from points (px, py) to the segments (ax, ay)-(bx, by),
# all in cell units with rows scaled by `cell_aspect`.
hit_segment_distance2 <- function(px, py, ax, ay, bx, by) {
  ay <- ay * cell_aspect; by <- by * cell_aspect; py <- py * cell_aspect
  dx <- bx - ax; dy <- by - ay
  len2 <- dx^2 + dy^2
  t <- ifelse(len2 > 0, ((px - ax) * dx + (py - ay) * dy) / len2, 0)
  t <- pmin(1, pmax(0, t))
  (px - (ax + t * dx))^2 + (py - (ay + t * dy))^2
}
