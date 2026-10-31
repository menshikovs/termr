# Performance measurements

Measurements were taken on Windows R 4.6.1 after warming the widget/render path. Local data were generated as an integer and a double column with 1,000, 100,000, and 1,000,000 rows. See `performance-local.csv` and `performance-source-10m.csv` for raw results. Timings are short local measurements and should be treated as indicative, not as cross-machine guarantees.

| Local rows | Input object bytes | Init mean (5) | Render mean (20) | Scroll + render mean (20) | Edit mean (10) | Edit allocations >1 KiB | Render allocations >1 KiB |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 1,000 | 12,848 | 0.008 s | 0.0195 s | 0.0120 s | 0.008 s | 4,048 B | 1,857,520 B |
| 100,000 | 1,200,848 | 0.004 s | 0.0115 s | 0.0110 s | 0.002 s | 400,048 B | 1,857,520 B |
| 1,000,000 | 12,000,848 | 0.004 s | 0.0110 s | 0.0115 s | 0.001 s | 4,000,048 B | 1,857,520 B |

Rprofmem counted allocations of at least 1 KiB during a render, not peak resident memory or constructor allocations. The same observed render allocation across these sizes is consistent with viewport-sized rendering; it is not evidence that retaining the local input table is free.

## 10M-row source simulation

The deterministic mock reported 10,000,000 rows without constructing that object. Schema initialization fetched 100 rows; a distant scroll fetched 200 rows total, at most 100 per call, and requested 12 of 40 columns. The two pages' selected-column payloads were 13,824 bytes. The equivalent all-40-column page payload was estimated from `object.size()` as 42,816 bytes, a 67.7% reduction for the same requests. Source initialization was 0.02 s and distant scroll/render 0.07 s in this run.

A single edit at row 9,000,000 completed below the timer's 0.01-second display resolution. It fetched 100 rows from one column, then called the source setter for that row. No other column was requested for that edit.

The payload comparison is an in-process mock, not a measured database bandwidth or query-plan comparison. It demonstrates bounded rows and projected columns. A separate 20-column/25-cell viewport reproduction recorded two 100-row fetches with 20 columns before the fix and 4 columns after it (see `projection-comparison.csv`). The 40-column stress case requested 12 visible columns. The repository had no trustworthy pre-A3.5 timed baseline, so no before/after latency claim is made.

Local edits changed the integer column. One-cell allocations grew from about 4 KB at 1,000 rows to 4 MB at 1,000,000 rows, matching R vector copy-on-modify behavior. This shows why source edit callbacks operate on the selected cell/page instead of fetching a full column.
