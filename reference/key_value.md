# Key/value list

Shows names and values in two aligned columns, e.g. a summary of a data
set.

## Usage

``` r
key_value(data = list(), id = NULL, classes = NULL, style = NULL)
```

## Arguments

- data:

  A named list or vector.

- id:

  Optional identifier.

- classes:

  Optional classes.

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md).

## Value

A `KeyValue` widget with a reactive `data` field.

## Choosing a key/value widget

- `key_value()`: a few known values shown in full, such as a summary
  panel. Not focusable, does not scroll; values are not wrapped.

- [`property_grid()`](https://menshikovs.github.io/termr/reference/property_grid.md):
  an inspector for many or arbitrary named values. Focusable and
  scrollable, wraps long values, formats vectors and lists compactly and
  accepts a `format` function.

- [`record_view()`](https://menshikovs.github.io/termr/reference/record_view.md):
  [`property_grid()`](https://menshikovs.github.io/termr/reference/property_grid.md)
  for exactly one record, such as the selected row of a
  [`data_table()`](https://menshikovs.github.io/termr/reference/data_table.md);
  accepts a one-row data frame.

## Examples

``` r
render_widget(key_value(list(Rows = 32, Columns = 11, Source = "mtcars")), 20, 3)
#> <ScreenBuffer 20x3>
#> +--------------------+
#> |Rows     32         |
#> |Columns  11         |
#> |Source   mtcars     |
#> +--------------------+
```
