# Architecture findings (Phase 3)

1. **Layout invalidation is coarse.** `Widget$set_state` repainted-only for a per-class `paint_states` list; everything else
   called `invalidate()` which marks the whole app for a layout pass (`App$request_repaint(layout = TRUE)`), and `refresh_screen`
   then walks the entire tree (`layout_tree`, `layout_snapshot`). Cost per keypress was linear in the number of widgets
   (360 ms at 2001 widgets). Introduced the `paint_only_change()` hook (see fixes.md); other widgets (text_area edits, checkbox,
   data_table cell edits, labels with equal-size updates) could use the same hook with their own proofs. Not attempted here.
2. **Geometry values are validated for sign but not for representability.** Cell counts were stored with `as.integer()`; anything
   outside the integer range became `NA` and failed far from the cause. Now clamped at 1,000,000 cells (one constant, `max_cells`).
3. **Incremental repaint relies on widget regions.** Decorations a container draws outside its children's regions (scroll bars)
   and glyphs that straddle a rectangle edge are not covered by region-based dirty rectangles; B-2/B-3 of phase 1 were both of this
   kind. The differential fuzzers are the safety net; any new container-drawn decoration should mark its container dirty.
4. **Simulated time in `Pilot`.** Timers only fire when `advance()`/`wait_for()` moves the clock. Long stress loops that do not
   advance time accumulate timers (looks like a leak, is not). Worth a sentence in `docs/testing.md`.
5. **Reactive graph** is self-contained (`R/signals.R`), deterministic, glitch-free on the tested space and bounds runaway watchers;
   widget bindings unsubscribe on removal.
6. **Headless `VirtualTerminal` is slow** (R-level per-character interpretation) and dominates the cost of repaint-heavy headless tests.
7. Process-level limits in R (signals): see remaining-risks.md.
