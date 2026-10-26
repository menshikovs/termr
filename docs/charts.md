# Native charts

termr includes five terminal chart widgets for common analysis and monitoring
views. They use the normal widget, layout, focus, theme and event systems and
do not require the separate `termrcharts` package.

```r
library(termr)

x <- seq_len(40)
app(
  vertical(
    horizontal(
      line_chart(x, cumsum(sin(x / 4)), title = "Line"),
      scatter_chart(x, cos(x / 5), title = "Scatter")
    ),
    horizontal(
      bar_chart(c("North", "South", "East", "West"), c(8, -3, 5, 11), title = "Regions"),
      histogram(rnorm(500), title = "Distribution"),
      heatmap_chart(matrix(rnorm(100), 10), title = "Residuals")
    )
  ),
  bind("q", "quit")
) |>
  run()
```

## Inputs

- `line_chart(x, y)` draws numeric, `Date` or `POSIXct` x coordinates with
  numeric y values. `NA` and non-finite pairs are omitted and break line
  segments. Numeric axes can use `x_scale = "log10"` or
  `y_scale = "log10"`; Date and POSIXct axes use calendar/clock ticks.
- `scatter_chart(x, y)` accepts the same coordinate types. Dense points are
  reduced to one representative per rendered dot cell while preserving source
  indices for selection.
- `bar_chart(labels, values)` accepts a numeric vector or a matrix whose rows
  match the category labels and whose columns are series. It supports vertical
  and horizontal bars, grouped and stacked series, negative values, optional
  value labels, and an optional value-axis reference line.
- `histogram(x, breaks = "Sturges")` delegates binning to
  `graphics::hist(..., plot = FALSE, include.lowest = TRUE)`. Non-finite
  observations are omitted. When bins exceed the available width, adjacent
  bins are combined and their counts are added.
- `heatmap_chart(z)` accepts a numeric matrix. Row and column names label the
  axes when space permits. Missing and non-finite cells render as `?` and are
  omitted from the color range. Large matrices are reduced to the viewport by
  taking the mean of finite values in each displayed block.

All constructors return focusable widgets by default. Set `interactive = FALSE`
for a display-only chart. Each chart accepts `title`, axis labels, `mode`,
`id`, `classes` and `style`. `mode` may be `"auto"`, `"ascii"`, `"block"` or
`"braille"`. Auto mode checks Unicode support and glyph display widths before
using block or Braille characters, then falls back to ASCII. Glyph patterns
and labels still convey the data when color is unavailable; series and heatmap
levels also use termr theme colors when the active theme enables them.

## Interaction and updates

With the default `interactive = TRUE`, arrow keys (or `j`/`k`), Home and End
move the selection; Enter posts a `selected` event followed by `activated`.
Left mouse clicks select the data item under the pointer. Event names keep the
termrcharts-compatible prefix `termrcharts.<type>.*`. Payloads identify source
data: line/scatter points report `index`, `x` and `y`; bars report category and
series identity; histogram bins report their boundaries and count; heatmap
cells report row, column and value. Payloads do not contain screen positions.
The read-only `$selected_index` field reports the current one-based source
selection; grouped bars and heatmaps return a two-element category/series or
row/column index. Prefer event payloads when the selected data values are
needed.

Replace data while an app is running with the widget's additive
`$update_data()` method:

```r
series <- line_chart(1:5, 1:5)
ui <- app(series, bind("r", function(app) {
  series$update_data(x = 1:5, y = c(2, 4, 1, 5, 3))
}))
run(ui)
```

Pass `x` and `y` for line/scatter, `labels` and `values` for bars, `x` for a
histogram, or `z` for a heatmap. Optional update arguments can change the
line/scatter scales or point labels, bar orientation or position, and histogram
breaks. The chart keeps its title, labels, mode, theme style and widget
identity. A valid update replaces data in place, resets selection to the first
available item, clears the size-specific plan and rendered-cell caches, and
requests a repaint. Invalid input errors before changing the current chart.

## Limits and compatibility

Charts keep their input data in memory. Rendering work is bounded to the
available viewport for dense lines, scatter points, bars and heatmaps, but
normalization, histogram binning and storing the original data still cost
time and memory. Headless `test_app()` measures the virtual terminal driver as
well as chart work; its timings are not interactive-terminal guarantees.
Unicode width depends on R's locale tables, and an unsupported glyph set falls
back to ASCII.

The five native constructors are additive to termr 1.0.1 and do not change
existing widget APIs. `termrcharts` remains a separate package with its
additional chart types, including area, density, box, violin, pie, bubble and
stacked-area charts. If both packages are attached, whichever package is
attached later determines the unqualified `line_chart`, `bar_chart`,
`scatter_chart`, `histogram` or `heatmap_chart` name on the search path. Use
`termr::line_chart()` or `termrcharts::line_chart()` to select a namespace
explicitly.

See [`inst/examples/native-charts-dashboard.R`](../inst/examples/native-charts-dashboard.R)
for a small table-and-chart application with keyboard navigation and live data
updates.
