# Experimental public API

Five new exports; 163 explicit exports total, existing S3 registrations unchanged.
Generated help comes from roxygen source; unrelated existing help was preserved.

| API | Purpose / default |
|---|---|
| `termr_shiny_receiver(source, interval=50L, max_points=600L, stale_after=5, validate=NULL, close_source=FALSE)` | Explicit process-local shared receiver; source caller-owned by default |
| `termr_shiny_reactive(source, session=shiny::getDefaultReactiveDomain(), max_points=600L)` | Reactive last valid unchanged payload |
| `termr_shiny_history(source, session=shiny::getDefaultReactiveDomain(), max_points=600L)` | Reactive bounded observation records |
| `termr_shiny_status(source, session=shiny::getDefaultReactiveDomain())` | Reactive live/unavailable/stale/invalid/closed status |
| `termr_stream_data(source, fields=c("cpu","ram"), max_points=600L, extractor=NULL)` | Ordinary typed frame, no optional packages required |

Receiver plain methods: latest/history/status/diagnostics/poll/close/is_closed.
History is observed data plus an initial latest snapshot, not remote replay.
Records carry payload/source_id/sequence/timestamp/received_at/gap. Unknown
metadata gets local identity. Restart generation clears old observations,
including restart with an empty snapshot. Consumers must check status before
presenting cached metrics as current.

Frames always have POSIXct UTC timestamp and received_at; numeric requested
fields; character source_id; double sequence; logical gap; integer segment.
Missing/non-numeric/NaN/Inf metrics are NA_real_. Raw invalid time is NA;
observation order is retained. An explicit extractor flattens nested metrics.
max_points=0 gives a typed empty frame. No global ggplot method is installed.

New dependencies are Suggests only: ggplot2, htmlwidgets and plotly. Existing
Shiny/nanonext/jsonlite integrations remain optional. No Imports/Depends change.
See docs/shiny.md, docs/plotly.md and docs/data-stream-visualization.md.
