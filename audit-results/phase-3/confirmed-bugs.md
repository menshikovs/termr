# Phase 3 confirmed bugs

No new rendering, reactive, parser or lifecycle defects were found beyond the items below. Phase 1 bugs B-1..B-4 were re-exercised by
the new fuzzers (diff-fuzz2: 200 seeds x 60 ops; layout-props: 300 trees) with no regressions.

## C-1 (Medium) Style sizes `Inf`, >= 2^31 and `.Machine$integer.max` pass validation and crash at layout
- Files: `R/style.R` (`parse_size`, `style_property_parsers` min/max sizes, `parse_gap`), `R/geometry.R` (`as_edges`).
- Root cause: validators accepted any non-negative number, but the stored value was `as.integer(x)`, which is `NA` for `Inf` and
  values above 2^31-1 (and an exact `.Machine$integer.max` overflows when sibling sizes are added). The `NA`/overflow surfaced
  later, in layout, as `missing value where TRUE/FALSE needed`, i.e. an app crash far from the faulty `style()` call.
- Repro: `a <- app(vertical(label("x", style = style(width = Inf)))); test_app(a, 20, 4)` (also `height`, `min_*`, `max_*`,
  `margin`, `padding`, two siblings with `width = .Machine$integer.max`).
- Expected: renders (an unbounded size is meaningful as "as large as possible"). Actual: R error during layout.
- Fix: values are clamped to 1,000,000 cells (`clamp_cells()`); truncation/rounding of normal values is unchanged (test added).
  Regression tests: `test-style.R` ("absurdly large cell counts are clamped...", "clamping keeps the original rounding...").
  Status: fixed. Public API unchanged (no new arguments); behavior change only for inputs that previously crashed.

## C-2 (Low) `grid_columns` / `grid_rows` with `Inf` or `.Machine$integer.max` tracks
- File: `R/style.R` (`parse_tracks`). `rep(list(...), v)` raised "invalid 'times' argument" for `Inf` and, for 2^31-1, tried to
  allocate a list of 2^31 entries (killed by my 8 s time limit; effectively a hang).
- Fix: more than 10,000 tracks is rejected up front with "`grid_columns` must be at most 10000 tracks."
  Regression test: `test-style.R` ("unusable grid track counts are rejected up front..."). Status: fixed.

## Not bugs (investigated and ruled out)
- "Memory growth" of ~65 B per event in my first stress runs: caused by (a) random typing legitimately adding text and (b) simulated
  time not advancing in the headless pilot, so button-release timers stayed pending (50 presses -> 50 timers; advancing 1 s -> 0).
  With time advancing and navigation-only keys: 0 cons cells per event over 13,000 events for buttons, text_area and input.
- Headless `tab` cost (~100 ms): 82% is the R-level `VirtualTerminal` interpreting output, a test-harness cost.
- Hardware cursor is always hidden by design (termr draws a reverse-video cursor).
