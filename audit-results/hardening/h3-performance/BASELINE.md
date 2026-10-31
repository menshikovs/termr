# Reproducible baseline

Baseline HEAD: 1b10370d1df50e54a63706673b150feaf7b04889; branch 2.0-termr; package 1.0.1.
git-status-before.txt records the pre-existing dirty tree. baseline/R contains
the actual H2-era working files, not a clean checkout of HEAD. The baseline
manifest covers 567 initial files outside audit-results; preservation.json and
h3-only.patch distinguish H3 edits from existing work.

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

Run from the repository root with the same R library paths:

```powershell
$env:TERMR_H3_PACKAGE='audit-results/hardening/h3-performance/baseline'
Rscript audit-results/hardening/h3-performance/benchmark-frozen.R before core
Remove-Item Env:TERMR_H3_PACKAGE
Rscript audit-results/hardening/h3-performance/benchmark-frozen.R after core
```

Repeat with `broad` and `events`; extra-benchmark.R takes `before extra` or
`after extra`; granular-benchmark.R takes `before granular` or `after granular`.
component-micro.R takes the phase. lifecycle-events.R runs the
1,000-cycle App/stream test. All scripts use temporary profiling files only.
The final frozen harness is never edited during execution.

The initial core run completed its recorded rows but exited 1 after this agent
edited the script while R was still reading it; before-core-initial.* preserves
that attempt. The canonical core baseline was rerun against the verified source
snapshot. The initial extra run exposed a benchmark-only partial `$p` match to
`$parent`; cleanup now uses exact `[["p"]]` lookup and the run was repeated.
Neither failed attempt is silently presented as a passing command.

Fresh-App startup and repeated startup of the same App are measured separately;
fresh-process R/package load startup is not timed. Detailed scenario coverage is
in the subsystem reports and the raw CSVs.
