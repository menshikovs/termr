# Layout containers

`vertical()` stacks its children top to bottom; `horizontal()` places
them side by side. By default a vertical container fills the available
space, and a horizontal container is as tall as its tallest child.

## Usage

``` r
vertical(..., id = NULL, classes = NULL, style = NULL)

horizontal(..., id = NULL, classes = NULL, style = NULL)
```

## Arguments

- ...:

  Child widgets.

- id:

  Optional identifier (for `#id` selectors).

- classes:

  Optional classes (for `.class` selectors).

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md).

## Value

A `Vertical` or `Horizontal` widget.

## Details

Children sized `"auto"` take their natural size, fixed sizes are exact,
and `"1fr"`, `"2fr"`, ... share the remaining space. Use
`style(align =, valign =)` on the container to position children that do
not fill it.

## Examples

``` r
ui <- vertical(
  label("Title"),
  horizontal(label("left"), label("right"))
)
render_widget(ui, 20, 3)
#> <ScreenBuffer 20x3>
#> +--------------------+
#> |Title               |
#> |leftright           |
#> |                    |
#> +--------------------+
```
