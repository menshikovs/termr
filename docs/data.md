# Data tools

## `data_table()`

```r
data_table(
  df,
  id = "table",
  cursor = "row",                          # "row", "cell" or "none"
  columns = list(
    name = column(width = 20),
    score = column(width = 10, align = "right", label = "Score")
  ),
  formatters = list(
    score = function(x) sprintf("%.2f", x),
    active = function(x) ifelse(x, "yes", "no")
  ),
  zebra = TRUE,
  row_style = function(row, data) if (data$score[row] < 0) style(foreground = "$error"),
  cell_style = function(value, row, column) NULL
)
```

* Works with data frames (including tibbles) and matrices.
* Preserves the input frame and its column classes. The built-in typed adapters
  cover logical, integer, double, character, factor, ordered factor, `Date`,
  `POSIXct`, `difftime`, raw byte vectors and list columns. `hms`,
  `bit64::integer64`, and `blob::blob` are supported when their optional
  packages are installed. Raw values, blob elements and raw elements in list
  columns use a bounded eight-byte hex preview; binary data is never decoded
  as text. Binary columns are read-only, and raw columns cannot be sorted.
  Other S3/S4 classes use their standard pillar or `format()` methods through
  the class chain when those methods return a valid bounded result; formatter
  errors and malformed results fall back to a compact class label. Their type
  header uses `pillar::type_sum()` or `vctrs::vec_ptype_abbr()` when available.
  Unknown classes are read-only by default. A `vctrs_vctr` class is editable
  only when its directed character-to-prototype `vec_cast()` accepts an empty
  probe and each submitted value returns the exact prototype storage type,
  class and attributes. The cast method owns text parsing and validation;
  incompatible input, warnings or changed metadata reject the edit atomically.
  Classes that do not pass these checks remain viewable and read-only. termr
  does not expose a type-handler registration API.
* `column_info()` reports each column's compact type, class, underlying R
  storage type, prototype, missing-value support, formatter, and editability.
  Set `show_types = TRUE` to display type summaries beneath the headers.
  Special types use pillar formatting when the optional `pillar` package is
  installed; only the sampled rows and visible slice are formatted. If
  `pillar` is unavailable, compatible S3 `format()` methods are used when
  available.
* **Virtualised**: only visible rows are formatted and painted; widths are
  estimated from the first and last 500 rows. Measured on Windows: a frame
  of a 1,000,000-row table at 120x40 takes about 20 ms to paint, moving
  the cursor about 20 ms per tick (see `tools/bench/bench.R`).
* For larger-than-memory data, pass an experimental `table_source()`; see
  [Lazy table sources](data-sources.md) for the fetch protocol, delegated
  capabilities, refresh and lifecycle behavior.
* Keys: arrows, Page Up/Down, Home/End, Enter. Mouse: click, header click,
  wheel.
* `$sort(by, decreasing)`, `$filter(rows)`, `$move_cursor(row, column)`,
  `$selected_row()`, `$row_data(row)`, `$view`.
* Messages: `datatable.row_selected`, `datatable.cell_selected`,
  `datatable.row_activated` (`row`, `position`, `value`, `column`) and
  `datatable.header_selected` (`column`, `index`).

## `browse_data()`

```r
browse_data(mtcars)
viewer <- data_browser(big_df, title = "Sales")   # build without running
```

Metrics, search across all columns (`/`), sorting by the current column
(`s`), column summaries, row details (Enter) and reset (`r`).

`data_profile()` also summarizes in-memory `difftime` vectors. It preserves
the source time zone for POSIXct summaries and handles `hms` and
`bit64::integer64` without widening values to double when those optional
packages are installed.

## Dashboards

```r
horizontal(
  metric("Rows", nrow(df)),
  metric("Accuracy", 0.943, delta = 0.012),
  panel(sparkline(history, id = "loss"), title = "Loss")
)
```

Use `app$set_interval()` to refresh, `sparkline$push()` for streams,
`log_view()` for logs and `app$run_worker()` for long computations.

## Spatial data

When the optional sf package is installed, sf frames keep their class, active
geometry column, CRS and attribute-geometry relationships in the table model.
sfc cells show a point preview or a bounded summary for larger geometries;
sfg list-columns receive the same summaries. Empty geometries display as
TYPE EMPTY. Geometry columns cannot be edited or sorted. Sorting and filtering
keep a row-index view, so geometry remains attached to its attributes.

Ordinary attribute columns use the existing typed editor. After each edit,
termr verifies that the sf class, geometry, CRS, active column and all frame
attributes remain unchanged before accepting it. column_info() includes
geometry type, dimensions, CRS, precision, active-column status and the stored
bounding box. In browse_data(), the selected column shows this metadata, and
Enter adds per-feature type, dimensions, empty status, coordinate count,
bounding box and a bounded WKT preview. WKT is generated only for the
selected feature and is omitted for geometries with more than 64 coordinates.
sf and its system GIS libraries remain optional.

## DataTable 2.0

* **Columns.** `column(width, align, formatter, visible, sortable, editable)`;
  `set_column_width(col, n)`, `auto_size_column(col, rows = "sample")` (never
  scans a huge table unless `rows = "all"`), `auto_size_all()`,
  `set_column_visible(col, FALSE)`, `column_info()`. Drag the separator
  between header cells, or Alt+Left/Right, to resize the active column.
  `reorder_column(col, to)` changes display order; drag a header or press
  Ctrl+Alt+Left/Right to move the active column. Data-frame column order is
  unchanged. `column_info()` includes both source and display positions.
* **Frozen columns.** `data_table(df, frozen_columns = 1)`: the first columns
  and the header stay while the rest scrolls; a bar marks the boundary.
* **Sorting.** `sort(c("a", "b"), decreasing = c(FALSE, TRUE))` sorts by
  several keys (stable, `NA` last) and shows `^1` / `v2` markers; the sort
  survives `filter()`. `header_sort = TRUE` sorts on header click (again:
  descending, then off; Shift+click adds a key) and binds `S`. `clear_sort()`.
* **Search.** Ctrl+F opens a find bar over the formatted cells (all columns, or
  the active one with Tab; Ctrl+R regex, Alt+C case); `find(query, column,
  case_sensitive, regex)`, `find_next()`, `find_previous()`, `match_hit`. Large
  tables are scanned in chunks. `goto_row(n)` and Ctrl+G jump to a row.
* **Selection and copy.** Shift+Up/Down extends a row range; Shift+drag does
  the same with the mouse. `select_range(from, to)`, `selected_data()` and
  `visible_data()` expose selected and viewport rows. Ctrl+C copies selected
  rows as TSV with visible headers; `copy_selection(headers = FALSE)` omits
  them. System clipboard output follows the terminal's OSC 52 capability.
* **Filters.** `filter_columns(list(score = table_filter("range", min = 10,
  max = 20), name = table_filter("contains", "r")))` combines column filters
  with AND. Supported types are `equals`, `contains`, `regex`, `range`, and
  `missing`; callers can also pass `function(values) logical`. Predicates run
  in chunks of 5,000 rows. Existing `filter(rows)` subsets compose with the
  column filters.
* **Editing (experimental).** `data_table(df, editable = TRUE, on_edit =
  function(row, column, value) ...)`: Enter or double click opens a small
  dialog; the table edits *its own copy* of the data (`$data`), converts text to
  the column type, runs `on_edit` (return a message to reject) and sends
  `datatable.cell_changed` (`row`, `column`, `old`, `value`). `set_cell()` does
  the same from code. Invalid edits are rejected before assignment. Factor
  levels and date/time classes are preserved. Dates use `YYYY-MM-DD`; local
  `POSIXct` input rejects nonexistent or ambiguous daylight-saving times unless
  an explicit UTC offset is supplied. `integer64` editing uses exact decimal
  text and requires `bit64`. When the optional `units` package is installed,
  units columns display their unit in `column_info()` and in the optional type
  header. Enter a bare number in the column's unit (`12.5` in an `m` column),
  or include a compatible unit (`125 cm`); values are converted with
  `units::set_units()` and retain the column's original unit. Incompatible or
  invalid units reject the edit without changing the cell. This also delegates
  offset temperature conversions to `units`. List columns are always read-only
  and display bounded summaries rather than expanding nested values.
* **Haven labelled vectors.** When optional `haven` is installed,
  `haven_labelled` and `haven_labelled_spss` columns retain their raw storage
  values, class and attributes. `column(label_mode = "raw")` is the default;
  `column(label_mode = "labels")` displays a known value label with its raw
  value in brackets. `column_info()` exposes the base storage type, variable
  label, value labels, tagged-NA labels and SPSS `na_values`/`na_range` without
  expanding them into the type header. Editing accepts exact known labels,
  raw values (`raw:8`, or `raw:<text>` for character data), explicit
  `label:<label>` input when a numeric label collides with a raw number, `NA`,
  `NaN`, and tagged missings such as `NA(a)`. Duplicate labels and ambiguous
  raw/label input are rejected. SPSS user-missing values remain their original
  raw values and retain their missing definitions; termr never adds labels or
  changes missing metadata. Labelled vectors are read-only when `haven` is
  unavailable or their metadata is invalid. `haven` remains optional.
* **Optional units dependency.** `units` uses UDUNITS-2. Linux source builds
  generally need the system `libudunits2-dev` package; macOS source builds need
  UDUNITS-2 (for example, Homebrew's `udunits`). Installing the CRAN binary on
  Windows avoids a local source build. Without `units`, other termr features
  continue to work and units objects remain read-only.
* **Type behavior.** Missing values display as `NA`; `NaN`, positive and
  negative infinity remain distinct for doubles. Empty strings remain valid
  character values. List-column `NULL` values are treated as missing for the
  `missing` filter and display as `<NULL>` so they remain distinguishable from
  a scalar `NA`.
* More messages: `datatable.sorted`, `datatable.column_resized`,
  `datatable.columns_changed`, `datatable.found`.

## Reproducible R code

`DataTable$reproducible_code("value")` returns source for the selected cell
when the table uses a cell cursor, or the selected rows and visible columns
otherwise. The result is bounded to 1,000 rows and 10,000 cells by default;
`max_rows` and `max_bytes` can lower those limits, subject to hard internal
caps. Supported base and checked optional classes retain their storage type
and attributes. Unknown classes, executable objects and values that exceed a
limit return an explicit status and reason instead of becoming character
strings.

`DataTable$reproducible_code("pipeline")` emits base R source for the current
local row filter, supported column filters, stable sort keys, explicit row
range and visible columns. It uses the symbolic source binding `data`; set
that name to the same in-memory frame before running the copied code. The
result describes the current final view. DataTable does not retain a sequence
of past filter/sort actions, so this output is not presented as operation
history. Cursor movement, search, terminal scrolling and ordinary selection
of one cursor row do not become pipeline steps.

`DataTable$reproducible_code("edits")` emits local cell assignments against
the original data-frame row numbers. Repeated edits to one cell collapse to
its final value, and resetting the table data clears the edit ledger. The
ledger is bounded at 1,000 changed cells. Edits against a `table_source()`
are never exported as writes.

The command palette (Ctrl+P) provides **Copy selection as R value**, **Copy
current R pipeline**, and **Copy local R edits**. These use the app's existing
clipboard path. Ctrl+C remains the existing tab-separated copy command.
Generated expressions are built from R language objects; source names and
filter values are represented as string/numeric literals. The generator
never evaluates user text. Optional package constructors are guarded with
`requireNamespace()` calls.

The return value includes `status`, `reason`, `packages`,
`requires_source_binding` and a compact typed model. A `table_source()` does
not expose a portable identity for its connection or query, so pipeline and
edit exports report unsupported without copying connection details. A bounded
selected source value can still be copied as a self-contained value when its
type survives the source read. Direct dbplyr and Arrow Dataset inputs are not
DataTable source adapters in this release; explicitly collecting a bounded
sample gives reproducibility only for that local sample, not its original
query or dataset.

```r
data <- data.frame(group = c("b", "a", "a"), score = c(1, 3, 2))
table <- data_table(data)
table$filter_columns(list(group = table_filter("equals", "a")))
table$sort("score", decreasing = TRUE)
pipeline <- table$reproducible_code("pipeline")
cat(pipeline$code)
```
