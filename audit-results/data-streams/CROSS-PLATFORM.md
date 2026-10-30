# Cross-platform evidence

Tested on 2026-10-29 in the current environment, not inferred from prior CI.

| Check | Windows R 4.6.1 UCRT | WSL Ubuntu 26.04.1, R 4.5.2 |
| --- | --- | --- |
| Extended full testthat, NOT_CRAN=true | 13740 expectations, 0 failures/errors/warnings, 19 skips | 13865 expectations, 0 failures/errors/warnings/skips |
| Final focused Stream/monitor tests | 5133 expectations, 0 failures/errors, Shiny skip | 5142 expectations, 0 failures/errors/skips |
| 100000 emissions / 10 subscribers | PASS | PASS |
| GC cleanup / seeded history model | PASS | PASS |
| Real system metric sampling | PASS | PASS |
| Independent collector/TUI processes, close/restart | PASS | PASS |
| Independent Shiny sessions, close/restart | NOT RUN: shiny absent | PASS |
| 300 concurrent snapshot reads | PASS | PASS |
| Collector stop / stale consumer state | TUI PASS | TUI and Shiny PASS |
| Actual Shiny runApp, loopback HTTP | NOT RUN: shiny absent | PASS, dashboard HTML at 127.0.0.1:3838 |
| bench and Rprof | PASS, 10 ms profiler | PASS, 10 ms profiler |
| Full installed-package R CMD check, --no-manual | Status: OK | Status: OK |
| Latest package check, focused Stream/monitor tests | Status: OK | Status: OK |
| New manual terminal/browser smoke | NOT RUN | NOT RUN |

Full suite logs precede the final two additional snapshot-access assertions;
final focused tests cover the final implementation. Full installed-package
R CMD check and final targeted installed-package verification are recorded
separately in TEST-RESULTS.md.

Windows lacks optional DBI/RSQLite/Shiny; WSL has them. Windows also skips the
POSIX driver test. Initial Windows validation inherited LC_ALL/LC_CTYPE/LANG
as C.UTF-8, which is invalid for this Windows R and forced ASCII snapshots;
restricted processx pipes also failed. The full suite was rerun successfully
with LC_ALL and LC_CTYPE cleared, LANG=en and approved subprocess execution.
The failing initial run is retained, not presented as a product regression.

WSL requires approved execution because the Windows sandbox denies WSL
service access. All package installs are scratch copies of the current
checkout inside audit-results/data-streams/lib-{windows,wsl}. No global
package installation, system software installation or external network bind.

Snapshot publication always renames a completed temporary file to a fresh
same-directory name. It never relies on replacing an open Windows file.
Readers retry removal races. Prior versions are pruned before publishing;
access failures stop new publication rather than allowing unbounded files.
The integration ran using the same directory on each tested platform; it
does not certify every network filesystem or cross-OS shared mount.

Interactive Windows console, SSH, tmux, screen, RStudio Terminal and macOS
remain outside this run. Existing platform/CI claims are documented in
docs/platform-testing.md; this report does not turn them into new evidence.
