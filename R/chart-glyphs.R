# Glyph sets and renderer selection.
#
# Every non-ASCII glyph the package emits is listed in this file. A set is
# used only when R measures each of its glyphs as exactly one display column
# in the current locale, so wide or ambiguous-width glyphs fall back to the
# next safer set instead of shifting the cells to their right. Nothing here
# probes the terminal: the checks use R's own width tables and the documented
# termr's locale-aware Unicode capability check.

# Lower-eighth block ramp, top half, and shades.
block_lower <- c("\u2581", "\u2582", "\u2583", "\u2584", "\u2585", "\u2586",
                 "\u2587", "\u2588")
block_half <- c(upper = "\u2580", lower = "\u2584", full = "\u2588")
block_shade <- c("\u2588", "\u2593", "\u2592", "\u2591", "\u259a", "\u259e")

# Unicode Braille: U+2800 + mask. Row dy (0 = top) and column dx of a 2 x 4
# cell map to the dot bits below (dots 1, 2, 3, 7 in the left column and
# 4, 5, 6, 8 in the right one).
braille_bits <- matrix(c(0x01L, 0x02L, 0x04L, 0x40L,
                         0x08L, 0x10L, 0x20L, 0x80L), nrow = 4L, ncol = 2L)

# U+2800 + mask for a single cell; mask 0 is the blank pattern U+2800.
braille_cell <- function(mask) intToUtf8(0x2800L + as.integer(mask), multiple = TRUE)

# Plot glyph lookup used by the packer: a blank cell is a plain space because
# some fonts draw U+2800 as a dotted square.
braille_lut <- function() c(" ", braille_cell(1:255))

text_unicode <- c(v = "\u2502", h = "\u2500", corner = "\u2514", tick_y = "\u2524",
                  tick_x = "\u2534", marker = "\u25c6", ellipsis = "\u2026",
                  cross = "\u253c")

glyph_width_ok <- function(chars) all(measure_width(chars) == 1L)

# Are the glyphs of each renderer measured as single columns here?
glyph_set_ok <- function(set) {
  switch(set,
    braille = glyph_width_ok(braille_cell(1:255)),
    block = glyph_width_ok(c(block_lower, block_half, block_shade)),
    text = glyph_width_ok(unname(text_unicode)),
    TRUE)
}

unicode_available <- function() {
  unicode_ok()
}

# Preferred renderer for `mode = "auto"`, by chart type. Braille suits strokes
# and curves; block glyphs suit filled shapes and categorical charts.
mode_preference <- c(line = "braille", scatter = "braille", bar = "block",
                     histogram = "block", heatmap = "block")

mode_choices <- c("auto", "block", "braille", "ascii")

# Resolve a requested mode to the renderer that is safe to use now.
# Returns list(mode = "ascii"/"block"/"braille", text = TRUE when the box-drawing
# axis glyphs are width-safe). Fallback chain: braille -> block -> ascii.
resolve_mode <- function(mode, type) {
  if (identical(mode, "ascii") || !unicode_available()) {
    return(list(mode = "ascii", text = FALSE))
  }
  want <- if (identical(mode, "auto")) mode_preference[[type]] else mode
  if (identical(type, "heatmap") && identical(want, "braille")) want <- "block"
  chain <- switch(want, braille = c("braille", "block", "ascii"),
                  block = c("block", "ascii"), "ascii")
  chosen <- "ascii"
  for (candidate in chain) {
    if (identical(candidate, "ascii") || glyph_set_ok(candidate)) {
      chosen <- candidate
      break
    }
  }
  list(mode = chosen, text = !identical(chosen, "ascii") && glyph_set_ok("text"))
}

# Dots per terminal cell (columns, rows) for each renderer.
mode_resolution <- function(mode) switch(mode, braille = c(2L, 4L), block = c(1L, 8L), c(1L, 1L))

# Height of a terminal cell relative to its width. Real cells are about twice
# as tall as wide; shapes that must look round (pie, bubble) use this ratio.
cell_aspect <- 2

axis_glyphs <- function(text_unicode_ok) {
  if (text_unicode_ok) {
    list(v = text_unicode[["v"]], h = text_unicode[["h"]], corner = text_unicode[["corner"]],
         tick_y = text_unicode[["tick_y"]], tick_x = text_unicode[["tick_x"]],
         marker = text_unicode[["marker"]], ellipsis = text_unicode[["ellipsis"]],
         cross = text_unicode[["cross"]])
  } else {
    list(v = "|", h = "-", corner = "+", tick_y = "+", tick_x = "+", marker = "X",
         ellipsis = "~", cross = "+")
  }
}
