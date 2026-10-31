# Phase E applications

Run from the termr checkout root with R >= 4.1. These applications use exported
APIs and are excluded from the installed package and source tarball. Apps load
the installed checkout from `.deps/current-windows` or `.deps/current-linux`.
Source/payload fingerprints reject stale builds; no global/pkgload fallback is
used. The old TERMR_USE_INSTALLED flag no longer changes the application loader.
After changing package R code, reinstall with `Rscript tools/integration/install-current.R`.
UTF-8 app files are read explicitly. If Windows R inherited an unsupported locale
and fell back to C, bootstrap selects supported UCRT UTF-8 character handling
inside that Rscript process. It does not edit user/system locale settings.

```sh
Rscript integration-apps/run.R --app=showcase --mode=terminal
Rscript integration-apps/run.R --app=analytics --mode=terminal
Rscript integration-apps/run.R --app=analytics --mode=web
Rscript integration-apps/run.R --app=monitor --mode=terminal
```

On this Windows machine Rscript is not on PATH. In PowerShell use:

```powershell
& 'C:/Program Files/R/R-4.6.1/bin/Rscript.exe' integration-apps/run.R --app=showcase --mode=terminal
```

Terminal mode needs an attached interactive terminal. Use `--mode=headless` for
a scripted smoke test; its text output does not certify terminal behavior.
Web mode prints a loopback URL; open it in a browser. Stop with Ctrl+C. It creates
read-only terminal snapshots rather than controlling a running TUI.

In VS Code use **Terminal → New Terminal**. The TUI paints this terminal; it
does not open a separate window. The Output panel is not a terminal host. Web
mode prints the address: open that address in a browser (no browser auto-launch).
For Windows launch from any directory:

```powershell
& 'C:/programming_pj/r_textualize/integration-apps/launch.ps1' -App showcase
& 'C:/programming_pj/r_textualize/integration-apps/launch.ps1' -App analytics -Mode web
```

## Dependencies and installation

`DESCRIPTION` remains the package dependency source of truth. No Phase E
dependency is mandatory for base termr. Application requirements are:

| Application | Optional packages used |
|---|---|
| Showcase | inkr for styles; bit64, units, haven, vctrs for typed fixtures |
| Analytics terminal | base termr stream/chart APIs |
| Analytics web | shiny, ggplot2, plotly, htmlwidgets, jsonlite, httpuv |
| Distributed monitor | mirai, nanonext, jsonlite |
| Automation | testthat, pkgload, processx, ps; analysis uses covr/lintr/profvis |

Bootstrap prepends `integration-apps/.deps/R-windows` or `.deps/R-linux` when
present. Project libraries, the isolated baseline and upstream checkout are
ignored by Git. Do not copy a Windows package library into Linux. Install only
into the relevant project directory, for example:

```r
lib <- file.path("integration-apps", ".deps", if (.Platform$OS.type == "windows") "R-windows" else "R-linux")
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
install.packages(c("shiny", "ggplot2", "plotly", "mirai", "nanonext"), lib = lib)
```

Source installations may require system compilers/libraries (e.g. units requires
UDUNITS). The showcase omits unavailable typed fixtures and falls back to termr's
dark/light themes without inkr. The monitor fails before startup with an explicit
list of missing dependencies. Phase E installed no global packages and changed
no version metadata. Exact versions/paths are in the audit package inventories.

## Workbench controls

F2 cycles cars/iris/typed; F11 switches local/lazy (10,000 synthetic rows).
F4 switches dark/light; F5 applies the sidebar threshold; F6 opens the native
cell editor; F7 selects three rows; F8/F9 show Copy as R value/pipeline; F10 adds
a stream sample. F12 focuses charts, Alt+T shows types, Escape returns to data,
q quits. Use Tab/Shift+Tab to reach buttons and inputs. Native DataTable shortcuts
provide find, navigation and sorting. Narrow layouts hide the sidebar below
70 columns, preserving keyboard actions. Charts and controls remain in tabs.

Edits use the existing typed editor and preserve supported column semantics.
Unknown S3/vctrs fixtures remain read-only according to termr's handlers. A4 code
is shown and copied to the application's clipboard (`system=FALSE`); no arbitrary
code is evaluated. Dataset charts summarize finite original dataset values,
not a claim of charting the current filtered table. Stream history is bounded to 64.

## Analytics controls and ownership

Terminal: F2 sample, F11 alpha/beta source, F4 empty, F5 NA/NaN, q quit. Web
controls update the same deterministic data model: ggplot2, table, Plotly traces
and read-only terminal snapshot share a cached frame. Plotly is initialized once
per session and updated through the existing example's acknowledged proxy path.
Auto sampling is opt-in. Source switch resets sequence identity, empty clears
traces and nonfinite samples become gaps. Each session leases one shared
receiver; the application owner closes producer, receiver and source.

## Distributed monitor controls

n submit, l long task, e controlled failure, c cancel, d disconnect publisher,
r reconnect, F5 refresh, q quit. Tasks/Stream/Actions tabs support narrow screens.
The app uses real mirai workers and existing nanonext transport on OS-allocated
loopback ports. Progress, results/errors, throughput and transport state are
observable. Job count and AIO count are public diagnostics, not an inferred
internal App event queue size. Task retention is capped at 24, event/metric histories
at 128, pending jobs at 8. Closing the owner closes its workers and sockets.
Enter opens task details and the actual completed worker result. Alt+S/Alt+C
remain aliases; F11/F12 are the portable path tested through Windows ConPTY.

## Reproducible automation

```sh
Rscript tools/integration/run-all.R --mode=unit,headless,process --timeout=180
Rscript tools/integration/run-all.R --app=showcase --mode=pty --timeout=180
Rscript tools/integration/run-all.R --mode=legacy,expect,tmux --timeout=180
Rscript tools/integration/run-all.R --mode=browser --timeout=180
Rscript tools/integration/run-all.R --mode=lifecycle,lint,profile,benchmark --timeout=600
Rscript tools/integration/run-all.R --mode=recording --timeout=300
python integration-apps/automation/entrypoint-pty.py --out=audit-results/real-world-apps/e-fix/recheck
```

Use `--out=path` for artifacts. Modes are opt-in; profiling/recording never run
in ordinary R CMD check. The runner records PASS/FAIL/SKIP and exits1 on a failed
task. POSIX-only modes report SKIP on Windows; execute them inside Ubuntu WSL.
Python browser automation uses Playwright and an existing Chrome executable;
override `TERMR_BROWSER_EXECUTABLE` on another machine. Project Python packages
were installed under `.deps/python-windows`; nothing is uploaded.

For coverage run `Rscript tools/integration/run-all.R --mode=coverage --timeout=900`
in WSL. The original `bash audit-results/real-world-apps/run-coverage-wsl.sh` also
separates instrumentation from native worker execution. Coverage
scope and unmeasured branches are documented in `COVERAGE.md`.

rtop requires Linux `/proc`. See `legacy-rtop/README.md` and the compatibility
report. Full validation evidence and limitations are in
`audit-results/real-world-apps/EXECUTIVE-SUMMARY.md`.
