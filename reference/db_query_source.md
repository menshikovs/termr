# Create a lazy DBI query source

The source implements
[`table_source()`](https://menshikovs.github.io/termr/reference/table_source.md)
and fetches bounded pages for a query result. The built-in pager
supports RSQLite only. Other DBI drivers can provide an `adapter` list
with `column_names(connection, query, params)`,
`row_count(connection, query, params)`, and
`get_rows(connection, query, params, start, count, columns)` callbacks.
This keeps dialect-specific pagination in the backend adapter rather
than assuming all DBI drivers use the same SQL.

## Usage

``` r
db_query_source(connection, query, params = NULL, adapter = NULL)
```

## Arguments

- connection:

  A
  [`db_connection()`](https://menshikovs.github.io/termr/reference/db_connection.md)
  wrapper or open DBI connection. It remains owned by its caller;
  closing this source never disconnects it.

- query:

  A single query that returns a result set.

- params:

  Optional DBI parameter list passed to the query.

- adapter:

  Optional backend adapter callbacks. `NULL` selects the built-in
  RSQLite pager when `connection` is an RSQLite connection.

## Value

An experimental
[`table_source()`](https://menshikovs.github.io/termr/reference/table_source.md)
accepted directly by
[`data_table()`](https://menshikovs.github.io/termr/reference/data_table.md).

## Details

The built-in SQLite adapter wraps the query as a subquery, runs one
cached `COUNT(*)`, and adds bound `LIMIT`/`OFFSET` values to page
requests. A single trailing semicolon is removed before wrapping. The
query must produce one result set; arbitrary SQL statements are not
parsed or rewritten. The row count can be expensive, but it is computed
once at source creation and on explicit refresh, never on repaint.

The returned source is read-only. Sorting, filtering, and search are not
pushed into the user query.
