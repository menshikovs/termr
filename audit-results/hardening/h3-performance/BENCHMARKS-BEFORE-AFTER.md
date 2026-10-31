# Complete before/after measurements

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

| Scenario | Size | Before: median [min,max]; allocations | After: median [min,max]; allocations |
|---|---:|---|---|
| app-events-dispatch | 1 | 0.000 s [0.000, 0.000]; 0.0000 MB; n=3 | 0.000 s [0.000, 0.000]; 0.0000 MB; n=3 |
| app-events-dispatch | 100 | 0.020 s [0.010, 0.030]; 0.0875 MB; n=3 | 0.030 s [0.030, 0.030]; 0.0875 MB; n=3 |
| app-events-dispatch | 10,000 | 1.590 s [1.560, 1.780]; 0.5573 MB; n=3 | 2.970 s [2.890, 2.990]; 0.5573 MB; n=3 |
| app-events-enqueue-frame | 1 | 0.000 s [0.000, 0.000]; 0.0784 MB; n=3 | 0.000 s [0.000, 0.020]; 0.0784 MB; n=3 |
| app-events-enqueue-frame | 100 | 0.030 s [0.030, 0.050]; 0.3900 MB; n=3 | 0.060 s [0.060, 0.070]; 0.2349 MB; n=3 |
| app-events-enqueue-frame | 10,000 | 3.150 s [3.130, 3.250]; 1356.2975 MB; n=3 | 3.620 s [3.580, 3.700]; 1.8452 MB; n=3 |
| app-focus | 100 | 0.150 s [0.140, 0.160]; 13.3220 MB; n=3 | 0.110 s [0.110, 0.110]; 13.4248 MB; n=3 |
| app-idle | 100 | 0.000 s [0.000, 0.000]; 0.0000 MB; n=3 | 0.000 s [0.000, 0.000]; 0.0000 MB; n=3 |
| app-reload | 100 | 0.000 s [0.000, 0.000]; 0.0394 MB; n=3 | 0.000 s [0.000, 0.020]; 0.0394 MB; n=3 |
| app-shutdown | 100 | 0.000 s [0.000, 0.000]; 0.1448 MB; n=3 | 0.000 s [0.000, 0.020]; 0.1451 MB; n=3 |
| app-startup | 100 | 0.250 s [0.230, 0.440]; 17.6978 MB; n=3 | 0.230 s [0.200, 0.380]; 17.5941 MB; n=3 |
| app-update | 100 | 0.060 s [0.060, 0.110]; 0.5029 MB; n=3 | 0.050 s [0.030, 0.060]; 0.5029 MB; n=3 |
| app-warm-startup | 100 | 0.050 s [0.040, 0.050]; 3.5119 MB; n=3 | 0.070 s [0.070, 0.090]; 3.3545 MB; n=3 |
| chart-bar-full | 1,000 | 0.030 s [0.030, 0.030]; 4.6905 MB; n=3 | 0.060 s [0.060, 0.080]; 4.6905 MB; n=3 |
| chart-bar-hit | 1,000 | 0.000 s [0.000, 0.020]; 0.0000 MB; n=3 | 0.010 s [0.000, 0.020]; 0.0000 MB; n=3 |
| chart-bar-initial | 1,000 | 0.090 s [0.090, 0.390]; 8.2895 MB; n=3 | 0.100 s [0.080, 0.250]; 8.4327 MB; n=3 |
| chart-bar-partial | 1,000 | 0.020 s [0.010, 0.020]; 2.2318 MB; n=3 | 0.030 s [0.010, 0.030]; 2.2318 MB; n=3 |
| chart-bar-resize | 1,000 | 0.090 s [0.090, 0.120]; 9.3662 MB; n=3 | 0.080 s [0.070, 0.090]; 9.3662 MB; n=3 |
| chart-bar-update | 1,000 | 0.310 s [0.310, 0.330]; 99.6459 MB; n=3 | 0.610 s [0.610, 0.610]; 99.6459 MB; n=3 |
| chart-bar-warm | 1,000 | 0.060 s [0.060, 0.060]; 4.6352 MB; n=3 | 0.040 s [0.030, 0.050]; 4.6352 MB; n=3 |
| chart-heatmap-full | 1,000 | 0.310 s [0.310, 0.320]; 60.5881 MB; n=3 | 0.640 s [0.620, 0.650]; 60.5881 MB; n=3 |
| chart-heatmap-hit | 1,000 | 0.000 s [0.000, 0.000]; 0.0000 MB; n=3 | 0.010 s [0.000, 0.010]; 0.0000 MB; n=3 |
| chart-heatmap-initial | 1,000 | 0.670 s [0.670, 0.860]; 62.2243 MB; n=3 | 0.540 s [0.510, 0.660]; 62.3674 MB; n=3 |
| chart-heatmap-partial | 1,000 | 0.010 s [0.000, 0.010]; 0.6629 MB; n=3 | 0.020 s [0.000, 0.020]; 0.6629 MB; n=3 |
| chart-heatmap-resize | 1,000 | 0.680 s [0.670, 0.680]; 73.6424 MB; n=3 | 0.390 s [0.390, 0.410]; 73.6424 MB; n=3 |
| chart-heatmap-update | 1,000 | 0.780 s [0.780, 0.830]; 191.6497 MB; n=3 | 1.510 s [0.830, 1.530]; 191.6497 MB; n=3 |
| chart-heatmap-warm | 1,000 | 0.600 s [0.570, 0.630]; 60.5327 MB; n=3 | 0.360 s [0.340, 0.390]; 60.5327 MB; n=3 |
| chart-histogram-full | 1,000 | 0.030 s [0.030, 0.030]; 6.0019 MB; n=3 | 0.080 s [0.060, 0.090]; 6.0019 MB; n=3 |
| chart-histogram-hit | 1,000 | 0.000 s [0.000, 0.020]; 0.0000 MB; n=3 | 0.010 s [0.000, 0.020]; 0.0000 MB; n=3 |
| chart-histogram-initial | 1,000 | 0.100 s [0.090, 0.110]; 9.6420 MB; n=3 | 0.080 s [0.080, 0.100]; 9.7852 MB; n=3 |
| chart-histogram-partial | 1,000 | 0.130 s [0.110, 0.130]; 30.2229 MB; n=3 | 0.250 s [0.240, 0.250]; 30.2229 MB; n=3 |
| chart-histogram-resize | 1,000 | 0.110 s [0.100, 0.110]; 10.8377 MB; n=3 | 0.080 s [0.070, 0.080]; 10.8377 MB; n=3 |
| chart-histogram-update | 1,000 | 0.070 s [0.060, 0.070]; 13.9744 MB; n=3 | 0.140 s [0.140, 0.160]; 13.9744 MB; n=3 |
| chart-histogram-warm | 1,000 | 0.060 s [0.050, 0.080]; 5.9465 MB; n=3 | 0.050 s [0.050, 0.060]; 5.9465 MB; n=3 |
| chart-line-full | 1,000 | 0.050 s [0.030, 0.050]; 4.8286 MB; n=3 | 0.060 s [0.060, 0.070]; 4.8286 MB; n=3 |
| chart-line-hit | 1,000 | 0.030 s [0.030, 0.030]; 12.5280 MB; n=3 | 0.050 s [0.040, 0.060]; 12.5280 MB; n=3 |
| chart-line-initial | 1,000 | 0.110 s [0.100, 0.820]; 8.0516 MB; n=3 | 0.150 s [0.140, 1.010]; 8.1948 MB; n=3 |
| chart-line-partial | 1,000 | 0.010 s [0.000, 0.020]; 1.4252 MB; n=3 | 0.030 s [0.010, 0.030]; 1.4252 MB; n=3 |
| chart-line-resize | 1,000 | 0.100 s [0.090, 0.110]; 8.9669 MB; n=3 | 0.140 s [0.110, 0.140]; 8.9669 MB; n=3 |
| chart-line-update | 1,000 | 0.380 s [0.370, 0.430]; 121.5370 MB; n=3 | 0.780 s [0.780, 0.890]; 121.5370 MB; n=3 |
| chart-line-warm | 1,000 | 0.050 s [0.040, 0.060]; 4.7733 MB; n=3 | 0.060 s [0.060, 0.060]; 4.7733 MB; n=3 |
| chart-scatter-full | 1,000 | 0.020 s [0.020, 0.030]; 4.8147 MB; n=3 | 0.060 s [0.040, 0.060]; 4.8147 MB; n=3 |
| chart-scatter-hit | 1,000 | 0.040 s [0.030, 0.050]; 37.1680 MB; n=3 | 0.060 s [0.050, 0.060]; 37.1680 MB; n=3 |
| chart-scatter-initial | 1,000 | 0.090 s [0.090, 0.100]; 7.3849 MB; n=3 | 0.160 s [0.150, 0.160]; 7.5281 MB; n=3 |
| chart-scatter-partial | 1,000 | 0.020 s [0.010, 0.020]; 1.3864 MB; n=3 | 0.020 s [0.010, 0.030]; 1.3864 MB; n=3 |
| chart-scatter-resize | 1,000 | 0.100 s [0.090, 0.110]; 8.2591 MB; n=3 | 0.080 s [0.080, 0.100]; 8.2591 MB; n=3 |
| chart-scatter-update | 1,000 | 0.380 s [0.370, 0.390]; 121.2393 MB; n=3 | 0.760 s [0.750, 0.760]; 121.2393 MB; n=3 |
| chart-scatter-warm | 1,000 | 0.060 s [0.040, 0.060]; 4.7593 MB; n=3 | 0.050 s [0.030, 0.060]; 4.7593 MB; n=3 |
| combined-input-parser | 1 | 0.000 s [0.000, 0.030]; 0.0011 MB; n=3 | 0.000 s [0.000, 0.070]; 0.0011 MB; n=3 |
| combined-input-parser | 100 | 0.040 s [0.040, 0.050]; 0.1473 MB; n=3 | 0.090 s [0.080, 0.090]; 0.1473 MB; n=3 |
| combined-input-parser | 10,000 | 5.140 s [4.720, 5.420]; 15.1008 MB; n=3 | 8.980 s [8.820, 9.200]; 15.1008 MB; n=3 |
| continuous-stream | 384 | 0.080 s [0.060, 0.090]; 3.4240 MB; n=3 | 0.890 s [0.880, 0.970]; 103.5845 MB; n=3 |
| deep-cold | 100 | 5.020 s [4.770, 5.050]; 6.1620 MB; n=3 | 1.360 s [1.220, 1.380]; 5.3471 MB; n=3 |
| events-dequeue | 1 | 0.000 s [0.000, 0.000]; 0.0000 MB; n=3 | 0.000 s [0.000, 0.000]; 0.0000 MB; n=3 |
| events-dequeue | 100 | 0.000 s [0.000, 0.000]; 0.0684 MB; n=3 | 0.000 s [0.000, 0.000]; 0.0003 MB; n=3 |
| events-dequeue | 10,000 | 1.260 s [1.240, 1.260]; 534.1790 MB; n=3 | 0.110 s [0.090, 0.150]; 0.0003 MB; n=3 |
| events-enqueue | 1 | 0.000 s [0.000, 0.000]; 0.0000 MB; n=3 | 0.000 s [0.000, 0.000]; 0.0000 MB; n=3 |
| events-enqueue | 100 | 0.010 s [0.000, 0.020]; 0.0875 MB; n=3 | 0.000 s [0.000, 0.000]; 0.0068 MB; n=3 |
| events-enqueue | 10,000 | 2.870 s [2.860, 3.050]; 820.9202 MB; n=3 | 0.220 s [0.220, 0.260]; 1.2016 MB; n=3 |
| focusable-traversal-100-tabs | 1,000 | 5.090 s [5.020, 5.210]; 47.8190 MB; n=3 | 8.760 s [8.580, 8.890]; 46.8340 MB; n=3 |
| inkr-session-insert | 100 | 0.020 s [0.000, 0.020]; 0.0475 MB; n=3 | 0.010 s [0.010, 0.020]; 0.0475 MB; n=3 |
| inkr-session-insert | 1,000 | 0.130 s [0.120, 0.160]; 4.0978 MB; n=3 | 0.120 s [0.100, 0.130]; 4.0978 MB; n=3 |
| inkr-session-insert | 2,000 | 0.250 s [0.230, 0.270]; 16.1854 MB; n=3 | 0.250 s [0.250, 0.260]; 16.1854 MB; n=3 |
| layout-only-inkr | 1,000 | 1.910 s [1.900, 1.930]; 36.0354 MB; n=3 | 1.860 s [1.850, 1.890]; 36.0354 MB; n=3 |
| layout-only-plain | 1,000 | 0.280 s [0.270, 0.280]; 0.5336 MB; n=3 | 0.310 s [0.300, 0.330]; 0.5336 MB; n=3 |
| micro-compute | 1,000 | 0.630 s [0.610, 0.660]; 2.0480 MB; n=3 | 0.630 s [0.610, 0.640]; 2.0480 MB; n=3 |
| micro-element | 1,000 | 0.470 s [0.450, 0.470]; 0.0000 MB; n=3 | 0.030 s [0.030, 0.040]; 0.0000 MB; n=3 |
| micro-hit | 1,000 | 0.140 s [0.140, 0.150]; 0.0000 MB; n=3 | 0.090 s [0.080, 0.100]; 0.0000 MB; n=3 |
| micro-path | 1,000 | 0.000 s [0.000, 0.020]; 0.0000 MB; n=3 | 0.000 s [0.000, 0.010]; 0.0000 MB; n=3 |
| paint-only-inkr | 1,000 | 0.040 s [0.030, 0.040]; 1.3599 MB; n=3 | 0.060 s [0.040, 0.060]; 1.3599 MB; n=3 |
| paint-only-plain | 1,000 | 0.030 s [0.030, 0.050]; 1.3599 MB; n=3 | 0.030 s [0.030, 0.030]; 1.3599 MB; n=3 |
| render-none | 100 | 0.080 s [0.060, 0.110]; 1.4687 MB; n=3 | 0.050 s [0.040, 0.050]; 1.4687 MB; n=3 |
| render-none | 1,000 | 0.640 s [0.630, 0.670]; 1.9475 MB; n=3 | 0.360 s [0.360, 0.370]; 1.9475 MB; n=3 |
| render-none | 10,000 | 6.420 s [6.370, 6.870]; 6.7355 MB; n=3 | 3.670 s [3.670, 3.750]; 6.7355 MB; n=3 |
| render-repeated | 100 | 0.110 s [0.110, 0.120]; 1.5743 MB; n=3 | 0.060 s [0.050, 0.070]; 1.5743 MB; n=3 |
| render-repeated | 1,000 | 0.910 s [0.860, 0.940]; 2.0531 MB; n=3 | 0.500 s [0.480, 0.560]; 2.0531 MB; n=3 |
| render-repeated | 10,000 | 5.250 s [5.110, 8.630]; 6.8411 MB; n=3 | 4.820 s [4.800, 4.890]; 6.8411 MB; n=3 |
| render-unique | 100 | 0.600 s [0.580, 0.610]; 5.0805 MB; n=3 | 0.330 s [0.310, 0.350]; 5.0805 MB; n=3 |
| render-unique | 1,000 | 3.620 s [3.580, 3.690]; 37.4493 MB; n=3 | 1.920 s [1.910, 2.000]; 37.4493 MB; n=3 |
| render-unique | 10,000 | 23.840 s [21.740, 31.560]; 360.9765 MB; n=3 | 19.860 s [19.490, 20.040]; 360.9765 MB; n=3 |
| source-cache-hit | 10,000,000 | 0.010 s [0.010, 0.010]; 2.9968 MB; n=3 | 0.030 s [0.030, 0.030]; 2.9968 MB; n=3 |
| source-replacement | 10,000,000 | 0.020 s [0.000, 0.030]; 3.0071 MB; n=3 | 0.030 s [0.030, 0.030]; 3.0071 MB; n=3 |
| table-edit | 1,000 | 0.020 s [0.000, 0.260]; 0.0980 MB; n=3 | 0.010 s [0.000, 0.290]; 0.0980 MB; n=3 |
| table-edit | 100,000 | 0.010 s [0.000, 0.020]; 0.8941 MB; n=3 | 0.000 s [0.000, 0.020]; 0.8941 MB; n=3 |
| table-edit | 1,000,000 | 0.000 s [0.000, 0.020]; 8.0941 MB; n=3 | 0.010 s [0.000, 0.020]; 8.0941 MB; n=3 |
| table-export | 1,000 | 0.020 s [0.000, 0.030]; 0.0009 MB; n=3 | 0.020 s [0.010, 0.020]; 0.0009 MB; n=3 |
| table-export | 100,000 | 0.020 s [0.000, 0.020]; 0.0009 MB; n=3 | 0.010 s [0.000, 0.020]; 0.0009 MB; n=3 |
| table-export | 1,000,000 | 0.000 s [0.000, 0.000]; 0.0009 MB; n=3 | 0.000 s [0.000, 0.010]; 0.0009 MB; n=3 |
| table-filter | 1,000 | 0.000 s [0.000, 0.000]; 0.0446 MB; n=3 | 0.000 s [0.000, 0.000]; 0.0446 MB; n=3 |
| table-filter | 100,000 | 0.000 s [0.000, 0.010]; 4.4118 MB; n=3 | 0.020 s [0.020, 0.020]; 4.4118 MB; n=3 |
| table-filter | 1,000,000 | 0.050 s [0.020, 0.060]; 44.1404 MB; n=3 | 0.030 s [0.030, 0.050]; 44.1404 MB; n=3 |
| table-init | 1,000 | 0.000 s [0.000, 0.060]; 0.4000 MB; n=3 | 0.010 s [0.000, 0.080]; 0.4000 MB; n=3 |
| table-init | 100,000 | 0.020 s [0.000, 0.020]; 0.4164 MB; n=3 | 0.000 s [0.000, 0.020]; 0.4164 MB; n=3 |
| table-init | 1,000,000 | 0.000 s [0.000, 0.000]; 0.4164 MB; n=3 | 0.020 s [0.010, 0.020]; 0.4164 MB; n=3 |
| table-lookup | 1,000 | 0.000 s [0.000, 0.020]; 0.0000 MB; n=3 | 0.000 s [0.000, 0.000]; 0.0000 MB; n=3 |
| table-lookup | 100,000 | 0.000 s [0.000, 0.000]; 0.0000 MB; n=3 | 0.000 s [0.000, 0.000]; 0.0000 MB; n=3 |
| table-lookup | 1,000,000 | 0.000 s [0.000, 0.000]; 0.0000 MB; n=3 | 0.000 s [0.000, 0.000]; 0.0000 MB; n=3 |
| table-render | 1,000 | 0.020 s [0.010, 0.160]; 3.0098 MB; n=3 | 0.020 s [0.020, 0.170]; 3.0098 MB; n=3 |
| table-render | 100,000 | 0.030 s [0.010, 0.030]; 3.0098 MB; n=3 | 0.050 s [0.030, 0.050]; 3.0098 MB; n=3 |
| table-render | 1,000,000 | 0.030 s [0.030, 0.050]; 3.0190 MB; n=3 | 0.030 s [0.030, 0.050]; 3.0190 MB; n=3 |
| table-resize | 1,000 | 0.000 s [0.000, 0.000]; 0.0006 MB; n=3 | 0.000 s [0.000, 0.000]; 0.0006 MB; n=3 |
| table-resize | 100,000 | 0.000 s [0.000, 0.000]; 0.0006 MB; n=3 | 0.000 s [0.000, 0.000]; 0.0006 MB; n=3 |
| table-resize | 1,000,000 | 0.000 s [0.000, 0.000]; 0.0006 MB; n=3 | 0.000 s [0.000, 0.000]; 0.0006 MB; n=3 |
| table-scroll | 1,000 | 0.020 s [0.020, 0.020]; 2.9948 MB; n=3 | 0.030 s [0.020, 0.050]; 2.9948 MB; n=3 |
| table-scroll | 100,000 | 0.030 s [0.030, 0.050]; 2.9948 MB; n=3 | 0.050 s [0.040, 0.050]; 2.9948 MB; n=3 |
| table-scroll | 1,000,000 | 0.050 s [0.040, 0.050]; 3.0041 MB; n=3 | 0.040 s [0.040, 0.040]; 3.0041 MB; n=3 |
| table-selection | 1,000 | 0.000 s [0.000, 0.020]; 0.0000 MB; n=3 | 0.000 s [0.000, 0.000]; 0.0000 MB; n=3 |
| table-selection | 100,000 | 0.000 s [0.000, 0.000]; 0.0000 MB; n=3 | 0.000 s [0.000, 0.000]; 0.0000 MB; n=3 |
| table-selection | 1,000,000 | 0.000 s [0.000, 0.000]; 0.0000 MB; n=3 | 0.000 s [0.000, 0.000]; 0.0000 MB; n=3 |
| table-sort | 1,000 | 0.000 s [0.000, 0.000]; 0.0202 MB; n=3 | 0.000 s [0.000, 0.010]; 0.0202 MB; n=3 |
| table-sort | 100,000 | 0.000 s [0.000, 0.020]; 2.0002 MB; n=3 | 0.000 s [0.000, 0.000]; 2.0002 MB; n=3 |
| table-sort | 1,000,000 | 0.000 s [0.000, 0.030]; 20.0002 MB; n=3 | 0.020 s [0.000, 0.020]; 20.0002 MB; n=3 |
| tree-focus | 1,000 | 1.170 s [1.020, 1.250]; 5.7744 MB; n=3 | 1.460 s [1.420, 1.530]; 5.7016 MB; n=3 |
| tree-full-layout | 1,000 | 0.120 s [0.120, 0.130]; 1.6749 MB; n=3 | 0.200 s [0.200, 0.200]; 1.6749 MB; n=3 |
| tree-mount | 1,000 | 0.050 s [0.040, 0.050]; 0.1458 MB; n=3 | 0.050 s [0.050, 0.060]; 0.0886 MB; n=3 |
| tree-paint-change | 1,000 | 0.330 s [0.310, 0.340]; 1.0413 MB; n=3 | 0.580 s [0.560, 0.580]; 1.0413 MB; n=3 |
| unmount-no-sheet | 100 | 0.010 s [0.000, 0.020]; 3.5273 MB; n=3 | 0.020 s [0.020, 0.020]; 0.3526 MB; n=3 |
| unmount-no-sheet | 1,000 | 1.020 s [1.000, 1.120]; 45.8886 MB; n=3 | 0.690 s [0.650, 0.750]; 12.9275 MB; n=3 |
| unmount-no-sheet | 5,000 | 26.120 s [25.030, 26.330]; 467.2806 MB; n=3 | 18.050 s [17.820, 18.750]; 301.9355 MB; n=3 |
| virtual-scroll-40-columns | 10,000,000 | 2.390 s [2.370, 2.440]; 243.9075 MB; n=3 | 2.770 s [2.730, 2.790]; 244.1256 MB; n=3 |

Component microbenchmarks are in before/after-components.csv (matching,
mapping, cache insert/reset, class changes and sheet swaps). The unchanged
public inkr session rows are controls and do not represent a bridge speedup.
before-core-initial.csv is historical diagnostic evidence only; the canonical
before-core.csv comes from the verified pre-H3 source snapshot.

## Paired bridge control

| Paired bridge operation | Before median [min,max], seconds | After median [min,max], seconds |
|---|---:|---:|
| render-unique-1000 | 3.225 [2.290, 4.350] | 3.160 [3.030, 3.380] |
| element-1000 | 0.590 [0.570, 0.600] | 0.030 [0.030, 0.050] |
| cache-hit-1000 | 0.175 [0.170, 0.180] | 0.110 [0.090, 0.110] |
| deep-element-100 | 6.385 [6.200, 6.420] | 0.105 [0.090, 0.110] |
| compute-control-1000 | 0.690 [0.690, 0.690] | 0.700 [0.690, 0.750] |

The final continuous-stream row comes from after-stream.csv. The earlier
after-core.csv stream row is the rejected eager-render candidate and is
excluded from this table. The remaining core timed paths do not call the
modified EventQueue; they retain the same final App/inkr functions. Queue,
stream, broad/extra App scenarios and lifecycle/resource runs were repeated
after the ring change. before/after-components.csv measures unchanged bridge
component code independently. Ring lifetime measurements are separate live
heap observations, not gross-allocation benchmarks.
