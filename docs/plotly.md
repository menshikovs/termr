# Incremental Plotly dashboard

Install optional `shiny`, `plotly`, `htmlwidgets` and `ggplot2` for all modes of
the [system monitor](../inst/examples/system-monitor-live/README.md). Plotly
and ggplot2 do not become runtime dependencies of termr.

The full `dashboard.R` example creates one empty Plotly widget with two named
CPU/RAM traces. A browser-ready handshake loads retained history through
`plotlyProxy()` / `plotlyProxyInvoke(..., "restyle", ...)`. Subsequent contiguous
events use `"extendTraces"` with zero-based indices `list(0L, 1L)`, two outer
arrays of x/y/customdata, and `maxPoints`. Inner arrays remain arrays even for a
single point. CPU and RAM retain at most the selected history window.

The observer retains a per-session cursor. Reactive bursts send all newer
retained observations in one proxy update. Unchanged data sends nothing; status
timers alone do not redraw. The widget is not rebuilt on each metric event.
Proxy calls run after the Shiny flush to avoid racing widget creation.

Each browser acknowledges completion after the Plotly promise and two animation
frames. The server permits at most one update in flight per session; while a
slow or background tab renders, incoming observations coalesce in the bounded
receiver ring. An acknowledgement sends the latest retained delta or an explicit
history replacement if the cursor fell outside that ring. A tab that never
acknowledges stops receiving graph commands until its widget is recreated;
status and other sessions continue. There is no timer that blindly adds retries.

Initial load, window changes, a new widget, source/generation changes, invalid
data and sequence gaps take a separate bounded full-history replacement path.
They are **not** incremental updates. Empty/new-source snapshots clear old
traces. A reconnect with the same source can extend only when the sequence is
contiguous; otherwise it replaces. Segment boundaries insert null y values
and `connectgaps = FALSE` so lines do not bridge missing data. Gap markers also
count towards `maxPoints`. No browser history replay is invented.

The owned widget omits Plotly R's redundant legacy typedarray polyfill and
targets current browsers with native typed arrays. This avoids a legacy asset
that required an absent `GLOBAL.WebModule` loader in the tested distribution;
no third-party files are modified. Use complete CRAN Shiny assets: a system
Shiny 1.10.0 installation tested here referenced a missing strftime filename;
the workspace-local CRAN Shiny 1.14.0 installation resolved that asset failure.

Set `TERMR_BROWSER_PROBE=1` only for measurement. The optional bounded browser
probe counts actual `Plotly.extendTraces`/`restyle` calls and records completion
after the API promise and two `requestAnimationFrame` callbacks. `browserUpdateMs`
measures that browser stage; `endToEndMs` uses the incoming measurement timestamp.
That is the newest point in each update; earlier points in a batch may wait longer.
It includes transport, R scheduling, websocket and browser work and requires
clock agreement. This is a real browser observation, not a GPU presentation
timestamp. Background-tab throttling and many simultaneous plots increase it.
The probe keeps at most 2000 samples and is off by default.

The audited environment delivered to 20 real browser sessions at 1 Hz with one
receiver and two bounded traces per session. Twenty Plotly tabs at 10 Hz caused
CPU pressure and slow page creation with the original 50 ms dashboard poll.
The example now defaults to a 500 ms poll, batching intermediate observations
into one history revision. The generic receiver API still defaults to 50 ms.
Set `TERMR_DASHBOARD_POLL_MS` for a different example polling interval, allowing
enough time for reactive fanout and browser work. This is not a production
capacity claim.
See `audit-results/shiny-plotly/PERFORMANCE.md` for measured stages and limits.
