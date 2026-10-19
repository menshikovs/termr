# Database explorer widget

Composes a lazy object tree, SQLite table preview, SQL editor and result
table, details and in-memory query history. The object tree loads
metadata only when its Tables or Views node is expanded. DBI/RSQLite
remain optional dependencies.

## Usage

``` r
db_explorer(connection, id = NULL)
```

## Arguments

- connection:

  A
  [`db_connection()`](https://menshikovs.github.io/termr/reference/db_connection.md)
  wrapper or open DBI connection. Raw connections are treated as
  externally owned.

- id:

  Optional widget identifier.

## Value

A `DatabaseExplorer` widget with `$refresh()`, `$run_query()`,
`$open_table()`, and `$query_history()` methods.

## Examples

``` r
if (requireNamespace("DBI", quietly = TRUE) && requireNamespace("RSQLite", quietly = TRUE)) {
  con <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
  DBI::dbWriteTable(con, "mtcars", mtcars)
  pilot <- test_app(app(db_explorer(db_connection(con, owned = TRUE))))
  pilot$stop() # App teardown closes its owned connection.
}
```
