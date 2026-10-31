# Known limitations

* Label display, tagged-NA tag inspection, SPSS missing classification and
  editing require the optional `haven` package. Without it, labelled vectors
  are read-only and use base raw formatting where possible; base R cannot
  expose Haven's tagged-NA letters or SPSS user-missing rules.
* Editing is implemented for Haven-labelled integer, double and character
  storage with valid metadata. Other storage types and malformed metadata are
  read-only.
* A duplicate label that maps to distinct raw values cannot be selected by
  label text. Users can edit the intended raw value with `raw:<value>`.
* `column_info()` returns full label and missing-definition vectors, but
  `show_types` intentionally displays only a compact type code. Very long
  cell labels remain subject to the DataTable's normal column width and
  viewport clipping.
* Termr does not edit value-label mappings, variable labels, SPSS
  `na_values`/`na_range`, or other Haven metadata. It does not add labels
  automatically.
* Tests requiring DBI, units, mirai, nanonext, plotly, promises, RSQLite or
  shiny are skipped when those optional packages are absent. The separate
  Haven-absent Windows test verifies base functionality and read-only behavior.
