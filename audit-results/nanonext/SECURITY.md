# Security boundary

Only numeric 127.0.0.1 TCP endpoints are accepted for both sockets. Wildcard,
LAN, DNS alias, IPC and arbitrary URL schemes are rejected. Port 0 is accepted
only by publishers and resolved with tcp-bound-port while the listener remains
bound. No external bind was used for cross-OS testing; unavailable reverse
localhost forwarding was recorded rather than bypassed with a host/LAN bind.

All wire receives use raw mode. Network data is bounded JSON, never readRDS,
unserialize, eval(parse()) or serialized R objects. Socket byte caps precede
receipt; application checks precede JSON parsing; nesting/envelope types and
topic identity precede callback dispatch. Malformed messages increment invalid
diagnostics and do not update latest state. Outgoing reference/classed objects
are rejected or explicitly normalized. Test configuration files are trusted
local harness inputs, separate from the network protocol.

Snapshot RPC exposes only latest telemetry retrieval. There are no remote
process controls, shell commands, file writes requested by messages, arbitrary
function dispatch, history queries or code evaluation. Publisher owns exactly
one stream/topic. A finite poll budget and receive queue bound retained work;
application callbacks may still be expensive and run on the owner's R thread.

Loopback is not authentication. Any local peer with socket access may spoof
messages, request data or exhaust resources. Source IDs are collision-resistant
diagnostic identities, not cryptographic identities. No TLS, credentials,
authorization, remote monitoring or open-network support is claimed. Byte caps
and schema checks reduce malformed-message exposure but do not establish a
hostile-local-peer security guarantee. JSON payloads must not be interpreted
as commands by downstream application callbacks.
