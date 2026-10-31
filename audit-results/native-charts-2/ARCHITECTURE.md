# C1.1 Native Charts Architecture Audit

Audit date: 2026-10-30. The audit compares Git objects directly; no branch was checked out or modified.

## Git baselines

- Local working branch: `2.0-termr`, HEAD `1b10370d1df50e54a63706673b150feaf7b04889` (`feat: add streaming and async runtimes for termr 2.0`).
- Chart source branch: `feature/core-charts-1.1`, commit `a3d6178647569dc586371c02ea5316041810a5d6` (`docs: finalize core charts CI evidence`). The local ref equals `origin/feature/core-charts-1.1`.
- Common ancestor: `d6ca75ea3e23c9320146602b9b790b4b91b16e92` (`Merge pull request #31 from menshikovs/new-docs`). Relative to that ancestor, local 2.0 has 1 commit and the chart branch has 5.
- The configured `origin` URL is `https://github.com/41929424/termr.git`, while the task names `github.com/menshikovs/termr`. A read-only `git ls-remote` against the named URL was blocked by the environment proxy. The local chart ref and its tracking ref are identical; the integration uses that available ref and does not claim a fresh network fetch.
- The pre-existing worktree changes are listed in [WORKTREE-BASELINE.md](WORKTREE-BASELINE.md). They were present before this phase and are being preserved.

## Chart source inventory

The source ref contains 22 `R/chart-*.R` modules, not approximately 23: annotations, public APIs, composition, glyphs, heatmap API, hit testing, labels, layout, packing, planning, registry, roles, axes/scales, surfaces, single/multiple-series bars, heatmaps, XY charts, utilities, validation, and the `ChartWidget` adapter. It also contains `tests/testthat/test-native-charts.R`, `inst/examples/native-charts-dashboard.R`, `docs/charts.md`, five chart Rd topics, an API inventory update, and `tools/bench/bench-native-charts.R`. There are no chart modules in the 2.0 worktree or at the local 2.0 HEAD.

The five selected constructors and their useful feature-branch arguments are `line_chart()`, `scatter_chart()`, `bar_chart()`, `histogram()`, and `heatmap_chart()`. The modules also include reusable data normalization, glyph and color-role handling, time/numeric scales, viewport layout, selection payloads, annotations, multiple-series bars, and in-place `update_data()`.

## Existing architecture and changed contracts

The source branch separates constructor validation and normalized specs from a size-specific chart plan. The plan resolves ASCII/block/Braille glyphs, scales and ticks, lays out axes, rasterizes the plot to a logical surface, composes labels, and packs the surface into termr styled lines. Heatmaps use a matrix-cell aggregation path. `ChartWidget` owns the plan/cell caches, maps keys and clicks to source indices, and paints only the requested `area`.

At the common ancestor, charts subclassed `Widget` and used its ordinary methods. The 2.0 commit keeps those methods (`mount`, `arrange_children`, `child_clip`, `paint`, `render_lines`, `invalidate`, `on_key`, `on_click`, `focus`, and `post_message`) while changing surrounding behavior:

- focus targets for queued keys are resolved at dispatch time;
- repaint scheduling distinguishes layout and paint-only invalidation and tracks old/new widget regions;
- dirty rectangles may be grown to keep wide Unicode graphemes whole;
- layout geometry is clamped to terminal-relevant bounds;
- widget removal disposes reactive bindings and workers, while app shutdown emits unmount events.

The chart adapter does not need a second renderer or direct access to compositor internals. Its `SelectionRegion` child requests the selected cells' old/new areas, while chart `paint()` supplies the corresponding clipped portion of the chart. Compatibility with the 2.0 compositor and wide-glyph dirty-region rules must be proved by full-versus-partial repaint tests.

## Conflicts and changes needed

- No constructor or chart module conflicts with an existing 2.0 implementation; none exists.
- `DESCRIPTION` and `NEWS.md` are already modified by earlier user work. The chart import/description and C1 news entry must be added without replacing those edits.
- The 2.0 widget, layout, focus, event, stream and renderer implementations are newer than the chart branch's base and must remain authoritative. The chart modules are to be adapted only where tests expose an incompatible contract; the 2.0 core is not to be copied from the chart branch.
- The chart branch already provides data replacement, which should be kept. The stream subsystem in 2.0 is synchronous and subscribable, unlike the chart branch's base. A small chart-to-stream binding can therefore use its existing callback order and `$update_data()` path without adding a transport or async framework. Chart-side history must be bounded, and its subscription must be disposed through the widget's existing detach/shutdown lifecycle.
- `termrcharts` exports overlapping names. `termr` remains independent; callers can qualify names with `termr::` or `termrcharts::`, and attachment order follows normal R search-path rules.

## Integration strategy

1. Bring over the source branch's five-chart subsystem as new files, preserving its chart behavior and MIT provenance.
2. Run its tests against current 2.0 before adapting anything; add regression tests for the updated compositor, current widget lifecycle, and stream cleanup.
3. Keep chart computation, layout and painting inside termr's existing widget/framebuffer architecture. Reuse source plans and viewport reductions rather than adding a renderer.
4. Expose the five constructors and document their signatures; merge metadata into the already-dirty package files without resetting them.
5. Bind line/scatter charts to the existing stream callback protocol with bounded history, in-place updates, error isolation, source replacement, and automatic unsubscription on widget disposal. nanonext remains optional.
6. Validate the focused chart, typed-data, stream and rendering paths on Windows and WSL, then run the broader suite/checks and report platform or optional-dependency limits.
