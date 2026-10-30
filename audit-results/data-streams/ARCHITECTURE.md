# Data streams: discovery and implementation boundary

Source of truth: local termr 1.0.1 working tree, 2026-10-29. Original tracked
changes are saved in INITIAL-CHANGES.patch; INITIAL-STATUS.txt lists initial
tracked and untracked paths. Existing edits must remain intact.

## Existing mechanisms

R/signals.R owns the standalone dependency graph: signals suppress identical
writes, computed values are lazy, watch effects settle in creation order,
batch defers effects, dispose unlinks dependencies. R/reactive.R implements
widget fields. Widget bindings detach on removal. These remain unchanged.
R/app.R polls workers, fires batched timers, dispatches bounded events, then
repaints on invalidation. Drivers alone own terminal I/O. Worker subprocesses
use processx and RDS result/progress files, and are cancelled on app shutdown:
they cannot own the independent collector required here.

inst/examples/system-monitor.R is explicitly synthetic: random walks every
0.5 seconds update metrics, gauges, sparklines and a log. It collects neither
system CPU/RAM nor process information. No real htop implementation was found.
Existing audit-results/phase-3/reactivity.md records graph lifecycle findings;
these are context, not test evidence for this change.

## Design

One experimental export, termr_stream(), returns a synchronous local stream.
It stores events in environment-backed ring slots, a separate latest value,
and registration-ordered subscribers. No scheduler or second reactive graph.
subscribe(function(event) state(event)) bridges to an existing signal. Each
event is accepted, even if identical. Reactive callbacks execute untracked;
signal observers still use the existing dependency graph.

Reentrant emit is rejected before changing storage. This bounded rule prevents
recursive stream/signal feedback. Dispatch snapshots subscriber IDs; removed
subscribers are skipped and new ones wait for the next event. Callback errors
are isolated and reported after dispatch. Close disconnects all callbacks,
stops remaining delivery, and preserves retained values for inspection.

Subscriptions are explicitly owned: keep the returned unsubscribe handle and
release it at owner cleanup, or close the stream. Garbage collecting the
handle does not unsubscribe. No global registry or background resource exists.
Values follow R copy-on-modify, without deep copying; environments and other
reference objects remain shared and callers must not mutate published values.

## Integration and transport

New inst/examples/system-monitor-live/ scripts separate collection, TUI and
Shiny into independently started R processes. ps (already an Import) supplies
real metrics, with explicit unavailable fields on errors. A demo-local JSON
snapshot adapter uses temp-file write plus same-directory rename to a new,
immutable version. It never overwrites a published file. Bounded retention
and reader retry handle concurrent cleanup on Windows/Linux. A directory lock
enforces one writer. A shared configured directory is the transport endpoint.
Consumers poll snapshots; no callbacks cross processes. TUI timers, Shiny
reactivePoll and bounded per-client histories own only their own resources.

The transport is a latest-state channel, not durable event delivery. Skipped
sequences are observable; unknown schema, malformed content, unavailable and
stale sources are explicit states. JSON is optional and never parsed as R code.
No external bind, nanonext, mirai, Plotly, remote monitoring or worker pool is
part of phases 0-2.
