# H4 long-run handoff

Use the source archive/hash and h3-only.patch as the exact H3 candidate. Start
with the commands in run-windows.ps1 and run-wsl-final.sh, inspect every .exit,
and load platform manifests before enabling optional workloads. Do not undo
H1/H2 atomic source replacement, exact export, ownership, finite count checks,
detached bubbling, Pilot cleanup or projection keys.

Run 1h/8h/24h continuous producer tests with keyboard input and terminal resizes.
Keep producer faster than consumer, record displayed sequence lag, max queue/
points, timer delay, handler and frame p50/p95/p99, ANSI bytes, disconnects and
post-unmount callbacks. H3's virtual-time fairness check is a deterministic
starting reproducer, not a real-time certificate.

Extend 1,000-cycle memory tests with object reference tracking and separate
R-live-heap, RSS, OS handle, child-process and socket census. Sample after warmup
and after explicit GC; compare slopes with the observer's own retained rows.
Combine stylesheet swap/clear, large subtree replacement, source switching,
owned and borrowed DBI connections, stream bind/unbind and optional async task
cancellation. Keep bounded cache/subscriber assertions active throughout.

Priority remaining investigations: semantics-preserving bulk child removal;
App-local versus global style epochs; deep-prefix retained memory; narrower
layout invalidation; independent inkr session key insertion. Coordinate any
inkr change in its own repository using the public reproducer, never copy its
engine into termr. EventQueue remains unbounded by total pending events; the
existing per-tick budget prevents a single dispatch turn from monopolizing the
loop, but overload policy is a separate API/design decision.

Repeat clean-machine timing on Windows/WSL separately, with profiling disabled
for a latency series and enabled for an allocation series. Add current macOS
CI and actual Windows console/ConPTY host runs. Any future performance patch
must retain the new freshness, FIFO/reference-release and cache-invalidation
contracts and compare the unchanged neighboring scenarios.

Temporary staging folders were removed after successful archive verification.
For this audit's staged rerun, first run prepare-ring-validation.py to recreate
the Windows staging directory and ring runners. These helpers overlay R/test
sources onto the trusted earlier archive; if other package files or fixtures
change in H4, stage the complete new package inputs instead. The workspace and
verified final archives, rather than the old ring-stage.json path, are the
authoritative H3 candidate.
