# Profiling evidence and root causes

Measurements use native Windows R 4.6.1 and the headless driver, seed 20261031,
one unrecorded warm-up and three recorded repetitions per scenario. Setup and
cleanup are outside timing; Rprofmem and 5 ms Rprof are enabled during the main
harness. CSV files contain every repetition, elapsed seconds and gross recorded
R allocation bytes; CPU profile CSVs preserve the first repetition's stack summary.
Reported spread is min–max, not a confidence interval. Sub-centisecond results
are below useful Windows timer resolution. MB means 1,000,000 bytes.

These are instrumented developer-machine measurements, not isolated-machine
latency guarantees. Some baseline and validation jobs overlapped; CPU contention
especially widens the 10,000-widget timing range. Allocation differences and
algorithmic evidence are stronger than small timing differences. Cross-platform
results are never used as speedup evidence. Rprofmem does not account for every
small SEXP or external-library allocation. Gross bytes are neither retained heap,
RSS nor peak memory. Credible process peak memory was not measured.

CPU profiles are named before/after-SCENARIO-SIZE-profile.csv. Their sampled
total percentages overlap through callers and must not be summed. Short cases
can have no samples. trace-copies.log demonstrates list duplication in the
original EventQueue; the timed allocation series supplies the scale evidence.

Before: unmount-no-sheet records 33,096,000 bytes under
inkr_reset_style_cache for 1,000 children and 165,480,000 for 5,000. App called
the reset and an extra subtree walk even without a stylesheet. The reset creates
an environment and a 4,096-slot character ring every time.

Before: render-unique-1000 spends substantial sampled time under
inkr_style_for_widget and inkr_element_for_widget. Every widget reconstructs the
same ancestor elements; every cache hit reconstructs ancestor signature lists.
The patch reuses epoch-scoped immutable public inkr elements and path prefixes.
The style adapter statements are extracted from the actual function body by
component-micro.R, so mapping timing does not use a separately maintained engine.

Before: enqueue of 10,000 events records 820,920,240 bytes; dequeue records
534,178,976. R6's environment holds a list, whose replacement through `$` copies
the growing/shrinking list. The revised hash environment avoids these copies.
Ordinary one-event and 100-event workloads are retained in the comparison table.

Chart evidence is structural: before-stream-freshness.csv shows processed=100,
displayed=0 and pending=48 after 21 flushes. Publication was conditional on an
empty queue. After publication occurs on the first chunk, at 60 Hz while
backlogged, and immediately on final drain, while yielding through widget
timers. This repair intentionally performs additional rendering.

Full Rprof raw sampling files are temporary; first-repeat summary stacks,
recorded allocation totals, scripts and per-repeat CSVs are retained. There is
no claim that these samples prove absence of all other bottlenecks.
