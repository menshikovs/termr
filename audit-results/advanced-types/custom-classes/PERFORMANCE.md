# A2.6 Performance

Measurements use `bench-custom-classes.R`. It reports medians of five timed calls after warm-up. DataTable first render and scrolling use the public widget methods; visible formatting requests 20 rows; build allocation counts Rprofmem allocations of at least 1 KiB. `data_bytes` and `table_data_bytes` report object sizes. Results are local smoke measurements, not a cross-machine benchmark. Windows timer resolution is coarse, so 0 and 10 ms readings should be read as bounds at that timer resolution.

## Windows 11 / R 4.6.1

Times in milliseconds; columns are build / first render / scroll-to-opposite-end / format 20 visible values / edit one cell. S3 classes are intentionally read-only, so edit is not applicable.

| Rows | Base double | Date | Custom S3 | Custom vctrs |
|---:|---|---|---|---|
| 1,000 | 0 / 10 / 0 / 0 / 0 | 10 / 20 / 0 / 0 / 0 | 50 / 20 / 0 / 0 / n/a | 50 / 10 / 0 / 0 / 0 |
| 100,000 | 0 / 10 / 0 / 0 / 0 | 10 / 20 / 0 / 0 / 0 | 50 / 10 / 0 / 0 / n/a | 40 / 10 / 0 / 0 / 0 |

## WSL Ubuntu 26.04 / R 4.5.2

Times in milliseconds, in the same column order as above.

| Rows | Base double | Date | Custom S3 | Custom vctrs |
|---:|---|---|---|---|
| 1,000 | 3 / 8 / 0 / 0 / 1 | 2 / 8 / 0 / 1 / 1 | 13 / 9 / 0 / 1 / n/a | 13 / 9 / 0 / 1 / 2 |
| 100,000 | 2 / 8 / 0 / 0 / 2 | 2 / 8 / 0 / 0 / 1 | 13 / 9 / 0 / 1 / n/a | 13 / 9 / 0 / 1 / 2 |

## Memory and interpretation

For 100,000 rows, `data.frame` object sizes were 800,728 bytes (double), 800,952 bytes (Date), 801,184 bytes (custom S3), and 801,032 bytes (custom vctrs) on both systems. Table data sizes matched their source data sizes. Rprofmem totals for allocations at least 1 KiB during table construction ranged from 172,048 to 340,480 bytes for these 100,000-row cases on both Windows and WSL. These totals are allocated bytes observed above the threshold, not peak resident memory.

Generic width estimation samples no more than 1,000 rows, and cell rendering formats only the requested slice. The 20-row formatting measurement stays at or below 1 ms on WSL and below the Windows timer's measurable 10 ms step. One-time custom-class setup and bounded width sampling make table construction slower than the primitive path (about 13 ms on WSL and 40–50 ms at Windows timer resolution); first rendering remains about 8–20 ms at both tested row counts. The scroll measurement exercises DataTable's row-navigation method and does not measure terminal repaint latency.
