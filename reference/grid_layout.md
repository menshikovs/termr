# Grid container

Places children in a grid, row by row. Column (and optionally row)
tracks are sized like widgets: a number of cells, `"auto"` (natural size
of the content), `"<n>fr"` (share of the remaining space) or `"<n>%"`.
Rows not listed are `"auto"`. A child can cover several cells with
`style(column_span = 2, row_span = 2)`.

## Usage

``` r
grid_layout(
  ...,
  columns = 2L,
  rows = NULL,
  gap = 0L,
  id = NULL,
  classes = NULL,
  style = NULL
)
```

## Arguments

- ...:

  Child widgets.

- columns:

  A number of equal columns, or a vector of column sizes.

- rows:

  Optional vector of row sizes.

- gap:

  Space between cells: one value, or `c(rows, columns)`.

- id:

  Optional identifier.

- classes:

  Optional classes.

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md).

## Value

A `Grid` widget.

## Details

Named `grid_layout()` because
[`grid()`](https://rdrr.io/r/graphics/grid.html) would mask
[`graphics::grid()`](https://rdrr.io/r/graphics/grid.html).

## Examples

``` r
ui <- grid_layout(
  label("a"), label("b"), label("c"),
  label("wide", style = style(column_span = 2)),
  columns = c("1fr", "2fr"), gap = 1
)
render_widget(ui, 20, 5)
#> <ScreenBuffer 20x5>
#> +--------------------+
#> |a      b            |
#> |                    |
#> |c                   |
#> |                    |
#> |wide                |
#> +--------------------+
```
