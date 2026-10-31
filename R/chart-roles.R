# Marks and chart roles.
#
# Every drawn dot or cell carries an integer mark = kind * 64 + series. Kinds
# are ordered by drawing priority (a larger kind wins where marks overlap),
# so "the strongest mark in a cell" is simply `max()`. A mark of 0 is empty.
# Adding INVERSE records that a block glyph is the complement of the filled
# part and must be drawn in reverse video.

K_GUIDE <- 1L          # zero baseline and similar guides
K_FILL <- 2L           # filled areas and bars
K_STROKE <- 3L         # curves
K_FRAME <- 4L          # outlines with line-art ASCII glyphs (box plots)
K_POINT <- 5L          # markers
K_SELECTED <- 6L       # selected dot (reverse video)
K_SELECTED_FILL <- 7L  # selected filled item (recoloured)
K_TITLE <- 8L
K_AXIS <- 9L
K_TICK <- 10L
K_LABEL <- 11L
K_LEGEND <- 12L
K_HEAT <- 13L          # heatmap level 1..HEAT_LEVELS (series field)
K_NOTE <- 14L          # hints such as "(no finite data)"
K_REF <- 15L           # reference lines (merged under the data, see annotations.R)

INVERSE <- 1024L
HEAT_LEVELS <- 10L
HEAT_COLOR_GROUPS <- 5L   # adjacent levels share a colour; the glyph ramp keeps all levels

mark_of <- function(kind, series = 1L) as.integer(kind) * 64L + as.integer(series)
mark_kind <- function(m) (m %% INVERSE) %/% 64L
mark_series <- function(m) m %% 64L
mark_inverse <- function(m) m >= INVERSE

# Series colours are termr theme tokens, so charts follow the active theme.
# Semantic colours (success/error) come late so two series never read as
# good versus bad.
palette_tokens <- c("$accent", "$warning", "$information", "$success", "$error", "$primary")
series_color <- function(s) palette_tokens[(as.integer(s) - 1L) %% length(palette_tokens) + 1L]

# Sequential colours for heatmaps. Theme tokens carry no ordered scale, so
# the ramp is fixed; the glyph ramp encodes all ten levels without colour, and
# colours come in five steps so runs of cells merge into fewer segments.
heat_colors <- function(groups = HEAT_COLOR_GROUPS) {
  anchors <- c("#2c3e8f", "#2b83ba", "#3ec1a0", "#abdda4", "#ffffbf", "#fdae61", "#f46d43", "#d53e4f")
  rgb <- grDevices::col2rgb(anchors)
  pos <- seq(0, 1, length.out = ncol(rgb))
  at <- seq(0, 1, length.out = groups)
  channel <- function(v) pmax(0, pmin(255, round(stats::approx(pos, v, xout = at)$y)))
  grDevices::rgb(channel(rgb[1L, ]), channel(rgb[2L, ]), channel(rgb[3L, ]), maxColorValue = 255)
}

# Colour group (1..HEAT_COLOR_GROUPS) of a heat level (1..HEAT_LEVELS).
heat_group <- function(level) (as.integer(level) - 1L) %/% (HEAT_LEVELS %/% HEAT_COLOR_GROUPS) + 1L

# Style identity for run compaction: marks that look the same share a key.
# Fill, stroke, frame and point marks of one series are drawn alike.
style_key <- function(m) {
  kind <- mark_kind(m)
  same <- kind %in% c(K_FILL, K_STROKE, K_FRAME, K_POINT)
  key <- ifelse(same, K_FILL * 64L + mark_series(m), m %% INVERSE)
  # Heat cells that share a colour group look alike (the glyph differs).
  key <- ifelse(kind == K_HEAT, K_HEAT * 64L + heat_group(mark_series(m)), key)
  key <- ifelse(m == 0L, 0L, key)
  key + ifelse(mark_inverse(m), INVERSE, 0L)
}

# Keys whose style is invisible on a blank cell (foreground colour / bold
# only), so blanks can be absorbed into a neighbouring run.
style_inert <- function(key) {
  kind <- mark_kind(key)
  !mark_inverse(key) & !(kind %in% c(K_SELECTED))
}

style_cache <- new.env(parent = emptyenv())

mark_style <- function(key) {
  kind <- mark_kind(key)
  s <- mark_series(key)
  inv <- mark_inverse(key)
  st <- switch(as.character(kind),
    `2` = style(foreground = series_color(s), reverse = if (inv) TRUE),
    `1` = NULL,
    `6` = style(foreground = series_color(s), bold = TRUE, reverse = TRUE),
    `7` = style(foreground = "$primary", bold = TRUE),
    `8` = style(bold = TRUE),
    `13` = style(foreground = heat_colors()[[max(1L, min(HEAT_COLOR_GROUPS, s))]]),
    `15` = style(dim = TRUE),
    NULL)
  st
}

# A reusable segment (list(text, style)) for a style key.
segment_template <- function(key) {
  id <- as.character(key)
  hit <- style_cache[[id]]
  if (is.null(hit)) {
    hit <- unclass(span("", mark_style(key)))[[1L]]
    style_cache[[id]] <- hit
  }
  hit
}
