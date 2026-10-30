# Shiny stream integration

The Shiny adapters are experimental. Install `shiny` only when using them;
local streams, TUI applications and the data.frame adapter work without it.
See [stability](stability.md) and [nanonext transport](nanonext.md).

Create the transport and shared receiver **outside** `server`, once per Shiny R
process. They do not create a collector. For example, with a separate publisher
on the two loopback endpoints:

```r
remote <- termr::termr_nano_connect("tcp://127.0.0.1:5555", "system.metrics",
  "tcp://127.0.0.1:5556")
shared <- termr::termr_shiny_receiver(remote, interval = 50L,
  max_points = 600L, stale_after = 5, close_source = TRUE)
server <- function(input, output, session) {
  latest <- termr::termr_shiny_reactive(shared, session)
  history <- termr::termr_shiny_history(shared, session, max_points = 600L)
  status <- termr::termr_shiny_status(shared, session)
  output$state <- shiny::renderText(status()$state)
  # Use latest() / history() in ordinary Shiny reactives and renderers.
}
ui <- shiny::fluidPage(shiny::textOutput("state"))
tryCatch(shiny::runApp(shiny::shinyApp(ui, server), host = "127.0.0.1"),
  finally = shared$close())
```

A local `termr_stream()` is also a source. Passing that source directly to a
wrapper creates a receiver owned by that session. Use the explicit shared
receiver above for multiple sessions; there is no hidden global connection
registry and no sharing across separate R processes.

The receiver owns one source subscription, a bounded ring and at most one
process-level Shiny poll observer. Three wrappers or multiple charts in one
session acquire only one lease. The first lease resumes polling; the last
session ending suspends it. Ending one session cannot close the shared source.
The owner must call `$close()` at app shutdown; this destroys the observer and
subscription. The source stays caller-owned unless `close_source = TRUE`.
Closing an implicit session receiver also leaves its caller's source open.

The poll interval is 10–60000 ms (default 50); it is a scheduling target, not a
deadline guarantee. The source's own `poll()` and validator must be bounded and
nonblocking. The nanonext source drains at most 64 messages per default poll,
has bounded native buffers and at most two pending AIO operations. R callbacks
and reactive work execute on the normal R thread. Slow plotting or a slow
callback delays the entire Shiny process.

Each poll publishes at most one data revision. A burst can retain its final
`max_points` observations while coalescing intermediate reactive invalidations.
Idle status checks do not invalidate history/latest. The handle's plain
`$diagnostics()` counts sessions, observers, polls, accepted/coalesced events,
duplicates, out-of-order values and poll errors; it is not a reactive read.

History begins with the latest known value and then observations seen by this
receiver. Records contain `payload`, `source_id`, `sequence`, `timestamp`,
`received_at` and `gap`; they are **not** a publisher replay log. Known duplicate
and older sequences are ignored. Source changes clear retained history and
increment `generation`, including a restart with an empty snapshot. Without
metadata, observations get a local identity/sequence; cross-process deduplication
then cannot be guaranteed.

`status()` exposes `live`, `unavailable`, `stale`, `invalid` or `closed`, plus
sequence/gaps, generation, last measurement timestamp and `reconnecting`.
Receipt age and measurement age independently mark data stale; heartbeats do
not make an old measurement current. An optional validator must return exactly
`TRUE`. Invalid timestamps/schema preserve the last good latest value while
reporting invalid status. Present cached values with a visible status, as the
dashboard example does. Missing timestamps use receipt time for history.

Pub/sub is lossy latest-state telemetry. Reconnect and periodic request/reply
snapshots recover current state; they cannot recover every missing event.
Loopback binding limits network reach but is not authentication against other
local processes. No arbitrary R objects or executable serialized functions are
accepted from the wire.

The runnable [dashboard](../inst/examples/system-monitor-live/dashboard.R)
shares a validated receiver and frame conversion, has base/ggplot2/Plotly modes,
and leaves collection independent. See its [README](../inst/examples/system-monitor-live/README.md)
for launch commands and [visualization](data-stream-visualization.md) for frames.
