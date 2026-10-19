# Rule (separator)

A horizontal or vertical line, optionally with a title.

## Usage

``` r
rule(
  orientation = "horizontal",
  title = NULL,
  id = NULL,
  classes = NULL,
  style = NULL
)
```

## Arguments

- orientation:

  `"horizontal"` or `"vertical"`.

- title:

  Optional title for horizontal rules.

- id:

  Optional identifier.

- classes:

  Optional classes.

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md).

## Value

A `Rule` widget.

## Examples

``` r
render_widget(rule(title = "Results"), 20, 1)
#> <ScreenBuffer 20x1>
#> +--------------------+
#> |───── Results ──────|
#> +--------------------+
```
