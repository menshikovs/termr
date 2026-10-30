# Phase 3 architecture

Local source is termr 1.0.1 plus uncommitted phases 0-2 and unrelated terminal
work. INITIAL-STATUS.txt, INITIAL-CHANGES.patch, baseline/ and initial-hashes.json
preserve the starting tree. R/streams.R and the standalone signal graph remain
unchanged. Worker/App lifetimes cannot own an independent collector: workers
are cancelled at App shutdown. No second graph, worker engine or mirai added.

Two optional exports: termr_nano_publish(stream, endpoint, snapshot_endpoint)
and termr_nano_connect(endpoint, stream, snapshot_endpoint). nanonext/jsonlite
are optional; no optional namespace is loaded until an adapter is requested.
R core and all added source are pure R. Tested nanonext API is 1.10.3; minimum
is explicitly 1.10.0. Official docs consulted: socket, subscribe/unsubscribe,
send/recv, send_aio/recv_aio, stop_aio, opt and pipe_notify. Source: official
https://nanonext.r-lib.org/reference/ (Context7 had no nanonext entry).

## Channels and consistency

One cooked pub/sub pair carries raw topic-prefixed JSON. One cooked req/rep
pair carries bounded JSON snapshot requests/replies, never serialized R.
The topic is exact `termr/<stream_id>\n`; a trailing delimiter prevents prefix
collisions between metrics and metrics.extra. Publisher identity changes per
adapter lifetime; sequence is monotone within it. Pub/sub is lossy. Snapshots
are latest-value recovery, with no replay/durable delivery guarantee.

Subscriber configures its subscription before requesting snapshot. Only a
snapshot establishes source identity; live messages for another source trigger
resync. Duplicate/older events are discarded, gaps counted, newer values
accepted. Heartbeats and periodic snapshot requests recover an otherwise
undetectable dropped final event. A restart resets client history without
touching local callback registrations. JSON file envelopes remain payloads;
collector metrics are not collected twice or parsed from terminal output.

## Event loop, backpressure and ownership

Owners explicitly poll on their R thread. Publisher emits nonblocking raw
pub sends and services at most 32 snapshot requests per poll. Remote drains
at most max_messages (default 64), plus bounded snapshot work. AIOs are held
in fixed slots and cancelled on close. No native callbacks invoke user R.
One request send/receive phase exists at a time. Socket receive byte caps,
native bounded queues, bounded JSON depth and stream ring histories limit
retained work. Slow subscribers can lose intermediate events and resync.

NNG dialers use 50-1000 ms reconnect backoff. Failed snapshot requests have
50-1000 ms retry backoff and finite timeouts. No blocking recv/call_aio waits,
unbounded operation lists, busy loop or hidden background R scheduler.
pipe_notify could signal native condition variables, but introduces no need
for native-thread R callbacks here; heartbeat freshness and snapshot recovery
are the transport-facing liveness model, not proof of measurement freshness.

Publisher owns its sockets and its one local subscription, never the supplied
stream. Remote owns sockets, AIOs and its local stream; close detaches its
callbacks. Construction failures release already-created resources. Closing
is idempotent and safe during callbacks/pending operations. A closed stream
should be preceded by closing its publisher. Only 127.0.0.1 TCP is accepted.
Port 0 allocation stays bound and returns both actual endpoints, avoiding a
find-free/close/rebind test race.
