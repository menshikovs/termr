#' Create a line chart widget
#'
#' @param x,y Vectors of equal length. `y` is numeric. `x` is numeric, a
#'   `Date` or a `POSIXct`; a Date or POSIXct `x` is drawn on a calendar or
#'   clock axis and events return the original object (class and time zone
#'   kept). Non-finite pairs are dropped; gaps in `y` break line segments.
#' @param title,x_label,y_label Optional chart and axis labels.
#' @param mode Renderer: `"auto"` (the default), `"block"`, `"braille"` or
#'   `"ascii"`. The renderer is presentation only; chart semantics do not
#'   change with it. `"auto"` prefers Braille for curves and block glyphs for
#'   filled and categorical charts, and falls back (Braille, block, ASCII)
#'   whenever a glyph is not measured as one display column.
#' @param id,classes Optional termr widget identity and classes.
#' @param style Optional termr style object applied to the widget.
#' @param interactive Enable keyboard cursor and selection events.
#' @param x_scale,y_scale `"linear"` (the default) or `"log10"`. A log axis
#'   needs strictly positive values (a finite value that is zero or negative is
#'   an error; non-finite values are dropped as usual) and is mapped in
#'   `log10` space, with ticks at powers of ten. Events carry the original
#'   values. `x_scale` must be `"linear"` for a Date or POSIXct `x`. See
#'   `docs/scales.md`.
#' @param point_labels Optional text for the points: a character vector with
#'   one label per observation, aligned with `x` and `y` (`NA` or `""` for no
#'   label). Nothing is labelled by default. Only the points that are drawn can
#'   be labelled (non-finite observations are dropped, and dense input is
#'   reduced to the retained points); a label goes right of its point, else left,
#'   above or below, in free cells only, and is omitted when none is free. See
#'   `docs/data-labels.md`.
#' @param hline,vline Reference lines: values of `y` (`hline`) or `x`
#'   (`vline`) in data space, one or several. A vline on a Date or POSIXct axis
#'   is a Date or POSIXct; on a log axis the original (positive) value is
#'   given. A line outside the visible domain is not drawn and does not change
#'   the domain. Lines are drawn only where the plot is empty or filled, so data
#'   and the selection stay on top; they cannot be selected and clicks pass
#'   through to the data. See `docs/annotations.md`.
#' @param hline_label,vline_label Optional text for the reference lines: a
#'   character vector with one label per `hline` / `vline` value, in the order
#'   given (`NA` for no label). A label is written beside its line (right edge
#'   of the plot for an hline, top edge for a vline) in free cells only, one
#'   alternative spot is tried, and it is omitted when there is no room or the
#'   plot is smaller than 12 x 4 cells; the line stays either way.
#' @param x_band,y_band Optional reference band: two values of `x` / `y` in data
#'   space (a reversed pair is sorted). A band is a sparse pattern drawn behind
#'   the data, clipped to the visible domain, not drawn when entirely outside,
#'   and never enlarges the domain. A log axis takes original positive values and
#'   a Date or POSIXct axis a Date or POSIXct pair.
#' @details Interactive line charts emit `termrcharts.line.cursor_changed`
#'   when keyboard navigation moves the cursor. Enter emits
#'   `termrcharts.line.selected` followed by
#'   `termrcharts.line.activated`. Each event has exactly `index`, `x`,
#'   and `y`: the original one-based input index and that observation's
#'   coordinates (`x` is a Date or POSIXct when the input was). No screen
#'   coordinates or widget internals are sent. On a log axis a click must be
#'   on the drawn line, measured on screen.
#' @section Updating chart data:
#' Every chart widget has an `$update_data()` method that replaces its input,
#' resets selection to the first available item and invalidates the cached
#' plan and cells. Call it with the constructor's data names: `x` and `y` for
#' line/scatter charts, `labels` and `values` for bars, `x` for a histogram,
#' and `z` for a heatmap. Line/scatter updates may also supply `x_scale`,
#' `y_scale` and `point_labels`; bar updates may supply `orientation` and
#' `position`; histogram updates may supply `breaks`. Invalid input leaves the
#' current chart data in place.
#' @return A focusable termr widget.
#' @examples
#' x <- 10^(0:4)
#' w <- line_chart(x, x^1.5, x_scale = "log10", y_scale = "log10")
#' d <- as.Date("2026-01-01") + 0:30
#' w <- line_chart(d, cumsum(rnorm(31)))
#' @export
line_chart <- function(x, y, title = NULL, x_label = NULL, y_label = NULL,
                       mode = "auto", id = NULL, classes = NULL, style = NULL,
                       interactive = TRUE, x_scale = "linear", y_scale = "linear",
                       hline = NULL, vline = NULL, hline_label = NULL, vline_label = NULL,
                       x_band = NULL, y_band = NULL, point_labels = NULL) {
  data <- normalize_xy(x, y, x_scale = x_scale, y_scale = y_scale, point_labels = point_labels)
  chart_widget("line", data, title, x_label, y_label, mode, id, classes, style, interactive,
               extra = list(refs = normalize_refs(data, hline, vline, hline_label = hline_label,
                                                  vline_label = vline_label, x_band = x_band, y_band = y_band)))
}

#' Create a scatter chart widget
#'
#' @inheritParams line_chart
#' @details Interactive scatter charts emit
#'   `termrcharts.scatter.cursor_changed` when keyboard navigation moves the
#'   cursor. Enter emits `termrcharts.scatter.selected` followed by
#'   `termrcharts.scatter.activated`. Each event has exactly `index`, `x`,
#'   and `y`: the original one-based input index and that observation's
#'   coordinates. Dense reduction happens on screen cells (after any axis
#'   transform) and preserves those source indices.
#' @inheritSection line_chart Updating chart data
#' @return A focusable termr widget.
#' @examples
#' t <- as.POSIXct("2026-01-01 09:00:00", tz = "UTC") + 60 * (0:59)
#' w <- scatter_chart(t, sin(seq_along(t) / 6))
#' @export
scatter_chart <- function(x, y, title = NULL, x_label = NULL, y_label = NULL,
                          mode = "auto", id = NULL, classes = NULL, style = NULL,
                          interactive = TRUE, x_scale = "linear", y_scale = "linear",
                          hline = NULL, vline = NULL, hline_label = NULL, vline_label = NULL,
                          x_band = NULL, y_band = NULL, point_labels = NULL) {
  data <- normalize_xy(x, y, x_scale = x_scale, y_scale = y_scale, point_labels = point_labels)
  chart_widget("scatter", data, title, x_label, y_label, mode, id, classes, style, interactive,
               extra = list(refs = normalize_refs(data, hline, vline, hline_label = hline_label,
                                                  vline_label = vline_label, x_band = x_band, y_band = y_band)))
}

#' Create a bar chart widget
#'
#' One constructor draws single, grouped and stacked bars, vertical or
#' horizontal. A numeric vector gives one bar per category exactly as before;
#' a numeric matrix gives several series.
#'
#' @param labels Character labels in stable input order, one per category.
#' @param values Numeric bar values. A **vector** has one value per label
#'   (`position = "single"`). A **matrix** has one row per label and one column
#'   per series (`rows = categories, columns = series`); its column names are
#'   the series names (`"series 1"`, `"series 2"`, ... when there are none).
#'   Finite values are rendered; non-finite values (`NA`, `NaN`, `Inf`,
#'   `-Inf`) are omitted from the chart and skipped by keyboard selection (they
#'   are never turned into zeros). Category order follows `labels`.
#' @param orientation `"vertical"` (the default, categories along the bottom)
#'   or `"horizontal"` (categories down the left, bars extending right for
#'   positive values and left for negative ones).
#' @param position `"single"` (the default; one series, required for a vector),
#'   `"grouped"` (one bar per series side by side inside each category) or
#'   `"stacked"` (the series accumulated inside each category). For a matrix the
#'   default is `"grouped"`. A matrix with one column and `position = "single"`
#'   is treated as a vector. Stacked bars put positive values on one side of
#'   zero and negative values on the other, each in series order, never one on
#'   top of the other.
#' @param value_labels Show each bar's value as text (`FALSE` by default): just
#'   past the end of the bar (above or right for positive values, below or left
#'   for negative ones), else inside the bar at its end, else omitted. Stacked
#'   bars label each segment with its own value, inside the segment, and only
#'   when the text fits. Values are the source values in a compact form (`42`,
#'   `1.2`, `1.5k`, `2.3M`, `1e12`, `1.2e-6`), never cut; text that does not fit
#'   is omitted. Labels are visual only: they are not clickable and change no
#'   event. See `docs/data-labels.md`.
#' @param value_line,value_line_label Reference lines at these values of the
#'   **value axis** (the numeric axis, whatever the orientation: horizontal lines
#'   for vertical bars, vertical lines for horizontal bars): one or several
#'   numbers, with an optional character vector of labels, one per value. A
#'   line spans the whole plot (it is a threshold, not one per series), is drawn
#'   under the bars and their value labels, is not drawn outside the bar value
#'   domain and never enlarges it. A line at zero shares the baseline's cells.
#'   Lines and their labels are not selectable and change no event. See
#'   `docs/annotations.md`.
#' @inheritParams line_chart
#' @details Interactive bar charts emit `termrcharts.bar.cursor_changed`
#'   on cursor movement. Enter emits `termrcharts.bar.selected` followed by
#'   `termrcharts.bar.activated`.
#'
#'   For a **vector**, each event has exactly `index`, `label` and `value`,
#'   where `index` is the one-based category position. `NA`, `NaN`, `Inf`, and
#'   `-Inf` bars are omitted from drawing and skipped during navigation; finite
#'   bars alone determine the zero baseline.
#'
#'   For a **matrix**, each event has exactly `category_index`, `category`,
#'   `series_index`, `series` and `value`: the one-based row and column and
#'   their names, and that cell's value.
#'
#'   Keyboard: for single bars, left/up/`k` and right/down/`j` move between
#'   bars. For grouped and stacked bars the primary direction (left/right for
#'   vertical bars, up/down for horizontal ones, and `k`/`j` in both) changes
#'   category and the secondary direction (up/down, or left/right) changes
#'   series; Home and End jump to the first and last category. A click selects
#'   the bar (single, grouped: the bar's whole strip, so zero bars can be
#'   clicked) or the visible segment (stacked), or a series in the legend at the
#'   current category; clicking the current bar again posts `selected`.
#'
#'   Series differ by pattern (ASCII fill characters, block shades, Braille
#'   dither) as well as colour, and a legend names them when there is room. A
#'   grouped chart needs at least one cell per series along the category axis:
#'   with more categories than fit, an even sample of categories is drawn, and
#'   when not even one category fits the chart says so.
#' @inheritSection line_chart Updating chart data
#' @return A focusable termr widget.
#' @examples
#' bar_chart(c("a", "b", "c"), c(3, 5, 4), orientation = "horizontal")
#' m <- cbind(north = c(10, 15, 8), south = c(20, 12, 25))
#' bar_chart(c("Q1", "Q2", "Q3"), m, position = "grouped")
#' bar_chart(c("Q1", "Q2", "Q3"), m, position = "stacked")
#' @export
bar_chart <- function(labels, values, title = NULL, x_label = NULL,
                      y_label = NULL, mode = "auto", id = NULL,
                      classes = NULL, style = NULL, interactive = TRUE,
                      orientation = "vertical", position = "single",
                      value_line = NULL, value_line_label = NULL, value_labels = FALSE) {
  check_flag(value_labels, "value_labels")
  orientation <- chart_check_choice(orientation, c("vertical", "horizontal"), "orientation")
  explicit_position <- !missing(position)
  normalized <- normalize_bar_data(labels, values, position, explicit_position)
  position <- normalized$position
  data <- normalized$data
  chart_widget("bar", data, title, x_label, y_label, mode, id, classes, style, interactive,
               extra = list(orientation = orientation, position = position, value_labels = value_labels,
                            refs = normalize_refs(
                              list(),
                              hline = if (identical(orientation, "vertical")) value_line,
                              vline = if (identical(orientation, "horizontal")) value_line,
                              hline_label = if (identical(orientation, "vertical")) value_line_label,
                              vline_label = if (identical(orientation, "horizontal")) value_line_label,
                              arg_names = list(hline = "value_line", vline = "value_line",
                                               hline_label = "value_line_label",
                                               vline_label = "value_line_label"))))
}

#' Create a histogram widget
#'
#' @param x Numeric observations. Non-finite observations are omitted.
#' @param breaks Number of bins or break points. Vector breaks must be finite
#'   and increasing. The default is `Sturges`.
#' @inheritParams line_chart
#' @details Interactive histograms emit
#'   `termrcharts.histogram.cursor_changed` on cursor movement. Enter emits
#'   `termrcharts.histogram.selected` followed by
#'   `termrcharts.histogram.activated`. Each event has exactly `index`,
#'   `lower`, `upper`, and `count`; index is the one-based bin position. When
#'   a terminal is narrower than the number of bins, adjacent bins are merged
#'   for display and the event describes the merged range (`index` is its
#'   first bin).
#' @inheritSection line_chart Updating chart data
#' @return A focusable termr widget.
#' @export
histogram <- function(x, breaks = "Sturges", title = NULL, x_label = NULL,
                      y_label = NULL, mode = "auto", id = NULL,
                      classes = NULL, style = NULL, interactive = TRUE) {
  check_flag(interactive, "interactive")
  data <- histogram_data(x, breaks)
  chart_widget("histogram", data, title, x_label, y_label, mode, id, classes,
               style, interactive, extra = list(breaks = breaks))
}

chart_widget <- function(type, data, title, x_label, y_label, mode, id,
                         classes, style, interactive, extra = list()) {
  validate_common(title, x_label, y_label, mode, id, classes, style, interactive)
  spec <- c(list(type = type, data = data, title = title, x_label = x_label,
                 y_label = y_label, mode = mode), extra)
  ChartWidget$new(spec, id = id, classes = classes, style = style,
                  interactive = interactive)
}
