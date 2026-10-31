# Verification of earlier known issues

| Issue | Fresh result | Evidence / interpretation |
|---|---|---|
| A: combined PTY Tab+Enter | Current baseline passed; final repetitions recorded in TEST-RESULTS | grouped headless/parser path passes; CR preserved by processx; exact current archive installed before PTY |
| B: Windows processx access denied | Reproduced only in sandbox diagnostic; same probe outside sandbox succeeds | probes-windows-before.log vs probes-windows-before-elevated.log; environment issue, not package process bug |
| C: force-Suggests-disabled coverage | Exact package manifests and skip reasons recorded | Native mirai/nano remain missing; not called full coverage |
| D: A2.3 lubridate | No specialized handler/editing; generic S4 readonly display | WSL probe: extension/FALSE for all three classes; three value exports round-trip |
| E: data adapters | SQLite table/query built-ins only | R/datatable-source-sqlite.R, R/datatable-source-query.R; dbplyr/Arrow rejection tests |
| F: inkr overhead | Measured selector-path sensitivity and session insertion allocation | INKR.md and CSV/sample profiles; no broad optimization |
| G: Pilot roxygen | Reproduced in isolated roclet, fixed by internal noRd annotation | roxygen-diagnostics.log and doc-windows.log |
| H: developer runner exit | Controlled failure/error/success return 1/1/0 | verify-test-runner.R uses isolated temporary packages; runner-exit-status.csv |

Earlier B-1 CJK cursor, B-2 scrollbar dirtiness, B-3 wide-edge repaint and B-4
layout diagnostic overflow regressions are still present and pass in current
full suites. They were not counted as newly open H1 bugs.

Earlier S-1 generic count coercion is still reachable through log_events(Inf),
now captured as F09. Tiny Pilot intervals, Ctrl+D interpretation, key-flood
latency and old ConPTY crash hypotheses were not rerun without a new bounded
hypothesis. Forced SIGTERM/SIGHUP cannot be inferred from normal cleanup;
getting-started docs already distinguish forced process termination.

The PTY install guard checks only package version, so matching version 1.0.1
alone would not prove matching source. H1 explicitly installs the recorded
current source archive and records its digest. Old failure logs are historical
evidence, not a current failure verdict or a proven root cause.
