# Phase 4–5 architecture

Independent collector → bounded local stream → optional raw JSON nanonext
pub/sub + request/reply snapshot → one remote handle per Shiny R process →
one explicit shared receiver → session reactives → ordinary data.frame →
base/ggplot2 or Plotly proxy. The existing TUI and simple Shiny fallback remain.

The receiver is created outside `server`, owns one source subscription, at most
one process-level poll observer and a bounded observation ring. Session wrappers
share a lease in session$userData; ending one session cannot stop the others.
First lease resumes the driver, last release suspends it. The app owner closes
the receiver explicitly; source ownership is controlled by close_source.
An implicit receiver created from a source is session-owned, but never closes
its caller's source. There is no global connection registry or cross-process
sharing. No collector or OS process is launched by these adapters.

Source polling is bounded/nonblocking. Callbacks run on the main R thread and
store records; a poll emits at most one reactive revision. Known duplicate and
older sequences are discarded; source changes clear history. Missing metadata
has only local identity. Invalid payload/time preserves cached latest with an
invalid status; stale measurement and receipt ages are independent of heartbeats.

Presentation uses normal frames. Segment groups and null Plotly y values avoid
bridging gaps. A session keeps its graph cursor. Ordered observations extend;
initial/window/source/gap/invalid changes explicitly replace history. One
browser acknowledgement permits at most one graph command in flight; slow tabs
coalesce subsequent data in the bounded ring. No unbounded application queue
or blind retry timer is added. Plotly/native websocket internals are external.

The generic receiver defaults to 50 ms. Profiling showed expensive reactive
fanout at 20 tabs, so the full example defaults to 500 ms and batches points.
This is a scheduling target, not a real-time guarantee. Slow R callbacks/plots
still delay the shared R thread. Public API details: API.md and docs/shiny.md.
