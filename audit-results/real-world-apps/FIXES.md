# Phase E — Fixes

APP-01 root cause: workbench global bindings reused keys already consumed by a
focused DataTable (F3 find-next and Ctrl+G goto). Bindings moved to Alt+S and
Alt+C; chart activation also focuses its line chart. No DataTable default binding
was changed. Three failing-first expectations and exit 1 are retained; final
headless tests and real keyboard/PTy scenarios validate the fix on the public API.

The analytics app explicitly polls its shared receiver after browser actions,
so frame/table/snapshot/Plotly state updates in the same reactive flush. It uses
one cached frame and one widget per session; owner cleanup destroys observers.
Other app changes preserve cursor position when real task rows refresh, put
buttons in a scrollable tab for narrow screens, use current timestamps and omit
a ggplot line for a single point. A data favicon avoids a cosmetic browser404.

Harness fixes address buffer draining, modal Escape semantics, baseline-owned
process counting, processx timeout units/env inheritance and fragmented stdout.
Profiler normalization is confined to a derived artifact. These changes neither
weaken core assertions nor modify terminal input/worker backend behavior.

Code paths are in `integration-apps/` and `tools/integration/`; public R source,
NAMESPACE and man files remain unchanged relative to the initial hashes.
Observed H2 test differences are explicitly retained and archived, not attributed
to an invented core fix. Packaging exclusions keep demo dependencies, runtime
data and the pre-existing recording out of the distributable tarball.

No speculative fix was made for the Windows handle trend: direct mirai reproduces
it without termr, so causal/native ownership work is handed to H4. Both package
checks pass with no warning suppression/global-variable declarations.
