# Create an experimental lazy table source

A table source lets
[`data_table()`](https://menshikovs.github.io/termr/reference/data_table.md)
request only the rows it needs. All callbacks are synchronous.
`get_rows()` must return a data frame with the requested columns in the
requested order. Row counts are known.

## Usage

``` r
table_source(
  row_count,
  column_names,
  get_rows,
  sort = NULL,
  filter = NULL,
  search = NULL,
  row_key = NULL,
  set_value = NULL,
  refresh = NULL,
  close = NULL,
  on_error = NULL
)
```

## Arguments

- row_count:

  Function returning the current number of rows, or a non-negative
  scalar count.

- column_names:

  Function returning unique, non-empty names, or a character vector.

- get_rows:

  Function `function(start, count, columns = NULL)`.

- sort, filter, search:

  Optional delegated operations.

- row_key:

  Optional function mapping view positions to row keys.

- set_value:

  Optional function `(row, column, value)` for editing.

- refresh, close:

  Optional functions called by `$refresh()` and `$close()`.

- on_error:

  Optional function returning a page-shaped placeholder when
  `get_rows()` fails. It receives the original condition and requested
  page.

## Value

An experimental `termr_table_source` object.

## Details

Optional `sort` and `filter` callbacks change the source's current view.
They receive the sort keys or the named filter list used by
`DataTable$sort()` and `DataTable$filter_columns()`. Returning `FALSE`
rejects the operation; returning `NULL` or `TRUE` accepts it. A source
should expose only operations it can implement without materializing its
entire data set.

`search` receives a parsed query, column names, `start`, `direction`,
and `include_current`; it returns `NULL` or `list(position, column)`.
`row_key` maps view positions to stable row identities.
`set_value(row, column, value)` receives a current view position.
`refresh` and `close` are optional lifecycle callbacks.
`on_error(error, start, count, columns)` may return a correctly shaped
placeholder data frame when a page read fails; the table then displays
the error instead of aborting a paint. Closing a source is explicit and
never closes resources the source does not own.
