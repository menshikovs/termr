# Key/value property inspector

Displays named list/vector entries in two aligned columns. Keys are
sized to their longest name up to `max_key_width`; values wrap and the
view scrolls when needed. `NULL`, `NA`, dates and vectors have compact
default formatting. Lists and other objects are shown as placeholders
instead of being recursively printed. A custom `formatter(name, value)`
can replace the default value formatting. `data` may be a reactive
function of no arguments.

## Usage

``` r
property_grid(
  data = list(),
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

  Named list or vector; data frames are accepted as named columns.
  `NULL` displays an empty grid.

- format:

  Optional `function(name, value)` returning display text.

- max_key_width:

  Maximum key column width in terminal cells.

- id:

  Optional identifier.

- classes:

  Optional classes.

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md).

- disabled:

  Disable focus and scrolling interaction?

## Value

A `PropertyGrid` (a focusable, scrollable widget) with reactive `$data`
and `$set_data()`.

## Choosing a key/value widget

- [`key_value()`](https://menshikovs.github.io/termr/reference/key_value.md):
  a few known values shown in full, such as a summary panel. Not
  focusable, does not scroll; values are not wrapped.

- `property_grid()`: an inspector for many or arbitrary named values.
  Focusable and scrollable, wraps long values, formats vectors and lists
  compactly and accepts a `format` function.

- [`record_view()`](https://menshikovs.github.io/termr/reference/record_view.md):
  `property_grid()` for exactly one record, such as the selected row of
  a
  [`data_table()`](https://menshikovs.github.io/termr/reference/data_table.md);
  accepts a one-row data frame.

## Examples

``` r
property_grid(list(type = "numeric", missing = 12, unique = 345))
#> <PropertyGrid>
#> ├── <Horizontal>
#> │   ├── <Label> "type"
#> │   └── <Label> "numeric"
#> ├── <Horizontal>
#> │   ├── <Label> "missing"
#> │   └── <Label> "12"
#> └── <Horizontal>
#>     ├── <Label> "unique"
#>     └── <Label> "345"
```
