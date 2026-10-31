# H1 architecture and integration audit — 2026-10-31

The current local development tree has a coherent widget/layout/compositor/driver
boundary and six working additive layers: typed tables, lazy sources, R-code
export, native charts, streams and optional inkr styles. This is not a release
certification. The package still declares version 1.0.1; “2.0” names the local
development programme, not a released package version.

Confirmed defects/documentation issues: P0 = 0, P1 = 3, P2 = 3, P3 = 1.
Six are runtime defects and one is a documentation-generation mismatch.
H1 fixed two P2 defects and the P3 mismatch. Four runtime defects remain open.
A documented chart liveness limitation and an unresolved event-lifecycle policy
are recorded separately and are not included in these defect counts.

| ID | Severity | Finding | H1 result |
|---|---|---|---|
| F01 | P1 | Failed DataTable source replacement corrupts active source state | Open, H2 |
| F02 | P1 | An “exact” pipeline can disagree with the displayed post-edit view | Open, H2 |
| F08 | P1 | Removing an owned SQLEditor loses subsequent App cleanup of its connection | Open, H2 |
| F05 | P2 | Failed Pilot startup retains a running/registered App | Fixed and regression-tested |
| F06 | P2 | Source projection cache aliases legal column names containing CR | Fixed and regression-tested |
| F09 | P2 | Non-finite log capacity is accepted, then fails during startup | Open, H2 |
| F07 | P3 | Internal Pilot triggers spurious roxygen R6 diagnostics | Fixed with explicit noRd |

Five principal remaining risks are failed source transactions (F01), false exact
exports (F02), owned DBI resource disposal after unmount (F08), chart display
starvation during a sustained backlog (F03, documented design limitation), and
the unexecuted native mirai/nanonext lifecycle paths (U01, coverage gap).
F04 shows delivery to an ancestor detached earlier in the same event; its
intended mid-dispatch contract needs a decision before calling it a defect.

Period/Duration/Interval have generic read-only display and working bounded
value export in the tested WSL samples, but no specialized A2.3 editor/DST
implementation. Built-in lazy adapters are SQLite table and SQLite query;
other DBI drivers require callbacks. DuckDB/dbplyr/Arrow adapters are absent.

Read FINDINGS.md for reproduction and evidence, TEST-RESULTS.md for fresh
Windows/WSL results, and the H2/H3/H4 plans for executable next steps.
No commit, push, release, package-version change or dependency update occurred.
