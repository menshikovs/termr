# Performance measurements

Windows R 4.6.1; WSL Ubuntu R 4.5.2; nanonext 1.10.3. Scratch CRAN Shiny
1.14.0 and Plotly 4.12.1; ggplot2 Windows 4.0.3 / WSL 4.0.2. Measurements
are local observations on this shared host, not production capacity guarantees.

## Independent publisher → receiver → reactive

`Rscript audit-results/shiny-plotly/performance_shared.R` uses a finite
independent processx publisher, 1/5/20 MockShinySession subscribers sharing one
receiver, one manual source poll/flush per ~50 ms. The one shared observer is
created but real timer scheduling/browser/websocket costs are not represented
by this harness. Source callbacks timestamp transport arrival; the reactive
observer timestamps receipt-to-observer and publisher-to-observer independently.
Samples are bounded to the latest 4000 per stage; short 3 s runs include startup
and have too few samples at 1 Hz for robust tails. Rate 0 emits only a seed and
heartbeats (its latency is initial load, not idle-event latency). CPU is R parent
user+system/wall, percent of one core; it excludes publisher/browser CPU. The
public session flush plus manual scheduling has overhead; this is not bare
socket CPU. First prototype polling for readiness emitted missing-file warnings;
the harness now checks existence. Those warnings did not change measured data.

| Host | Sessions | Target Hz | CPU % | Transport p50/p95 ms | Receipt→reactive p50/p95 ms | Publisher→reactive p50/p95 ms | Accepted / sequence gaps |
|---|---:|---:|---:|---:|---:|---:|---:|
| windows | 1 | 0 | 7.49 | 127.63 / 127.63 | 16.96 / 16.96 | 144.58 / 144.58 | 1 / 0 |
| windows | 1 | 1 | 5.72 | 46.28 / 63.60 | 3.05 / 3.79 | 49.67 / 66.66 | 4 / 0 |
| windows | 1 | 10 | 8.96 | 37.74 / 63.85 | 2.98 / 3.90 | 40.65 / 66.85 | 31 / 0 |
| windows | 1 | 100 | 8.38 | 32.45 / 62.74 | 2.94 / 4.89 | 5.08 / 20.32 | 301 / 0 |
| windows | 5 | 0 | 3.87 | 50.80 / 50.80 | 7.38 / 9.23 | 58.16 / 60.01 | 1 / 0 |
| windows | 5 | 1 | 6.65 | 40.97 / 48.11 | 6.88 / 8.90 | 47.94 / 56.17 | 4 / 0 |
| windows | 5 | 10 | 13.51 | 32.05 / 65.65 | 7.36 / 10.61 | 40.06 / 74.01 | 31 / 0 |
| windows | 5 | 100 | 21.86 | 32.98 / 71.27 | 7.38 / 11.77 | 11.68 / 38.32 | 301 / 0 |
| windows | 20 | 0 | 3.92 | 109.80 / 109.80 | 19.80 / 33.13 | 129.61 / 142.92 | 1 / 0 |
| windows | 20 | 1 | 6.25 | 47.77 / 95.14 | 22.17 / 30.83 | 70.93 / 129.42 | 4 / 0 |
| windows | 20 | 10 | 37.95 | 48.75 / 98.81 | 23.28 / 36.48 | 78.07 / 132.34 | 31 / 0 |
| windows | 20 | 100 | 38.14 | 48.73 / 93.81 | 24.99 / 38.54 | 30.68 / 67.03 | 301 / 0 |
| wsl | 1 | 0 | 4.28 | 114.18 / 114.18 | 23.26 / 23.26 | 137.42 / 137.42 | 1 / 0 |
| wsl | 1 | 1 | 3.53 | 31.86 / 34.45 | 3.15 / 3.55 | 34.71 / 37.55 | 3 / 0 |
| wsl | 1 | 10 | 5.67 | 26.62 / 51.29 | 3.03 / 3.60 | 31.78 / 54.20 | 30 / 0 |
| wsl | 1 | 100 | 10.35 | 28.91 / 52.18 | 2.84 / 3.38 | 10.52 / 19.96 | 300 / 0 |
| wsl | 5 | 0 | 3.52 | 55.76 / 55.76 | 6.82 / 8.60 | 62.55 / 64.33 | 1 / 0 |
| wsl | 5 | 1 | 4.28 | 36.97 / 69.84 | 7.53 / 9.61 | 44.33 / 84.44 | 4 / 0 |
| wsl | 5 | 10 | 10.52 | 26.83 / 49.91 | 6.34 / 9.96 | 33.75 / 57.68 | 31 / 0 |
| wsl | 5 | 100 | 18.20 | 31.73 / 58.56 | 6.63 / 9.99 | 14.02 / 28.96 | 301 / 0 |
| wsl | 20 | 0 | 3.79 | 116.70 / 116.70 | 18.57 / 31.50 | 135.26 / 148.18 | 1 / 0 |
| wsl | 20 | 1 | 5.41 | 53.75 / 113.78 | 19.51 / 27.71 | 77.12 / 143.82 | 3 / 0 |
| wsl | 20 | 10 | 29.61 | 30.57 / 51.69 | 21.24 / 32.33 | 51.86 / 77.31 | 30 / 0 |
| wsl | 20 | 100 | 42.34 | 47.14 / 86.09 | 24.34 / 39.76 | 32.40 / 66.92 | 301 / 0 |

**windows, 20 sessions, target 100 Hz for 60 s:** accepted 5995, gaps 6, coalesced 5536, retained 600 <=600; CPU 57.35%; RSS 245.20–258.57 MiB (first 247.86, last 252.04). Publisher→reactive p50/p95 48.99/81.55 ms.

**wsl, 20 sessions, target 100 Hz for 60 s:** accepted 6000, gaps 0, coalesced 5497, retained 600 <=600; CPU 59.02%; RSS 214.26–220.37 MiB (first 214.26, last 220.37). Publisher→reactive p50/p95 48.97/80.93 ms.

Native pending operations stayed <=2. All leases released, receiver observer
destroyed and pending operations reached zero at teardown (assertions in harness).
The history and sampling lists are structurally bounded. RSS warmed up and
levelled within the observed range; a one-minute run is not proof of absence of
all long-duration/native/browser leaks. Windows dropped six sequences in the
long run; telemetry is lossy and gaps are reported, not concealed.

## Server-side plotting preparation

Synthetic 600-row frame; 20 repetitions except 10 PNG ggplot draws. Proxy uses a
fake immediate-flush session; these timings exclude websocket and browser work.
Millisecond timer resolution yields zero for some tiny operations.

| Host | Frame p50/p95 ms | Initial arrays p50/p95 ms | ggplot PNG p50/p95 ms | One-point proxy p50/p95 ms |
|---|---:|---:|---:|---:|
| windows | 10.00 / 20.00 | 30.00 / 30.00 | 210.00 / 310.00 | 0.00 / 0.00 |
| wsl | 9.00 / 11.00 | 18.00 / 36.00 | 186.00 / 278.00 | 0.00 / 1.00 |

## Actual browser stage

Real Playwright Chromium, real independent system collector and Shiny app.
Probe records completion after the actual Plotly promise plus two animation
frames; this is not a GPU presentation timestamp. End-to-end uses the **incoming**
measurement timestamp captured before a later command can mutate graph.data.
This is latency of the newest point in each update; earlier points in a batch
may wait longer. Core reactive latency likewise measures observed latest values,
not a promise that every intermediate event invalidates a reactive separately.
Clock agreement is required. Background-tab throttling contributes strongly.
Samples are bounded (2000 in browser, latest 50/tab or 200 single-tab exported).

browser-1-batched.json: 124 samples, browser update p50/p95 17.30 / 21.90 ms; end-to-end p50/p95 170.00 / 253.00 ms. Navigation→initial 50-point history completion 811 ms.

browser-20-batched-10hz.json: 994 samples, browser update p50/p95 783.20 / 1247.30 ms; end-to-end p50/p95 1255.00 / 1721.00 ms.

The real collector's configured interval was 0.1 s **plus collection cost**; observed publication rate across that sampled trace was about 6.29/s, not a guaranteed 10 Hz. The controlled synthetic benchmark above supplies the 100 Hz rate test.

## Baseline and changes supported by it

Before optimizing, repeated restyle was observed in real browsers (cursor
scope bug), per-session repeated frame conversion was counted, and AIO rearm
drained about one ready message per poll under graph load. The ready-queue drain
and shared frame conversion address those measured costs. Native polling remains
bounded. Browser-20 baseline and subsequent JSON snapshots preserve evidence.

Even after true extension, 50 ms dashboard polling with 20 tabs saturated R,
delayed diagnostics and caused page-open timeouts. `browser-profile-summary.txt`
shows reactive flush/fanout and renderText/JSON/frame work. One in-flight command
per browser prevents graph command accumulation; 500 ms dashboard batching gives
that fanout time to finish. In the final 20-tab run all traces extended, stayed
<=50, closing 19 tabs and reloading the remaining tab succeeded. The shared
receiver API retains its 50 ms default for smaller/custom applications.
