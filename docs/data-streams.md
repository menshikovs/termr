# Data streams (experimental)

`termr_stream()` is a synchronous, pure-R event sequence that needs no App,
terminal, Shiny session or background worker. A signal is a current reactive
value: an identical write does nothing. A stream delivers **every** emission,
even identical values. Its snapshot is `latest()`; its history is a bounded
chronological list. A transport moves values between processes and is separate
from both the stream and the signal dependency graph.

```r
library(termr)
events <- termr_stream("system.metrics", history = 120L)
current <- signal(NULL)
subscription <- events$subscribe(function(event) current(event))
events$emit(list(timestamp = Sys.time(), cpu = 42, ram = 61))
events$latest()
events$history()
subscription$unsubscribe()
events$close()
```

History counts events, not bytes. A ring retains at most `history` values and
overwrites the oldest in constant time. Zero disables history while retaining
the latest value. Empty history is `list()`; empty latest is `NULL`, also a
valid event value. `clear()` releases history and latest; `close()` retains
them for inspection and disconnects callbacks. Treat published values as
immutable: ordinary R values use copy-on-modify; environments and other
reference objects are shared without cloning.

Callbacks run synchronously in registration order and receive one value, with
no replay on subscription. An unsubscribe handle is independent and idempotent.
Removing a subscriber during dispatch skips it; adding one starts at the next
event. Keep the handle and unsubscribe when its owner finishes: garbage
collection of a handle does not unsubscribe. Closing is idempotent, stops
remaining delivery, and makes emit/subscribe fail. `subscriber_count()` and
`is_closed()` support lifecycle diagnostics. No global registry keeps a stream
alive.

Callback errors do not prevent delivery to later subscribers; one warning
after dispatch reports their count and first error. With `options(warn = 2)`,
this warning becomes an error **after** delivery. Interrupts propagate and
restore dispatch state. A nested emit on the same stream is rejected before
storage, preventing recursive feedback. Reads inside callbacks are untracked;
explicit signal writes still use the existing graph, batching and identical
write semantics. Never mutate an R object directly from another process.

The [live system monitor](../inst/examples/system-monitor-live/README.md)
demonstrates real CPU/RAM/process collection in one independently started R
process, a termr terminal client, and a Shiny client in a third process. It
documents Windows/WSL launch commands, JSON schema version 1, rate limiting,
immutable version publication, stale/unavailable recovery, bounded client
history, single-writer ownership and sequence-gap diagnostics. jsonlite and
Shiny are optional; neither is needed by the local Stream API. This is a
latest-state prototype; it does not guarantee delivery of every event.

The API is experimental. Optional [nanonext telemetry](nanonext.md) now carries
the same payloads with snapshot recovery and live events. Mirai workers and
Plotly adapters remain future work.
