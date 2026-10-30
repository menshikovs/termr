# Optional mirai task runtime

Install the current termr checkout, plus optional `mirai` (>=2.7.3), `nanonext`
(>=1.10.0) and `jsonlite`. Add `shiny` (>=1.8.1) and `promises` for the direct
Shiny ExtendedTask example. No system service, fork backend or external broker
is needed. The examples use local mirai IPC and a private loopback progress
socket. Functions and results use trusted local R serialization; telemetry is
bounded JSON metadata and never the full result.

From this repository:

```sh
Rscript inst/examples/mirai-tasks/tui.R 2
Rscript inst/examples/mirai-tasks/shiny.R direct
```

The TUI owns one pool. It shows retained tasks, status, elapsed submission time,
known/unknown progress, errors and recent events. `n` submits, `e` demonstrates
failure, `c` cancels the first active owned task, `i` tests keyboard response,
`q` exits and closes the pool. The paced chunk workload mixes computation and
waiting; it is a demonstration, not a performance benchmark. Collection and
compute never execute in the terminal event loop.

The direct Shiny app serves `127.0.0.1:3840`, creates one shared two-worker pool
outside server and one ExtendedTask per session. Every invocation snapshots its
inputs; a second invocation while busy is ignored, avoiding an unbounded user
queue. The session owns its task handles (up to eight retained) and cancels only
its own tasks at session end. The app owner closes the shared receiver/pool at
shutdown. Cancellation/errors are displayed as task outcome envelopes; native
task promises still reject unsuccessful tasks. ExtendedTask construction and
invocation use a null reactive domain so late completion cannot write into a
destroyed module scope. No pool is created per chart.

For an independently owned producer, use two terminals:

```sh
Rscript inst/examples/mirai-tasks/producer.R 60
Rscript inst/examples/mirai-tasks/shiny.R remote
```

The producer creates one two-worker pool, publishes bounded full task-state
snapshots on `tcp://127.0.0.1:5581`, and serves recovery snapshots on `:5582`.
The remote Shiny app reuses `termr_nano_connect()` and the existing shared Shiny
receiver. It owns only its connection; closing a browser/app cannot stop the
producer or its workers. This is a read-only monitor, with no remote execution
or cancellation command channel. Port arguments may be supplied to both
scripts; endpoints must remain loopback.

The model retains at most twelve task handles, 64 local metadata events and 32
events per published snapshot. A task's full R result is available through its
handle and is not embedded in the snapshot. Total terminal counters are labelled
separately from retained rows. Idle task-event streams may become stale while
completed results remain valid; the producer's periodic snapshots maintain
connection liveness for remote monitoring.

Always call `demo$close()` when using these constructors programmatically.
Script entry points use try/finally. Task cancellation resolves a mirai request;
compiled code/side effects may stop later. Task timeout includes queue time;
the explicit `wait()` timeout does not cancel. See [mirai guide](../../../docs/mirai.md).

The Unix real-terminal regression is `python3 tools/pty/mirai_check.py` with this
checkout installed and optional packages available. Windows supports the same
runtime without fork, but requires an actual console for an interactive TUI;
headless/parser tests do not certify every Windows Terminal/ConPTY host.
