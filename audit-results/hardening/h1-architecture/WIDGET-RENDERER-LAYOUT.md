# Widget, renderer, layout and input audit

Read paths: Widget$mount/detach/invalidate/computed_style, App$post_input/
process_queue/dispatch/refresh_screen/shutdown, FocusManager, layout_tree and
indexed_layout_tree, dirty_rects/keep_wide_chars_whole, ScreenBuffer and Renderer.
Layout computes regions; compositor paints clipped buffers; driver alone
performs terminal IO. Dirty rectangles expand split wide glyphs using the
previous frame and fall back to full repaint for structural changes.

Grouped KeyParser input Ada+Tab+CR produces five ordered events. A single
headless step inserts Ada, focuses the button and presses it exactly once.
App uses a private focus marker at post_input and resolves focus at dispatch,
so routing is not frozen before a preceding Tab. Processx preserves CR in
both available environments. Fresh PTY results are in TEST-RESULTS.md.

Ordinary queued events targeted at a widget detached before dispatch are
skipped by App$dispatch's membership check. However a bubbling path is
snapshotted once: removal inside the child handler does not recheck ancestor
membership (F04). The desired mid-dispatch policy is not explicit in current
public docs; this is recorded as a policy risk, not asserted as a new defect.

Live run() uses on.exit shutdown for callback errors/interrupts. Pilot's
failed initialization had no returned handle available to the caller for
cleanup; F05 adds unwind cleanup. Existing started Pilots still require
caller stop/on.exit around subsequent test actions.

Full suites exercise incremental/full differential rendering, CJK and emoji,
resize, scroll, focus, mouse, paste and tree ownership. Historical B-1 through
B-4 fixes remain represented by current input/scroll/renderer/layout tests.
This does not certify actual font glyph widths, ConPTY hosts, tmux, remote SSH,
forced process termination, or arbitrary custom layout callbacks.

Indexed scrolling caches ordinary vertical extents for sufficiently wide
trees and limits repeated layout/paint to the viewport. Focus traversal and
first layout can still inspect the mounted tree. Class/style/state changes
bump shared epochs; an inkr or RTCSS sheet conservatively makes a state
transition layout-affecting even when a rule only changes foreground color.
