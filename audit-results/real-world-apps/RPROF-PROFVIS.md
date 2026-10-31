# Phase E — Rprof Profvis

Real Rprof workloads on both platforms cover application startup, DataTable and
event input, native stream-chart updates, Shiny reactive updates and real mirai
completion/nanonext traffic. WSL additionally profiles original rtop fixture
refresh in a separate candidate process. Rprof uses 10ms samples with memory
profiling; CPU/self/total CSVs, raw profiles, summary RDS and timing scope are in
`profiles-windows-final/` and `profiles-wsl-final/`. Both final runners exit 0.

`workbench-profvis.html` plus its local assets is a genuine profvis 0.4.0 workload,
saved without requiring Pandoc. `rtop-refresh.Rprof`/`rtop-refresh-total.csv`
capture the legacy path. Time includes setup/cleanup and lazy package/JIT costs;
these sampled profiles are diagnostic, not latency benchmarks. Worker compute
is in a different R process and not attributed to controller CPU.

An initial requested 5ms interval was clamped by this platform to 10ms; the final
script requests 10ms explicitly. A real Rprof/summaryRprof interoperability issue
also appeared: Shiny/Plotly debug call labels contain physical newlines and
break summaryRprof's memory parser. Raw `.Rprof` files are untouched. A separate
`shiny_updates-normalized.Rprof` joins only record-continuation lines; no samples
are dropped. `profile-summary.json` records the exact parser error, join count
and derived file on each platform. Other profiles parse directly.

Hot tables include termr layout/painting/event dispatch and Shiny/ggplot render
machinery as expected. No additional core performance rewrite was justified by
these short application profiles. Use H4 sustained loads to distinguish package
warmup, UI frame cost and backend/collector time before optimizing.
