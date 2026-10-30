# 01 Architecture map (confirmed against current code)

- **Public API**: `NAMESPACE`/`man/`; widgets are R6 classes created via factory functions (`label()`, `vertical()`, `input()`...).
- **App lifecycle** (`R/app.R`): `app()` -> `App` R6 -> `run()`; per tick: driver `read_events` -> `post_input` -> timers ->
  `process_queue` (dispatch/bubbling) -> `refresh_screen` (layout, snapshot diff, dirty rects, compose, renderer diff).
- **Input**: `R/keys.R` `KeyParser` (byte stream -> `KeyEvent`/`PasteEvent`/mouse); new in this branch: key events get a
  *focus-target marker* resolved at dispatch time (`private$.focus_target_marker`).
- **Terminal**: `R/terminal-posix.R`, `terminal-windows.R`, `terminal.R` (headless `HeadlessDriver` -> `VirtualTerminal`).
- **Rendering**: `layout.R` (+`layout-grid.R`, `layout-index.R`) -> `paint_tree` into `ScreenBuffer` -> `renderer.R` diffs frames
  into ANSI. Incremental path: `layout_snapshot`/`snapshot_changes` + `dirty_rects` (`R/dirty.R`) repaint into a copy of the last frame.
- **Focus**: `FocusManager` (`R/focus.R`); **timers**: `TimerManager`; **workers**: `R/workers.R` (callr/processx).
- **Reactivity**: `signal`/`reactive` (`R/signals.R`, `R/reactive.R`), `bind_reactive` for widget fields.
- **Testing**: `Pilot` (`R/testing.R`) drives the real loop headlessly.
- **Platform-specific**: termios/stty/SIGWINCH on POSIX, ConPTY/VT mode on Windows.

Risky seams examined: dirty-rect repaint vs. wide glyphs and container-drawn decorations (found 2 bugs), widget `render_lines`
at degenerate sizes (found 1), deferred focus targeting (no defect found), signal handling at the R boundary (limitation).
