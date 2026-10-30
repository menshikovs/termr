# Phase 3 changes (uncommitted; nothing staged)

## 1. Input edits no longer relayout the whole tree when that cannot change geometry (optimization O-1)
- Files: `R/widget.R` (`Widget$set_state` uses new private hook `paint_only_change()`, default `FALSE`);
  `R/widget-input.R` (`Input` private `paint_only_change()`).
- Rule: a change of the `value` state skips the layout pass (repaint only, size caches still cleared) iff walking from the input
  to the root, no node has an `auto` width, every parent is a plain `Vertical`/`Horizontal`/`Screen` using the vertical or horizontal
  algorithm, or a `fixed` width ends the chain. Rationale: the only geometric effect of a new value is the input's natural width;
  `natural_width()` is used by `auto` sizes and by ancestors' `measure()`, nothing else. Input height is the number of render lines
  (always one). Grid, ScrollView, split panes, panels, custom containers and auto-width ancestors keep the old (full) layout path.
- Evidence: `bench-keypress.R` (see performance.md): keypress at 2001 widgets 360 ms -> 20 ms. Tests (`test-input.R`):
  layout counter stays 0 for eligible trees and rises for auto-width input / auto-width ancestor / scroll_view / auto grid
  column; incremental output equals a fresh full render for six layouts while typing wide, emoji and combining text, then resizing.
  Mutation check: forcing the hook to always return TRUE makes these tests fail (5 failures) - they do detect an over-aggressive rule.
- Full suites after the change: Windows 8411 tests, 0 failures; WSL see final section. No public API change.
- Risk: a future widget/style feature that makes ancestors depend on child content width through a path other than
  `natural_width()`/`measure()` would break the rule; the differential test is the guard.

## 2. C-1 / C-2 hardening of numeric style values (see confirmed-bugs.md)
- Files: `R/geometry.R`, `R/style.R`. Tests: `tests/testthat/test-style.R`.

## Tests added in phase 3
`test-input.R` (2 tests), `test-style.R` (3 tests). All other new checks are standalone scripts under `audit-results/phase-3/`.
