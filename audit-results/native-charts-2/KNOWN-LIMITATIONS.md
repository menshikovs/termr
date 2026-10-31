# Known Limitations

- Charts retain their source data in memory. Rendering is viewport-bounded for dense line/scatter data, heatmaps, and bars, but input normalization and storage still scale with source size.
- Histogram construction uses `graphics::hist()` and computes bins before viewport rendering.
- The stream adapter is intentionally limited to line and scatter charts, uses caller-provided synchronous extractors, and caps history and pending callbacks at `max_points`. Each mounted update pass processes at most 16 records; unusually large bursts take several event-loop turns, and the displayed chart catches up when the pending queue drains.
- Queue overflow drops the oldest pending events and marks the next retained event as a line gap. This preserves bounded memory and makes the discontinuity visible; dropped observations cannot be recovered by the chart.
- Headless timings include app/driver and R event-loop overhead and do not predict a specific terminal's interactive latency.
- No native Windows terminal/PTY smoke result was reliably captured during this audit. Headless tests and R CMD check ran; PTY behavior should be checked in CI/manual platform runs.
- macOS was unavailable locally. WSL results are Linux-on-Windows evidence only and are not a native Linux or macOS claim.
- Optional integrations such as `termrcharts` are intentionally not dependencies. If it is attached alongside termr, namespace qualification is needed to disambiguate overlapping constructor names.
- Existing roxygen warnings for the unrelated `Pilot` R6 documentation in `R/testing.R` remain. Chart help topics are generated and R CMD check reports no documentation warning.
