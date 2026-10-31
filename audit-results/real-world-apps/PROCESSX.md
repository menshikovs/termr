# Phase E — Processx

Processx3.9.0 checks run on native Windows and Ubuntu WSL. Final ten cases PASS:
quiet successful exit; separate stderr; exit 7 preservation; bounded timeout;
owned grandchild cleanup; each of the three real app headless processes; explicit
missing-package diagnostic; actual monitor startup without project native
optionals. Outputs, stderr and `process-results.json` are retained in
`final-windows/` and `final-wsl/`.

`process-fixture.R` contains only controlled fixtures. Readiness is required
before inspecting an owned child's creation-time-aware ps handle. Process
cleanup uses processx's owned tree; no system-wide process-name kill is used.
No native backend is mocked in the three real app cases. Missing packages are
tested by separate child library paths, not a global uninstall.

Three harness errors were found and fixed: run() timeout is seconds while
process$wait() uses milliseconds; env overrides need `current` to retain the
Windows environment; streamed stdout must be concatenated without inserting
newlines between chunks. The last issue split `CHILD <pid>` on Windows and
made readiness falsely time out. Atomic fixture writes and correct buffer
assembly fix it. `process-windows-final`/earlier runner logs retain failures;
`process-windows-verified` and the final runner prove the corrected cases.

The unified runner limits task duration, captures stdout/stderr separately,
reports SKIP with a reason, returns nonzero for failure and records exit codes.
Windows process pipes required the managed sandbox's elevated execution path;
no global permission or package setting was changed.
