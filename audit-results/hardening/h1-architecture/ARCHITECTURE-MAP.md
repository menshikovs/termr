# Current architecture map

| Component / source | Input → output and mutable state | Lifecycle / contract |
|---|---|---|
| App, R/app.R | Driver events/callbacks → dispatch and frames; owns queues, focus, screens, timers, workers | run() brackets start/shutdown; events and repaint settle on the R main thread |
| Widget, R/widget.R | R6 fields/styles/children → invalidation, geometry and paint; parent, state, caches | mount/remove preserve single parent and ID uniqueness; same-app moves retain reactive/timer/worker ownership |
| Screen/ScreenStack, R/screens.R | Root widgets → visible layers; stack and saved focus | push/pop manage modal input, lifecycle events and restoration |
| Layout, R/layout*.R | Resolved styles and terminal size → regions; per-widget indices/revisions | Does not paint; indexed scrolling retains offscreen widget ownership while selecting visible layout roots |
| Focus, R/focus.R | Widget tree/current focus → valid focusable target | Top-screen, visible/enabled membership; App posts focus/blur events |
| Events, R/event-queue.R | Posted R6 events → FIFO dispatch | Global guard limits handler-generated loops, not a hard queue-size bound |
| Drivers, R/terminal*.R + R/keys.R | Console records/bytes → canonical events; writes ANSI | Own OS handles/raw-mode state; drivers perform terminal IO |
| Compositor/buffer/dirty/renderer | Layout/paint → buffer → changed-cell ANSI | Wide-grapheme-aware dirty regions; no application data parsing in drivers |
| Reactive graph, R/signals.R | Signal writes → ordered effects and lazy computed values | Global observer/pending graph; batch/untracked/dispose restore tracking on unwinds |
| termr_stream, R/streams.R | Values → callbacks/history/latest | Synchronous, bounded event-count ring; explicit subscription/close |
| DataTable, R/widget-datatable.R | Local frame or source pages → viewport/events | Maintains row-index view, schema, 32-page cache, selection, edit ledger; see F01/F02/F06 |
| Typed foundation, R/datatable-typed.R | Column prototypes/text → safe slices, display and typed values | Specialized handlers precede generic S3/vctrs fallback; readonly fallback for unsafe casts |
| Sources, R/datatable-source*.R | Explicit callbacks/DBI → exact row counts and bounded data.frames | Synchronous; caller owns source/connection unless explicit owned policy |
| R-code export, R/reproducible-code.R | Current view/value/edit model → bounded language objects and source | Does not execute cell text; source binding remains caller-supplied; F02 is a correctness gap |
| Charts, R/chart-*.R | Validated specs → viewport plans/cells/events | One Widget renderer integration; SelectionRegion marks partial repaint bounds |
| Nano, R/transport_nanonext.R | Raw bounded JSON → local stream | Polled PUB/SUB plus request/snapshot recovery; explicit socket ownership |
| Mirai, R/tasks_mirai.R + R/mirai_progress.R | Minimized trusted local job → task handles and metadata stream | Separate named compute profile; explicit pool close, caller-owned terminal handles |
| Shiny, R/shiny_streams.R | Source subscriptions → reactive values/history/status | Receiver owns one subscription and observer; sessions hold leases |
| Plotly / visualization example | Bounded telemetry frame → append/reset messages | Optional example bridge, not a second core renderer |
| RTCSS / inkr | Selector tree and state → partial termr styles | defaults < RTCSS < inkr < inline; final termr focus-theme treatment remains |

The bidirectional App–Widget links are ownership/control relationships within
one package, not namespace dependency cycles. Retention roots matter: running
Apps, stream callback registries and Shiny observers can keep R6 graphs alive.
F05 demonstrates a real global-root leak on failed startup and is now fixed.

Cross-layer couplings deserving care are ChartWidget's private widget disposal
handle, DataTable's combined UI/source/reproduction state, and App's widget
shutdown hook. These are concrete internal integration points, not proof that
their mere existence is an architectural defect.
