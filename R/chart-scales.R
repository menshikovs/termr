# Domains, unit mapping and ticks. Pure functions; no termr calls.

# Map values to [0, 1] over [lo, hi]. Values are divided by the largest
# magnitude first so domains near +/-DBL_MAX do not overflow; a constant
# domain maps to the middle.
unit_values <- function(x, lo, hi) {
  scale <- max(abs(c(lo, hi)))
  if (!is.finite(scale) || scale == 0) return(rep(0.5, length(x)))
  a <- lo / scale
  b <- hi / scale
  if (a == b) return(rep(0.5, length(x)))
  pmax(0, pmin(1, (x / scale - a) / (b - a)))
}

normalize_domain <- function(x) {
  if (!length(x)) return(numeric())
  unit_values(x, min(x), max(x))
}

normalize_scalar <- function(x, lo, hi) unit_values(x, lo, hi)[[1L]]

# Unit coordinate -> 1-based dot index (1 = first dot) on an axis of `n` dots.
# `floor(z + 0.5)` rather than round(): R rounds halves to even.
dot_from_unit <- function(u, n) {
  if (n <= 1L) return(rep(1L, length(u)))
  as.integer(floor(u * (n - 1L) + 0.5)) + 1L
}

# y grows upward in data space but downward in the dot matrix.
dot_row_from_unit <- function(u, n) n + 1L - dot_from_unit(u, n)

# Round-number tick positions inside [lo, hi].
tick_values <- function(lo, hi, max_n) {
  if (!is.finite(lo) || !is.finite(hi) || max_n < 1L) return(numeric())
  if (lo == hi) return(lo)
  ticks <- tryCatch(pretty(c(lo, hi), n = max_n), error = function(e) numeric())
  ticks <- ticks[is.finite(ticks)]
  slack <- 1e-9 * max(abs(c(lo, hi)))
  ticks[ticks >= lo - slack & ticks <= hi + slack]
}

# Format ticks with a common format no wider than `max_width` columns, using
# scientific notation when fixed notation does not fit.
format_tick_labels <- function(ticks, max_width = 8L) {
  if (!length(ticks)) return(character())
  fmt <- function(digits, sci) {
    format(ticks, digits = digits, trim = TRUE, scientific = sci,
           decimal.mark = ".", big.mark = "")
  }
  for (sci in c(FALSE, TRUE)) for (digits in 3:1) {
    labels <- fmt(digits, sci)
    if (all(measure_width(labels) <= max_width)) return(labels)
  }
  fmt(1L, TRUE)
}

# Cell positions (1-based, within `n` cells) for tick values on [lo, hi] when
# each cell holds `res` dots; `flip` counts from the top (y axes).
tick_cells <- function(ticks, lo, hi, cells, res, flip) {
  n <- cells * res
  d <- dot_from_unit(unit_values(ticks, lo, hi), n)
  if (flip) d <- n + 1L - d
  (d - 1L) %/% res + 1L
}

# Round-trip helper for hover/selection: cell -> approximate data value.
value_from_cell <- function(cell, lo, hi, cells, flip) {
  frac <- if (cells <= 1L) 0.5 else (cell - 1L) / (cells - 1L)
  if (flip) frac <- 1 - frac
  lo + (hi - lo) * frac
}

# Linear interpolation of (x, y) at `xout` with constant extrapolation. Ties
# in `x` (which floating-point grids at extreme magnitudes produce) are
# averaged silently, and fewer than two distinct x values give a constant.
interp_linear <- function(x, y, xout) {
  if (length(unique(x)) < 2L) return(rep(mean(y), length(xout)))
  stats::approx(x, y, xout = xout, rule = 2, ties = mean)$y
}
