# Native charts and sustained streams

All five chart types have initial/warm render, resize, update_data, partial
selection redraw, forced full redraw and hit-plan measurements. The extra
scenarios invoke the existing update and hit logic; painting counters are saved
alongside timings. Rendering uses a headless terminal; it does not measure
physical terminal flush latency.

The continuous producer emits 64 events, then another 16 before each of 20
timer advances. Each consumer chunk processes 16; the queue therefore remains
non-empty. Before: processed view=100, displayed=0, pending=48, flushes=21.
The drain-only publication rule could starve indefinitely. H3 changes exactly
that predicate: the first chunk publishes immediately, a continuously non-empty
queue publishes at a 60 Hz cadence, and final drain publishes immediately.
The 1 ms timer yield, queue cap, max_points, error handling, gaps and ordering
remain unchanged. Stream freshness artifacts record before/after state.

The H3 regression requires a strictly advancing displayed latest value every
20 ms of simulated time, at most four paints over 40 ms, equality to processed
values when published, max_points <=100, and no subscription or callback work
after removal. Existing tests cover overflow/gap semantics,
selection, replacement and finite burst drain. Two old expectations requiring
no intermediate display were updated; their remaining assertions are intact.

This change increases redraw/allocation work when the producer never pauses.
The continuous-stream row in the before/after table quantifies the tradeoff.
It is a correctness and responsiveness repair, not a claimed faster stream
processor. Virtual-time advances test scheduling/freshness, not a real 1 ms
wall-clock guarantee. PTY and H4 long continuous input/stream tests remain
necessary for terminal-host latency confidence.
