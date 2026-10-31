#' Create a heatmap widget
#'
#' Shows a numeric matrix as shaded cells. Rows and columns keep their input
#' order (row 1 at the top). Values are mapped to ten levels over the range
#' of the displayed values, drawn as a glyph ramp (so the chart reads without
#' colour) plus a sequential colour.
#'
#' @param z A numeric matrix. `NA`, `NaN` and infinite cells are shown as `?`
#'   and excluded from the colour scale. `rownames(z)` and `colnames(z)` label
#'   the axes when space permits. A constant matrix is drawn at the middle
#'   level.
#' @inheritParams line_chart
#' @details A matrix larger than the plot is aggregated to the plot size
#'   before drawing: each displayed cell is the **mean of the finite values**
#'   in its block of source cells, and the colour scale spans the displayed
#'   values (the scale bar shows that range). Block means are less extreme
#'   than the source, so the scale describes the picture, not the full source
#'   range. A matrix smaller than the plot is enlarged so every source cell
#'   fills a block of cells.
#'
#'   Interactive heatmaps move a cursor with the arrow keys (or `j`/`k` for
#'   down/up); Home and End jump to the first and last column of the current
#'   row. Cursor movement posts `termrcharts.heatmap.cursor_changed`; Enter
#'   posts `termrcharts.heatmap.selected` and then
#'   `termrcharts.heatmap.activated`. Each event has exactly `row`, `column`
#'   and `value`: the one-based source position and its value. When the matrix
#'   is aggregated, the cursor visits the first source cell of each displayed
#'   block and the event reports that source cell's own value.
#' @inheritSection line_chart Updating chart data
#' @return A focusable termr widget.
#' @export
heatmap_chart <- function(z, title = NULL, x_label = NULL, y_label = NULL,
                    mode = "auto", id = NULL, classes = NULL, style = NULL,
                    interactive = TRUE) {
  check_flag(interactive, "interactive")
  chart_widget("heatmap", normalize_matrix(z), title, x_label, y_label, mode, id,
               classes, style, interactive)
}
