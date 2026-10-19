# DataTable widget

A virtualised table for data frames or lazy table sources. See
[`data_table()`](https://menshikovs.github.io/termr/reference/data_table.md).

## Super class

[`Widget`](https://menshikovs.github.io/termr/reference/Widget-class.md)
-\> `DataTable`

## Public fields

- `paint_states`:

  Cursor and scroll changes only repaint.

- `focusable`:

  Tables can be focused.

- `cursor_type`:

  `"row"`, `"cell"` or `"none"`.

- `show_header`:

  Show the header row?

- `zebra`:

  Stripe alternate rows?

- `row_style`:

  `NULL` or `function(row, data)` returning a style for a data row
  (`row` is the original row number or source position).

- `cell_style`:

  `NULL` or `function(value, row, column)` returning a style for a cell.

- `frozen_columns`:

  Number of leading columns that stay visible while the others scroll
  horizontally.

- `header_sort`:

  Clicking a header sorts by that column (click again: descending, then
  unsorted; Shift+click adds a column)?

- `editable`:

  Allow editing cells (Enter / double click)?

- `on_edit`:

  `NULL` or `function(row, column, value)` called before a cell edit is
  applied; return `NULL` / `TRUE` to accept or a message to reject the
  edit.

## Active bindings

- `data`:

  The data frame or source (assigning calls `set_data()`).

- `row_count`:

  Number of rows in the current view.

- `column_names`:

  Names of the data columns.

- `cursor_row`:

  Cursor position in the view (0 = none).

- `cursor_column`:

  Cursor column number (cell cursor; 0 = none).

- `offset_row, offset_column`:

  Scroll offsets (rows / columns).

- `view`:

  Row numbers or source view positions in display order.

- `sort_state`:

  `NULL` or a data frame (`column`, `decreasing`) of the current sort
  keys.

- `match_hit`:

  `NULL` or the current search result (`position`, `row`, `column`).

## Methods

### Public methods

- [`DataTable$new()`](#method-DataTable-initialize)

- [`DataTable$default_style()`](#method-DataTable-default_style)

- [`DataTable$default_bindings()`](#method-DataTable-default_bindings)

- [`DataTable$set_data()`](#method-DataTable-set_data)

- [`DataTable$refresh()`](#method-DataTable-refresh)

- [`DataTable$close()`](#method-DataTable-close)

- [`DataTable$source_stats()`](#method-DataTable-source_stats)

- [`DataTable$sort()`](#method-DataTable-sort)

- [`DataTable$clear_sort()`](#method-DataTable-clear_sort)

- [`DataTable$toggle_sort()`](#method-DataTable-toggle_sort)

- [`DataTable$filter()`](#method-DataTable-filter)

- [`DataTable$filter_columns()`](#method-DataTable-filter_columns)

- [`DataTable$move_cursor()`](#method-DataTable-move_cursor)

- [`DataTable$scroll_to_row()`](#method-DataTable-scroll_to_row)

- [`DataTable$selected_row()`](#method-DataTable-selected_row)

- [`DataTable$row_data()`](#method-DataTable-row_data)

- [`DataTable$selected_data()`](#method-DataTable-selected_data)

- [`DataTable$visible_data()`](#method-DataTable-visible_data)

- [`DataTable$reorder_column()`](#method-DataTable-reorder_column)

- [`DataTable$select_range()`](#method-DataTable-select_range)

- [`DataTable$copy_selection()`](#method-DataTable-copy_selection)

- [`DataTable$goto_row()`](#method-DataTable-goto_row)

- [`DataTable$column_width()`](#method-DataTable-column_width)

- [`DataTable$set_column_width()`](#method-DataTable-set_column_width)

- [`DataTable$auto_size_column()`](#method-DataTable-auto_size_column)

- [`DataTable$auto_size_all()`](#method-DataTable-auto_size_all)

- [`DataTable$set_column_visible()`](#method-DataTable-set_column_visible)

- [`DataTable$column_info()`](#method-DataTable-column_info)

- [`DataTable$find()`](#method-DataTable-find)

- [`DataTable$find_next()`](#method-DataTable-find_next)

- [`DataTable$find_previous()`](#method-DataTable-find_previous)

- [`DataTable$clear_find()`](#method-DataTable-clear_find)

- [`DataTable$edit_cell()`](#method-DataTable-edit_cell)

- [`DataTable$set_cell()`](#method-DataTable-set_cell)

- [`DataTable$action_cursor_up()`](#method-DataTable-action_cursor_up)

- [`DataTable$action_cursor_down()`](#method-DataTable-action_cursor_down)

- [`DataTable$action_extend_selection_up()`](#method-DataTable-action_extend_selection_up)

- [`DataTable$action_extend_selection_down()`](#method-DataTable-action_extend_selection_down)

- [`DataTable$action_move_column_left()`](#method-DataTable-action_move_column_left)

- [`DataTable$action_move_column_right()`](#method-DataTable-action_move_column_right)

- [`DataTable$action_copy_selection()`](#method-DataTable-action_copy_selection)

- [`DataTable$action_cursor_left()`](#method-DataTable-action_cursor_left)

- [`DataTable$action_cursor_right()`](#method-DataTable-action_cursor_right)

- [`DataTable$action_page_up()`](#method-DataTable-action_page_up)

- [`DataTable$action_page_down()`](#method-DataTable-action_page_down)

- [`DataTable$action_first_row()`](#method-DataTable-action_first_row)

- [`DataTable$action_last_row()`](#method-DataTable-action_last_row)

- [`DataTable$action_open_find()`](#method-DataTable-action_open_find)

- [`DataTable$action_open_goto()`](#method-DataTable-action_open_goto)

- [`DataTable$action_find_next()`](#method-DataTable-action_find_next)

- [`DataTable$action_find_previous()`](#method-DataTable-action_find_previous)

- [`DataTable$action_widen_column()`](#method-DataTable-action_widen_column)

- [`DataTable$action_narrow_column()`](#method-DataTable-action_narrow_column)

- [`DataTable$action_sort_column()`](#method-DataTable-action_sort_column)

- [`DataTable$action_activate()`](#method-DataTable-action_activate)

- [`DataTable$on_mouse_down()`](#method-DataTable-on_mouse_down)

- [`DataTable$on_drag_move()`](#method-DataTable-on_drag_move)

- [`DataTable$on_drag_end()`](#method-DataTable-on_drag_end)

- [`DataTable$on_key()`](#method-DataTable-on_key)

- [`DataTable$on_paste()`](#method-DataTable-on_paste)

- [`DataTable$on_mouse_scroll()`](#method-DataTable-on_mouse_scroll)

- [`DataTable$content_width()`](#method-DataTable-content_width)

- [`DataTable$content_height()`](#method-DataTable-content_height)

- [`DataTable$paint()`](#method-DataTable-paint)

- [`DataTable$clone()`](#method-DataTable-clone)

Inherited methods

- [`Widget$add_class()`](https://menshikovs.github.io/termr/reference/Widget.html#method-add_class)
- [`Widget$ancestors()`](https://menshikovs.github.io/termr/reference/Widget.html#method-ancestors)
- [`Widget$animate()`](https://menshikovs.github.io/termr/reference/Widget.html#method-animate)
- [`Widget$arrange_children()`](https://menshikovs.github.io/termr/reference/Widget.html#method-arrange_children)
- [`Widget$bind()`](https://menshikovs.github.io/termr/reference/Widget.html#method-bind)
- [`Widget$bind_reactive()`](https://menshikovs.github.io/termr/reference/Widget.html#method-bind_reactive)
- [`Widget$bindings()`](https://menshikovs.github.io/termr/reference/Widget.html#method-bindings)
- [`Widget$blur()`](https://menshikovs.github.io/termr/reference/Widget.html#method-blur)
- [`Widget$capture_mouse()`](https://menshikovs.github.io/termr/reference/Widget.html#method-capture_mouse)
- [`Widget$child_clip()`](https://menshikovs.github.io/termr/reference/Widget.html#method-child_clip)
- [`Widget$clear()`](https://menshikovs.github.io/termr/reference/Widget.html#method-clear)
- [`Widget$computed_style()`](https://menshikovs.github.io/termr/reference/Widget.html#method-computed_style)
- [`Widget$focus()`](https://menshikovs.github.io/termr/reference/Widget.html#method-focus)
- [`Widget$format()`](https://menshikovs.github.io/termr/reference/Widget.html#method-format)
- [`Widget$get_state()`](https://menshikovs.github.io/termr/reference/Widget.html#method-get_state)
- [`Widget$has_class()`](https://menshikovs.github.io/termr/reference/Widget.html#method-has_class)
- [`Widget$invalidate()`](https://menshikovs.github.io/termr/reference/Widget.html#method-invalidate)
- [`Widget$invalidate_paint()`](https://menshikovs.github.io/termr/reference/Widget.html#method-invalidate_paint)
- [`Widget$is_displayed()`](https://menshikovs.github.io/termr/reference/Widget.html#method-is_displayed)
- [`Widget$is_enabled()`](https://menshikovs.github.io/termr/reference/Widget.html#method-is_enabled)
- [`Widget$layout_descend()`](https://menshikovs.github.io/termr/reference/Widget.html#method-layout_descend)
- [`Widget$layout_differs()`](https://menshikovs.github.io/termr/reference/Widget.html#method-layout_differs)
- [`Widget$matches()`](https://menshikovs.github.io/termr/reference/Widget.html#method-matches)
- [`Widget$mount()`](https://menshikovs.github.io/termr/reference/Widget.html#method-mount)
- [`Widget$on()`](https://menshikovs.github.io/termr/reference/Widget.html#method-on)
- [`Widget$post_message()`](https://menshikovs.github.io/termr/reference/Widget.html#method-post_message)
- [`Widget$print()`](https://menshikovs.github.io/termr/reference/Widget.html#method-print)
- [`Widget$pseudo_states()`](https://menshikovs.github.io/termr/reference/Widget.html#method-pseudo_states)
- [`Widget$query()`](https://menshikovs.github.io/termr/reference/Widget.html#method-query)
- [`Widget$query_one()`](https://menshikovs.github.io/termr/reference/Widget.html#method-query_one)
- [`Widget$release_mouse()`](https://menshikovs.github.io/termr/reference/Widget.html#method-release_mouse)
- [`Widget$remove()`](https://menshikovs.github.io/termr/reference/Widget.html#method-remove)
- [`Widget$remove_children()`](https://menshikovs.github.io/termr/reference/Widget.html#method-remove_children)
- [`Widget$remove_class()`](https://menshikovs.github.io/termr/reference/Widget.html#method-remove_class)
- [`Widget$render()`](https://menshikovs.github.io/termr/reference/Widget.html#method-render)
- [`Widget$render_lines()`](https://menshikovs.github.io/termr/reference/Widget.html#method-render_lines)
- [`Widget$replace()`](https://menshikovs.github.io/termr/reference/Widget.html#method-replace)
- [`Widget$run_action()`](https://menshikovs.github.io/termr/reference/Widget.html#method-run_action)
- [`Widget$run_process()`](https://menshikovs.github.io/termr/reference/Widget.html#method-run_process)
- [`Widget$run_worker()`](https://menshikovs.github.io/termr/reference/Widget.html#method-run_worker)
- [`Widget$set()`](https://menshikovs.github.io/termr/reference/Widget.html#method-set)
- [`Widget$set_interval()`](https://menshikovs.github.io/termr/reference/Widget.html#method-set_interval)
- [`Widget$set_state()`](https://menshikovs.github.io/termr/reference/Widget.html#method-set_state)
- [`Widget$set_timeout()`](https://menshikovs.github.io/termr/reference/Widget.html#method-set_timeout)
- [`Widget$toggle_class()`](https://menshikovs.github.io/termr/reference/Widget.html#method-toggle_class)
- [`Widget$walk()`](https://menshikovs.github.io/termr/reference/Widget.html#method-walk)

------------------------------------------------------------------------

### `DataTable$new()`

Create a table. See
[`data_table()`](https://menshikovs.github.io/termr/reference/data_table.md).

#### Usage

    DataTable$new(
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
      style = NULL,
      disabled = FALSE
    )

#### Arguments

- `data`:

  A data frame, matrix, or
  [`table_source()`](https://menshikovs.github.io/termr/reference/table_source.md).

- `cursor`:

  Cursor type.

- `columns`:

  Named list of
  [`column()`](https://menshikovs.github.io/termr/reference/column.md)
  options.

- `formatters`:

  Named list of formatter functions.

- `row_names`:

  Show row names? `NA`: only when they are not 1..n.

- `header`:

  Show the header?

- `zebra`:

  Stripe rows?

- `row_style, cell_style`:

  Style hooks.

- `max_column_width`:

  Upper limit for estimated widths.

- `frozen_columns, header_sort, editable, on_edit`:

  See the fields.

- `id, classes, style, disabled`:

  See
  [Widget](https://menshikovs.github.io/termr/reference/Widget-class.md).

- `filters`:

  Named column filters for `filter_columns()`.

------------------------------------------------------------------------

### `DataTable$default_style()`

The built-in style.

#### Usage

    DataTable$default_style()

------------------------------------------------------------------------

### `DataTable$default_bindings()`

Navigation keys and Enter.

#### Usage

    DataTable$default_bindings()

------------------------------------------------------------------------

### `DataTable$set_data()`

Replace the data. Resets the view, cursor and scroll.

#### Usage

    DataTable$set_data(data)

#### Arguments

- `data`:

  A data frame, matrix, or
  [`table_source()`](https://menshikovs.github.io/termr/reference/table_source.md).

------------------------------------------------------------------------

### `DataTable$refresh()`

Re-read the source row count and clear cached rows.

#### Usage

    DataTable$refresh()

------------------------------------------------------------------------

### `DataTable$close()`

Explicitly close this table's source resource.

#### Usage

    DataTable$close()

------------------------------------------------------------------------

### `DataTable$source_stats()`

Read structural fetch/cache counters for diagnostics.

#### Usage

    DataTable$source_stats()

------------------------------------------------------------------------

### `DataTable$sort()`

Sort the view by one or more columns (stable; `NA`s last). Sorting
always starts from the unsorted view (after
[`filter()`](https://rdrr.io/r/stats/filter.html)), so
`sort(c("cyl", "mpg"))` sorts by cyl, then mpg.

#### Usage

    DataTable$sort(by, decreasing = FALSE)

#### Arguments

- `by`:

  Column names or numbers.

- `decreasing`:

  Sort in decreasing order? One value, or one per column.

------------------------------------------------------------------------

### `DataTable$clear_sort()`

Remove the sort order (back to the order before sorting).

#### Usage

    DataTable$clear_sort()

------------------------------------------------------------------------

### `DataTable$toggle_sort()`

Header-click behaviour: sort by a column ascending, then descending,
then unsorted.

#### Usage

    DataTable$toggle_sort(column, add = FALSE)

#### Arguments

- `column`:

  Column name or number.

- `add`:

  Add the column to the existing sort (secondary key)?

------------------------------------------------------------------------

### `DataTable$filter()`

Show a subset of rows (in the given order), or all rows.

#### Usage

    DataTable$filter(rows = NULL)

#### Arguments

- `rows`:

  Row numbers of the data, a logical vector over the rows, or `NULL` for
  all rows.

------------------------------------------------------------------------

### `DataTable$filter_columns()`

Filter named columns; all predicates are combined with AND and evaluated
in row chunks. A predicate may be a
[`table_filter()`](https://menshikovs.github.io/termr/reference/table_filter.md)
or `function(values) logical`.

#### Usage

    DataTable$filter_columns(filters = NULL)

#### Arguments

- `filters`:

  Named list by column; `NULL` clears column filters.

------------------------------------------------------------------------

### `DataTable$move_cursor()`

Move the cursor (and scroll so it is visible).

#### Usage

    DataTable$move_cursor(row = NULL, column = NULL)

#### Arguments

- `row`:

  Position in the view.

- `column`:

  Column name or number (cell cursor).

------------------------------------------------------------------------

### `DataTable$scroll_to_row()`

Scroll so that a view position is the first visible row.

#### Usage

    DataTable$scroll_to_row(row)

#### Arguments

- `row`:

  Position in the view.

------------------------------------------------------------------------

### `DataTable$selected_row()`

The data-frame row number or source row key under the cursor (or `NA`).

#### Usage

    DataTable$selected_row()

------------------------------------------------------------------------

### `DataTable$row_data()`

One data row as a named list.

#### Usage

    DataTable$row_data(row)

#### Arguments

- `row`:

  Original row number.

------------------------------------------------------------------------

### `DataTable$selected_data()`

Data for selected view rows, in view order. A single cursor row is
returned when no range is selected.

#### Usage

    DataTable$selected_data()

------------------------------------------------------------------------

### `DataTable$visible_data()`

Data in the current viewport, in display order.

#### Usage

    DataTable$visible_data()

------------------------------------------------------------------------

### `DataTable$reorder_column()`

Move a column in the display order.

#### Usage

    DataTable$reorder_column(column, to)

#### Arguments

- `column`:

  Column name or number.

- `to`:

  New 1-based position in the complete column order.

------------------------------------------------------------------------

### `DataTable$select_range()`

Select a range of rows by view position.

#### Usage

    DataTable$select_range(from, to = from)

#### Arguments

- `from, to`:

  1-based positions in the view.

------------------------------------------------------------------------

### `DataTable$copy_selection()`

Copy selected rows as tab-separated values.

#### Usage

    DataTable$copy_selection(headers = TRUE, system = TRUE)

#### Arguments

- `headers`:

  Include column names?

- `system`:

  Also write to the system clipboard when supported?

------------------------------------------------------------------------

### `DataTable$goto_row()`

Jump to a row of the view (and scroll to it).

#### Usage

    DataTable$goto_row(row)

#### Arguments

- `row`:

  Position in the view (1-based).

------------------------------------------------------------------------

### `DataTable$column_width()`

Width of a column in cells.

#### Usage

    DataTable$column_width(column)

#### Arguments

- `column`:

  Column name or number.

------------------------------------------------------------------------

### `DataTable$set_column_width()`

Set a column's width (at least 1 cell). Sends
`"datatable.column_resized"`.

#### Usage

    DataTable$set_column_width(column, width)

#### Arguments

- `column`:

  Column name or number.

- `width`:

  Width in cells.

------------------------------------------------------------------------

### `DataTable$auto_size_column()`

Fit a column to its content. Rows are sampled, never all scanned unless
asked for, so this is fast for huge tables.

#### Usage

    DataTable$auto_size_column(column, rows = c("sample", "visible", "all"))

#### Arguments

- `column`:

  Column name or number.

- `rows`:

  `"sample"` (the visible rows plus the first and last 500; default),
  `"visible"` (visible rows only) or `"all"` (every row of the view;
  slow for millions of rows).

------------------------------------------------------------------------

### `DataTable$auto_size_all()`

Fit every visible column to its content.

#### Usage

    DataTable$auto_size_all(rows = c("sample", "visible", "all"))

#### Arguments

- `rows`:

  See `auto_size_column()`.

------------------------------------------------------------------------

### `DataTable$set_column_visible()`

Show or hide a column.

#### Usage

    DataTable$set_column_visible(column, visible = TRUE)

#### Arguments

- `column`:

  Column name or number.

- `visible`:

  `TRUE` to show, `FALSE` to hide.

------------------------------------------------------------------------

### `DataTable$column_info()`

Describe the columns: name, label, width, visible, sortable.

#### Usage

    DataTable$column_info()

------------------------------------------------------------------------

### `DataTable$find()`

Search the formatted cell text and move the cursor to the first match at
or after the cursor (reading order, wrapping around). Large tables are
scanned in chunks; the data is never converted to one big string matrix.

#### Usage

    DataTable$find(query, column = NULL, case_sensitive = FALSE, regex = FALSE)

#### Arguments

- `query`:

  Text or regular expression (PCRE).

- `column`:

  Search only this column (name or number); `NULL`: all visible columns.

- `case_sensitive`:

  Match case?

- `regex`:

  Is `query` a regular expression?

#### Returns

`TRUE` if there is a match (invisibly).

------------------------------------------------------------------------

### `DataTable$find_next()`

Go to the next match.

#### Usage

    DataTable$find_next()

------------------------------------------------------------------------

### `DataTable$find_previous()`

Go to the previous match.

#### Usage

    DataTable$find_previous()

------------------------------------------------------------------------

### `DataTable$clear_find()`

Forget the search and close the find bar.

#### Usage

    DataTable$clear_find()

------------------------------------------------------------------------

### `DataTable$edit_cell()`

Edit a cell in a small dialog (needs `editable = TRUE`). The default is
the cursor cell.

#### Usage

    DataTable$edit_cell(position = NULL, column = NULL)

#### Arguments

- `position`:

  Position in the view (default: the cursor row).

- `column`:

  Column name or number (default: the cursor / active column).

------------------------------------------------------------------------

### `DataTable$set_cell()`

Change one cell of the table's own copy of the data (the data frame you
passed in is never modified; read the result with `$data`). Runs
`on_edit`, then sends `"datatable.cell_changed"` with `row`, `column`,
`old` and `value`.

#### Usage

    DataTable$set_cell(row, column, value)

#### Arguments

- `row`:

  Original row number.

- `column`:

  Column name or number.

- `value`:

  New value (must fit the column type).

------------------------------------------------------------------------

### `DataTable$action_cursor_up()`

Actions used by the bindings.

#### Usage

    DataTable$action_cursor_up()

------------------------------------------------------------------------

### `DataTable$action_cursor_down()`

Move down.

#### Usage

    DataTable$action_cursor_down()

------------------------------------------------------------------------

### `DataTable$action_extend_selection_up()`

Extend selection upward.

#### Usage

    DataTable$action_extend_selection_up()

------------------------------------------------------------------------

### `DataTable$action_extend_selection_down()`

Extend selection downward.

#### Usage

    DataTable$action_extend_selection_down()

------------------------------------------------------------------------

### `DataTable$action_move_column_left()`

Move the active column left in display order.

#### Usage

    DataTable$action_move_column_left()

------------------------------------------------------------------------

### `DataTable$action_move_column_right()`

Move the active column right in display order.

#### Usage

    DataTable$action_move_column_right()

------------------------------------------------------------------------

### `DataTable$action_copy_selection()`

Copy selected rows.

#### Usage

    DataTable$action_copy_selection()

------------------------------------------------------------------------

### `DataTable$action_cursor_left()`

Move left (cell cursor) or scroll left.

#### Usage

    DataTable$action_cursor_left()

------------------------------------------------------------------------

### `DataTable$action_cursor_right()`

Move right (cell cursor) or scroll right.

#### Usage

    DataTable$action_cursor_right()

------------------------------------------------------------------------

### `DataTable$action_page_up()`

Move one page up.

#### Usage

    DataTable$action_page_up()

------------------------------------------------------------------------

### `DataTable$action_page_down()`

Move one page down.

#### Usage

    DataTable$action_page_down()

------------------------------------------------------------------------

### `DataTable$action_first_row()`

Go to the first row.

#### Usage

    DataTable$action_first_row()

------------------------------------------------------------------------

### `DataTable$action_last_row()`

Go to the last row.

#### Usage

    DataTable$action_last_row()

------------------------------------------------------------------------

### `DataTable$action_open_find()`

Open the find bar (Ctrl+F).

#### Usage

    DataTable$action_open_find()

------------------------------------------------------------------------

### `DataTable$action_open_goto()`

Open the "go to row" bar (Ctrl+G).

#### Usage

    DataTable$action_open_goto()

------------------------------------------------------------------------

### `DataTable$action_find_next()`

Go to the next match (F3).

#### Usage

    DataTable$action_find_next()

------------------------------------------------------------------------

### `DataTable$action_find_previous()`

Go to the previous match (Shift+F3).

#### Usage

    DataTable$action_find_previous()

------------------------------------------------------------------------

### `DataTable$action_widen_column()`

Make the active column one cell wider (Alt+Right).

#### Usage

    DataTable$action_widen_column()

------------------------------------------------------------------------

### `DataTable$action_narrow_column()`

Make the active column one cell narrower (Alt+Left).

#### Usage

    DataTable$action_narrow_column()

------------------------------------------------------------------------

### `DataTable$action_sort_column()`

Sort by the active column (S): ascending, descending, off.

#### Usage

    DataTable$action_sort_column()

------------------------------------------------------------------------

### `DataTable$action_activate()`

Send `"datatable.row_activated"` for the cursor row (or edit the cell
when the table is editable).

#### Usage

    DataTable$action_activate()

------------------------------------------------------------------------

### `DataTable$on_mouse_down()`

Mouse: clicking a row moves the cursor, clicking the header sends
`"datatable.header_selected"` (and sorts when `header_sort` is on);
dragging a column separator in the header resizes the column; a double
click edits a cell of an editable table.

#### Usage

    DataTable$on_mouse_down(event)

#### Arguments

- `event`:

  A `MouseEvent`.

------------------------------------------------------------------------

### `DataTable$on_drag_move()`

Resizing a column by dragging its header separator.

#### Usage

    DataTable$on_drag_move(event)

#### Arguments

- `event`:

  A `MouseEvent`.

------------------------------------------------------------------------

### `DataTable$on_drag_end()`

Ends a column resize.

#### Usage

    DataTable$on_drag_end(event)

#### Arguments

- `event`:

  A `MouseEvent`.

------------------------------------------------------------------------

### `DataTable$on_key()`

Keys for the find / go-to bar while it is open.

#### Usage

    DataTable$on_key(event)

#### Arguments

- `event`:

  A `KeyEvent`.

------------------------------------------------------------------------

### `DataTable$on_paste()`

Pasted text goes into the find / go-to bar when open.

#### Usage

    DataTable$on_paste(event)

#### Arguments

- `event`:

  A `PasteEvent`.

------------------------------------------------------------------------

### `DataTable$on_mouse_scroll()`

The mouse wheel scrolls three rows.

#### Usage

    DataTable$on_mouse_scroll(event)

#### Arguments

- `event`:

  A `MouseEvent`.

------------------------------------------------------------------------

### `DataTable$content_width()`

Natural width: all columns.

#### Usage

    DataTable$content_width()

------------------------------------------------------------------------

### `DataTable$content_height()`

Natural height: header plus rows (at most 1000).

#### Usage

    DataTable$content_height(width)

#### Arguments

- `width`:

  Content width.

------------------------------------------------------------------------

### `DataTable$paint()`

Draw the visible part of the table.

#### Usage

    DataTable$paint(buffer, area, st)

#### Arguments

- `buffer`:

  A
  [ScreenBuffer](https://menshikovs.github.io/termr/reference/ScreenBuffer.md).

- `area`:

  Visible part of the region.

- `st`:

  Computed style.

------------------------------------------------------------------------

### `DataTable$clone()`

The objects of this class are cloneable with this method.

#### Usage

    DataTable$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
