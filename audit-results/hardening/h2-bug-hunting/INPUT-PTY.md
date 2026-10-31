# Terminal Input, PTY & Event Ordering

## 1. Real Pseudo-Terminal Test Results

All integration checks in `tools/pty/pty-check.py` were run against the updated installed package in a real Linux PTY:

```
PASS hello app ready
PASS raw mode while running (no ICANON, no ECHO)
PASS alternate screen entered
PASS typing reaches input
PASS Tab focuses button
PASS Enter presses button
PASS escape sequences are parsed
PASS resize redraws
PASS Ctrl+C quits with status 0
PASS combined-input app ready
PASS one PTY write delivers text, Tab focus and Enter activation in order
PASS combined Tab+Enter fires focus and press once
PASS combined-input app exits normally
PASS keys app starts
PASS ASCII, accented and emoji characters
PASS key enter / tab / shift+tab / escape / arrows / home / end / delete / f1..f12 / alt+x / ctrl+a
PASS mouse press/release/wheel
PASS mouse drag press/move/release
PASS resize storm reaches final size
PASS timers fire
PASS SIGINT exits cleanly
PASS fragments app starts (split escape sequences, split UTF-8, split paste)
PASS lone Escape flushed after timeout
PASS error app exits with error printed after screen restored
PASS termios restored cleanly
PASS stdin-only PTY fallback usable
PASS no-TTY topology fails with clear termr error
PASS TERM=dumb degrades gracefully
all PTY checks passed
```

## 2. The Combined Tab-to-Enter Sequence

When a single chunk `b"Ada\t\r"` is written to the PTY:
1. `PosixDriver` parses all 5 keys: `A`, `d`, `a`, `tab`, `enter`.
2. Each key is posted to `App` with `target = private$.focus_target_marker`.
3. At dispatch time, `App$dispatch()` evaluates `private$.focus$focused` dynamically:
   - `A`, `d`, `a` resolve to `Input #name`.
   - `tab` resolves to `Input #name`, bubbles to `App`, triggers `focus_next`, synchronously setting `private$.focus$focused <- Button #submit`.
   - `enter` pops next, resolves target to `Button #submit`, triggering `action_press()` and logging `"pressed name=Ada"`.
4. Event ordering is strictly preserved.\n