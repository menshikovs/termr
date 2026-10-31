# Shiny and Plotly

termr_shiny_receiver owns one source subscription, bounded history, cached
status/value reactives and one polling observer. Per-session wrappers share
a binding in session$userData; acquire/release leases resume at first session
and suspend after the last. A shared receiver remains explicitly owner-closed;
implicit receivers close at session end. close_source is FALSE by default.

receive/poll track duplicate/out-of-order metadata, gaps, stale values,
restarted source identity and invalid snapshots. Source callbacks coalesce
before reactive flush. The bridge is telemetry-only: no bidirectional Shiny
process-control protocol exists or was added.

Plotly integration lives in the system-monitor-live visualization/dashboard
examples and tests. It appends bounded traces and resets on restart/gap; this
is not a generic new plotly renderer in the termr core. termr_stream_data()
converts telemetry to a bounded data.frame with time/sequence/segment columns.

WSL has Shiny 1.10.0 and Plotly 4.10.4 and executes shared-session, plot building
and optional visualization tests. Windows lacks these packages and skips
their runtime tests. Browser visual rendering, disconnected real sessions
under long load and native telemetry reconnection were not certified.
No Shiny session ownership defect was confirmed in H1. Future fault injection
must distinguish shared receiver ownership from borrowed source lifetime.
