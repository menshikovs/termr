# Layout engine (Phase 3, sections 4 and 11)

## Property tests (`layout-props.R`, 300 seeded random trees, sizes 1x1 to 80x24)
Trees mix vertical / horizontal / grid / scroll_view containers, labels (all wrap modes), buttons, inputs, hidden widgets,
dimensions fixed / auto / fr / percent, margins, padding, borders, min/max limits, texts with CJK, emoji, combining marks, newlines.
Checked per tree: regions are finite integers with non-negative size; hidden widgets occupy no area; a second layout pass gives an
identical result (idempotence); rebuilding the same seed gives the same geometry (determinism); layout at 1x1 followed by the
original size restores the original geometry; initial render equals a fresh full composition; resize round trip equals a fresh
composition; no rendered line is wider than the terminal. **0 violations.**

## Numeric boundaries (`layout-numeric.R`, log in `logs/layout-numeric.log`)
Before the fix, values that the validators accepted but could not represent failed late and cryptically:

| Input | Before | After |
|---|---|---|
| `style(width/height = Inf, 1e10, 2^31, .Machine$integer.max)` | render error "missing value where TRUE/FALSE needed" | clamped to 1,000,000 cells, renders |
| `min_/max_ width/height`, `margin`, `padding` with Inf / >= 2^31 | same error | clamped |
| `grid_gap = Inf` | accepted, failed at layout | clamped |
| `grid_columns = Inf` | "invalid 'times' argument" | clear error "must be at most 10000 tracks" |
| `grid_columns = .Machine$integer.max` | hang (allocating 2^31 list entries; killed by time limit) | clear error |
| two siblings of fixed width `.Machine$integer.max` | integer overflow -> NA -> error | renders |

Already handled with clear messages: NA, NaN, -Inf, negatives, malformed strings ("-1fr", "1e9fr", "NaN%"), `test_app()` with NA or
negative size. `test_app(width = .Machine$integer.max)` still tries to allocate a screen buffer of that width (not changed:
a screen of 2^31 columns is not a supported size; I did not run it to completion).

See `confirmed-bugs.md` (C-1, C-2) and `fixes.md`.
