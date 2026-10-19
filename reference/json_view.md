# Collapsible viewer for R list-like data

Displays already-parsed R objects as a
[`tree_view()`](https://menshikovs.github.io/termr/reference/tree_view.md).
Named lists and data frames are objects; unnamed lists and vectors are
arrays. Children are created when a node is expanded. At most
`page_size` children are created per page; a `Load next ...` node
exposes the next page. Character scalars are quoted, logical values use
lowercase JSON spelling, `NULL` is shown as `null`, and R `NA` is shown
as `NA` to keep it distinct from JSON `null`. Set `parse = TRUE` for
JSON text when optional package `jsonlite` is installed; this is a
convenience over the primary R-object interface.

## Usage

``` r
json_view(
  x,
  parse = FALSE,
  page_size = 100L,
  id = NULL,
  classes = NULL,
  style = NULL,
  disabled = FALSE
)
```

## Arguments

- x:

  An R object, or one JSON string when `parse = TRUE`.

- parse:

  Parse a JSON character string with optional `jsonlite`?

- page_size:

  Maximum children created when a tree node is expanded.

- id:

  Optional identifier.

- classes:

  Optional classes.

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md).

- disabled:

  Disable focus and tree interaction?

## Value

A `TreeView` with lazily loaded object/array children.

## Examples

``` r
json_view(list(user = list(id = 42, name = "Alice"), active = TRUE))
#> <TreeView>
```
