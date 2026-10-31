# Performance measurements

## Method

`benchmark-units.R` measured units DataTables with 100, 10,000 and 100,000
rows; `benchmark-numeric-control.R` measured ordinary double columns using the
same operations. Both warmed the package/UI first, used an 80x24 headless
terminal and type row, formatted 20 visible values 100 times, sent 40 Down
keys, and measured a one-cell edit. Constructor time is the median of 20
constructions; edit time is the median per operation over 50 edits. Allocation
bytes are from `Rprofmem(threshold = 1)` for a single edit. Results are in
`performance.csv`, `performance-numeric-control.csv` and platform logs.

## Units DataTable results

| OS / rows | Construct ms | First render ms | First render alloc bytes | 40 Down ms | Format 20 visible cells ×100 ms | Edit ms/cell | Edit alloc bytes |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Windows / 100 | <1 | 360 | 27,775,568 | 1,720 | 30 | 2.2 | 9,824 |
| Windows / 10,000 | <1 | 90 | 25,931,240 | 2,390 | 50 | 4.0 | 89,024 |
| Windows / 100,000 | <1 | 180 | 25,931,240 | 2,520 | 50 | 3.8 | 809,024 |
| WSL / 100 | 2 | 189 | 27,774,872 | 1,074 | 14 | 1.46 | 9,824 |
| WSL / 10,000 | 3 | 56 | 25,931,240 | 887 | 14 | 1.50 | 89,024 |
| WSL / 100,000 | 2 | 55 | 25,931,240 | 894 | 14 | 1.54 | 809,024 |

## Interpretation

- First render allocations are process-level Rprofmem totals that include the
  `test_app()`/screen harness, not retained table memory. Their near-constant
  size across row counts shows that the first paint did not allocate a
  formatted string for every units value. First-render time also includes
  harness initialization, so it is not a stable scaling curve.
- Viewport formatting is bounded to the selected 20-row slice. One hundred
  visible-slice formatting calls took 14–50 ms for units; the numeric control
  took 0–20 ms on Windows and 3 ms on WSL. Windows sub-10-ms readings are
  quantized by timer resolution.
- Forty key events took 0.89–2.52 seconds for units. Numeric controls were
  0.83–2.58 seconds. The similar range indicates scrolling is dominated by the
  existing widget/event/render path; it does not scale as a whole-column unit
  conversion.
- A single edit's allocations were 9.8 KB / 89 KB / 809 KB for the three row
  counts. The conversion and round-trip check operate on one scalar. The
  increasing allocation is the R vector copy required by `vec_assign()` and
  DataTable copy-on-modify, not conversion of all units in the column.
- Per-cell edits took about 1.5–4 ms for units. The numeric control took
  0.6–3 ms. This is the scalar conversion/range-check overhead plus ordinary
  table assignment; measurements are machine and runtime specific.
