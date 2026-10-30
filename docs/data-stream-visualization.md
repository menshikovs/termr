# Stream data frames and ggplot2

`termr_stream_data(source, fields = c("cpu", "ram"), max_points = 600L,
extractor = NULL)` is an experimental ordinary-data.frame adapter. It accepts a
local/remote stream, Shiny receiver or list of retained observations. It does
not require Shiny, ggplot2, Plotly or nanonext. It reads a cached history; it
does not poll or subscribe on its own.

```r
events <- termr::termr_stream("metrics", history = 100L)
events$emit(list(timestamp = Sys.time(), cpu = 12, ram = NA_real_))
data <- termr::termr_stream_data(events, c("cpu", "ram"))
stopifnot(is.data.frame(data), is.na(data$ram[[1L]]))
events$close()
```

Every frame, including an empty one, has `timestamp` (POSIXct, UTC), requested
numeric fields, `source_id` (character), `sequence` (double), `gap` (logical),
`segment` (integer) and `received_at` (POSIXct, UTC). Finite Unix seconds or
POSIXt timestamps are accepted; arbitrary date strings are not parsed. Missing,
NaN, Inf and non-numeric metrics become `NA_real_`, never fabricated zeros.
Invalid/missing times become `NA` in a raw stream frame. The Shiny receiver
separately validates explicitly supplied times and supplies receipt time when
the payload has no timestamp.

Order is observation order, not sorted wall time. Sequence gaps, source changes,
time rollback and missing metrics split `segment`, so charts can avoid drawing
continuous lines across missing observations. A plotting layer should also
show source status. `max_points = 0` returns the typed empty schema.

For nested system-monitor payloads, flatten explicitly:

```r
extract <- function(x) list(timestamp = x$timestamp,
  cpu = x$metrics$cpu, ram = x$metrics$ram)
data <- termr::termr_stream_data(shared, extractor = extract)
ggplot2::ggplot(data, ggplot2::aes(timestamp, cpu, group = segment)) +
  ggplot2::geom_line(na.rm = TRUE) + ggplot2::theme_minimal()
```

Inside Shiny, call `history()` in a reactive expression before converting the
shared receiver. This establishes the history revision dependency; the plain
receiver `$history()` is deliberately not reactive. The dashboard caches one
frame conversion per receiver revision and tails it for individual sessions.

`inst/examples/system-monitor-live/ggplot_history.R` collects a finite bounded
history and writes separate CPU, RAM and comparison PNGs. These charts use
ordinary frames and ggplot2; there is no global ggplot dispatch registration.
The full dashboard rebuilds static ggplots on a data revision. That is more
expensive than incremental browser updates, so choose a suitable publication
rate/window. See [Plotly](plotly.md) and [Shiny lifecycle](shiny.md).
