# Panel

A container with a border and an optional title in the top border. Its
height follows its content by default.

## Usage

``` r
panel(..., title = NULL, id = NULL, classes = NULL, style = NULL)
```

## Arguments

- ...:

  Child widgets.

- title:

  Title shown in the top border.

- id:

  Optional identifier.

- classes:

  Optional classes.

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md).

## Value

A `Panel` widget. Change the title with `$border_title`.

## Examples

``` r
render_widget(panel(label("CPU 42%"), title = "Metrics"), 20, 3)
#> <ScreenBuffer 20x3>
#> +--------------------+
#> |╭ Metrics ─────────╮|
#> |│ CPU 42%          │|
#> |╰──────────────────╯|
#> +--------------------+
```
