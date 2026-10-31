# A2.5 Implementation

Implemented spatial awareness for `sf`, `sfc`, `sfg`, and list-columns containing simple features.

- Bounded geometry display handles POINT coordinates while summarizing more complex geometries structurally.
- `column_info()` reports geometry type, coordinate dimensions, CRS label, bbox, precision, and whether a column is active geometry.
- `show_types` exposes geometry type information without expanding long metadata into every row.
- The row inspector provides feature metadata and a bounded WKT preview.
- Geometry values are read-only. Attribute columns remain editable through the typed replacement path, preserving geometry and row associations.
- Empty geometries are distinct from missing `NULL` list elements; `is.na()` semantics are used for `sfc` missingness.
- CRS labels prefer EPSG codes and fall back to compact labels for custom or missing CRS.

The implementation uses public `sf` functions where available and has a structural fallback for simple feature objects when formatting an individual POINT without `sf` installed. `sf` is an optional dependency. No native code or new exports were added.

Source changes: `DESCRIPTION`, `R/datatable-typed.R`, `R/widget-datatable.R`, `R/browse-data.R`, `docs/data.md`, `NEWS.md`, and generated `man/DataTable-class.Rd`. Tests are in `tests/testthat/test-datatable-sf.R`.
