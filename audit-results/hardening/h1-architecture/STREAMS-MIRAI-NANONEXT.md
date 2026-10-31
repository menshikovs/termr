# Reactive graph, streams, mirai and nanonext

signal/computed/watch use namespace-level rx state, dependency versioning,
ordered effect flushing and explicit disposal. batch/untracked restore
observer/depth state on unwinds. These APIs are experimental and synchronous.
Custom effects can still run arbitrary slow R code on the main thread.

termr_stream uses mutable ring slots, bounded event count and registration-order
callbacks. It rejects reentrant emit before storage, skips unsubscribed
callbacks, stops delivery after close, isolates callback errors and runs
callbacks untracked. History/latest may retain reference objects by contract;
event count is not a byte bound. Dropping a handle does not unsubscribe.

Nano uses loopback defaults, bounded raw JSON, payload/depth/schema validation,
bounded send/receive buffers, nonblocking AIO and polled snapshot recovery.
Publisher close unlinks the source subscription but does not own the stream.
Subscriber owns its reconstructed local ring. There is no native R callback
thread or process-control command protocol. Authentication/encryption is not
supplied for arbitrary external endpoint deployments.

Mirai has a separate named compute profile, bounded admissions/serialized
inputs, explicit task timeout/cancel and a bounded metadata stream. Progress
uses a nonblocking push/pull channel; final envelopes reconcile progress.
settle() observes already-resolved completion before cancellation, removes
terminal tasks from pool state and releases the duplicate native reference.
Task results/handles remain caller-owned. close/restart touch only verified
owned daemon processes. trusted local job serialization is distinct from
untrusted nano JSON.

U01: mirai and nanonext are absent on both current platforms. Pure stream/
validation and dependency-guard tests ran; actual sockets/daemons, cancellation
races, promise settlement and shutdown failure injection did not. Static
inspection of these paths is not runtime proof. No native-runtime race or
process leak is claimed without execution.

H2/H4 must run installed native backends: complete-vs-cancel scheduling,
queued timeout, worker exit during poll, stalled snapshot recovery, callback
close/reentry and repeated pool/socket creation. Source callbacks that run
slowly remain an explicit UI responsiveness limitation.
