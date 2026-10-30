# Phase 6 architecture decision

Use optional mirai >=2.7.3 through public APIs, with two constructors:
termr_mirai_pool() and termr_mirai_submit(). Keep the existing processx Worker,
App worker lifecycle, reactive engine and stream/transport interfaces unchanged.
Worker's app-owned fields/callbacks differ from this UI-independent reusable pool.

Each pool owns a unique private compute profile, dispatcher, bounded admission
count and queued payload memory. Submit with try_mirai(), never blocking queue
admission and never adding a second task scheduler. Only close that owned
profile. Drop terminal tasks from the pool registry; callers own retained task
handles/results. Event history contains bounded metadata, never full results.

Task handles provide status/ready/info/result/cancel/wait/promise. Polling is
nonblocking; explicit wait is the only blocking wait. The optional promise uses
mirai's event-driven as.promise integration, suitable for Shiny ExtendedTask.
Actual worker-start time comes from the evaluation wrapper, received via progress
or result envelope; queued remains queued until start is confirmed. Finished_at
is host resolution time. Native 5/19/20 map to timed_out/failed/cancelled.
Cancellation races resolve already-completed results first. Native cancellation
confirms the mirai result, not physical cessation of all user side effects.

Progress is an explicit injected function, not automatic mirai reporting. One
pool-owned native pull socket and per-running-task push socket exchange bounded
raw JSON on private loopback; no files, executable wire objects or native R
callbacks. Sends are nonblocking and throttled. Receive work and buffers are
bounded; progress is lossy latest state, with sequence dedupe and terminal-state
guards. Final result envelopes reconcile dropped latest progress/start records.
Task result transport remains mirai's trusted local serialization path.

Prepare minimal function captures using existing worker capture helpers without
changing processx behavior. Reject reference-bearing inputs before dispatch;
cap serialized task input bytes and telemetry metadata. Keep result objects in
the task API, publishing only class/type/size metadata. Never export arbitrary
results via JSON. Reentrant mutation during event dispatch is rejected; getters
remain safe. One terminal transition per task.

TUI owns a poll timer and closes its pool in try/finally. Shiny session tasks use
ExtendedTask + native promises and explicit session cleanup. Independent producer
publishes bounded state through existing stream/nanonext APIs; Shiny receiver
observes it without owning producer or creating pools per graph. Both ownership
models receive separate runnable examples and lifecycle tests.

Validate actual installed semantics first, then focused/independent-process,
Windows/WSL, deterministic stress, real PTY, optional-only installations and
full package checks. Preserve all initial files outside authorized scope.
