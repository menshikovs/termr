# View one record

`record_view()` accepts a named list/vector or exactly one data-frame
row and presents it through the same renderer as
[`property_grid()`](https://menshikovs.github.io/termr/reference/property_grid.md).
It is a semantic convenience wrapper, not a separate rendering system. A
reactive function may return a new record whenever its signals change.

## Usage

``` r
record_view(
  data,
  format = NULL,
  max_key_width = 20L,
  id = NULL,
  classes = NULL,
  style = NULL,
  disabled = FALSE
)
```

## Arguments

- data:

  One named list, named vector, or one-row data frame. `NULL` displays
  an empty view.

- format:

  Optional `function(name, value)` formatter.

- max_key_width:

  Maximum key column width.

- id:

  Optional identifier.

- classes:

  Optional classes.

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md).

- disabled:

  Disable focus and scrolling interaction?

## Value

A `PropertyGrid` widget.

## Choosing a key/value widget

- [`key_value()`](https://menshikovs.github.io/termr/reference/key_value.md):
  a few known values shown in full, such as a summary panel. Not
  focusable, does not scroll; values are not wrapped.

- [`property_grid()`](https://menshikovs.github.io/termr/reference/property_grid.md):
  an inspector for many or arbitrary named values. Focusable and
  scrollable, wraps long values, formats vectors and lists compactly and
  accepts a `format` function.

- `record_view()`:
  [`property_grid()`](https://menshikovs.github.io/termr/reference/property_grid.md)
  for exactly one record, such as the selected row of a
  [`data_table()`](https://menshikovs.github.io/termr/reference/data_table.md);
  accepts a one-row data frame.

## Examples

``` r
record_view(list(id = 42, name = "Alice", active = TRUE))
#> <PropertyGrid>
#> ├── <Horizontal>
#> │   ├── <Label> "id"
#> │   └── <Label> "42"
#> ├── <Horizontal>
#> │   ├── <Label> "name"
#> │   └── <Label> "Alice"
#> └── <Horizontal>
#>     ├── <Label> "active"
#>     └── <Label> "TRUE"
```
