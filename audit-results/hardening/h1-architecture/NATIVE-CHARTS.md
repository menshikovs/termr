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
