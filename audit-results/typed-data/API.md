# Typed DataTable API

No exported symbols were added. `data_table()` adds the trailing
`show_types = FALSE` argument; its default keeps the existing one-row header.
Set it to `TRUE` to display the compact type label beneath each header.

`DataTable$column_info()` retains its existing source/display layout fields and
adds `type`, `class`, `typeof`, `prototype`, `attributes`, `allows_missing`,
`format`, and `editable` columns. These are derived from each column's
zero-length prototype and adapter.

`set_cell()` and the edit dialog accept text and return a typed scalar through
the existing `datatable.cell_changed` event. The `old` and `value` fields keep
their source class and attributes. Unsupported object and list columns report
read-only status. Existing data conversion, selection, and lazy-source APIs
are unchanged.

The optional dependencies `pillar`, `vctrs`, `tibble`, `dplyr`, `hms`, and
`bit64` are listed in `Suggests`, not `Imports`. No `NAMESPACE` exports were
added. Roxygen generates the public help topic from `R/widget-datatable.R`.
