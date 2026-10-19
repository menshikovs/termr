# Data table

A fast, read-only viewer for data frames: a header, optional row names,
automatic column widths, keyboard and mouse navigation, horizontal and
vertical scrolling, and a row or cell cursor. Only the visible rows are
formatted and painted, so tables with millions of rows scroll smoothly.

## Usage

``` r
data_table(
  data,
  cursor = "row",
  columns = NULL,
  formatters = NULL,
  row_names = NA,
  header = TRUE,
  zebra = FALSE,
  row_style = NULL,
  cell_style = NULL,
  max_column_width = 40L,
  frozen_columns = 0L,
  header_sort = FALSE,
  editable = FALSE,
  on_edit = NULL,
  id = NULL,
  classes = NULL,
  style = NULL
)
```

## Arguments

- data:

  A data frame (tibbles work too) or a matrix.

- cursor:

  `"row"` (default), `"cell"` or `"none"`.

- columns:

  Named list of
  [`column()`](https://menshikovs.github.io/termr/reference/column.md)
  options, e.g. `list(score = column(width = 10, align = "right"))`.

- formatters:

  Named list of `function(x)` returning strings, e.g.
  `list(score = function(x) sprintf("%.2f", x))`.

- row_names:

  Show row names? `NA` (default) shows them only when they are not the
  automatic `1..n` (e.g. `mtcars`).

- header:

  Show the header row?

- zebra:

  Stripe alternate rows?

- row_style:

  `function(row, data)` returning a
  [`style()`](https://menshikovs.github.io/termr/reference/style.md) (or
  `NULL`) for a data row.

- cell_style:

  `function(value, row, column)` returning a
  [`style()`](https://menshikovs.github.io/termr/reference/style.md) (or
  `NULL`) for a cell.

- max_column_width:

  Upper limit for automatic column widths.

- frozen_columns:

  Number of leading columns that stay in place while the others scroll
  horizontally.

- header_sort:

  Sort when a header is clicked (again: descending, then off;
  Shift+click adds a secondary key)?

- editable:

  Allow editing cells (Enter or double click opens a small dialog)? The
  table edits its own copy of the data; read it with `$data` or react to
  `"datatable.cell_changed"`. **Experimental.**

- on_edit:

  `function(row, column, value)` called before an edit is applied;
  return `NULL`/`TRUE` to accept or a message to reject.

- id:

  Optional identifier.

- classes:

  Optional classes.

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md);
  by default the table fills its parent.

## Value

A `DataTable` widget.

## Details

Keys: arrows move the cursor (with a row cursor, Left/Right scroll the
columns), Page Up/Down move a page, Home/End go to the first / last row,
Enter activates the row (or edits the cell when `editable`), Ctrl+F
finds text (Enter/Down next, Up previous, Tab all columns / this column,
Ctrl+R regex, Alt+C case, Esc close), F3 / Shift+F3 next / previous
match, Ctrl+G jumps to a row, `S` (with `header_sort`) sorts by the
active column (ascending, descending, off), Alt+Left / Alt+Right narrow
/ widen the active column. Clicking a row selects it; clicking the
header sends `"datatable.header_selected"` (and sorts with
`header_sort`); dragging the separator between two header cells resizes
a column; the wheel scrolls. The header and the first `frozen_columns`
columns stay in place while the rest scrolls.

Messages (`event$data`):

- `"datatable.row_selected"` / `"datatable.cell_selected"`: the cursor
  moved; `row` (original row number), `position` (in the view), `value`
  (the row as a list, or the cell value), `column` (cell cursor);

- `"datatable.row_activated"`: Enter; same data;

- `"datatable.header_selected"`: `column` (name) and `index`;

- `"datatable.sorted"` (`columns`, `decreasing`),
  `"datatable.column_resized"` (`column`, `width`),
  `"datatable.columns_changed"` (`column`, `visible`),
  `"datatable.found"` (`position`, `row`, `column`),
  `"datatable.cell_changed"` (`row`, `column`, `old`, `value`).

Methods: `set_data()`, `sort(by, decreasing)` (several columns allowed),
`clear_sort()`, `toggle_sort()`, `filter(rows)`,
`move_cursor(row, column)`, `goto_row()`, `scroll_to_row()`,
`selected_row()`, `row_data(row)`, `set_column_width()`,
`auto_size_column()`, `auto_size_all()`, `set_column_visible()`,
`column_info()`, [`find()`](https://rdrr.io/r/utils/apropos.html),
`find_next()`, `find_previous()`, `edit_cell()`, `set_cell()`.

## Examples

``` r
tbl <- data_table(mtcars, id = "cars", zebra = TRUE,
                  formatters = list(mpg = function(x) sprintf("%.1f", x)))
render_widget(tbl, 60, 6)
#> <ScreenBuffer 60x6>
#> +------------------------------------------------------------+
#> |                     mpg cyl  disp  hp drat    wt  qsec vs  |
#> |Mazda RX4           21.0   6 160.0 110 3.90 2.620 16.46  0 █|
#> |Mazda RX4 Wag       21.0   6 160.0 110 3.90 2.875 17.02  0 │|
#> |Datsun 710          22.8   4 108.0  93 3.85 2.320 18.61  1 │|
#> |Hornet 4 Drive      21.4   6 258.0 110 3.08 3.215 19.44  1 │|
#> |                    ██████████████████████████████───────── |
#> +------------------------------------------------------------+
```
