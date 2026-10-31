# E-FIX — Shiny Browser

Both web paths pass all gates: native Windows R server and WSL R server, each
tested with real Chrome via Playwright. This is not an HTTP-start-only test.
`proof-windows/browser-gates/ and proof-web-wsl/browser-results.json` records actual Plotly trace arrays, CPU formula
agreement within1e-10, source identity reset, empty clearing, NA/NaN gaps, loaded
ggplot image, stable widget DOM identity and absence of Shiny output errors.
No page/console/HTTP errors were observed in these final browser runs.

The app uses one model, receiver and cached frame per server, one producer and
one Plotly construction per session. Data changes use the existing example's
acknowledged proxy helpers. Four browser sessions were opened/closed per run.
`gates.json` captures sessions0, observers0 and producer_observers0 after owner
shutdown; no stale receiver lease was accepted as successful cleanup.

Commands: documented `--app=analytics --mode=web` starts the actual server;
`entrypoint-browser.R` drives that command, browser and graceful stop. Run its
`--wsl-server` option from native Windows R for the WSL-server/Chrome bridge.
Raw stdout/stderr, runtime package paths, lifecycle events, browser results and
`analytics-browser.png` are in both web-final directories. Screenshots were
reviewed for visible ggplot/Plotly/table/snapshot content.

Browser controls change only demonstration data. The server does not hold or
control a running TUI, send terminal keys, change terminal focus or implement a
new WebSocket protocol. Terminal and web modes in separate processes instantiate
the same model code but are not claimed to share process-local mutable memory.
These tests use Windows Chrome; no Linux-native, macOS, Safari or Firefox engine
certification is implied. A single lines-only Plotly sample has no line segment;
the final screenshots contain several actual samples.
