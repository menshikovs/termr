# Create a lazy source for a SQLite table

This optional adapter uses bounded `LIMIT`/`OFFSET` queries and
parameterized filter values. It supports `equals`, `contains`, `range`,
and `missing`
[`table_filter()`](https://menshikovs.github.io/termr/reference/table_filter.md)
filters and sorting by quoted column names. Arbitrary queries and other
SQL dialects are intentionally outside this adapter; custom
[`table_source()`](https://menshikovs.github.io/termr/reference/table_source.md)
callbacks can implement driver-specific pagination.

## Usage

``` r
db_table_source(connection, table, owned = FALSE)
```

## Arguments

- connection:

  An open RSQLite connection, or a
  [`db_connection()`](https://menshikovs.github.io/termr/reference/db_connection.md)
  wrapper of one.

- table:

  A table name or [`DBI::Id`](https://dbi.r-dbi.org/reference/Id.html).

- owned:

  If `TRUE`, `source$close()` disconnects this connection. The default
  leaves connection ownership with the caller.

## Value

An experimental table source accepted by
[`data_table()`](https://menshikovs.github.io/termr/reference/data_table.md).
