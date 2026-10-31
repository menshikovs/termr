# Phase E — Bug Findings

Counts:0 confirmed new core defects requiring a source fix;1 confirmed functional
application defect reproduced failing-first and fixed;0 known open P0/P1 in the
tested scenarios. Additional application integration refinements and harness
issues are separated from that defect count. One open P2 native backend resource
trend remains; absence of an orphan worker is not absence of all leaks.

| Finding | Class/severity | Reproducer/evidence | Resolution/status |
| --- | --- | --- | --- |
| APP-01 reserved shortcut collisions | Application/P2 | Focus DataTable then former F3/Ctrl+G shortcuts; `apps-failing-first.log` has 3 failed expectations and exit 1 | Alt+S source and Alt+C chart/focus; final83 app expectations pass on both OS and real PTY |
| INT-01 delayed frame after Shiny action | Application integration refinement | Existing periodic receiver initially delayed updates; testServer checks immediate frame agreement | Explicit public receiver poll in action callbacks; browser/testServer agreement pass; no core change |
| TEST-01 suspended receiver observer | Test-oracle error | sessions 0 but observer 1 until owner closes | Assert suspended lease lifecycle, then owner close→0 |
| TOOL-01 PTY output starvation/Escape | Harness | Saved initial PTY timeout; editor consumes Escape | Continuously drain output; semantic waits and focus handling; final4 PTY cases pass |
| TOOL-02 processx timeout/environment | Harness | Early process results fail/timeout | Correct seconds vs milliseconds; inherit current environment; all10 final cases pass |
| TOOL-03 fragmented stdout marker | Harness | Windows `CHILD` and PID arrived in separate reads | Concatenate bytes without injected newline; atomic fixture marker; owned cleanup passes |
| TOOL-04 multiline Rprof debug label | Profiler interoperability | Raw Shiny profile fails summaryRprof memory parser | Preserve raw; normalize continuations in derived copy; zero dropped samples; final profiles pass |
| TOOL-05 rtop recording errno61 | Recorder/environment transient | Earlier recording result FAIL | Separate retry and final all-app recording PASS; no silent retry relabeling |
| BACKEND-01 Windows native handle retention | Optional backend/P2 open |15 fresh profiles via direct mirai, pool and model in separate processes | Direct mirai alone reproduces ~2 handles/cycle after warmup; document for H4/upstream; no speculative core patch |
| ENV-01 unavailable Windows typed packages/console | Environment limitation | Package inventory and platform matrix | Honest SKIP/NOT RUN; WSL supplies corresponding supported tests |

Preventive app refinements (scrollable actions, preserving task cursor during
refresh, live timestamps, one-point ggplot handling and favicon) are not counted
as independently confirmed termr bugs. No new user-data eval/parse, scheduler,
protocol or API shim was introduced to hide a failure.
