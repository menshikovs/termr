# JSON telemetry protocol, schema version 1

## Framing and schema

Live packet = raw UTF-8 `termr/<stream_id>\n` followed by one JSON object.
Subscription uses exactly that full byte prefix, including newline. Cooked
NNG pub/sub sockets are used with send mode raw; no R serialization is sent
or accepted. Request/reply packets contain one JSON object without the prefix.

| Field | Contract |
| --- | --- |
| schema_version | integer 1 |
| source_id | lifetime-unique publisher identity, ASCII ID, <=128 bytes |
| stream_id | ASCII ID: letters, numbers, underscore, dot, hyphen; <=128 bytes |
| sequence | nonnegative integer-valued number <=2^53-1; event/snapshot >=1 |
| timestamp | finite nonnegative Unix seconds |
| message_type | event, snapshot, heartbeat, status; snapshot_request on RPC |
| payload | bounded JSON tree; no executable R representation |

Publisher sequence advances only after successful encoding. JSON event and
snapshot encodings are cached separately: an invalid outgoing payload leaves
the last successfully encoded state available. Native pub send failures may
still lose events after sequence advances; diagnostics count send failures.
An existing stream's non-NULL latest value, or its retained NULL event, seeds
the publisher. NULL emitted before attachment with history=0 is inherently
indistinguishable from an empty stream in the existing core API; attach first
when that distinction matters.

Event carries a value; snapshot carries current value at its sequence;
heartbeat carries current sequence and null payload. Empty source replies
with status `{status: "empty"}` at sequence 0. Unknown stream receives status
`unknown_stream` and does not establish a source for that requested topic.
There is no remote-control command, general RPC dispatcher or replay request.

POSIXt values normalize to Unix seconds; NA maps to null; scalar vectors
unbox; arrays decode as lists and integer/double storage mode may differ.
Classed objects, reference objects, matrices and functions require explicit
conversion. JSON names must be nonempty/unique for outgoing list objects.
Envelope keys are validated, incoming embedded NUL bytes and excessive nesting
are rejected, as are future envelope timestamps beyond five seconds.

## Initial state, loss and restart

Subscriber configures topic and initiates live receive before requesting a
snapshot. Snapshot establishes identity and high-water sequence. Live messages
for other identities trigger resync rather than switching sources. Events
at/below the high-water mark are discarded. Newer events are delivered in
increasing sequence order; a jump increments gaps and schedules snapshot
recovery. This is ordered delivery of the observed subsequence, not delivery
of every published event. Periodic snapshot recovery detects a dropped final
message even if no newer live event arrives. Heartbeats also advertise the
source high-water sequence.

Snapshot replies cannot overwrite a newer accepted sequence within the same
source. A new source clears bounded local history and starts a new sequence;
existing client callbacks survive. Gap diagnostics are cumulative across
source lifetimes. There is no stored full-history replay or durable queue.

## Scheduling and limits

Both owners poll on their R thread; no native R callbacks. Per remote poll:
one RPC phase, at most max_messages live receives (default 64), and at most
one new snapshot request. At most two AIO references are pending (one live
receive and one request send or response receive). Publisher owns at most
one request receive or reply send, and services at most 32 requests per poll.
Resolved operations are explicitly stopped before discarding; close cancels
all operations, closes sockets and releases native socket references.

Default max packet size 1 MiB, default native receive depth 64, configurable
within documented bounds. NNG recv-size-max is set before binding/dialing,
and R checks size before parsing. Native reconnection backoff is 50-1000 ms;
request retry backoff is 50-1000 ms with finite per-operation timeouts.
The monitor uses 3-second RPC timeout rather than the generic 500 ms default.

The unchanged file metrics envelope is nested as payload, not confused with
the transport envelope. Its source/sequence identify collector observations;
outer source/sequence identify this publisher's successfully encoded events.
