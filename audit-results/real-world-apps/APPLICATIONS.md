# Phase E — Applications

```sh
Rscript integration-apps/run.R --app=showcase --mode=terminal
Rscript integration-apps/run.R --app=analytics --mode=terminal
Rscript integration-apps/run.R --app=analytics --mode=web
Rscript integration-apps/run.R --app=monitor --mode=terminal
```

| Application source | Behavior |
| --- | --- |
| integration-apps/01-termr-showcase/app.R | Data Workbench: cars/iris/typed fixtures, filter/sort/find/select, supported safe edits, local/lazy 10k switch, type metadata, A4 value/pipeline dialogs, five native charts, bounded stream, inkr styles and fallback |
| integration-apps/02-shiny-visual-analytics/app.R | Standalone TUI plus real Shiny/ggplot2/Plotly/table/status/read-only terminal snapshot sharing deterministic values |
| integration-apps/03-mirai-nanonext-monitor/app.R | Real local workers, controlled success/failure/cancellation, progress and results, bounded metrics transported through nanonext, disconnect/reconnect and shutdown |

New support files include `integration-apps/bootstrap.R`, `run.R`, two `.inkr`
stylesheets, application tests, legacy fixtures/driver wrapper, automation scripts
and `tools/integration/run-all.R`. Existing-file change intentionally made by
Phase E is `.Rbuildignore`; separately observed H2 test changes are documented
under WINDOWS-WSL.md. There are no new public exports or dependencies in DESCRIPTION.

Workbench: F2 dataset, Alt+S source, F4 theme, F5 filter, F6 edit modal, F7
selection, F8/F9 A4, F10 sample, Alt+C charts, Alt+T types, Escape data, q quit.
Sidebar inputs/buttons are keyboard reachable; below 70 columns it hides and
shortcuts remain. Custom unknown S3/vctrs columns follow read-only type handlers.
Fixtures are conditional: Windows lacks units/haven/bit64; WSL exercises them.
Charts summarize finite original dataset values; filtered-table chart linkage
is not claimed. Stream history 64 and chart max_points 64 bound memory.

Analytics terminal: F2 sample, Alt+S source, F4 empty, F5 nonfinite. Web uses its
own controls, not terminal keystrokes. Monitor: n/l/e/c/d/r/F5/q with task details,
progress and narrow-screen action tabs. All app owner cleanup is idempotent.
No new scheduler, binary protocol, custom unit system or C/C++ code was added.

Automated app tests, real headless subprocesses and PTY input validated these
behaviors. See TESTTHAT.md and PEXPECT-EXPECT.md for scope and evidence.
