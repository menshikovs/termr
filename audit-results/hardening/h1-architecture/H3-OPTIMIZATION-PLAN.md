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
