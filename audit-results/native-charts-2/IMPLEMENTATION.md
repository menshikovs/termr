# Implementation

## Native chart widgets

Added `line_chart()`, `scatter_chart()`, `bar_chart()`, `histogram()`, and `heatmap_chart()` as regular termr `Widget` subclasses. The chart plan, glyph, axis, scaling, hit-testing, and surface modules use the existing widget, layout, focus, paint, theme, and event systems. No alternate renderer or native code was introduced. `graphics` is an explicit Imports dependency for `graphics::hist()`; `termrcharts`, ggplot2, Plotly, and Shiny are not required.

The migrated behavior includes numeric and Date/POSIXct line/scatter axes, log10 scales, missing-value line breaks, annotations, selectable points/bars/bins/cells, grouped and stacked bars, histogram binning, matrix heatmaps, and viewport reduction for dense views. `$update_data()` replaces chart data in place and clears size-specific paint plans and caches.

## 2.0 compatibility work

Charts rely on ordinary widget operations. `SelectionRegion` remains an empty child covering cells affected by a selection change; chart painting respects the content clip. This preserves selection-only dirty repaint and the 2.0 compositor contract. Chart stream subscriptions are registered in the widget's existing reactive cleanup collection and are also released by `on_app_shutdown()`.

## Public documentation and examples

Roxygen generated five chart help topics and exports. Added the interactive chart/table dashboard, a static dashboard, and a live stream example. `docs/charts.md`, README, NEWS, API inventory, and stability notes describe the public surface.

## Defects found and fixed

- A lifecycle regression test caught stream subscriptions surviving app shutdown; chart cleanup now runs from the documented widget shutdown hook.
- A burst benchmark showed that repainting after every chunk repeated chart normalization. Mounted charts now process no more than 16 queued records per event-loop turn, retain accumulated typed chart state between turns, and normalize/repaint once when the pending queue drains. A short widget timer yields between chunks while preserving bounded queue capacity and retained-record order.

See [REACTIVE-INTEGRATION.md](REACTIVE-INTEGRATION.md) and [TEST-RESULTS.md](TEST-RESULTS.md) for behavior and validation evidence.
