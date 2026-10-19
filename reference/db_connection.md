# Wrap a DBI connection for use by termr SQL widgets

Wrap a DBI connection for use by termr SQL widgets

## Usage

``` r
db_connection(con, name = NULL, owned = FALSE)
```

## Arguments

- con:

  A DBI connection.

- name:

  Optional connection label.

- owned:

  Disconnect this connection when `disconnect()` is called? Defaults to
  `FALSE` for externally managed connections.

## Value

A lightweight connection wrapper with `query()`, `execute()`,
`is_valid()`, and `disconnect()` methods.
