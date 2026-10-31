# A2.5 Performance

Measurements were collected in WSL against sf-backed tables. They are single-run observations, not performance guarantees.

| Rows | Create (ms) | First render (ms) | Scroll to end (ms) | Selection (ms) | 20 visible values (ms) | Sort (ms) | One attribute edit (ms) |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 100 | 4 | 228 | 7 | 8 | 3 | 20 | 2 |
| 10,000 | 5 | 106 | 1 | 1 | 2 | 2 | 51 |
| 100,000 | 5 | 120 | 1 | 0 | 2 | 3 | 2 |

The 10,000-row edit timing is an outlier in this single-run sample. Table data size matched input object size at each scale (51,456; 4,486,656; and 44,806,656 bytes). Allocations at or above 1 KB during creation were 2,656 bytes / 2 allocations for 100 rows, and 471,400 bytes / 98 allocations for both 10,000 and 100,000 rows. This is consistent with avoiding full-column WKT materialization. Geometry output is clipped and generated for requested visible rows; larger geometry summaries inspect structural metadata instead of rendering all coordinates.

Reproduce with `Rscript audit-results/advanced-types/sf/bench-sf.R`. Windows performance was not measured because the optional `sf` package was unavailable there.
