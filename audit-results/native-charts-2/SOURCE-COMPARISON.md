# Source Comparison

Compared local `2.0-termr` (`1b10370d1df50e54a63706673b150feaf7b04889`) with local ref `feature/core-charts-1.1` (`a3d6178647569dc586371c02ea5316041810a5d6`), based on their common ancestor `d6ca75ea3e23c9320146602b9b790b4b91b16e92`. The feature ref matched its local `origin/feature/core-charts-1.1` tracking ref. Network fetch was unavailable through the configured proxy, so this report makes no claim of a fresh remote fetch. See [ARCHITECTURE.md](ARCHITECTURE.md) and [WORKTREE-BASELINE.md](WORKTREE-BASELINE.md).

## Migrated chart modules

The feature ref had 22 `R/chart-*.R` files. All were brought over. `R/chart-api.R` was adapted with stream API documentation and `R/chart-widget.R` was adapted for 2.0 lifecycle cleanup and stream queue scheduling. The remaining 20 chart modules were copied without implementation changes. `R/chart-stream.R` is new integration code; there was no chart-stream module on the feature ref.

| File(s) | Disposition |
| --- | --- |
| `R/chart-annotations.R` | Copied unchanged |
| `R/chart-api.R` | Adapted documentation for stream binding; constructor implementation retained |
| `R/chart-compose.R` | Copied unchanged |
| `R/chart-glyphs.R` | Copied unchanged |
| `R/chart-heatmap-api.R` | Copied unchanged |
| `R/chart-hit.R` | Copied unchanged |
| `R/chart-labels.R` | Copied unchanged |
| `R/chart-layout.R` | Copied unchanged |
| `R/chart-pack.R` | Copied unchanged |
| `R/chart-plan.R` | Copied unchanged |
| `R/chart-registry.R` | Copied unchanged |
| `R/chart-roles.R` | Copied unchanged |
| `R/chart-scales-axis.R` | Copied unchanged |
| `R/chart-scales.R` | Copied unchanged |
| `R/chart-surface.R` | Copied unchanged |
| `R/chart-types-bars-multi.R` | Copied unchanged |
| `R/chart-types-bars.R` | Copied unchanged |
| `R/chart-types-heatmap.R` | Copied unchanged |
| `R/chart-types-xy.R` | Copied unchanged |
| `R/chart-utils.R` | Copied unchanged |
| `R/chart-validation.R` | Copied unchanged |
| `R/chart-widget.R` | Adapted for stream binding, bounded queue, and 2.0 widget lifecycle |
| `R/chart-stream.R` | New; connects existing termr streams to line/scatter widgets |

## Other feature-branch artifacts

| Feature artifact | Disposition |
| --- | --- |
| `tests/testthat/test-native-charts.R` | Copied unchanged |
| `inst/examples/native-charts-dashboard.R` | Copied unchanged |
| `docs/charts.md` | Migrated and updated with stream batching, package API, and example guidance |
| Five chart Rd topics | Generated from roxygen; no hand edits |
| `NAMESPACE` chart exports | Generated from roxygen |
| `docs/api-inventory.md` | Updated for five public constructors |
| `tools/bench/bench-native-charts.R` | Reworked into a two-source, same-process-isolated benchmark; stream measurement drains all event-loop chunks |

Additional C1 files are `inst/examples/native-charts-static.R`, `inst/examples/native-charts-stream.R`, `tests/testthat/test-chart-streams.R`, and the C1 audit reports. No feature-branch artifact was deliberately excluded as obsolete. Existing user work recorded in the baseline report remains present.
