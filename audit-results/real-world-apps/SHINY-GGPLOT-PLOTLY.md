# Phase E — Shiny Ggplot Plotly

The web application is real Shiny with ggplot2 rendering, two Plotly traces,
a numeric table, source/timestamp/status and a read-only `render_text()` snapshot.
One producer and one receiver are application-owned; sessions acquire leases
through existing termr Shiny APIs. One reactive frame feeds all views. Actions
explicitly poll the receiver after updating the model to avoid a delayed stale
frame. Source identities reset sequence, empty markers clear traces and NA/NaN
become gaps. Values are deterministic by source and sequence; timestamps are live.

Plotly uses the existing `system-monitor-live/visualization.R` example's bounded
ready/ack/proxy helpers, not a new transport protocol. `renderPlotly` builds once
per session; frame changes use proxy updates. The browser checks DOM identity,
CPU formula agreement within 1e-10, source reset, cleared data, gaps, loaded ggplot
image and absence of Shiny output errors. A single sample has no Plotly line
segment; the final screenshot intentionally contains six samples.

```sh
Rscript tools/integration/run-all.R --mode=browser --timeout=180
```

Chrome 156.0.8078.74 passed the real Playwright browser scenarios.
`browser-visual-final/browser-results.json` records no page/console/HTTP errors;
`analytics-browser.png` was visually reviewed. Four sessions close cleanly.
`browser-lifecycle.json` shows sessions 0, observers 0 and producer_observers 0
after application shutdown. While idle before owner close, the receiver retains
one suspended observer by design; treating it as a leak was a test-oracle error.

The browser never holds a running TUI handle and cannot change its focus, send
keys or execute its commands. Browser controls modify only demonstration data.
No pixel equivalence between ggplot2, Plotly and terminal charts is claimed.
