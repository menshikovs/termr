# API Compatibility

Five additive exports are generated into `NAMESPACE`: `line_chart()`, `scatter_chart()`, `bar_chart()`, `histogram()`, and `heatmap_chart()`. No existing exported function or widget signature was changed. Runtime comparison of `formals()` against the feature ref confirmed identical constructor formals:

```r
line_chart(x, y, title = NULL, x_label = NULL, y_label = NULL,
  mode = "auto", id = NULL, classes = NULL, style = NULL,
  interactive = TRUE, x_scale = "linear", y_scale = "linear",
  hline = NULL, vline = NULL, hline_label = NULL, vline_label = NULL,
  x_band = NULL, y_band = NULL, point_labels = NULL)
scatter_chart(x, y, title = NULL, x_label = NULL, y_label = NULL,
  mode = "auto", id = NULL, classes = NULL, style = NULL,
  interactive = TRUE, x_scale = "linear", y_scale = "linear",
  hline = NULL, vline = NULL, hline_label = NULL, vline_label = NULL,
  x_band = NULL, y_band = NULL, point_labels = NULL)
bar_chart(labels, values, title = NULL, x_label = NULL, y_label = NULL,
  mode = "auto", id = NULL, classes = NULL, style = NULL,
  interactive = TRUE, orientation = "vertical", position = "grouped",
  value_line = NULL, value_line_label = NULL, value_labels = NULL)
histogram(x, breaks = "Sturges", title = NULL, x_label = NULL,
  y_label = NULL, mode = "auto", id = NULL, classes = NULL,
  style = NULL, interactive = TRUE)
heatmap_chart(z, title = NULL, x_label = NULL, y_label = NULL,
  mode = "auto", id = NULL, classes = NULL, style = NULL,
  interactive = TRUE)
```

The chart-specific addition is `$bind_stream(stream, x, y, max_points = 600L)`, `$unbind_stream()`, and read-only `$stream_error` on line/scatter chart widgets. Other chart types reject stream binding explicitly. Selection events retain the `termrcharts.<type>.*` compatibility prefix. If `termrcharts` is also attached, use namespace qualification to choose the implementation. No existing API was replaced.

## Generated API files

Roxygen generated `NAMESPACE` and `man/{line_chart,scatter_chart,bar_chart,histogram,heatmap_chart}.Rd`. These files were not edited manually. The public API inventory lists all five functions.
