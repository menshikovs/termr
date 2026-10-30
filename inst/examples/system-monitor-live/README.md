# Live system monitor: collector + termr + Shiny

This is a new minimal real monitor. The existing `system-monitor.R` example
uses synthetic data and remains unchanged. All scripts use installed,
documented termr APIs; install the current checkout before running them.

The collector uses ps (already a termr dependency). JSON publication requires
optional jsonlite; only the dashboard requires optional shiny. No Plotly,
ggplot2, nanonext or mirai is required. If needed, install R packages with
`install.packages(c("jsonlite", "shiny"))` yourself.

## Optional live nanonext transport

File mode remains the default. Live mode additionally needs optional
`nanonext >= 1.10.0` and jsonlite. Install the current checkout after installing
those R packages. Both transports can publish simultaneously without another
metrics collector. The adapter and both consumers poll on their ordinary R
thread; no network callback executes user R from a native thread.

PowerShell, four separate terminals in the checkout:

```powershell
# Terminal 1: one independent collector publishes both channels
$env:TERMR_METRICS_TRANSPORT = 'both'
$env:TERMR_METRICS_ENDPOINT = 'tcp://127.0.0.1:5555'
$env:TERMR_METRICS_SNAPSHOT_ENDPOINT = 'tcp://127.0.0.1:5556'
Rscript inst/examples/system-monitor-live/collector.R C:/temp/termr-metrics

# Terminal 2: live TUI (set these variables in each client terminal)
$env:TERMR_METRICS_TRANSPORT = 'nano'
$env:TERMR_METRICS_ENDPOINT = 'tcp://127.0.0.1:5555'
$env:TERMR_METRICS_SNAPSHOT_ENDPOINT = 'tcp://127.0.0.1:5556'
Rscript inst/examples/system-monitor-live/tui.R C:/temp/termr-metrics

# Terminal 3: same client environment, optional Shiny
Rscript inst/examples/system-monitor-live/shiny-app.R C:/temp/termr-metrics

# Terminal 4: same client environment, independent R subscriber
Rscript inst/examples/system-monitor-live/subscriber.R C:/temp/termr-metrics
```

WSL Ubuntu, separate terminals with Linux paths:

```sh
# Collector terminal
TERMR_METRICS_TRANSPORT=both TERMR_METRICS_ENDPOINT=tcp://127.0.0.1:5555 \
TERMR_METRICS_SNAPSHOT_ENDPOINT=tcp://127.0.0.1:5556 \
Rscript inst/examples/system-monitor-live/collector.R /tmp/termr-metrics

# In each client terminal, then launch one client per terminal:
export TERMR_METRICS_TRANSPORT=nano
export TERMR_METRICS_ENDPOINT=tcp://127.0.0.1:5555
export TERMR_METRICS_SNAPSHOT_ENDPOINT=tcp://127.0.0.1:5556
Rscript inst/examples/system-monitor-live/tui.R /tmp/termr-metrics
Rscript inst/examples/system-monitor-live/shiny-app.R /tmp/termr-metrics
Rscript inst/examples/system-monitor-live/subscriber.R /tmp/termr-metrics
```

Choose `TERMR_METRICS_TRANSPORT=file` for a file consumer, `nano` for a live
consumer, and `file`, `nano` or `both` for the collector. Missing nanonext never
disables file mode. Ctrl+C/q closes only that owner; STOP still gracefully
stops the collector using the directory argument. A late or restarted live
client obtains current state from the separate snapshot endpoint, detects
sequence gaps and periodically resynchronizes. It cannot replay every missed
event. The transport envelope wraps the unchanged file metrics schema.

Live TUI and Shiny poll every 50 ms; collector services transport between
samples at up to 20 ms intervals. Snapshot requests allow 3 seconds for a
busy metrics collector. A blocking system API or slow user callback still
delays its own process. Heartbeats indicate transport freshness; payload
timestamps independently mark stale measurements. Keep a reasonable sampling
interval (default one second) rather than busy-looping the collector.

Endpoints bind only 127.0.0.1; there is no authentication, encryption or remote
control. Local peers are not authenticated. This is not an open-network
monitor. Windows/WSL localhost forwarding is host-specific; tests here verified
WSL publisher -> Windows subscriber including restart, but Windows publisher
-> WSL localhost did not connect. No non-loopback workaround is enabled.

See [nanonext API/protocol](../../../docs/nanonext.md) for JSON limitations,
queue/byte limits, ownership and consistency guarantees.

## Windows PowerShell

From the repository root, install the package with `R CMD INSTALL .` using
your R installation on PATH. Open three terminals in the same checkout:

```powershell
# Terminal 1
Rscript inst/examples/system-monitor-live/collector.R C:/temp/termr-metrics
# Terminal 2
Rscript inst/examples/system-monitor-live/tui.R C:/temp/termr-metrics
# Terminal 3, a separate R process
Rscript inst/examples/system-monitor-live/shiny-app.R C:/temp/termr-metrics
```

Open <http://127.0.0.1:3838>. Only loopback is bound. The TUI requires a real
terminal; press q to close it. Ctrl+C stops collector or Shiny independently.
For graceful collector shutdown from another terminal:

```powershell
New-Item C:/temp/termr-metrics/STOP -ItemType File
# Remove STOP before starting a new collector:
Remove-Item -LiteralPath C:/temp/termr-metrics/STOP
```

## WSL Ubuntu

Use the WSL R installation and install this checkout there separately. Open
three WSL terminals in the checkout and use Linux paths:

```sh
R CMD INSTALL .
Rscript inst/examples/system-monitor-live/collector.R /tmp/termr-metrics
Rscript inst/examples/system-monitor-live/tui.R /tmp/termr-metrics
Rscript inst/examples/system-monitor-live/shiny-app.R /tmp/termr-metrics
# Graceful stop, from a fourth terminal:
touch /tmp/termr-metrics/STOP
```

Windows `C:/temp/termr-metrics` and WSL `/tmp/termr-metrics` are different
directories. For deliberate cross-OS sharing, use `C:/temp/termr-metrics` on
Windows and `/mnt/c/temp/termr-metrics` in WSL, with exactly one writer.
Filesystem guarantees on network shares/WSL mounts need separate validation.

Instead of the first argument, set `TERMR_METRICS_DIR` in all three processes.
The default is the same per-user termr cache/metrics directory within one OS,
obtained with `tools::R_user_dir("termr", "cache")`. Explicit paths are easier
to diagnose. The optional second collector argument bounds the sample count,
e.g. `Rscript collector.R /tmp/termr-metrics 10`.

## Data and lifecycle

The collector samples cumulative **system** CPU times and memory once per
second. CPU is the busy fraction between samples (Linux iowait counts as idle;
guest counters are not double-counted). The first CPU value is unavailable.
RAM is `(total - available) / total`. A sample of at most 100 PIDs (collector
first, then descending PIDs), sorted within the sample by RSS, includes PID,
name and RSS bytes when available. It is not a full system process ranking.
Collection is bounded before querying metadata, avoiding full ps::ps() scans
that can block the publisher for seconds on Windows. Process access races
or platform permission errors produce null fields or an unavailable reason,
never fabricated metrics. The TUI shows the largest 12 processes.

Snapshots are immutable JSON versions, written to `.pending-*`, closed, then
renamed in the same directory. Readers ignore pending files. Publication is
limited to one per second, the last three versions are retained, and reads
retry if cleanup removes a selected version. The `.writer-lock` directory
prevents two collectors. After a hard kill, confirm the old collector has
stopped and remove **only** its `.writer-lock` directory before restart.
Ordinary exit/interrupt releases the lock. Power-loss durability is not promised.

Schema version 1 has `schema_version` (integer 1), `source_id` (unique per
collector run), `sequence` (positive integer-valued number), `timestamp`
(publication observation end), `collected_at` (observation start), and
`metrics`. Times are Unix seconds UTC. `metrics` contains `cpu` and `ram`
(percent or null), `processes` (up to 100 `{pid, name, rss}` records), and
`unavailable` (field names mapped to reasons). JSON has no executable payload.
Readers validate the schema and reject files larger than 2 MiB. This is a
local, single-writer prototype, not an authenticated remote protocol.

Each consumer has its own latest snapshot and bounded 120-event history.
Shiny polls every 500 ms and plots CPU/RAM; TUI polls every second. After five
seconds without updates the source becomes stale even if no file changes.
Missing/invalid snapshots show a status and preserve the last known values;
the next valid publication restores live status. Restarting the collector
changes source_id and resets client history. Restarting a consumer starts a
new local history and does not affect collection or another consumer.

This channel carries latest state, not every event. A `missed` counter counts
sequence gaps observed after the first sample; slow consumers may skip
samples. A backward sequence within one source is invalid. Publication errors
appear as Stream callback warnings on collector stderr. Check path agreement,
permissions, STOP, lock ownership, source status, clock agreement and sequence
gaps when diagnosing data loss. Timestamp more than five seconds in the
future is rejected. Keep the directory on a local filesystem.

For programmatic/headless use, source `tui.R`, call `demo <- monitor_tui(path)`,
use `termr::test_app(demo$app)`, and always call `demo$close()` in cleanup.
The script entry point does this automatically on exit/error. Sourcing
`shiny-app.R` defines `monitor_shiny(path)` and `monitor_server(path)` without
starting a server. No UI launches, stops or owns the collector.

## Full dashboard and ggplot history

Install this checkout, then install optional `shiny`, `ggplot2`, `plotly` and
`htmlwidgets` for all chart modes. The full dashboard also works with Shiny
alone in base mode. In separate R terminals, from this repository:

```sh
Rscript inst/examples/system-monitor-live/collector.R /tmp/termr-metrics
Rscript inst/examples/system-monitor-live/dashboard.R /tmp/termr-metrics auto
Rscript inst/examples/system-monitor-live/ggplot_history.R /tmp/termr-metrics 10 /tmp/termr-charts
```

On Windows use an explicit local directory such as `C:/temp/termr-metrics` in
each command. `dashboard.R` serves only `127.0.0.1:3838`. Its modes are `auto`,
`base`, `ggplot` and `plotly`; unavailable explicitly requested modes error.
Auto prefers Plotly, then ggplot2, then base graphics. The existing
`shiny-app.R` remains the simple fallback. `TERMR_HISTORY_POINTS` sets the full
dashboard capacity (2..10000; default 600); the slider selects a smaller view.
`TERMR_DASHBOARD_POLL_MS` sets the dashboard poll interval (default 500 ms);
each revision batches retained observations. The generic Shiny receiver API
defaults to 50 ms. Choose a slower dashboard interval when many sessions render
charts: reactive fanout shares R's single thread with HTTP handling.
The ggplot history script writes CPU, RAM and comparison PNGs after a finite
collection period, independently of Shiny.

For nanonext, set these variables in the collector and consumers (PowerShell:
`$env:NAME='value'`; bash: `export NAME=value`):

```text
TERMR_METRICS_TRANSPORT=nano
TERMR_METRICS_ENDPOINT=tcp://127.0.0.1:5555
TERMR_METRICS_SNAPSHOT_ENDPOINT=tcp://127.0.0.1:5556
```

The collector also accepts `both`; consumers choose `file` or `nano`. The
collector remains one independent process. The dashboard creates one shared
connection/receiver outside `server`, one poll observer and one bounded frame
conversion per revision, regardless of session count. Every session has its
own chart cursor/window. App shutdown closes the receiver/source; closing a
single browser only releases that session's lease. With no sessions polling
is suspended. Reopening a browser recovers the latest state, not missing history.

The UI labels stale/invalid/reconnecting data and reports sequence gaps and
last measurement time. Plotly uses true `extendTraces` for contiguous data and
explicit replacement for initial load, gaps, source changes or window changes.
Trace arrays and retained history are bounded; missing values are not zeros.
Each browser acknowledges finished updates, allowing at most one graph command
in flight per session and coalescing new observations while a slow tab renders.
ggplot2 mode rebuilds ordinary static plots. See [Shiny](../../../docs/shiny.md),
[data frames](../../../docs/data-stream-visualization.md) and
[Plotly](../../../docs/plotly.md) for lifecycle and version limits.

These are local loopback prototypes without authentication. In WSL, localhost
connectivity is directional and depends on host networking. Windows-to-WSL
publication was unavailable in this environment; do not change firewall or
bind a public interface as a workaround. Use one OS or the validated WSL
publisher/Windows subscriber direction when available.
