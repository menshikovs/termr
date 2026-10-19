# SQL editor widget

A thin
[`text_area()`](https://menshikovs.github.io/termr/reference/text_area.md)
subclass with SQL highlighting. When `connection` is supplied,
`execute_key` runs the selected SQL, or the full buffer if nothing is
selected. Queries run synchronously in the current R process.

## Usage

``` r
sql_editor(
  value = "",
  id = NULL,
  connection = NULL,
  execute_key = "ctrl+enter",
  execution = c("query", "execute"),
  line_numbers = TRUE,
  tab_size = 2L,
  ...,
  result_mode = c("data", "lazy"),
  query_adapter = NULL
)
```

## Arguments

- value:

  Initial SQL text.

- id:

  Optional widget id.

- connection:

  A
  [`db_connection()`](https://menshikovs.github.io/termr/reference/db_connection.md)
  wrapper or raw DBI connection.

- execute_key:

  Key binding used to execute SQL.

- execution:

  Either `"query"`
  ([`DBI::dbGetQuery`](https://dbi.r-dbi.org/reference/dbGetQuery.html))
  or `"execute"`
  ([`DBI::dbExecute`](https://dbi.r-dbi.org/reference/dbExecute.html)).

- line_numbers:

  Show line numbers? Defaults to `TRUE`.

- tab_size:

  Spaces inserted by Tab.

- ...:

  Additional arguments passed to
  [TextArea](https://menshikovs.github.io/termr/reference/TextArea-class.md).

- result_mode:

  Query result mode: "data" materializes the result (the default);
  "lazy" returns a
  [`db_query_source()`](https://menshikovs.github.io/termr/reference/db_query_source.md)
  for a paged table. Lazy mode is available only with execution =
  "query".

- query_adapter:

  Optional backend pager callbacks passed to
  [`db_query_source()`](https://menshikovs.github.io/termr/reference/db_query_source.md).

## Value

A `TextArea` subclass with an `execute()` method.
