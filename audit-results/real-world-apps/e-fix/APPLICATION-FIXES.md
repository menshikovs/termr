# E-FIX — Application Fixes

The existing three applications were repaired in place.

- run.R resolves its own root independently of cwd and keeps the same CLI modes.
- App/helper files are sourced explicitly as UTF-8. Windows bootstrap repairs
  only this process's non-UTF-8 LC_CTYPE to the supported UCRT locale before
  parsing. User/system settings and other locale categories are untouched.
  Correct Unicode is asserted in actual terminal and browser output.
- bootstrap.R loads only `.deps/current-windows/termr` or `current-linux/termr`.
  `source-manifest.R` and `install-current.R` stamp source and installed payload,
  version, R minor and platform; missing/stale/modified builds fail explicitly.
  No implicit install, pkgload fallback, global overwrite or version bump occurs.
- Workbench retains filtering/sorting, typed local editing, A4 and five charts.
  F11 source/F12 charts avoid the observed native Alt delivery issue. Actual
  cell-changed and chart-tab telemetry makes native assertions observable.
- Analytics TUI empties both table and chart, and reconnects its chart binding
  when data returns. Both TUI and web use analytics_model; separate processes
  are not falsely claimed to share one in-memory stream. Web views within a
  server share one frame/model, with existing Plotly proxy helpers.
- Monitor Enter now opens details and displays the real completed result.
  Closure diagnostics check pool/transport/source state and subscriptions;
  optional telemetry records creation-time-aware descendant identities.
- The terminal owner catches errors/interrupts, performs cleanup, then rethrows
  the original condition. Active-task crash tests verify this behavior.
- launch.ps1 provides a concrete Windows entrypoint from any directory.

```powershell
$R = 'C:/Program Files/R/R-4.6.1/bin/Rscript.exe'
& $R integration-apps/run.R --app=showcase --mode=terminal
& $R integration-apps/run.R --app=analytics --mode=terminal
& $R integration-apps/run.R --app=analytics --mode=web
& $R integration-apps/run.R --app=monitor --mode=terminal
```
Run from the checkout root in VS Code **Terminal → New Terminal**. A TUI paints
that terminal rather than opening a separate window. Web mode prints its URL;
open that URL in a browser (automatic browser launch is intentionally disabled).
From any working directory on Windows:
`& 'C:/programming_pj/r_textualize/integration-apps/launch.ps1' -App showcase`.
The launcher was itself run in a native Windows PTY from the system Temp directory;
the interface rendered and q exited0 (`launcher-real-pty.json`).

Reinstall after package source changes only:
`& $R tools/integration/install-current.R`. Current builds are already installed
for both tested platforms. Source R, DESCRIPTION, NAMESPACE, man and user H1/H2/H3
tests were not changed. Complete changed-file evidence is `preservation.json`.
