# Rendering correctness (Phase 3, sections 3 and 11)

Oracle: after every operation the text of the incrementally painted `VirtualTerminal` (what a terminal would show after applying
termr's ANSI output) must equal `compose_frame()`, a from-scratch layout + paint of the same widget tree. Also checked: no line
wider than the terminal. Differences between the two are termr defects only if the fresh composition is correct; two cases where
the harness itself was wrong are listed at the end.

| Fuzzer | Operations | Volume | Result |
|---|---|---|---|
| `diff-fuzz.R` (phase 1) | keys, resize, text updates, hide/show, typing | 120 seeds x 50 ops | 0 mismatches (after B-2, B-3 fixes) |
| `diff-fuzz2.R` | + scroll_by, focus jumps, mounting nested scroll views with inputs | 200 seeds x 60 ops | 0 mismatches |
| `layout-props.R` | random trees, initial render, resize round trip | 300 seeds | 0 mismatches |
| `widget-matrix.R` (phase 1) | 24 widgets x 8 texts x 8 sizes | 1,536 combos | 0 real problems |
| Input tests (new) | typing wide/emoji/combining text, backspace, home/end, resize, six container layouts | `test-input.R` | pass |

Texts used: ASCII, Cyrillic, CJK, emoji, ZWJ sequences, combining marks, tabs, newlines, ANSI escapes embedded in text, empty strings.

## Terminal state
- Hardware cursor stays hidden for the whole session (termr paints its own reverse-video cursor), alternate screen on; verified via
  `cursor-state.R` through focus changes and typing. No tests of cursor *position* are meaningful for that reason.
- Exit/restore of alternate screen, cursor, mouse and paste modes: covered by `pty-check.py` (WSL, all pass) and the ConPTY runs of phase 1.

## Harness limitations
- A popup layer (dropdown) is a separate screen; `compose_frame(a$screen)` then composes only the popup, so differential results
  for open popups are meaningless (produced false "mismatches" in phase 1's matrix).
- The virtual terminal is termr's own emulator; a bug in both emitter and emulator that cancel out would not be seen. No independent
  emulator (pyte) was available in WSL; pyte exists for Windows ConPTY e2e only.
