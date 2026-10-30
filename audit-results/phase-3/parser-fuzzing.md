# Terminal input parser (Phase 3, section 8)

Scripts: `parser-chunking.R`, plus `parser-fuzz.R` from phase 1.

## Differential test: same byte stream, different chunking
3000 random streams built from 41 fragments (printable ASCII, Cyrillic, CJK, emoji, combining marks, arrows with and without
modifiers, F-keys, Home/End/PageUp, Shift+Tab, SGR mouse press/release/wheel/motion, bracketed paste with newlines and
CJK, `ESC a` / `ESC ESC [A` Alt combinations, focus in/out, an unknown CSI, an incomplete CSI, an OSC string).
Each stream was parsed (a) in one chunk, (b) split at 1-6 random byte offsets (so UTF-8 sequences and escape sequences are cut),
(c) one byte at a time; events (class, type, key, text, mouse position/action/button/direction) were compared after `flush()`.
**0 mismatches in 3000 streams.**

Other observations
- A lone `ESC` stays pending until `flush()` and then yields an `escape` key; feeding after `flush()` works normally.
- Phase 1 byte-level fuzz (4000 cases of random and invalid bytes) produced no errors or warnings.
- Real-terminal behaviour of the escape timeout is covered by `tools/pty/pty-check.py`; not re-measured here.

Not covered: events arriving after the terminal is closed by the OS (PTY hang-up) beyond the SIGHUP finding from phase 1.
