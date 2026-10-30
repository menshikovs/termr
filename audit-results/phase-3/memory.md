# Memory (Phase 3, section 5)

Method: full `gc()` twice before each reading; reported "used" Mb and cons cells (`gc()` matrix), `lobstr::obj_size` for retained size.
Scripts: `memory-stress.R`, `memory-stress-100k.R`, `memory-attrib*.R`, `memory-plateau*.R`, `memory-bisect.R`, `memory-locate*.R`.

## Long runs (random keys over input, text_area, button, log_view, data_table, 80x24)
| events | time | used before -> after | delta |
|---|---|---|---|
| 1,000 | 4.5 s | 67.7 -> 67.7 MB | +0.00 |
| 10,000 | 47 s | 67.7 -> 68.6 MB | +0.90 |
| 100,000 | 937 s | 67.6 -> 73.5 MB | +5.90 (half-way 70.6) |

Apparent linear growth (~60 B/event) was investigated instead of reported as a leak:
- 8000 events per widget (`memory-attrib2.log`): label-only 0 B/event; data_table nav 0; input editing 13 B; text_area 26-92 B; buttons 170 B.
- No internal collection grows (`.frame_times` is capped at 60; queue, timers, focus, handlers, toasts, dirty list constant).
- Buttons: the growth is exactly the unfired 150 ms release timers of the simulated clock (50 presses -> 50 pending timers; after
  `advance(1)` -> 0). With the clock advancing: **+0.00 cons cells/event** for buttons.
- text_area / input: navigation-only keys (arrows/home/end/page): **+0.00/event** over 13,000 events; the remainder is typed text
  (a random walk that adds characters) and a bounded undo stack (200 entries).
- Mount/remove churn (phase 1: 300 cycles, +0.2 MB) and 200 bound-label mount/remove cycles leave no signal subscribers.

Conclusion: no leak found; growth in raw stress runs is content and simulated-timer accumulation. Not verified: very long real-time
sessions with a real driver (workers, toasts and notifications over hours).

## Allocation hot spots
Not measured with `bench::mark`/`tracemem` in this phase; profiling (Rprof) showed time rather than copies dominating
(`layout_tree` 67% of a keypress before O-1; `VirtualTerminal$print_char` 82% of a headless `tab`).
