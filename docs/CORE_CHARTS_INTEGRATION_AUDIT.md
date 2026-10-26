# Native charts integration audit

## Scope and source baseline

- `termr`: feature branch `feature/core-charts-1.1`, based on `origin/main` at `d6ca75ea3e23c9320146602b9b790b4b91b16e92` (termr 1.0.1). The separate Stage 2 checkout has uncommitted work; it is intentionally not included. Stage 1 (`feature/worker-lifecycle-1.1`) and Stage 3A (`feature/developer-experience-1.1`, `60d0420013e45a4557a0b4e062e2dbcfa59013fb`) are separate review branches and are not merged into this chart branch.
- `termrcharts`: local checkout `main` at `361556778c7fc6e93a46b485a7cdefd1e5f15231`; the worktree has an unrelated untracked `.vscode/` directory and is not being modified. The supplied ZIP has SHA256 `CE8ECE977E69EEA63A0543AFEC5AA1B8E3E53F953AD1AABA8F2BCCE20C61A5B5`; its R chart sources match this checkout, while `docs/api-overview.md`, `tools/bench/bench-cursor.R` and `tools/validation/stress.py` differ. This audit uses the local committed checkout as the source of truth.
- Published compatibility reference: CRAN termr 1.0.1. No chart constructor names are currently exported by the selected termr base.
- Audit machine: Windows 11, R 4.5.2, termr 1.0.1 installed. `termrcharts` has MIT licensing and imports `graphics`, `grDevices`, `R6`, `stats` and termr >= 1.0.0; its R sources do not import `termrcharts:::` internals.

## Existing chart architecture

The implementation separates constructor validation and normalized chart specifications from a size-specific pure plan. A chart plan resolves a renderer, calculates scales and ticks, lays out a frame, maps data to a logical dot surface, rasterizes geometry, composes labels/axes, packs dots into terminal glyphs, and adapts the result to termr's widget lifecycle. Heatmaps use a matrix-cell path rather than the dot surface. Plans and rendered cells are cached by size; selection has its own overlay and invalidates a small selection region.

The shared logical surface is 1x1 dots for ASCII, 1x8 for block characters and 2x4 for Braille. Unicode modes are chosen only when glyph display widths are measured as one column; ASCII is the fallback. Styling is represented as termr style spans and theme roles. Geometry is clipped to the plot surface.

Available termrcharts constructors are `line_chart`, `scatter_chart`, `area_chart`, `stacked_area_chart`, `bubble_chart`, `bar_chart`, `histogram`, `density_plot`, `box_plot`, `violin_plot`, `pie_chart` and `heatmap_chart`. This integration selects only line, bar, scatter, histogram and heatmap. Box plots are deferred because they require a separate statistical-summary path and would add new tests and behavior beyond the shared five-chart infrastructure. Pie, violin, density, bubble, area and stacked area remain in termrcharts.

## Proposed dependency graph

```text
public constructors (charts.R, charts-more.R)
  -> input validation / normalization / histogram statistics
  -> internal chart specification + registry
  -> chart plan
       -> mode and glyph resolution
       -> scales + axis ticks + frame/layout + text composition
       -> line/scatter: XY reducer -> surface -> line rasterizer / hit testing
       -> bar/histogram: bar geometry -> surface -> grouped-bin mapping
       -> heatmap: matrix normalization -> cell aggregation/color ramp
  -> plan packing / styled lines
  -> termr Widget subclass -> ordinary layouts, focus, mouse/key events,
     invalidation, resize, and test_app()
```

The small coherent subsystem needs shared utilities, validation, glyph roles, surfaces, packing, scales, axis/layout, labels/composition, plans, hit testing, chart registry, adapter, and the four selected type handlers (with multi-series bars). Annotation modules are not required unless a selected constructor retains annotation arguments. Color and accessibility code must be retained only where chart types use it. Dependencies used only by excluded chart families should not be copied.

## API and implementation boundaries

Existing termrcharts signatures at the audited commit are:

```r
line_chart(x, y, title = NULL, x_label = NULL, y_label = NULL,
           mode = "auto", id = NULL, classes = NULL, style = NULL,
           interactive = TRUE, x_scale = "linear", y_scale = "linear",
           hline = NULL, vline = NULL, hline_label = NULL,
           vline_label = NULL, x_band = NULL, y_band = NULL,
           point_labels = NULL)
scatter_chart(x, y, title = NULL, x_label = NULL, y_label = NULL,
              mode = "auto", id = NULL, classes = NULL, style = NULL,
              interactive = TRUE, x_scale = "linear", y_scale = "linear",
              hline = NULL, vline = NULL, hline_label = NULL,
              vline_label = NULL, x_band = NULL, y_band = NULL,
              point_labels = NULL)
bar_chart(labels, values, title = NULL, x_label = NULL, y_label = NULL,
          mode = "auto", id = NULL, classes = NULL, style = NULL,
          interactive = TRUE, orientation = "vertical", position = "single",
          value_line = NULL, value_line_label = NULL, value_labels = FALSE)
histogram(x, breaks = "Sturges", title = NULL, x_label = NULL,
          y_label = NULL, mode = "auto", id = NULL, classes = NULL,
          style = NULL, interactive = TRUE)
heatmap_chart(z, title = NULL, x_label = NULL, y_label = NULL,
              mode = "auto", id = NULL, classes = NULL, style = NULL,
              interactive = TRUE)
```

The selected constructors are absent from termr's current namespace. `histogram()` does not conflict with base `graphics::hist()`, and `heatmap_chart()` avoids `stats::heatmap()`. Existing termrcharts events are named `termrcharts.<type>.<event>` and carry data identity; they do not expose screen positions. Retaining these names and payload shapes is the lowest-surprise interaction path for applications using the old charts. Both attached package load orders need documented behavior and qualified-call coverage; termrcharts remains a separate package and no source changes there are in scope.

The chart adapter subclasses exported `termr::Widget` and calls documented methods (`mount`, `arrange_children`, `child_clip`, `paint`, `render_lines`, `invalidate`, `on_key`, `on_click`, `focus`, and `post_message`) plus documented `MouseEvent` fields. The `Widget` subclass extension contract is marked experimental by termr's stability policy, so moving an adapter into termr removes the external-package boundary but does not make that contract stable for third-party subclass authors. Internal termrcharts APIs (plans, normalized specs, surface, glyph marks, caches and reducers) are not public APIs and must remain internal in termr.

## Existing tests and performance-sensitive paths

The source package has focused tests for renderers, accessibility, text, validation, scales, events, keyboard/mouse behavior, selection repaint, bars and multi-series bars, distributions (including histogram), heatmaps and labels, plus randomized/property, example, and static-audit tests. The full untouched suite is being run against this baseline before edits. The selected tests to adapt are renderer/text/accessibility, validation/scales, event contract, mouse, selection repaint, bars/multi bars, distributions for histogram only, and heatmap/heatmap labels; assertions for excluded chart types must be excluded explicitly, not converted to skips.

The main cost centers identified in source are: line reduction and rasterization; scatter cell de-duplication; large matrix aggregation; layout/tick formatting; per-cell packing/composition; and the headless driver's interpretation of ANSI and Unicode output. Existing code bounds line/scatter work against plot dimensions and aggregates heatmaps for screen size. Axis and label formatting can dominate tiny plots. Performance comparisons must use the same datasets, R, dimensions and headless path; old charts have no in-place data replacement method, so their update baseline is necessarily chart reconstruction plus redraw.

## Reuse, adaptation and exclusions

- Reuse where it remains coherent: the logical dot surface and raster helpers, renderer packing and width checks, scale/tick calculations, layout/composition helpers, density-aware reducers, normalized histogram semantics from `graphics::hist(..., plot = FALSE, include.lowest = TRUE)`, matrix heatmap aggregation, data-identity hit payloads and the existing termr widget adapter pattern.
- Adapt: namespacing and internals must become local to termr; registry/plan branches must be trimmed to the five selected types; `ChartWidget` must use local `Widget`, `style()` and `span()`; validation must use termr conventions; source-level constructors should retain their useful termrcharts arguments where they do not create dependencies on excluded types. Dynamic updates need an additive widget method that invalidates normalized data, plans and rendered cells, without replacing the containing app.
- Keep only in termrcharts: all excluded chart constructors and their type handlers; type-specific density/violin/box/pie/area/bubble/stacked-area code; termrcharts documentation and repository history. Do not add termrcharts as a termr dependency and do not edit its checkout.

## Licensing and compatibility risks

Both projects declare MIT licenses with the same named copyright holder. Any source adapted from termrcharts must retain the upstream MIT notice in the package license and preserve attribution in the integration documentation; no external dependency is required for chart functionality. Histogram uses `graphics`, so this base R namespace must be declared in Imports if its function is called with namespace qualification.

Principal compatibility risks are interaction/event drift, symbol masking when both packages are attached, Unicode display width differences, and use of termr's experimental widget subclass contract. The port must be additive to termr 1.0.1: no existing exports, signatures, defaults, widget behavior, or dependencies should change except adding the chart API and the necessary base `graphics` import. termrcharts remains unmodified and its exported API remains available from its own namespace. CI and a final behavior check are required before making a cross-platform or release-readiness claim.
