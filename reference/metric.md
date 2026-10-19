# Metric

A key number with a label and an optional change (delta) shown as a
green up or red down arrow. Useful in dashboards.

## Usage

``` r
metric(
  label,
  value = NA,
  delta = NULL,
  format = NULL,
  id = NULL,
  classes = NULL,
  style = NULL
)
```

## Arguments

- label:

  Label shown above the value.

- value:

  The value (any R value; numbers are formatted with thousands
  separators).

- delta:

  Optional change since the last value.

- format:

  Optional `function(value)` returning a string (also used for the
  delta).

- id:

  Optional identifier.

- classes:

  Optional classes.

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md).

## Value

A `Metric` widget with reactive `value` and `delta`, and method
`update(value, delta)`.

## Examples

``` r
render_widget(metric("Accuracy", 0.943, delta = 0.012), 20, 4)
#> <ScreenBuffer 20x4>
#> +--------------------+
#> |╭──────────────────╮|
#> |│ Accuracy         │|
#> |│ 0.943  ▲ 0.012   │|
#> |╰──────────────────╯|
#> +--------------------+
```
