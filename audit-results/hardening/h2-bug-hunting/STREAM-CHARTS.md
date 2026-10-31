# Native Stream Charts Architecture

`NativeChart` streaming integrates real-time time-series streams into terminal visualizations.

## 1. Ingestion & Drain Policy
- Incoming stream records are queued in a bounded ring-buffer queue (`state$queue`).
- To prevent UI starvation during continuous high-rate bursts, `flush_stream_queue()` drains events in 16-record batches.
- Per the documented design contract, chart rendering occurs when the queue is drained (`render = !state$queue$size`).
- During active draining, `state$pending_render` is maintained, and a short timer (1ms) yields control back to the terminal event loop to preserve input responsiveness.

## 2. Gap Semantics
- When the stream queue drops records due to capacity saturation, a gap marker is emitted, preventing misleading continuous lines across dropped data intervals.\n