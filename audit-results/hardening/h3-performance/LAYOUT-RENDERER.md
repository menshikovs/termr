# Layout and renderer

No layout algorithm, framebuffer, ANSI diff or dirty-rectangle code changed.
Fresh initial renders, warm chart renders, idle App ticks, one-widget paint
updates, full layout/render, partial selection redraw and resize are represented
in the core/broad/extra CSVs. The chart *-paint.txt artifacts preserve full,
dirty-cell, rectangle and ANSI-byte counters after the requested operation.

The inkr bridge optimization reduces style preparation before layout. It does
not assume that a foreground-only declaration cannot affect layout through
selectors, inheritance or custom styles. The existing conservative stylesheet
layout invalidation and global epochs remain. No new dirty-render shortcut was
introduced without evidence that its semantics are safe.

The full suite includes dirty rendering, incremental/full framebuffer equality,
layout, regions, scrolling, resize storms and Unicode bounds. PTY covers live
POSIX input/output and restoration separately. Warm render_widget timings still
compose a frame and are distinct from App idle ticks that can avoid a frame.
Fresh-process startup and monitor-to-screen latency are not measured here.

Granular CSVs separately time layout_tree and paint_tree for 1,000 unique
widgets, with and without inkr. Painting starts from a prepared layout and
buffer; those setup costs are excluded. This separates measurement/layout work
from painting instead of treating compose_frame as a layout-only measurement.
