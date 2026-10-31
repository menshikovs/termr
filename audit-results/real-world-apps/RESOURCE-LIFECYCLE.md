# Phase E — Resource Lifecycle

Both OS ran 100 application startup/shutdown cycles, 1000 keyboard UI actions,
100 source changes, 100 theme changes, 100 chart updates, 5 real worker-pool cycles
and 20 transport reconnects. Counters, history limits and zero owned subscribers
after close were asserted. These are finite controlled series, not an H4 soak.

Windows samples (ps descriptors API reports OS handles on Windows):

| Checkpoint | RSS MiB | Live R heap MB | Child count | R connections | Handles |
| --- | --- | --- | --- | --- | --- |
| cold | 77.9 | 28.3 | 1 | 3 | 171 |
| startup-10 | 192.3 | 65.7 | 1 | 3 | 177 |
| startup-100 | 191.5 | 65.7 | 1 | 3 | 178 |
| workbench-closed | 157.2 | 68.6 | 1 | 3 | 179 |
| final | 160.6 | 72.7 | 1 | 3 | 289 |


WSL samples:

| Checkpoint | RSS MiB | Live R heap MB | Child count | R connections | FDs |
| --- | --- | --- | --- | --- | --- |
| cold | 74.0 | 28.7 | 0 | 3 | 6 |
| startup-10 | 209.5 | 73.3 | 0 | 3 | 6 |
| startup-100 | 210.9 | 73.3 | 0 | 3 | 6 |
| workbench-closed | 220.4 | 76.4 | 0 | 3 | 6 |
| final | 221.9 | 80.1 | 0 | 3 | 8 |


Warmup allocations are distinct from retained growth: UI live heap stabilizes
across startup 10→100; OS RSS may retain allocator arenas after GC. Action/render
median/p95: Windows 50.0/70.0ms;
WSL 40.0/55.0ms.
These synchronous headless timings include event+layout+paint, not terminal I/O
or a production responsiveness SLA. Samples/quantiles are in lifecycle JSON/CSV.

Windows handles rise by roughly2 per repeated new compute profile after warmup.
`resource-probe.R` isolates direct mirai, termr pool and distributed model in
fresh processes,15 cycles each, GC and a short settle before each measurement.
Direct mirai alone rises 223→251 handles from cycle1→15, pool 256→284;
model settles to the same per-cycle trend after initial native initialization.
No additional workers remain; direct probe's one child is its prior supervisor
baseline. This is an open P2 optional-backend retention risk, not dismissed as
mere temporary allocation. Exact CSVs are in `resource-probes/`. Initial direct
probe lacked child R_LIBS and was terminated only by its verified owned PID;
the corrected timeout-bounded probe passes.

WSL file descriptors stabilize at 8 after native warmup. R connections remain 3
on both OS; no database was opened. Public subscription/transport diagnostics
are tested, but individual private App timers/caches are deliberately not
inspected. Browser shutdown independently reports zero sessions/observers/producer.
