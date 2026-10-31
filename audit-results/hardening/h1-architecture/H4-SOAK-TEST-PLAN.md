# H4 bounded soak plan

This is a plan, not an executed long-duration validation result. Resolve F01,
F02, F08 and the chosen F03 policy before treating their soak cases as gates.

| Scenario | Controlled workload / deadline | Ownership and leak criterion |
|---|---|---|
| App lifecycle | 1000 mount/start/stop cycles; inject mount/handler errors every 10 cycles; 10 min cap | active App registry returns exactly to baseline, driver stopped, no owned processes/timers |
| Native charts + stream | 30 min, fixed seed 20261031, <=100 events/s, <=1 KiB/event, history/max_points 1000; bounded bursts 2000 | subscribers return to baseline after unbind/unmount; queue <=max_points; documented gaps and visible frame cadence; no linear retained heap growth |
| SQLite table/source | 100k seeded rows; 500 source swaps, 10% controlled failures; bounded 100-row pages | cache <=32, old source intact after rejection, all owned connections invalid at cleanup, borrowed ones valid |
| R-code export | 1000 bounded edit/filter/sort/selection cycles, values <=1 KiB, output <=1 MB | generated exact output equals model; ledger <=1000; limits fail closed without retaining prior selected data |
| Mirai/processx | 30 min, 2 workers, max_pending 16, results <=1 MB; explicit 10 s task timeouts + 5 s teardown grace | active native/task count returns to baseline; no descendant processes/temp files after close; caller-retained results excluded from leak total |
| Nano/Shiny | 30 min, 2 sessions, receiver 600 points, socket buffers 64, message <=16 KiB; disconnect/restart every 1000 messages | one shared subscription/observer, lease count exact, owner close clears native sockets/AIO; borrowed source stays open |
| Styles/selectors | 10k controlled class/focus changes and <=5k unique selector strings; 10 min cap | inkr <=4096 entries; selector-cache growth separately attributed; unmount no widget retained by cache values |
| PTY/resize/input | 10 min, finite recorded key batches and terminal sizes 1x1..120x40, no unbounded flood | ordered focus/press markers, restored termios/modes, normal or explicitly injected exit status |

Warm up first, then sample retained R heap after GC, RSS high-water, resource
counts and latency. RSS growth alone is not a leak verdict: require monotonic
retained-object/native-resource evidence under a fixed bounded workload.
Abort on budget/timeout, preserve seed/logs, cancel only owned resources and
restore the terminal in finally/on.exit. Use isolated temporary databases,
directories and loopback endpoints; never manipulate unrelated user resources.
