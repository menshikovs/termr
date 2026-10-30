# 08 Fixes applied (uncommitted; nothing staged or committed)

| Bug | Source change | Test added (appended, existing tests untouched) |
|---|---|---|
| B-1 | `R/widget-input.R`: early return of a reverse-video blank when no glyph fits | `tests/testthat/test-input.R` |
| B-2 | `R/widget-scroll.R`: `arrange_children` marks the view dirty when viewport / virtual size / bars change | `tests/testthat/test-scroll.R` |
| B-3 | `R/dirty.R`: new `keep_wide_chars_whole()`, `dirty_rects(..., frame =)`; `R/app.R`: passes the previous frame | `tests/testthat/test-renderer.R` |
| B-4 | `R/app.R:185`: `anyNA(size) ||` | `tests/testthat/test-layout.R` |

Each regression test was run before its fix and failed (B-1, B-2, B-3 confirmed failing; B-4 failed with the cryptic error), then passed after.
No exported symbol, signature, dependency or roxygen text changed, so `man/` and `NAMESPACE` need no regeneration.
`dirty_rects()` is internal; its new `frame` argument is optional, so existing callers and tests are unaffected.
NEWS.md was not edited; a "Bug fixes" line for B-1..B-3 would be appropriate before release.
