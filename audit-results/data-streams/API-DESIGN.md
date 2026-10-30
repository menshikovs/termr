# API design

One experimental export: `termr_stream(name = NULL, history = 1000L)`.
No changes to existing exports, widgets, App, event loop or signal graph.
See `?termr_stream` and docs/data-streams.md for the maintained public contract.

| Method | Contract |
| --- | --- |
| emit(value) | Store every event, then synchronously dispatch; invisible NULL |
| latest() | Last event, or NULL when empty |
| history() | Chronological list, at most configured event count |
| clear() | Release latest/history; retain subscribers and open/closed state |
| subscribe(callback) | Callback(event), no replay; returns unsubscribe handle |
| handle$unsubscribe() | Idempotent, removes only that registration |
| close() | Idempotent, detach all callbacks, preserve retained values |
| is_closed() | Lifecycle flag |
| subscriber_count() | Number of live registrations |

Registration-order dispatch snapshots IDs. Removed callbacks are skipped;
new callbacks wait for the next event. Closing stops delivery. Nested emit
fails before storage, avoiding recursion/feedback with no queue growth.
Errors in callbacks are collected and one warning follows delivery to other
callbacks; ordinary warning escalation therefore occurs after delivery.
Interrupts unwind normally. Dispatch state resets on all exits.

No GC-dependent unsubscribe: stream owns callbacks explicitly. Keep handles
and release them on owner cleanup. Unsubscribed handles do not retain their
callback's lexical data. No global stream registry, finalizer or scheduler.
Values use ordinary R copy-on-modify; reference values remain shared.
Capacity counts events rather than bytes; latest is retained even at zero
capacity. Subscriber count is user-controlled rather than silently capped.

Integration is one-way and explicit: subscribe(function(event) state(event)).
Callbacks are untracked; signal writes use the existing graph. Identical
events still dispatch, while identical signal writes remain suppressed.

The demo-local transport is intentionally not an exported framework. The
version-1 JSON envelope is a small reusable data contract, documented in the
demo README. A new transport can publish/consume the same envelopes and feed
the same local stream without altering sources or widgets.
