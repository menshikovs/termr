# Sparkline

A tiny line chart made of block characters (`\u2581` to `\u2588`), one
column per value. With more values than columns, the latest values are
shown (`summary = "tail"`) or buckets are averaged (`"mean"`). Missing
values are blank. Use `push()` to stream values.

## Usage

``` r
sparkline(
  data = numeric(),
  min = NULL,
  max = NULL,
  summary = "tail",
  max_length = 1000L,
  id = NULL,
  classes = NULL,
  style = NULL
)
```

## Arguments

- data:

  Numeric vector.

- min, max:

  Fixed scale; `NULL` uses the range of the data.

- summary:

  `"tail"` or `"mean"`.

- max_length:

  Number of values kept by `push()`.

- id:

  Optional identifier.

- classes:

  Optional classes.

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md);
  the foreground colour colours the bars.

## Value

A `Sparkline` with reactive `data` and method `push()`.

## Examples

``` r
render_widget(sparkline(c(1, 4, 2, 8, 5, NA, 7)), 7, 1)
#> <ScreenBuffer 7x1>
#> +-------+
#> |▁▄▂█▅ ▇|
#> +-------+
```
