# Create a DBI metadata interface

The returned functions use DBI's portable table and field listing.
SQLite additionally exposes views from its catalog. Driver packages can
use this small callback protocol when building their own metadata views;
the explorer does not yet have an adapter registry.

## Usage

``` r
db_metadata(connection)
```

## Arguments

- connection:

  A
  [`db_connection()`](https://menshikovs.github.io/termr/reference/db_connection.md)
  wrapper or open DBI connection.

## Value

A list with `schemas()`, `tables(schema)`, `views(schema)`,
`columns(table, schema)`, and `quote(identifier)` functions.
