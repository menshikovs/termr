# Real browser validation

Playwright Chromium drove an actual loopback Shiny app and independent actual
system-metrics collector. Synthetic core load tests are separately labelled.

Validated:

- Initial bounded history, two named CPU/RAM traces; zero-based proxy indices
  0/1; array shape preserved for a single point; maxPoints honoured.
- Ordered data produces actual Plotly.extendTraces calls. Initial/gap/source/
  window resynchronization uses explicit restyle, not claimed as incremental.
- 1, 5 and 20 tabs receive data from one process-level receiver/observer and
  independent collector. Final 20-tab data and acknowledgement counts are in
  browser-20-batched-10hz.json; two traces per tab <=50, unique source:sequence
  keys excluding explicit gap separators. Configured collector interval is
  0.1 s plus sampling cost; actual rate is reported in PERFORMANCE.md.
- Closing 19 tabs releases their leases. After closing the last tab sessions
  reach zero, poll count stops increasing, shared driver is suspended. Explicit
  app shutdown destroys it (browser-shutdown-wsl.json / -windows.json).
- Collector stopped gracefully: stale/reconnecting status and cached-value
  label appear. Restart changes source_id, clears old source keys, replaces
  history once and resumes extension. No missing history is fabricated.
- Window input changed to 20: both traces reduced to <=20 by full replacement.
- Actual ggplot2 and base PNG outputs rendered; switching back recreates Plotly
  and performs initial history synchronization. Screenshots plotly-stale.png
  and ggplot-live.png were visually inspected. ggplot_history.R produced and
  saved CPU/RAM/comparison PNGs from real samples.
- Acknowledgement deliberately withheld: source sequence advanced 547→549
  while extension count stayed 37; releasing it resumed delivery. slow-browser.json.
- Final error-level browser console capture: 0 errors (browser-console-complete.txt).

Current browser/native typed arrays are required by this owned example widget.
The legacy redundant typedarray dependency is omitted without editing Plotly.
The complete CRAN Shiny scratch installation fixes a pre-existing system asset
filename mismatch. Early baseline console failures are retained in older raw
artifacts, not presented as current success.

Browser timing uses Plotly promise + two animation frames, not GPU timestamps.
The final one-tab reload after closing the other 19 succeeded and initial
50-point history completed in 811 ms on that observation. See PERFORMANCE.md
for distributions and background-tab constraints. A 50 ms dashboard baseline
did overload this environment; 500 ms batching is the shipped example default.
