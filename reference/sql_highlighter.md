# SQL syntax highlighter

A tolerant, line-oriented tokenizer for SQL text areas. `dialect` is
reserved for small dialect-specific extensions; token classes are
shared.

## Usage

``` r
sql_highlighter(
  dialect = c("generic", "postgres", "sqlite", "mysql", "sqlserver")
)
```

## Arguments

- dialect:

  SQL dialect: `generic`, `postgres`, `sqlite`, `mysql`, or `sqlserver`.

## Value

A highlighter function for
[`text_area()`](https://menshikovs.github.io/termr/reference/text_area.md).
