# Reactive Integration

## In-place data replacement

`ChartWidget$update_data()` validates new inputs, replaces the chart specification, resets selection, clears dimension-dependent plans and rendered-cell caches, and invalidates the widget. An invalid update errors before changing chart data. The chart object and widget identity are retained.

## Existing stream protocol

Only line and scatter charts subscribe. `$bind_stream(stream, x, y, max_points)` snapshots stream history at bind time, validates extractor functions, then subscribes to ordered future callbacks. Extractors return scalar values: numeric/Date/POSIXct x and numeric y. The chart retains bounded history, handles source-id changes and sequence rollback as restarts, inserts a line break for explicit or detected sequence gaps, and reports invalid payloads through `$stream_error` and `chart.stream.error` without replacing last valid data.

The source callback is synchronous. Before mount, valid events update the chart synchronously. Once mounted, callbacks enqueue records in a ring queue capped at `max_points`; overflow drops the oldest queued event and marks a gap. One event-loop pass processes at most 16 records. If more remain, a short widget timer schedules the next chunk so the app can paint between passes. The chart state advances in memory while chunks are processed, then one `update_data()` and repaint is applied when the pending queue drains. Queue order and the final retained records are preserved. The adapter creates no worker or transport and imposes no dependency on `nanonext`.

`$unbind_stream()` removes only the chart subscription, leaving the stream open and the chart's last data visible. Widget removal and app shutdown use existing cleanup paths to unsubscribe. A pending timer observes inactive state after unbinding and cannot mutate the chart.

## Limits

The adapter intentionally does not make callbacks asynchronous; event extraction is caller code and should remain small. `max_points` bounds both view history and pending events. A large event burst may take multiple event-loop turns to drain.
