# 04 Confirmed bugs

B-1..B-3 predate the uncommitted work (B-2 and B-3 reproduced on an export of HEAD) but are reachable on this branch.
B-4 is in the new, uncommitted `layout_diagnostics`.

## B-1 (High) Focused `input()` crashes the app when the cursor glyph is wider than the box
- File: `R/widget-input.R` (`Input$render_lines`, around line 300).
- Root cause: `visible <- visible[cumsum(widths[visible]) <= width]` is empty when the glyph under the cursor is 2 cells wide and
  the content box is 1 cell. `kind`, `groups` and `split` then end in `kind[[i[[1]]]]` on an empty group: `subscript out of bounds`.
- Repro: `i <- input("你好"); a <- app(i); p <- test_app(a, 10, 3); i$focus(); i$render_lines(1)`, or shrink a terminal to
  1 column while a CJK/emoji input is focused. Found by PTY fuzz (4 of 25 runs killed the R process).
- Expected: renders, clipped. Actual: R error, `Execution halted` (terminal modes were restored correctly).
- Fix: return a reverse-video blank cursor cell when nothing fits. Regression test: `test-input.R`, "a focused input renders when
  its cursor character is wider than the box" (fails before, passes after). Status: fixed.

## B-2 (Medium) Stale scroll bar after scroll-view content changes (incremental repaint)
- Files: `R/widget-scroll.R` (`ScrollView$arrange_children`), interacting with `R/dirty.R`.
- Root cause: bar visibility and thumb depend on the extent of the children, but incremental repaint only repaints regions of
  changed widgets. A narrow child's region (9 columns) never reaches the bar column, and the scroll view is not itself marked dirty.
- Repro: `scroll_view(label(12 lines))` at 20x6, then `label$update("x")`: the screen keeps the bar while a fresh compose has none
  (and a bar may fail to appear when content grows).
- Fix: mark the view dirty when viewport, virtual size or bars change during layout. Regression test: `test-scroll.R`, "incremental
  repaint follows scroll bar changes caused by child content". Status: fixed.

## B-3 (Medium) Incremental repaint drops a wide character next to a changed widget
- Files: `R/dirty.R` (`dirty_rects`), `R/app.R` (`refresh_screen`).
- Root cause: dirty rectangles are the widget region plus or minus one column, so one can start on the right half of a wide glyph
  from the previous frame. `fill()` blanks the left half and the clipped repaint treats the glyph as cut and writes a space.
- Repro: `horizontal(label("你好世界你好世界"), button("OK"), input("你好"))` at 40x6; hide and show the button. The label's last glyph
  becomes two blanks until the next full repaint. Found by differential fuzz (4 of 120 seeds).
- Fix: `keep_wide_chars_whole()` grows rectangles over split glyphs using the previous frame. Regression test: `test-renderer.R`,
  "incremental repaint does not split a wide character next to a changed widget". Status: fixed.

## B-4 (Low) `App$layout_diagnostics()` accepts `Inf` and sizes above 2^31
- File: `R/app.R:185`. `check_count()` coerces to `NA_integer_` with a warning. `Inf` returned an empty data frame silently, and 3e9
  gave "missing value where TRUE/FALSE needed".
- Fix: `anyNA(size) ||` in the positivity check. Regression test in `test-layout.R`. Status: fixed.
