# Next phase: optional nanonext adapter

Keep `collect()` producing schema-version-1 envelopes and publishing them to
the local stream. Replace the demo writer's publish callback with an optional
nanonext pub adapter; keep the stream and collection logic unchanged. On the
consumer side replace file polling with an adapter that drains bounded work
on the consumer's own R thread and calls the same local stream's emit method.
TUI widgets and signal bindings still consume the same values.

Retain source_id + sequence for deduplication, reset on source change, gap
reporting, timestamp-based stale detection and schema validation. Define
transport close independently from producer/consumer lifetime. Do not allow
socket-thread callbacks to mutate R state; schedule main-thread delivery using
the existing App timer/poll integration or Shiny scheduling. Explicitly bound
queues, payload sizes and per-tick drain work to preserve input latency.

Before implementation decide reconnect behavior, slow-subscriber policy,
subscription handshakes, initial snapshot/replay, socket endpoint ownership,
clock skew, authentication and local versus remote exposure. Pub/sub alone
does not supply durable delivery or initial latest-state retrieval. A snapshot
request or retained-state handshake will be needed to preserve reconnect UX.

Keep nanonext optional with requireNamespace; add no mandatory transport
dependency. Put future mirai workers, Shiny adapters and Plotly views behind
independent optional boundaries. The current synchronous stream rejects
reentrant emit; adapters must deliver sequentially and cannot assume nested
queueing. None of these future adapters is implemented in phases 0-2.
