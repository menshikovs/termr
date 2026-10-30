# Optional nanonext telemetry (experimental)

`termr_nano_publish()` attaches a transport to an existing named
`termr_stream()`. `termr_nano_connect()` returns a remote stream handle with
cached latest value, bounded history and local subscriptions. Install optional
`nanonext >= 1.10.0` and `jsonlite` to use them; ordinary termr streams, widgets
and file snapshots continue working without either package. The implementation
was exercised with nanonext 1.10.3. termr adds no compiled source.

```r
# Publisher process
library(termr)
metrics <- termr_stream("system.metrics", history = 120L)
publisher <- termr_nano_publish(metrics, "tcp://127.0.0.1:5555")
metrics$emit(list(timestamp = Sys.time(), cpu = 42, ram = 61))
publisher$poll()  # call regularly from the owner's event loop

# Another R process
remote <- termr_nano_connect("tcp://127.0.0.1:5555", "system.metrics")
subscription <- remote$subscribe(function(value) print(value))
remote$poll()     # call regularly; never waits for network data
remote$latest()   # cached value, possibly NULL before connection/snapshot
remote$status()

# At each owner's cleanup:
subscription$unsubscribe()
remote$close()
publisher$close()
```

The publisher and subscriber **both need regular poll calls**. An App can use
`app$set_interval(0.05, function() remote$poll())`; Shiny can use a session-owned
observer with `invalidateLater()`, or the bundled monitor's reactivePoll.
No automatic thread, native-thread R callback or global networking scheduler
is created. The example statements above describe separate owners; a running
application must continue polling after setup. Closing a publisher leaves its
source stream open. Closing a remote cancels AIO and detaches local callbacks.
Keep and close handles explicitly; callback registration alone does not poll.

## Snapshot and live consistency

Two TCP endpoints are required: pub/sub at `endpoint` and request/reply at
`snapshot_endpoint` (defaults to the next port). A publisher may pass port 0
for OS allocation and read both actual endpoints from its returned handle;
pass both to clients. The sockets stay bound throughout allocation. Tests
use this approach instead of guessing an available port.

Subscribe is configured before the snapshot request. The current snapshot
establishes source identity, then newer events advance sequence. Older or
duplicate events are discarded. A sequence gap increments status `$gaps` and
triggers resync. Heartbeats reveal an advanced source sequence; periodic
snapshots recover a final dropped event even without another live event.
A changed source_id resets history and accepts that source's latest snapshot.
No arbitrary replay or durable queue is promised: this is **latest-value
consistency with gap detection**, not guaranteed delivery of every event.

Snapshot requests have finite timeouts and 50-1000 ms retry backoff. NNG
dialers reconnect with 50-1000 ms exponential backoff. Connect-before-publish,
disconnect, restart and multiple subscribers are supported without blocking
the owner's loop. Publisher poll services at most 32 requests; remote poll
drains at most 64 messages by default (configurable per poll). Queue depth,
pending AIO slots, wire bytes and local history are bounded. Slow clients may
drop intermediate values; callbacks run on the polling R thread and their
runtime contributes to the polling cost.

`status()` reports state (connecting/live/stale/closed), source_id, sequence,
gaps, invalid messages, resyncs, pending operations and last_error. Heartbeat
freshness describes a responsive publisher; application measurement freshness
must be checked independently using payload timestamps. The monitor does both.

## Wire contract

Version 1 JSON object: schema_version (1), source_id and stream_id (ASCII
letters/digits/underscore/dot/hyphen, at most 128 bytes), sequence (integer-valued
number 0..2^53-1), timestamp (Unix seconds), message_type and payload. Event and
snapshot sequences start at 1. Heartbeat/status/request can use 0. Supported
messages: event, snapshot, heartbeat, status (empty/unknown stream), and
snapshot_request on the request channel only. These request messages only ask
for current state; no system command or code execution is implemented.

Live messages are raw UTF-8 bytes prefixed with `termr/<stream_id>\n`. This
matches nanonext's byte-prefix subscription rule and prevents topic-prefix
collisions. Socket protocol `raw=TRUE` is not needed: **send mode** is raw,
with no R serialization. Snapshot traffic is plain JSON without a topic.

Payloads are JSON trees. POSIXt becomes Unix seconds, NA becomes null, length-1
atomic vectors unbox, JSON arrays decode as lists, and integer/double storage
mode may change with numeric values. Data frames, matrices with semantic
attributes, factors, environments, functions and other classed objects need
explicit conversion. There is no exact R-object round trip. Schema validation,
native recv-size-max, application byte checks, duplicate envelope-key checks
and a nesting limit precede callback delivery. Outgoing size failures follow
stream callback error semantics and do not advance the publisher sequence.

The file monitor schema remains unchanged: the whole existing snapshot
(`schema_version`, `source_id`, `sequence`, `timestamp`, `collected_at`, metrics)
is the transport **payload**. Envelope identity/sequence belong to the
publisher; payload identity/sequence belong to the collector. File and live
clients thus receive the same structured measurements.

## Security and platform scope

Only `tcp://127.0.0.1:PORT` is accepted. There is no wildcard bind, remote
control, eval, R deserialization, authentication or encryption. Loopback
does not authenticate local processes. This adapter is for local telemetry,
not exposure to an open network. JSON byte caps are not authentication.

Windows/WSL networking varies by host. Addresses that work within Windows
or within WSL do not prove cross-OS loopback forwarding. See the current
audit-results/nanonext/WINDOWS-WSL.md in a development checkout for scenarios
actually exercised. The [monitor README](../inst/examples/system-monitor-live/README.md)
contains launch commands for file, live and simultaneous modes.
