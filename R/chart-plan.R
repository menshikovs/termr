# Chart plans.
#
# A plan is everything needed to draw one chart at one size: the resolved
# renderer, the frame, the static text layer, the base dot surface and the
# navigable items. Plans are rebuilt whenever the widget size (or the data)
# changes; only the selection overlay is recomputed on cursor movement.
#
# Pipeline per chart type (see `chart_handlers`):
#   validation -> statistics -> domains/scales -> layout (frame) ->
#   geometry (dots on the logical surface) -> renderer packing ->
#   segment compaction -> termr adapter.

fallback_label <- function(spec) {
  switch(spec$type, line = "Line chart", scatter = "Scatter chart", bar = "Bar chart",
         histogram = "Histogram", heatmap = "Heatmap", "Chart")
}

chart_plan <- function(spec, W, H) {
  W <- max(0L, as.integer(W)[1L]); H <- max(0L, as.integer(H)[1L])
  resolved <- resolve_mode(spec$mode %||% "auto", spec$type)
  handler <- chart_handler(spec$type)
  if (is.null(handler)) stop(sprintf("Unknown chart type `%s`.", spec$type), call. = FALSE)
  plan <- handler(spec, W, H, resolved)
  plan$W <- W; plan$H <- H; plan$mode <- resolved$mode
  plan
}

# Finish a surface-based plan: compose the static layer once and define the
# per-selection plot, which stamps the selected item onto a copy of the
# surface before packing.
surface_plan <- function(spec, frame, glyphs, extras, surf, stamp, ids, nav = NULL,
                         positions = ids, payload = NULL, hit = NULL) {
  base <- compose_static(spec, frame, glyphs, extras)
  plot <- function(selected) {
    if (!frame$ok) return(NULL)
    st <- if (!is.null(stamp) && length(selected) && !anyNA(selected)) stamp(selected) else NULL
    cur <- surf
    if (!is.null(st) && length(st$ops)) cur$m <- apply_ops(surf$m, st$ops)
    packed <- pack_surface(cur)
    mk <- st$marker
    if (!is.null(mk) && mk$row >= 1L && mk$row <= nrow(packed$glyph) &&
        mk$col >= 1L && mk$col <= ncol(packed$glyph)) {
      packed$glyph[mk$row, mk$col] <- glyphs$marker
      packed$mark[mk$row, mk$col] <- mark_of(K_SELECTED_FILL)
    }
    packed
  }
  list(frame = frame, glyphs = glyphs, base = base, surf = surf, plot = plot,
       ids = ids, positions = positions, nav = nav, payload = payload, hit = hit)
}

# A frame too small to draw in: only the static layer (title or label).
empty_plan <- function(spec, frame, glyphs, extras = list()) {
  base <- compose_static(spec, frame, glyphs, extras)
  list(frame = frame, glyphs = glyphs, base = base, surf = NULL,
       plot = function(selected) NULL, ids = integer(), positions = integer(),
       nav = NULL, payload = NULL, hit = function(row, col, selected) NULL)
}

# Glyph and mark matrices of a plan for one selection (the static layer, the
# packed plot with the selection stamped on it, and any overlay).
plan_cells <- function(plan, selected = NA_integer_) {
  cells <- compose_plot(plan$base, plan$frame, apply_refs(plan$plot(selected), plan$refs))
  if (!is.null(plan$overlay)) cells <- plan$overlay(cells, selected)
  cells
}

# Bounding box c(row, col, rows, cols) of the cells where two cell sets
# differ, or NULL when they are identical.
cells_diff_box <- function(a, b) {
  if (!length(a$glyph)) return(NULL)
  d <- a$glyph != b$glyph | a$mark != b$mark
  rows <- which(rowSums(d) > 0L)
  if (!length(rows)) return(NULL)
  cols <- which(colSums(d) > 0L)
  c(row = min(rows), col = min(cols), rows = max(rows) - min(rows) + 1L,
    cols = max(cols) - min(cols) + 1L)
}

render_plan_lines <- function(plan, selected = NA_integer_) {
  if (plan$W == 0L || plan$H == 0L) return(list())
  cells <- plan_cells(plan, selected)
  compact_lines(cells$glyph, cells$mark)
}

# Plain-text rendering of a plan, for tests and examples.
render_plan_text <- function(plan, selected = NA_integer_) {
  lines_text(render_plan_lines(plan, selected))
}

# Text note centred in the plot area (e.g. "(no finite data)").
note_item <- function(frame, text) {
  if (!frame$ok) return(NULL)
  row <- frame$plot[["row"]] + (frame$plot[["rows"]] - 1L) %/% 2L
  list(row = row, col = frame$plot[["col"]], text = text, kind = K_LABEL,
       width = frame$plot[["cols"]])
}
