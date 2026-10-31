# Phase E — Coverage

covr 3.6.5 was actually run in Ubuntu. Core line coverage: 79.0439%.
Three application files: 92.0705%. Raw RDS, public data.frame
CSV, Cobertura XML and local HTML reports are in `coverage/` (`core.html`,
`apps.html`, with `lib/` assets). Branch coverage is **not measured** by this
line-instrumented run; it is not inferred from assertion counts.

Core instrumentation uses normal Linux libraries, deliberately excluding the
project-only inkr/mirai/nanonext installations. Their unexecuted lines remain
in the denominator; no core file/function exclusion inflates the percentage.
Native cross-process R bodies cannot carry the parent's covr counter registry.
Normal tests independently exercise those real optional backends.

Application instrumentation does use real workers/sockets. Its worker body is
the identical uninstrumented `monitor_work` copy; its lines remain uncovered,
while controllers, UI and lifecycle are instrumented. This is explicitly not
coverage of a remote R process's CPU workload. Core/full test coverage and
application coverage have separate scopes and are not averaged together.

Function-label hit coverage from covr's exported `functions` field:
core 1527/1735 = 88.01%;
apps 7/8 = 87.50%.
A distinct(file,function label) counts hit if any instrumented expression ran;
nested/anonymous/R6 labels may be grouped. This is entry/hit coverage, not full
function-path coverage. `*-functions.csv` and `function-summary.json` document it.

Commands: `bash audit-results/real-world-apps/run-coverage-wsl.sh` then
`python3 integration-apps/automation/coverage-functions.py`. Both coverage exit
files contain0. This single-platform coverage run is not a Windows covr claim.
