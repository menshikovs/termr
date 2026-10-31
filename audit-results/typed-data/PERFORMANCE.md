# Typed DataTable performance comparison

Measured 2026-10-30 on Windows with R 4.6.1. Baseline is clean `HEAD`
(`1b10370`) extracted with `git archive`; current is the working tree. Both
used the same `performance.R`, mixed integer/double/Date/character columns,
100x30 headless render, five timing samples and repeated batches to reduce the
Windows timer's coarse resolution. The CSVs and run logs are included here.

Times are median milliseconds per operation. They are local observations, not
promises. Values of zero are below the observed timer resolution. The sample
shows the cost of constructing typed metadata; wall-clock differences below
about 5 ms are not meaningful on this host.

| Rows | Operation | HEAD ms | Typed ms |
|---:|---|---:|---:|
| 0 | build | 2 | 2 |
| 0 | render | 2 | 4 |
| 10 | build | 1 | 2 |
| 10 | render | 6 | 8 |
| 1,000 | build | 8 | 14 |
| 1,000 | render | 16 | 16 |
| 100,000 | build | 8 | 14 |
| 100,000 | render | 16 | 16 |
| 100,000 | range filter | 4 | 2 |
| 1,000,000 | build | 8 | 14 |
| 1,000,000 | render | 16 | 16 |
| 1,000,000 | edit one cell | <1 | 1 |
| 1,000,000 | sort | 12 | 16 |
| 1,000,000 | range filter | 22 | 18 |

Scroll calls remained below timer resolution. Formatting the viewport is
bounded by the rendered rows; the test suite separately asserts that a 3-row
slice of a 1,000,001-element Date column produces exactly three formatted
cells.

The 1M-row frame's `object.size(data)` was 92,001,312 bytes for both revisions.
Table construction retained the source frame by reference until an edit; the
measurement found no additional frame-sized copy. `object.size()` on an R6
environment is shallow, so `table_object_bytes` is recorded but is not used as
a total-memory estimate. `retained_vcells_delta_kb` is included in the CSV as
an approximate diagnostic only.

The same comparison ran on Ubuntu WSL with R 4.5.2, using the same script and
batch counts:

| Rows | Operation | HEAD ms | Typed ms |
|---:|---|---:|---:|
| 0 | build | 0.9 | 1.5 |
| 0 | render | 1.6 | 1.8 |
| 10 | build | 1.1 | 1.6 |
| 10 | render | 4.0 | 4.0 |
| 1,000 | build | 2.4 | 3.1 |
| 1,000 | render | 11.2 | 10.8 |
| 100,000 | build | 2.5 | 3.4 |
| 100,000 | render | 10.8 | 11.0 |
| 100,000 | range filter | 1.4 | 1.6 |
| 1,000,000 | build | 2.5 | 3.4 |
| 1,000,000 | render | 10.0 | 10.2 |
| 1,000,000 | edit one cell | 0.4 | 0.6 |
| 1,000,000 | sort | 15.6 | 15.0 |
| 1,000,000 | range filter | 19.8 | 21.2 |

The WSL source-data object sizes match the Windows sizes for all five row
counts. At one million rows both sides report 92,001,312 bytes. Differences
below a millisecond should be treated as timer/host variation rather than a
reliable regression.

Reproduce from a checkout with:

```sh
Rscript audit-results/typed-data/performance.R output.csv
```
