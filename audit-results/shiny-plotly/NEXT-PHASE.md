# Readiness for mirai

The stream/transport/reactive boundaries are ready for an optional mirai
producer experiment: plain validated telemetry payloads, main-thread bounded
polling, explicit ownership/cleanup, source identity/sequence and bounded
presentation history are available. A future worker can publish observations
without a TUI or Shiny session owning its lifetime.

Do not add mirai to Imports or replace the existing worker system as part of
this phase. Before calling that backend ready, test worker creation/failure,
cancel/restart, mailbox/backpressure limits, independent-process snapshots,
package/environment propagation and Windows lifecycle using inherited launch
environment. Preserve JSON wire data boundaries; never deserialize executable
R payloads from a network peer. Add multi-process Shiny worker tests and a
longer browser/native-memory soak. Durable replay and authenticated remote
transport would require separate architecture and scope.

No mirai implementation, new daemon service, system networking change or
release was performed. Current limits are explicit in KNOWN-LIMITATIONS.md.
