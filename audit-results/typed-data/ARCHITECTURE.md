# Typed data architecture

The in-memory DataTable path remains an R data frame or tibble plus a row
index. Type metadata is derived from each source column; editing never converts
the whole frame to a common representation.

```text
R column ──> adapter + prototype ──> viewport slice ──> formatter ──> cells
    ▲                                                                  │
    └──── typed parse <──── assignment check <──── user text <─────────┘
```

`R/datatable-typed.R` owns a closed internal adapter set. Each adapter describes
the display class, metadata label, missing-value policy and editability.
Shared helpers provide prototype inspection, slicing, formatting, strict text
parsing, scalar casts and assignment checks. Adding an adapter does not expose
a public registry or permit arbitrary class conversion.

`DataTable` owns cursor, viewport, selection, sort and filters. It slices only
the rows required by width sampling, search chunks or the current viewport.
Specialized pillar formatting receives that bounded slice. List columns use
small per-cell summaries and are never traversed recursively by painting.

`vctrs` is used through public `vec_ptype()`, `vec_slice()`, `vec_cast()` and
`vec_assign()` calls when present. Base-R fallbacks cover the supported scalar
types. The code does not widen types with `vec_ptype2()` or restore arbitrary
objects blindly. Post-assignment checks compare `typeof`, class and attributes
to the original column before replacing the table column.

Data-frame and tibble classes are left intact. Table sorting changes row
positions, and editing assigns one validated value into one typed column.
Grouped and rowwise metadata therefore remain attached to the frame; no dplyr
verbs are required for table behavior.
