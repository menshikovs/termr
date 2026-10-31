# Phase E — Mirai Nanonext

The monitor uses public `termr_mirai_pool`, task handles, event subscriptions,
`termr_stream`, `termr_nano_publish` and `termr_nano_connect`. There are real R
worker processes and real loopback sockets, not mocked task results. OS-assigned
ports avoid assuming fixed-port availability. It shows jobs, progress, failure
text, results, throughput, history and transport states. App queue internals are
not inspected; pending-job/AIO counts are labelled for their actual public meaning.

The real workload computes square-root sums in chunks; a controlled failure is
raised at chunk 2, a long task supports cancellation. Five repeated cancel races
assert one terminal transition per task, and active shutdown verifies only newly
owned child handles (pre-existing runner supervisor children are excluded).
Disconnect closes the publisher; reconnect closes/replaces the receiver and
rebinds the chart. Histories cap 128, retained tasks 24, pending jobs 8.

Windows uses mirai 2.7.3/nanonext 1.10.3; WSL uses mirai 2.7.3/nanonext 1.10.4.
Actual success/failure/cancel/reconnect ran in application tests, subprocesses,
PTY/Expect/tmux and lifecycle loops. Missing-native-package startup was tested
in a separate normal-library scope, without uninstalling global packages.
`final-windows/process-results.json` and `final-wsl/process-results.json` retain
the ten process cases; app tests contain the task/socket assertions.

Owner shutdown unbinds charts, unsubscribes, closes receiver/publisher/streams
and pool. Worker counts return to their prior process baseline. An independent
Windows probe nevertheless shows about two retained OS handles per new compute
profile even using direct mirai without termr. This is an open P2 backend risk,
not a leak-free certification; see RESOURCE-LIFECYCLE.md and H4-HANDOFF.md.
