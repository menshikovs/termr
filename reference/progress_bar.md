# Progress bar

A bar filling as `value` goes from 0 to `total`, with a percentage. Set
`value = NA` for an indeterminate (animated) bar.

## Usage

``` r
progress_bar(
  value = 0,
  total = 1,
  show_percent = TRUE,
  id = NULL,
  classes = NULL,
  style = NULL
)
```

## Arguments

- value:

  Current progress, or `NA`.

- total:

  Value that means complete.

- show_percent:

  Show the percentage?

- id:

  Optional identifier.

- classes:

  Optional classes.

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md).

## Value

A `ProgressBar` with a reactive `value` and method `advance()`.

## Examples

``` r
render_widget(progress_bar(0.42), 20, 1)
#> <ScreenBuffer 20x1>
#> +--------------------+
#> |━━━━━━━━━━━━━━━  42%|
#> +--------------------+
```
