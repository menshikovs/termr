# Performance observations

Date 2026-10-29; Windows R 4.6.1 UCRT and WSL Ubuntu R 4.5.2, nanonext 1.10.3.
Shared development host, with other validation processes active. Results are
local observations, not isolated hardware guarantees. Scripts and raw logs are
retained; no optimization was performed without a measured bottleneck.

## Codec, local dispatch and file publication

`performance.R`: bench::mark, 500 iterations, check=FALSE, filter_gc=FALSE.
Telemetry codec sample is 163 wire bytes. File benchmark publishes/reads a
real bounded metrics envelope, so it is intentionally a larger payload.

| Operation | Windows median | WSL median |
| --- | ---: | ---: |
| local emit, no transport | 3.70 us | 3.21 us |
| emit with publisher, including two JSON encodings and raw enqueue | 718.5 us | 592.13 us |
| one envelope encoding | 307.15 us | 289.36 us |
| decoding plus schema/depth validation | 67.80 us | 57.98 us |
| local emit + one no-op callback | 8.10 us | 7.97 us |
| file snapshot publish | 27.05 ms | 9.02 ms |
| file read + validation/status | 2.74 ms | 435.97 us |

Publisher keeps separate event/snapshot encodings. Codec cost dominates this
small-message adapter benchmark; this is not pure network transit time. Local
emit is not equivalent to an interprocess operation. File and nano samples
also differ in payload size, so their timings are not an equivalent-workload
speedup claim. All rows are repeated, measured stages rather than inferred
subtractions.

## Independent installed-runtime fan-out

`Rscript tools/nanonext_integration.R N 200`, N=1,10,50. All clients are separate
R processes. Target cadence is 5 ms after each emit; observed rate includes R
scheduling, codec, socket service and final-state synchronization. Therefore
this is paced observed throughput, not maximum NNG capacity. The last client
in the 10/50 runs polls slowly with a one-message native receive queue. All
reach the final latest value, report gaps where intermediate events drop,
retain at most 16 values and at most two pending AIO references.

| Host | Clients | 200-event elapsed | Observed offered events/s | Median client p50 / p95 latency |
| --- | ---: | ---: | ---: | ---: |
| Windows | 1 | 3.460 s | 57.8 | 31.99 / 66.09 ms |
| Windows | 10 | 3.560 s | 56.2 | 17.67 / 79.48 ms |
| Windows | 50 | 4.830 s | 41.4 | 15.63 / 36.68 ms |
| WSL | 1 | 1.644 s | 121.7 | 2.03 / 4.05 ms |
| WSL | 10 | 1.880 s | 106.4 | 2.70 / 5.92 ms |
| WSL | 50 | 2.537 s | 78.8 | 4.84 / 7.21 ms |

Latency is payload send timestamp to R callback, including polling and codec.
Windows timer granularity contributes to the observations. Medians across
clients are not a worst-client tail guarantee; individual SUMMARY.json files
retain all client p50/p95/p99, gap counters, delivered counts and RSS. Slow
clients may receive fewer callbacks while still recovering the final value.

## Raw transport control, separate processes

`Rscript tools/nanonext_integration.R 1 20000 raw` uses fixed 164-byte packets,
no JSON codec or termr callback dispatch. A beacon establishes receive
readiness; publisher sends the burst and repeats the final value until the
bounded completion check observes it. Client parses the fixed sequence field.
These are lossy pub/sub observations, not guaranteed-delivery throughput.

| Host | Burst offered | Observed offered/s | Observed delivered/s |
| --- | ---: | ---: | ---: |
| Windows | 20000 in 1.260 s | 15873 | 10512 |
| WSL | 20000 in 1.740 s | 11494 | 2416 |

Delivered rates differ because of bounded queue loss and R drain scheduling;
they must not be used to rank native transport capacity across platforms.
This control separates socket/framing/draining from JSON and graph callbacks.

## Memory and cross-OS

Fan-out RSS is approximately 80.1-81.7 MiB per Windows client and 74.5-74.9 MiB
per installed WSL client, including R/package baseline, not just transport.
Raw-only control client RSS: 79.7 MiB Windows, 71.6 MiB WSL.

After 10000 publisher emissions with history=64, retained history remains 64
and pending operation count 1. Windows RSS before/after GC: 139755520 /
133816320 bytes; WSL: 131448832 / 131801088 bytes. Two RSS observations do not
prove an absence of every native leak; bounded queues/AIO slots/history are
also asserted directly, and lifecycle tests close owners/processes.

WSL publisher -> Windows subscriber with restart: p50 7.00 ms, p95 25.89 ms,
p99 37.14 ms, recorded in cross-restart/RESULT.json. Reverse localhost did not
connect; no latency is claimed for that direction.
