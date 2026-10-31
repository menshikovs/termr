from pathlib import Path
import csv
import re
import textwrap

root = Path.cwd()
out = root / "audit-results/hardening/h1-architecture"


def read(name):
    raw = (out / name).read_bytes()
    return raw.decode("utf-16" if raw.startswith((b"\xff\xfe", b"\xfe\xff")) else "utf-8-sig", errors="replace")


def rows(name):
    return list(csv.DictReader(read(name).splitlines()))


def write(name, content):
    (out / name).write_text(textwrap.dedent(content).strip() + "\n", encoding="utf-8")


def total(name):
    matches = re.findall(r"TOTAL: (\d+) tests, (\d+) failed, (\d+) errors, (\d+) skipped, (\d+) warnings", read(name))
    return matches[-1] if matches else ("NOT RECORDED",) * 5


def exitcode(name):
    return read(name).strip() if (out / name).exists() else "NOT RUN"


def check(name):
    matches = re.findall(r"^Status:\s*(.*)", read(name), re.M)
    return matches[-1].strip() if matches else "NOT RECORDED"


windows = total("full-windows.log")
wsl = total("full-wsl.log")
packages_windows = {r["package"]: r for r in rows("packages-windows.csv")}
packages_wsl = {r["package"]: r for r in rows("packages-unix.csv")}
baseline = rows("baseline-files.csv")
exports = rows("exports.csv")

write("EXECUTIVE-SUMMARY.md", r"""
    # H1 architecture and integration audit — 2026-10-31

    The current local development tree has a coherent widget/layout/compositor/driver
    boundary and six working additive layers: typed tables, lazy sources, R-code
    export, native charts, streams and optional inkr styles. This is not a release
    certification. The package still declares version 1.0.1; “2.0” names the local
    development programme, not a released package version.

    Confirmed defects/documentation issues: P0 = 0, P1 = 3, P2 = 3, P3 = 1.
    Six are runtime defects and one is a documentation-generation mismatch.
    H1 fixed two P2 defects and the P3 mismatch. Four runtime defects remain open.
    A documented chart liveness limitation and an unresolved event-lifecycle policy
    are recorded separately and are not included in these defect counts.

    | ID | Severity | Finding | H1 result |
    |---|---|---|---|
    | F01 | P1 | Failed DataTable source replacement corrupts active source state | Open, H2 |
    | F02 | P1 | An “exact” pipeline can disagree with the displayed post-edit view | Open, H2 |
    | F08 | P1 | Removing an owned SQLEditor loses subsequent App cleanup of its connection | Open, H2 |
    | F05 | P2 | Failed Pilot startup retains a running/registered App | Fixed and regression-tested |
    | F06 | P2 | Source projection cache aliases legal column names containing CR | Fixed and regression-tested |
    | F09 | P2 | Non-finite log capacity is accepted, then fails during startup | Open, H2 |
    | F07 | P3 | Internal Pilot triggers spurious roxygen R6 diagnostics | Fixed with explicit noRd |

    Five principal remaining risks are failed source transactions (F01), false exact
    exports (F02), owned DBI resource disposal after unmount (F08), chart display
    starvation during a sustained backlog (F03, documented design limitation), and
    the unexecuted native mirai/nanonext lifecycle paths (U01, coverage gap).
    F04 shows delivery to an ancestor detached earlier in the same event; its
    intended mid-dispatch contract needs a decision before calling it a defect.

    Period/Duration/Interval have generic read-only display and working bounded
    value export in the tested WSL samples, but no specialized A2.3 editor/DST
    implementation. Built-in lazy adapters are SQLite table and SQLite query;
    other DBI drivers require callbacks. DuckDB/dbplyr/Arrow adapters are absent.

    Read FINDINGS.md for reproduction and evidence, TEST-RESULTS.md for fresh
    Windows/WSL results, and the H2/H3/H4 plans for executable next steps.
    No commit, push, release, package-version change or dependency update occurred.
""")

counts = {prefix: sum(r["Path"].startswith(prefix) for r in baseline)
          for prefix in ("R/", "tests/", "inst/", "docs/", "man/", "tools/")}
write("REPOSITORY-BASELINE.md", f"""
    # Repository baseline

    - Date: 2026-10-31, user timezone Europe/Riga.
    - Branch: 2.0-termr.
    - HEAD: 1b10370d1df50e54a63706673b150feaf7b04889.
    - DESCRIPTION: termr 1.0.1, R >= 4.1.0.
    - Staged changes at entry: none; see git-staged-before-numstat.txt.
    - Existing unstaged/untracked work: see git-status-before.txt and
      git-diff-before-numstat.txt. A1/A2/A3.5/A4/C1/B code was already present.
    - Hashed non-audit files at entry: {len(baseline)}. Counts by path:
      {", ".join(f"{k} {v}" for k, v in counts.items())}.

    The working tree, including untracked R source, was the audit target. HEAD was
    used only for compatibility comparison, not as a replacement for that tree.
    No remote main comparison or fetch was needed.

    Current inventory: {len(exports)} exports, five additive chart constructors,
    78 local R6 class generators. exports.csv, function-signatures.csv,
    r6-classes.csv and namespace-usage.csv record reproducible inventories.
    Existing audit reports were treated as historical hypotheses. In particular,
    old PTY failure and backend-completion claims were checked against fresh
    executions and current source rather than copied as conclusions.

    baseline-files.csv stores SHA256 values. preservation.csv and git-status-after.txt
    record final preservation evidence. H1 source changes are restricted to
    R/testing.R, three lines of source-cache key construction in
    R/widget-datatable.R, and tests/testthat/test-h1-contracts.R. The report tree is
    new. Roxygen regenerated no changed public Rd topic or NAMESPACE.

    Source build/check ran from the complete current package tree. audit-results
    is already excluded by .Rbuildignore. The exact tarball is stored under build/
    and its Windows/WSL digest is recorded; no “clean” checkout discarded local work.
""")

write("ARCHITECTURE-MAP.md", r"""
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
""")

write("DEPENDENCY-GRAPH.md", r"""
    # Dependency and control graph

    ~~~mermaid
    flowchart TD
      Driver[POSIX / Windows / Headless driver] -->|input| App
      App --> Queue[EventQueue / timers / focus]
      Queue -->|dispatch| Tree[Screen and Widget tree]
      Tree --> Styles[RTCSS + optional inkr + inline]
      Styles --> Layout
      Tree --> Layout
      Layout --> Paint[Compositor and widget paint]
      Paint --> Buffer[ScreenBuffer / dirty rectangles]
      Buffer --> Renderer
      Renderer -->|ANSI writes| Driver
      Signal[Global reactive graph] -->|invalidation| Tree
      Tree --> Table[DataTable]
      Table --> Typed[Typed adapters]
      Table --> Sources[table_source callbacks]
      Sources --> SQLite[DBI / SQLite pagers]
      Table --> Code[Bounded R AST generation]
      Tree --> Charts[ChartWidget / plans / SelectionRegion]
      Stream[termr_stream] --> Charts
      Stream --> Nano[Optional nanonext transport]
      Nano --> Stream
      Mirai[Optional isolated mirai pool] -->|metadata| Stream
      Stream --> Shiny[Optional Shiny receiver]
      Shiny --> Plotly[Example Plotly / ggplot views]
      App --> Worker[processx Worker]
    ~~~

    Runtime Imports are codetools, grDevices, graphics, methods, R6, processx, ps,
    stats and utils. inkr, DBI/RSQLite, vctrs/pillar and all telemetry/chart-browser
    integrations are optional. Native charts need only existing runtime Imports.
    Mirai's optional runtime additionally requires nanonext and jsonlite.

    Mutable namespace state: termr_env stores active Apps, style/layout epochs and
    profiling state; rx stores the active observer, pending effects and IDs.
    size_cache is capped at 512 entries; selector_cache is a global environment
    without eviction; per-widget caches are epoch/revision based. inkr's per-App
    cache is capped at 4096 entries. Source caches cap at 32 pages of up to 100 rows
    each, not a fixed byte budget.

    Internal callbacks carry unavoidable reverse edges (Widget → App events,
    source fetch → caller code, worker completion → App). Detach and shutdown must
    explicitly unlink them. See RESOURCE-LIFECYCLE.md rather than treating all
    callback cycles as leaks.
""")

write("API-AUDIT.md", r"""
    # Public API and compatibility

    exports.csv resolves all 170 NAMESPACE exports in the loaded namespace. The
    static alias scan finds no export without an Rd alias. R CMD check separately
    validates namespace, documentation and signatures. Production R source and
    runnable R examples have no triple-colon calls.

    Comparing parsed function definitions with local HEAD adds exactly:
    bar_chart, heatmap_chart, histogram, line_chart, scatter_chart. No prior export
    was removed. Existing arguments/defaults of app(), column(), data_table() are
    unchanged; inkr_stylesheet, label_mode and show_types were appended,
    respectively. The comparison is stored in function-signatures.csv, not
    inferred from a remote branch.

    | Classification | Surface | Evidence / qualification |
    |---|---|---|
    | Stable | Core constructors/events, RTCSS, in-memory table display | docs/stability.md; full existing regressions |
    | Additive | Five charts, typed metadata, bounded R-code exports, App inkr methods | Current R source, NAMESPACE and generated man topics |
    | Experimental | Editing, lazy sources, native chart events, signals, streams, workers, mirai, Shiny and inkr | Stability guide explicitly identifies them |
    | Internal / undocumented as extension points | Handler lists, caches, ChartWidget generator, private disposal registries, Pilot generator | They are not separately exported; applications must use documented constructors/methods |
    | Potentially breaking for reflective clients | Widget id/classes changed from public fields to active bindings; assignment now validates and invalidates | Ordinary documented reads/assignments remain; field-list introspection or invalid IDs can differ |

    Chart events deliberately retain the documented termrcharts.* names even
    though no termrcharts package is required. This is an existing event contract,
    not evidence of a hidden runtime dependency. Shiny control commands are absent.

    H1 changes no public signature, export, event payload, dependency or package
    version. Pilot's noRd annotation describes an internal class and produces no
    new help topic. R6 reference graphs still require explicit ownership; API
    compatibility alone cannot establish lifecycle correctness (F01/F05/F08).

    Minimum R 4.1 and native macOS were not rerun here. The CI matrix declares
    those jobs, but historical CI success is not current-tree evidence.
""")

write("WIDGET-RENDERER-LAYOUT.md", r"""
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
""")

write("TYPED-DATA.md", r"""
    # Typed Data Foundation

    Resolution order in table_type_handlers is explicit: blob, sfc/sfg/list<sfg>,
    raw/list<raw>, integer64, units, haven SPSS/labelled, hms, ordered/factor,
    POSIXct, Date, difftime, bare atomic/list, then extension and unsupported.
    Therefore generic vctrs capability does not override stricter geometry,
    binary or labelled handlers. Metadata uses a zero-length prototype; display
    formats slices, not the whole column. Scalar edits cast before assignment,
    then verify storage, class and attributes.

    | Type | Display / inspect | Edit | Preservation / current evidence |
    |---|---|---|---|
    | Bare logical/integer/double/character | Native typed formatting and column_info | Strict scalar parser | Windows/WSL typed regressions; injection text rejected without mutation |
    | Factor/ordered | Levels and compact type | Existing levels only | Levels/order/class invariant tests |
    | Date/POSIXct/difftime/hms | Typed formatting/timezone metadata | Strict date/time and explicit offset contract | DST ambiguity/nonexistent-time tests in full suites where optional hms is present |
    | integer64 | Exact decimal path | Requires bit64 | WSL bit64 4.6.0.1 tests; absent on Windows |
    | units | Unit metadata and visible formatting | Optional units conversion, round-trip checks | WSL units 1.0.0 tests; class/unit/offset-temperature preservation; Windows absent |
    | haven_labelled / spss | Raw/label modes, tagged NA and user-missing metadata | Valid integer/double/character metadata only | WSL haven 2.5.5; absent-mode Windows tests |
    | raw / list<raw> / blob | Bounded hex summaries and readonly inspector | Read-only | Raw/control tests on both; WSL blob 1.3.0 and binary PTY |
    | sf / sfc / sfg | Geometry/CRS summary and bounded selected-cell inspection | Geometry read-only; ordinary sf attributes can edit | WSL sf 1.0.24 tests; active geometry/CRS/class checked |
    | Generic S3/vctrs | Validated pillar/format fallback | Only verified text-to-prototype casts | Class-specific checks and readonly failure; arbitrary methods remain trusted R code |
    | Period/Duration/Interval | Generic extension, not dedicated calendar display | Read-only | WSL lubridate 1.9.5: S4 TRUE, extension handler, editable FALSE for all three |

    A2.3 is not implemented as a specialized typed handler. No lubridate dependency
    or Period/Duration/Interval parser exists in the typed source. The separate A4
    value exporter recognizes these S4 classes; the three WSL sample values
    round-trip identically through generated methods::new code. That is not proof
    of calendar editing, DST semantics or the complete A2.3 test matrix.

    Optional absence is guarded; unsafe extension types stay read-only. Scalar
    editing may copy the R vector under copy-on-modify, an expected O(n) allocation,
    without converting all values. List-type inference samples up to 1000 edges,
    so unusual middle-only raw/geometry cells may use the generic safe summary.
    Huge single geometries and custom format methods remain H3 profiling targets.
""")

write("DATA-SOURCES.md", r"""
    # Data sources and schema contracts

    Built-ins found in source are table_source(), db_table_source() for RSQLite,
    and db_query_source() with a built-in SQLite pager and a caller-provided DBI
    adapter protocol. No DuckDB/dbplyr/Arrow auto-adapter, source identity registry,
    Arrow reader or collect() path exists. WSL tests construct dbplyr/Arrow objects
    and verify explicit rejection; they do not demonstrate adapter support.

    table_source requires an exact nonnegative whole count <= .Machine$integer.max,
    unique nonempty names and data.frame page results. Unknown, estimated and
    over-limit counts are rejected. Current docs/data-sources.md states the same
    exact-count requirement, so the earlier documentation contradiction is resolved.

    DataTable samples at most 100 rows across all columns to infer schema, then
    projects visible columns and caches at most 32 pages. Reusing a wider cached
    page is allowed. Later successful pages must preserve storage/class/type
    attributes and S4 prototype slots; slice-dependent sfc bounds are excluded.
    Unsupported source operations do not silently materialize or scan. Supplied
    callbacks, initial counts and database queries are synchronous and may block UI.

    F06 fixed a real collision in the concatenated projection key using byte-length
    prefixes. The public regression switches from columns a,b to one column a-CR-b
    at row 101 and checks that the resulting viewport contains 501.

    F01 remains: set_data assigns .source and clears schema/cache before validating
    row count/seed. A rejected replacement leaves old .data with the new invalid
    source. This also clears edit provenance before success. Refresh delegates
    source mutations before rebuilding state; callback-side transactions cannot
    generally be rolled back by termr, so H2 must define the boundary explicitly.

    SQLite identifiers are DBI-quoted and supported filters bind values; paging
    uses bound LIMIT/OFFSET. Without requested sorting, queries do not promise a
    stable SQL row order. Concurrent external writes and nonunique sorts can
    change positions between pages. No snapshot transaction/stable row key is
    created implicitly; this is a documented positional protocol limitation.

    Source close is explicit. Changing a DataTable source does not close borrowed
    sources automatically. Query sources never own the supplied DBI connection.
    Custom non-SQLite DBI pagers are user code, not built-in feature coverage.
""")

write("REPRODUCIBLE-CODE.md", r"""
    # Reproducible R-code audit

    R/reproducible-code.R builds calls/symbols/constants with language objects.
    parse() is restricted to dput-emitted bare literals; arbitrary cell/filter
    text is not parsed/evaluated during generation. Executable/reference-bearing
    values fail the whitelist. Value export preserves double precision, integer64,
    Haven tagged payloads and tested structured attributes. Limits are 1000 rows,
    10000 cells, 1 MB source, 1000 edited cells and nesting depth 40.

    Value mode serializes the selected bounded current value. Pipeline mode
    describes the final filter/sort/columns/selection, not action history.
    Edits mode records bounded original-row assignments, not remote writes.
    The model marks source identity unknown and requires a caller-supplied data
    binding. Source-backed pipeline/edits exports explicitly return unsupported.
    Query strings, credentials and remote connection state are not exported.

    F02 is confirmed even when the binding is exactly table$data: after editing
    the sorted key 1 to 10, table$view is still 1,2,3, but the generated filter/sort
    pipeline computes 2,3,1 and claims exact. This is a DataTable-view/export
    integration error, not merely an unidentified external source.

    New source assignment resets the edit ledger and view; failed assignment can
    reset them before committing the replacement (F01). H2 must cover failure
    rollback and edits affecting filters as well as sort keys. Existing tests
    cover hostile names, source-row edit identity, unchanged input, limits, column
    reorder/hide and typed round-trips but did not expose this combined path.
""")

write("NATIVE-CHARTS.md", r"""
    # Native charts

    Five exported constructors create internal ChartWidget instances: line,
    scatter, bar, histogram, heatmap. ChartWidget inherits Widget and contains one
    empty SelectionRegion child. Validated spec → statistics/scales → layout →
    geometry/surface → packed cells → ordinary termr painting. There is no extra
    terminal driver or optional termrcharts runtime requirement.

    replace_chart_data validates a candidate before update_data commits it.
    Selection resets to a valid initial item after replacement; original data
    indices are kept through finite-point filtering for documented event payloads.
    Resize/data changes rebuild plans; selection-only changes reuse geometry and
    invalidate the marker region. Empty/narrow/Unicode/clipping and differential
    repaint cases are covered by native chart tests.

    Binding supports line/scatter, scalar x/y extractors, source restart detection,
    discontinuities and a max_points limit of 1..1000000. Pending records use a
    bounded ring. Overflow drops oldest events and marks a gap; each scheduled
    chunk handles at most 16 records. Unmount disposes its private subscription
    handle; App shutdown invokes on_app_shutdown; borrowed streams remain open.

    F03 is the documented drain-only render policy: with 64 queued records and 16
    new records before each drain, nine flushes leave 48 pending, 100 processed
    retained values and zero displayed values. The event loop itself remains
    responsive and memory count is bounded, but live charts can stay stale forever.
    H2 should choose a bounded display cadence; H3 should measure cost rather than
    simply raising the per-pass limit.

    Input normalization/storage scale with source size, and histogram bins are
    computed eagerly with graphics::hist(). Viewport-bounded output does not mean
    O(viewport) first-render CPU for all inputs. Queue limits count records, not
    arbitrary payload bytes. ChartWidget's disposal registration accesses Widget
    private state, a concrete internal coupling to preserve in lifecycle work.
""")

write("STREAMS-MIRAI-NANONEXT.md", r"""
    # Reactive graph, streams, mirai and nanonext

    signal/computed/watch use namespace-level rx state, dependency versioning,
    ordered effect flushing and explicit disposal. batch/untracked restore
    observer/depth state on unwinds. These APIs are experimental and synchronous.
    Custom effects can still run arbitrary slow R code on the main thread.

    termr_stream uses mutable ring slots, bounded event count and registration-order
    callbacks. It rejects reentrant emit before storage, skips unsubscribed
    callbacks, stops delivery after close, isolates callback errors and runs
    callbacks untracked. History/latest may retain reference objects by contract;
    event count is not a byte bound. Dropping a handle does not unsubscribe.

    Nano uses loopback defaults, bounded raw JSON, payload/depth/schema validation,
    bounded send/receive buffers, nonblocking AIO and polled snapshot recovery.
    Publisher close unlinks the source subscription but does not own the stream.
    Subscriber owns its reconstructed local ring. There is no native R callback
    thread or process-control command protocol. Authentication/encryption is not
    supplied for arbitrary external endpoint deployments.

    Mirai has a separate named compute profile, bounded admissions/serialized
    inputs, explicit task timeout/cancel and a bounded metadata stream. Progress
    uses a nonblocking push/pull channel; final envelopes reconcile progress.
    settle() observes already-resolved completion before cancellation, removes
    terminal tasks from pool state and releases the duplicate native reference.
    Task results/handles remain caller-owned. close/restart touch only verified
    owned daemon processes. trusted local job serialization is distinct from
    untrusted nano JSON.

    U01: mirai and nanonext are absent on both current platforms. Pure stream/
    validation and dependency-guard tests ran; actual sockets/daemons, cancellation
    races, promise settlement and shutdown failure injection did not. Static
    inspection of these paths is not runtime proof. No native-runtime race or
    process leak is claimed without execution.

    H2/H4 must run installed native backends: complete-vs-cancel scheduling,
    queued timeout, worker exit during poll, stalled snapshot recovery, callback
    close/reentry and repeated pool/socket creation. Source callbacks that run
    slowly remain an explicit UI responsiveness limitation.
""")

write("SHINY-PLOTLY.md", r"""
    # Shiny and Plotly

    termr_shiny_receiver owns one source subscription, bounded history, cached
    status/value reactives and one polling observer. Per-session wrappers share
    a binding in session$userData; acquire/release leases resume at first session
    and suspend after the last. A shared receiver remains explicitly owner-closed;
    implicit receivers close at session end. close_source is FALSE by default.

    receive/poll track duplicate/out-of-order metadata, gaps, stale values,
    restarted source identity and invalid snapshots. Source callbacks coalesce
    before reactive flush. The bridge is telemetry-only: no bidirectional Shiny
    process-control protocol exists or was added.

    Plotly integration lives in the system-monitor-live visualization/dashboard
    examples and tests. It appends bounded traces and resets on restart/gap; this
    is not a generic new plotly renderer in the termr core. termr_stream_data()
    converts telemetry to a bounded data.frame with time/sequence/segment columns.

    WSL has Shiny 1.10.0 and Plotly 4.10.4 and executes shared-session, plot building
    and optional visualization tests. Windows lacks these packages and skips
    their runtime tests. Browser visual rendering, disconnected real sessions
    under long load and native telemetry reconnection were not certified.
    No Shiny session ownership defect was confirmed in H1. Future fault injection
    must distinguish shared receiver ownership from borrowed source lifetime.
""")

write("INKR.md", r"""
    # inkr integration and focused profiling

    The sibling official checkout is inkr 0.1.0, HEAD 3a19331. termr calls exported
    ink_parse/read/compile/element/compute/explain via guarded getExportedValue.
    It does not reimplement inkr selector resolution or import private inkr code.
    Existing RTCSS is a separate older language; the inkr result enters one
    documented layer above RTCSS and below inline/state style. Explicit provenance
    filters registry defaults so an empty sheet does not reset termr themes.

    Focus/classes/parents/states form the path key. The per-App FIFO holds at most
    4096 signature results, no Widget objects. The probe inserted 4100 unique
    keys and observed exactly 4096. Replacement and unmount reset it; focused
    tests cover class/id assignment, reparent, states, clear, transparency and
    chart/DataTable paths.

    Colors pass through idempotent termr normalization in the adapter/style
    parser and capability downgrade in the renderer. This repeats validation,
    not RGB-to-palette downgrade. Explicit transparent background is a named NULL
    clearing a lower fill. L03: alpha declarations compile and replace the sheet,
    then error when a matching widget is computed. Atomicity currently means
    parse/compile/probe validation, not prevalidation of every termr mapping.

    Profile evidence is in inkr-profile-summary.csv, inkr-micro-profile.csv and
    the sampled profile-*-total/self.csv files. For 2000 widgets, one profiled
    run took 0.83 s without inkr, 1.77 s with repeated paths (3 entries, 6096 bytes),
    and 6.67 s with unique IDs (2002 entries, 4850088 bytes). Profiling overhead,
    startup and scheduling mean these are diagnostic measurements, not a fresh
    replacement for the previous 10000-widget benchmark.

    For 1000 direct operations: element path construction 0.81 s; public compute
    on a prebuilt element 0.97 s; bridge cache hit 0.26 s. A 100-widget tree walk
    repeated 100 times took 0.06 s. In sampled unique-path CPU, bridge total was
    77.34%, exported-call wrapper 57.91%, element construction 27.52%, color mapping
    3.24%. These totals overlap: never add them. Mapping/bookkeeping remains in
    bridge self time and is not independently measured as an entire stage.

    Avoiding ink_session_* in 0.1.0 is supported by fresh evidence: sibling
    insertion allocates 4.10 MB at 1000 nodes and 16.19 MB at 2000. The public
    implementation's link_child in R/session-state.R:196 appends c(existing,key).
    The bounded stateless path cache therefore avoids a measured quadratic cost.

    L04: unmount code resets inkr caches even with no sheet. Removing 1000 siblings
    without inkr allocated 33,096,000 bytes specifically below
    inkr_reset_style_cache, out of 45,888,552 gross bytes. It is not a retention
    leak, but it contradicts a performance reading of “unchanged optional-free
    path.” H3 should guard unused cache work and separate state paint/layout
    signatures before revisiting the external session API.
""")

write("RESOURCE-LIFECYCLE.md", r"""
    # Resource ownership and lifecycle

    | Resource | Creator/owner | Cleanup and failure boundary | Can outlive App? |
    |---|---|---|---|
    | Terminal driver/raw console state | App starts supplied driver | run() on.exit → shutdown → driver.stop; steps protected; F05 fixes unreturned Pilot startup | Forced OS termination remains outside guaranteed cleanup |
    | POSIX reader process/PTY harness | Driver / Python Session respectively | kill_tree, stty restoration; harness wait/close handles sessions | Not intended |
    | processx workers and temporary RDS/progress files | App; optional widget owner | completion/cancel/timeout and dispose-unmount; same-app moves preserve; stdout draining line-bounded | Retained Worker results can remain caller-owned |
    | Widget timers/animation | Widget handles / App TimerManager | detach cancels widget timers; App shutdown cancels manager/animator | Inactive handles may remain but do not run |
    | Signal effects | Widget reactive handles or caller | Widget disposal or explicit dispose | Yes when caller-owned; App stop is not blanket disposal of arbitrary user graphs |
    | Stream listeners/history | Stream callback registry and caller subscription | Explicit unsubscribe/close; close stops further current dispatch | Yes by contract; dropping handle alone does not release callback |
    | Chart stream binding | ChartWidget | dispose handle on unmount plus on_app_shutdown, active flag prevents late scheduled work | Stream itself is borrowed |
    | Nano sockets/AIO | Publisher/subscriber transport | Explicit idempotent close, unsubscribe/cancel AIO; setup on.exit | Yes if caller intentionally keeps transport |
    | Mirai compute profile/pull socket | Explicit pool | close/restart settle tasks and stop owned daemons only | Pool and result handles are caller-owned; runtime untested here |
    | Shiny subscription/observer | Receiver; sessions acquire leases | Last session suspends; implicit receiver closes; shared owner explicitly closes | Shared receiver intentionally can |
    | DataTable source/pages | Caller supplies source; table owns cache | Table$close explicitly invokes source close; switching does not own borrowed source | Yes, explicit protocol |
    | DBI connection wrapper | Caller, ownership flag | disconnect only if owned or force; query source never owns | Borrowed resources must remain open |
    | SQLEditor/DatabaseExplorer owned DB | Mounted widget shutdown hook | F08: hook is absent after remove, so later App shutdown misses it | Currently survives unexpectedly after removal |
    | Arrow readers | No built-in reader created | User callback's responsibility | No built-in ownership contract exists |
    | inkr cache | App | Bounded results; replace/unmount reset; no session/native resource | App object can retain bounded cache until GC |

    Reference cycles by themselves are collectable in R. Observable retained roots
    are decisive: F05 retained App in termr_env$apps; F08 left a real live owned DBI
    connection after its automatic cleanup path disappeared. No native worker/socket
    leak is claimed from static suspicion alone.

    Close operations are often idempotent by flags and backend validity checks.
    Error halfway through external close remains a fault-injection target, especially
    mirai shutdown and nano socket/AIO close. Do not “fix” this by closing borrowed
    DBI connections or shared Shiny/stream resources.
""")

write("SECURITY.md", r"""
    # Security and input validation

    No confirmed exploit/security P0 was found; this is not a proof of absence.
    Only local non-destructive probes were performed, with no network attacks.

    | Reachable input | Current boundary / evidence |
    |---|---|
    | Cell edit text | Strict type parsers/casts; stop('must not execute') rejected as integer text and data unchanged |
    | Generated R source | Whitelisted values, language-object AST, escaped names, bounded source; tests evaluate generated output separately |
    | SQL identifiers/filter values | DBI quoting and bound values in SQLite pagers; full SQL editor intentionally executes caller SQL |
    | Worker command/closure | processx executes command/args without a shell; minimized closure capture rejects unsupported references/active bindings |
    | Nano wire | Bounded raw JSON, schema/topic/version/depth checks; no R unserialize on network telemetry |
    | Mirai job | Trusted local serialized R closure/args; not a sandbox for hostile code |
    | Stylesheet | Local file/text/AST/compiled object; HTTP(S) URL input rejected; URLs in comments remain inert text |
    | Binary cells | Eight-byte hex summary and bounded readonly inspector; raw bytes are never interpreted as UTF-8/ANSI |
    | Visible text/labels | sanitize_text removes C0/C1 terminal controls; charts clean text; ScreenBuffer/ANSI output is centralized |
    | Clipboard | OSC52 payload is encoded, not raw control text; exporter has source-size limits |

    F06 demonstrates that legal control characters in column names also matter
    to internal encodings, even though terminal text is sanitized. Its cache key
    now uses lengths rather than an ambiguous separator. F09 shows a non-finite
    count validation gap; this is malformed-input correctness, not an asserted
    security vulnerability.

    Remaining limits: arbitrary trusted callback/format/extractor R code can block
    or have side effects; record-count limits do not bound arbitrary local payload
    bytes; one very long subprocess line can exceed a line-count budget; selector
    cache has no eviction. H2/H4 should use bounded adversarial fixtures before
    classifying these as denial-of-service defects.
""")

package_table = "\n".join(
    f"| {name} | {packages_windows[name]['version'] if packages_windows[name]['available'] == 'TRUE' else 'absent'} | "
    f"{packages_wsl[name]['version'] if packages_wsl[name]['available'] == 'TRUE' else 'absent'} |"
    for name in packages_windows if name not in ("roxygen2", "testthat", "processx")
)
write("OPTIONAL-DEPENDENCIES.md", textwrap.dedent("""
    # Optional dependencies and actual coverage

    DESCRIPTION declares a small Imports set. None of inkr, typed-data extension
    packages, DBI, Shiny, Plotly, mirai or nanonext is a mandatory namespace import.
    R CMD check's loading-with-stated-dependencies stage passes independently.
    Guard/source inspection, not merely skipped tests, supports optionality.

    | Package | Windows available version | WSL available version |
    |---|---|---|
    """) + package_table + textwrap.dedent(r"""

    inkr 0.1.0 was installed only into temporary validation libraries from the local
    sibling checkout; separate default-library focused runs verified its absence
    path on both platforms. No package dependency update was made.

    WSL's units, haven, bit64, sf, blob, hms, DBI/SQLite, dbplyr/Arrow and
    Shiny/Plotly cases actually execute in current suites. A loaded namespace alone
    was not called full integration proof: backend Arrow/dbplyr tests verify
    rejection, while lubridate probes show readonly fallback and three value
    round-trips. DuckDB is absent and no automatic adapter exists.

    mirai/nanonext are absent on both platforms. Their runtime tests are skipped;
    JSON/stream/guard-only tests are not described as daemon/socket validation.
    System libraries for installed WSL units/sf/Arrow are usable for the tests
    exercised; no standalone clean-system installation or macOS UDUNITS/GDAL setup
    was attempted. Future CI needs explicit optional-runtime jobs and an available
    repository/source for the independent inkr package.
"""))

write("KNOWN-ISSUES-VERIFICATION.md", r"""
    # Verification of earlier known issues

    | Issue | Fresh result | Evidence / interpretation |
    |---|---|---|
    | A: combined PTY Tab+Enter | Current baseline passed; final repetitions recorded in TEST-RESULTS | grouped headless/parser path passes; CR preserved by processx; exact current archive installed before PTY |
    | B: Windows processx access denied | Reproduced only in sandbox diagnostic; same probe outside sandbox succeeds | probes-windows-before.log vs probes-windows-before-elevated.log; environment issue, not package process bug |
    | C: force-Suggests-disabled coverage | Exact package manifests and skip reasons recorded | Native mirai/nano remain missing; not called full coverage |
    | D: A2.3 lubridate | No specialized handler/editing; generic S4 readonly display | WSL probe: extension/FALSE for all three classes; three value exports round-trip |
    | E: data adapters | SQLite table/query built-ins only | R/datatable-source-sqlite.R, R/datatable-source-query.R; dbplyr/Arrow rejection tests |
    | F: inkr overhead | Measured selector-path sensitivity and session insertion allocation | INKR.md and CSV/sample profiles; no broad optimization |
    | G: Pilot roxygen | Reproduced in isolated roclet, fixed by internal noRd annotation | roxygen-diagnostics.log and doc-windows.log |
    | H: developer runner exit | Controlled failure/error/success return 1/1/0 | verify-test-runner.R uses isolated temporary packages; runner-exit-status.csv |

    Earlier B-1 CJK cursor, B-2 scrollbar dirtiness, B-3 wide-edge repaint and B-4
    layout diagnostic overflow regressions are still present and pass in current
    full suites. They were not counted as newly open H1 bugs.

    Earlier S-1 generic count coercion is still reachable through log_events(Inf),
    now captured as F09. Tiny Pilot intervals, Ctrl+D interpretation, key-flood
    latency and old ConPTY crash hypotheses were not rerun without a new bounded
    hypothesis. Forced SIGTERM/SIGHUP cannot be inferred from normal cleanup;
    getting-started docs already distinguish forced process termination.

    The PTY install guard checks only package version, so matching version 1.0.1
    alone would not prove matching source. H1 explicitly installs the recorded
    current source archive and records its digest. Old failure logs are historical
    evidence, not a current failure verdict or a proven root cause.
""")

findings = [
    ("F01", "P1", "confirmed defect — open", "DataTable source replacement", "R/widget-datatable.R: DataTable$set_data",
     "A rejected source replacement commits .source and clears state before count/schema validation.",
     "Construct a local x=1:3 table; replace it with table_source(function() NA_real_, 'x', ...).",
     "Replacement errors and the previous usable table remains active.",
     "The error occurs, but source_changed is TRUE and subsequent row_data also errors on the invalid source.",
     "probe-contracts.R / failed-source-switch; Windows elevated and WSL current/final logs.",
     "High: deterministic on Windows and WSL.",
     "Build candidate state before commit or restore every affected UI/cache/provenance field on failure. Define callback-side rollback separately.",
     "regressions-open.R F01; extend to seed errors, schema mismatch, refresh and previous edit ledger.",
     "H2, priority 1"),
    ("F02", "P1", "confirmed defect — open", "DataTable / A4 view contract", "R/widget-datatable.R: set_cell and reproducible_code; R/reproducible-code.R: termr_r_pipeline_ast",
     "An exact pipeline re-sorts edited data while DataTable retains the old row-index order.",
     "Sort x=1:3; set_cell(1,'x','10'); evaluate pipeline with data equal to table$data.",
     "An exact result equals the displayed current view under the explicitly supplied binding.",
     "Display is 10,2,3; generated result is 2,3,10; status remains exact.",
     "edited-sort-pipeline-consistency in fresh Windows/WSL probes.",
     "High: binding ambiguity was removed by using the current table$data.",
     "Choose edit/view semantics; reapply sort/filter or encode actual view state/fail closed. Do not silently claim exactness.",
     "regressions-open.R F02; add edited filter keys, selection, hidden sort keys and source replacement.",
     "H2, priority 1"),
    ("F08", "P1", "confirmed defect — open", "Owned DBI lifecycle", "R/sql.R: SQLEditor$on_app_shutdown; R/app.R: shutdown tree walk",
     "Unmount removes the only automatically traversed owner of an owned connection.",
     "Create SQLite connection and owned wrapper; mount SQLEditor; remove editor; stop App.",
     "The owned connection is released by disposal or eventual App cleanup; borrowed connections stay open.",
     "DBI::dbIsValid(con) remains TRUE after both unmount and App stop. Probe explicitly disconnects it afterwards.",
     "owned-sql-editor-unmount, probes-wsl-current.log and final WSL log.",
     "High observation; supported by existing automatic shutdown hook/ownership contract.",
     "Register one ownership-aware disposal routine for both unmount and shutdown, preserving same-App moves and shared borrowed wrappers.",
     "regressions-open.R F08; add owned/borrowed, repeated close, same-App reparent and DatabaseExplorer composition.",
     "H2, priority 1"),
    ("F05", "P2", "confirmed defect — fixed", "Headless startup lifecycle", "R/testing.R: Pilot$initialize",
     "A mount callback error before a Pilot is returned leaves its App running and globally registered.",
     "Mount a widget whose mount handler stops; call test_app().",
     "Startup failure unwinds App/driver registration without requiring an unavailable Pilot handle.",
     "Before: running TRUE, retained driver, active-App delta 1. After: FALSE/NULL/0.",
     "regressions-failing-first.log; regressions-after.log; test-h1-contracts.R and final probes.",
     "High: failing-first and passing-after regression.",
     "H1 added startup-completion guarded on.exit shutdown, preserving the original error.",
     "tests/testthat/test-h1-contracts.R: failed pilot startup releases its registered app and driver.",
     "Fixed in H1; H4 repeated failure cycles"),
    ("F06", "P2", "confirmed defect — fixed", "Source projection cache", "R/widget-datatable.R: get_source_page",
     "CR-delimited column-name concatenation aliases a two-column projection with one legal CR-containing name.",
     "At source row 101 render columns a,b; then show only the column named a-CR-b.",
     "Cache selects the correct projected data and renders value 501.",
     "Before: undefined columns selected; after: correct bounded viewport renders.",
     "source-projection-cache-key; failing-first and after regression logs.",
     "High: deterministic public operations reproduce and verify the fix.",
     "H1 replaced delimiter-only projection encoding with byte-length-prefixed tokens.",
     "tests/testthat/test-h1-contracts.R: source projection cache keys distinguish control characters in names.",
     "Fixed in H1"),
    ("F09", "P2", "confirmed defect — open", "Count validation / logging", "R/style.R: check_count; R/app.R: App$log_events",
     "Non-finite capacity is accepted and coerced to NA, producing a downstream startup error.",
     "Call app(label('x'))$log_events(size=Inf), then test_app on that App.",
     "Reject invalid capacity immediately with an actionable size error.",
     "No validation error; integer coercion warning; startup errors in tail with invalid n.",
     "nonfinite-log-capacity in probes-wsl-current/final; regressed earlier S-1.",
     "High: deterministic local invalid-input probe.",
     "Audit callers of check_count and apply finite/whole/range validation where counts must be bounded; distinguish cell-size clamping policy.",
     "regressions-open.R F09; NULL/0/fractional/NA/Inf/2^31 boundary matrix.",
     "H2 validation sweep"),
    ("F07", "P3", "documentation mismatch — fixed", "Roxygen internal class documentation", "R/testing.R: Pilot class definition",
     "The undocumented internal R6 class was processed as a help topic and emitted R6 field/method diagnostics.",
     "Run diagnose-roxygen.R on the same internal class with and without a noRd block.",
     "Internal class does not create a public topic or spurious public-method diagnostics.",
     "Without block: diagnostics plus skipped nameless Pilot topic; with noRd: zero diagnostics/topics.",
     "roxygen-diagnostics.log; regenerated doc-windows.log.",
     "High: isolated same-source comparison, roxygen2 8.1.1.",
     "H1 added an explicit internal noRd block; public test_app/Pilot method prose remains.",
     "diagnose-roxygen.R and tools/dev.R doc; NAMESPACE/man preservation hashes.",
     "Fixed in H1"),
]
lines = [
    "# H1 findings", "",
    "Defect/documentation counts: P0 0, P1 3, P2 3, P3 1. This is six confirmed",
    "runtime defects plus one documentation mismatch. F05/F06/F07 are fixed; F01/F02/",
    "F08/F09 remain open. Design limitation F03 and policy risk F04 are separate.",
    "Passing package checks do not negate the reproducible failures below.", ""
]
for ident, sev, status, component, location, description, repro, expected, actual, evidence, confidence, fix, regression, stage in findings:
    lines.extend([f"## H1-{ident} — {sev} — {component}", "",
                  f"- Category/status: {status}.",
                  f"- Location: {location}.",
                  f"- Description: {description}",
                  f"- Reproduction: {repro}",
                  f"- Expected: {expected}",
                  f"- Observed: {actual}",
                  f"- Evidence: {evidence}",
                  f"- Confidence: {confidence}",
                  f"- Fix: {fix}",
                  f"- Regression: {regression}",
                  f"- Target: {stage}.", ""])
lines.extend([r"""
## H1-F03 — P2 — confirmed documented design limitation

- Component/location: ChartWidget$flush_stream_queue in R/chart-widget.R.
- Reproduce: max_points=100; emit 64 records; before each of eight 1 ms flush
  advances emit another 16. Probe uses controlled headless scheduling, not sleeps.
- Expected H2 responsiveness goal: displayed data advances while backlog remains
  bounded. Current documented contract only catches up after the queue drains.
- Observed: 9 flushes, 48 pending, 100 processed retained points, 0 displayed points.
- Evidence/confidence: sustained-chart-backlog on both platforms; high.
- Suggested work: choose a bounded render cadence without removing 16-record
  processing limits or overflow gaps; measure cost in H3.
- Regression/target: F03 in regressions-open.R is a proposed H2 liveness invariant,
  not evidence that current documentation promises continuous rendering. H2/H3.

## H1-F04 — P2 — unverified contract risk, confirmed behavior

- Component/location: App$dispatch snapshots target$ancestors once.
- Reproduce: child handler removes its parent; parent also has a handler.
- Observed: parent$app is NULL, but its snapshotted handler runs once.
- Evidence/confidence: detached-ancestor-dispatch; high observation confidence,
  medium contract interpretation because detach is not destruction of the R6
  object and the public mid-dispatch rule is unspecified.
- Proposed invariant: inactive ordinary ancestors should not receive further
  delivery; lifecycle events may need different treatment.
- Suggested work/target: decide and document semantics in H2 before changing the
  dispatch loop. F04 in regressions-open.R records the candidate policy.

## Other confirmed limitations and coverage risks

| ID / category | Severity | Evidence and reproduction | Current boundary / next action |
|---|---|---|---|
| L01 specialized lubridate absent | P2 limitation | WSL creates Period/Duration/Interval: all choose extension/read-only; three value exports round-trip | No dedicated calendar parsing, DST editing or A2.3 suite; plan a separate type phase |
| L02 backend adapters absent | P2 limitation | Source inventory + dbplyr/Arrow rejection tests | SQLite built-ins; other DBI callbacks need caller code; no automatic DuckDB/dbplyr/Arrow support |
| L03 inkr conversion errors are late | P2 limitation | Valid alpha sheet replaces old sheet; matching computed_style then errors | Compile transaction does not validate all future termr mappings; H2 decide eager validation/fail-closed contract |
| L04 inkr overhead | P2 limitation | INKR.md: unique paths, element-conversion microprofile and optional-free unmount allocation | Bound counts are real; optimize measured conversion/cache-reset work in H3 |
| L05 global selector cache unbounded | P2 design risk | R/selectors.R parse_selector assigns every successful unique selector with no eviction | Static bound absence confirmed, no retained-heap soak measured; H3/H4 measure distinct-query churn |
| U01 native telemetry/task runtime untested | P1 validation risk, not defect | packages manifests show mirai/nanonext absent; guarded runtime tests skip | Install/pin optional test jobs and exercise races/cleanup before release |
| E01 Windows child pipes denied in sandbox | Environment issue | Same processx probe fails restricted and succeeds elevated with unchanged package | Use authorized subprocess-capable environment; no termr worker fix justified |

Open regression script exits nonzero intentionally for unresolved defects/design/
policy candidates. It is outside the package suite. It must never be summarized
as an unexpected package-check failure or hidden by blanket skips.
"""])
write("FINDINGS.md", "\n".join(lines))

write("H2-BUG-HUNTING-PLAN.md", r"""
    # H2 prioritized bug-hunting plan

    Run run-open-regressions.R first. Its named cases provide concrete current
    failures; F03 and F04 additionally require an explicit contract decision.

    | Priority / finding | Fixture and failure trigger | Required invariant / successful fix |
    |---|---|---|
    | 1 F01 | Local table with edits/filters/selection; replacement callbacks return NA count, throw on seed, change schema, then refresh/switch | Failed replacement preserves previous source, data, schema, selection, cache and edit ledger; successful replacement resets all together |
    | 1 F02 | Sorted/filtered table; edit sort/filter key across threshold; hide sort key, reorder columns, select rows | Exact pipeline evaluation under the declared data binding equals current selected/displayed state; otherwise result explicitly unsupported/limited |
    | 1 F08 | SQLite owned/borrowed wrappers; unmount, same-App move, screen pop, repeated stop, shared explorer/SQL child | Owned connection closes once at agreed disposal point; borrowed remains valid; same-App move does not release ownership |
    | 2 F09 | Public count consumers with NULL,0,1.5,NA,Inf,2^31; record logging startup | Invalid capacities fail at the boundary without warnings/partial state; accepted values have explicit documented rounding/range policy |
    | 2 F03 | Existing 64-backlog fixture + 16 arrivals each tick; max_points=100; independent keyboard/timer activity | Choose bounded display cadence; visible progress while queue nonempty; memory count bounded and gap semantics preserved |
    | 2 F04 | Detach child/parent during propagation, reparent across Apps, queued key and lifecycle events | Define ordinary vs lifecycle continuation policy, then test no delivery to disallowed inactive targets |
    | 2 U01 | Real mirai/nano installed: scheduled completion before cancel, cancel queued task, timeout, process exit during poll, duplicate/stale snapshot | Completion/cancellation terminal states agree; bounded progress; no owned native resources remain after close/error |
    | 3 L03 | Valid inkr syntax with unsupported termr color/custom property; matched/unmatched future widgets | Document compile-only transaction or prevalidate mappings safely; rendering must not silently corrupt fallback style |

    Automate source/property cases with fixed seeds and public methods. Save the
    smallest failing seed, data and exact event order. Do not base race assertions
    on arbitrary sleeps: use task readiness, controlled timers and explicit
    callback barriers. Compare incremental and forced full frames after failure
    recovery. Reuse test-h1-contracts.R for already-fixed lifecycle/cache behavior.

    Acceptance requires passing the relevant open regression, failure-then-success
    cases, owner cleanup checks, focused old regressions and appropriate platform
    checks. Do not “fix” F02 by merely relabeling an inaccurate export as exact or
    F08 by closing every supplied connection.
""")

write("H3-OPTIMIZATION-PLAN.md", r"""
    # H3 optimization plan

    Measured baselines are diagnostic, single-host measurements, not speed targets.
    Preserve H2 semantics before optimizing paths with unresolved correctness.

    | Candidate | Evidence | Next controlled measurement |
    |---|---|---|
    | Widget-to-inkr conversion on unique paths | 2000 unique IDs: 6.67 s vs repeated paths 1.77 s; element construction 27.52% sampled unique-path total CPU | Separate construction, public compute, map and cache-hit counters; compare repeated/unique/deep trees at 100/1k/10k and cold/warm |
    | Optional-free unmount resets | 1000 sibling removals allocate 33.1 MB under unused inkr reset | Compare guarded cache work with same logical tree; Rprofmem, total removal time, retained heap and final zero resource counts |
    | Paint-only state invalidation | Widget$same_layout_in conservatively returns FALSE whenever RTCSS/inkr exists | Trace layout vs paint counts for foreground-only, border/spacing-changing and ancestor selectors; preserve accurate layout semantics |
    | Session API insertion | 1000→2000 siblings grows gross allocation 4.10→16.19 MB | Re-evaluate only on a changed inkr release; record exact version and public API performance |
    | Global selectors / epochs | selector_cache lacks eviction; style/layout epochs are shared across Apps | Distinct-selector churn and two-App invalidation benchmarks; measure retained objects after GC, not RSS alone |
    | Chart streaming | 16-record chunks and full spec update at queue drain | After F03 policy fix, measure frame cadence, processing throughput, dropped-gap count, input latency and allocations at bounded rates |
    | Source formatting and large cells | 32-page count bound; schema signatures/prototype work; visible huge geometry may scan vertices | Sample row fetch vs type signature vs formatting time at 100/10k/100k rows with fixed page size and controlled cell bytes |

    Use Rprof plus function counters and Rprofmem. Windows sampled CPU totals differ
    from elapsed wall time; nested totals overlap and must not be summed. Separate
    instrumentation overhead from uninstrumented repeated runs and record locale,
    R/package versions, viewport, input bytes and tree shape. No arbitrary percent
    acceleration target is assigned before these baselines.
""")

write("H4-SOAK-TEST-PLAN.md", r"""
    # H4 bounded soak plan

    This is a plan, not an executed long-duration validation result. Resolve F01,
    F02, F08 and the chosen F03 policy before treating their soak cases as gates.

    | Scenario | Controlled workload / deadline | Ownership and leak criterion |
    |---|---|---|
    | App lifecycle | 1000 mount/start/stop cycles; inject mount/handler errors every 10 cycles; 10 min cap | active App registry returns exactly to baseline, driver stopped, no owned processes/timers |
    | Native charts + stream | 30 min, fixed seed 20261031, <=100 events/s, <=1 KiB/event, history/max_points 1000; bounded bursts 2000 | subscribers return to baseline after unbind/unmount; queue <=max_points; documented gaps and visible frame cadence; no linear retained heap growth |
    | SQLite table/source | 100k seeded rows; 500 source swaps, 10% controlled failures; bounded 100-row pages | cache <=32, old source intact after rejection, all owned connections invalid at cleanup, borrowed ones valid |
    | R-code export | 1000 bounded edit/filter/sort/selection cycles, values <=1 KiB, output <=1 MB | generated exact output equals model; ledger <=1000; limits fail closed without retaining prior selected data |
    | Mirai/processx | 30 min, 2 workers, max_pending 16, results <=1 MB; explicit 10 s task timeouts + 5 s teardown grace | active native/task count returns to baseline; no descendant processes/temp files after close; caller-retained results excluded from leak total |
    | Nano/Shiny | 30 min, 2 sessions, receiver 600 points, socket buffers 64, message <=16 KiB; disconnect/restart every 1000 messages | one shared subscription/observer, lease count exact, owner close clears native sockets/AIO; borrowed source stays open |
    | Styles/selectors | 10k controlled class/focus changes and <=5k unique selector strings; 10 min cap | inkr <=4096 entries; selector-cache growth separately attributed; unmount no widget retained by cache values |
    | PTY/resize/input | 10 min, finite recorded key batches and terminal sizes 1x1..120x40, no unbounded flood | ordered focus/press markers, restored termios/modes, normal or explicitly injected exit status |

    Warm up first, then sample retained R heap after GC, RSS high-water, resource
    counts and latency. RSS growth alone is not a leak verdict: require monotonic
    retained-object/native-resource evidence under a fixed bounded workload.
    Abort on budget/timeout, preserve seed/logs, cancel only owned resources and
    restore the terminal in finally/on.exit. Use isolated temporary databases,
    directories and loopback endpoints; never manipulate unrelated user resources.
""")

tests = f"""
    # Fresh validation results

    All results below come from this H1 turn, not earlier completion reports.

    | Run | Result |
    |---|---|
    | Windows focused integration | exit {exitcode("focused-windows.exit")}; missing optional integrations explicitly skipped |
    | WSL focused integration | exit {exitcode("focused-wsl.exit")}; installed typed/DBI/Shiny/Plotly cases execute |
    | Windows optional-free inkr | exit {exitcode("optional-free-windows.exit")} |
    | WSL optional-free inkr | exit {exitcode("optional-free-wsl.exit")} |
    | Windows tools/dev.R test | {windows[0]} assertions: {int(windows[0])-int(windows[3])} pass, {windows[1]} fail, {windows[2]} errors, {windows[3]} skips, {windows[4]} warnings; exit {exitcode("full-windows.exit")} |
    | WSL tools/dev.R test | {wsl[0]} assertions: {int(wsl[0])-int(wsl[3])} pass, {wsl[1]} fail, {wsl[2]} errors, {wsl[3]} skips, {wsl[4]} warnings; exit {exitcode("full-wsl.exit")} |
    | Windows R CMD build | exit {exitcode("build-windows.exit")} |
    | Windows R CMD check | Status: {check("check-windows.log")}; exit {exitcode("check-windows.exit")} |
    | WSL R CMD check | Status: {check("check-wsl.log")}; exit {exitcode("check-wsl.exit")} |
    | WSL headless PTY fixture | exit {exitcode("pty-fixture-wsl-final.exit")} |
    | WSL full real PTY harness | exit {exitcode("pty-full-wsl.exit")} |
    | WSL combined-focus repeats | {exitcode("pty-combined-wsl-repeat-1.exit")}, {exitcode("pty-combined-wsl-repeat-2.exit")} |
    | WSL binary/control PTY | exit {exitcode("pty-binary-wsl.exit")} |

    Windows is R 4.6.1 on Windows 11 x64; WSL is R 4.5.2 on Ubuntu 26.04.1 LTS,
    both UTF-8. Package checks use --no-manual --no-vignettes and
    _R_CHECK_FORCE_SUGGESTS_=false. Windows check lists 15 missing Suggests as INFO;
    WSL lists mirai/nanonext. Those native runtimes were not validated. MacOS,
    minimum R 4.1, live Windows console glyph rendering and PDF manual are NOT RUN.

    H1's failing-first main regressions reproduce Pilot retention and source-cache
    collision; both pass after fixes. The separate open-regressions script is
    intentionally nonzero: Windows has five failed candidate/defect assertions and
    one DBI skip; WSL has six failures and no skips. F03 is a documented design
    limitation and F04 is a proposed contract policy, not counted as proven defects.
    These audit-only files are excluded from the package suite by location.

    Developer runner status was independently checked with isolated temporary
    packages: failure=1, error=1, success=0. Windows processx sandbox denial was
    compared with a successful authorized outside-sandbox probe using the same
    code. It was not worked around by skipping worker tests in final validation.

    The Windows-built source archive is installed/checked natively in WSL; both
    digest records refer to the same file. The earlier baseline combined-focus
    run plus full-harness case plus two final repeats provide four current-tree
    combined-focus observations. This is not a proof that every historical PTY
    race is fixed, and the old failure's exact root cause remains unresolved.

    Roxygen generation now emits no Pilot diagnostics. Public man/NAMESPACE hashes
    and other baseline hashes are checked in preservation.csv. git diff --check
    output is saved in git-diff-check.txt. No release readiness claim follows from
    successful checks while P1 findings remain open.
"""
write("TEST-RESULTS.md", tests)

expected = {
    "EXECUTIVE-SUMMARY.md", "REPOSITORY-BASELINE.md", "ARCHITECTURE-MAP.md",
    "DEPENDENCY-GRAPH.md", "API-AUDIT.md", "WIDGET-RENDERER-LAYOUT.md",
    "TYPED-DATA.md", "DATA-SOURCES.md", "REPRODUCIBLE-CODE.md", "NATIVE-CHARTS.md",
    "STREAMS-MIRAI-NANONEXT.md", "SHINY-PLOTLY.md", "INKR.md",
    "RESOURCE-LIFECYCLE.md", "SECURITY.md", "OPTIONAL-DEPENDENCIES.md",
    "KNOWN-ISSUES-VERIFICATION.md", "FINDINGS.md", "TEST-RESULTS.md",
    "H2-BUG-HUNTING-PLAN.md", "H3-OPTIMIZATION-PLAN.md", "H4-SOAK-TEST-PLAN.md"
}
assert all((out / name).stat().st_size > 300 for name in expected)
print("Wrote", len(expected), "substantive H1 reports.")
