# Performance results

Benchmarked on Windows 11 x64 with R 4.6.1 and inkr 0.1.0 using
`Rscript tools/bench/bench-inkr-integration.R`. Rendering was headless through
`render_widget()`. Wall times are elapsed seconds from a single run; small
timings are subject to normal run-to-run noise. `Rprofmem()` reports gross
allocated bytes, not retained memory. Cache bytes are `object.size()` of the
app's current cache entries.

## Flat widget trees

| Widgets | First render, no inkr | First render, inkr | First allocation, no inkr | First allocation, inkr | Warm render, no inkr | Warm render, inkr | Cache entries / bytes |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 10 | 0.26 s | 0.07 s | 3,508,240 | 1,343,544 | 0.03 s | <0.01 s | 3 / 6,096 |
| 100 | 0.03 s | 0.06 s | 1,468,696 | 1,574,344 | 0.01 s | 0.01 s | 3 / 6,096 |
| 1,000 | 0.38 s | 0.47 s | 1,947,496 | 2,053,144 | 0.09 s | 0.07 s | 3 / 6,096 |
| 10,000 | 3.22 s | 4.48 s | 6,735,496 | 6,841,144 | 0.98 s | 0.89 s | 3 / 6,096 |

At 10,000 repeated-signature widgets, the cold inkr render took 1.26 seconds
(about 39% longer) and allocated 105,648 more gross bytes (about 1.6%). Warm
render time and allocation were comparable. The 10-widget timing is affected
by startup/JIT noise and is not a performance claim.

## Nested and interactive workloads

| Scenario | Result |
|---|---|
| 1,000 leaves nested in groups of 10 | 0.52 s first render; 0.06 s warm; 4 cache entries / 8,368 bytes |
| 100 focus transitions | 0.07 s |
| 100 class-toggle loops (each adds and removes a class) | 0.11 s |
| 20 stylesheet replacements | 0.06 s |
| 20 termr theme changes | 0.01 s |
| 10,000-row scroll view | 4.59 s first render; 20 scroll renders in 0.69 s; 3 entries / 3,896 bytes |
| Scroll-view unmount | Cache entries fell from 3 to 0 |
| Native chart + DataTable | 0.11 s first and warm render; 5 entries / 10,720 bytes |

The repeated widget paths share entries, while unique paths are capped at 4096
entries per app. This benchmark does not test terminal I/O, retained heap after
garbage collection, other operating systems, or every possible widget tree.
