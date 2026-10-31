# E-FIX — Mirai Nanonext

The actual Monitor entrypoint constructs termr's real mirai pool and nanonext
publisher/subscriber. No task completion/progress or IPC payload is mocked.
Native keyboard tests submit the real CPU workload, await completion, press
Enter and assert the worker's chunks/result text, trigger a real error, cancel
a long task, disconnect/reconnect and observe the receiver return to live.
The app uses OS-assigned loopback ports and bounded history/pending limits.

Evidence: terminal-gates/monitor/events.jsonl in final-runner-windows,
proof-wsl/terminal-gates/monitor/, normal stdout/stderr and runtime manifests. The details
event includes the actual result payload (sum and chunks), not a local synthetic
status assignment. Task transitions and transport sequence values come from
public pool/receiver APIs. Headless app tests independently verify task results,
failure text, cancel races, resubscription and active pool shutdown.

Normal and active-crash runs require closed=true, pool_closed=true,
transport_closed=true, source_closed=true and zero pool event subscribers.
Observed descendant identities are captured with PID and creation time, then
checked from a separate R process after the entrypoint exits:3 on Windows,
1 on WSL in the recorded runs. This is explicitly an observed descendant list,
not a claim that all backend internals expose public PID lists. Public pool
shutdown and final global process snapshots complement those checks.

`active-crash-windows` and `active-crash-wsl` submit a real long task before
Ctrl+E; expected exit1 follows cleanup, PID checks pass, and WSL stty restores.
Their traceback files identify the controlled failing callback. No unrelated
process-name kill is used. Failure cleanup targets only the harness's fresh
owned process tree/group. Real absent-native-package startup is separately
tested through library scope in the processx suite; no global uninstall occurs.
Long-duration native handle retention is not resolved or disproven by these
bounded shutdown tests.
