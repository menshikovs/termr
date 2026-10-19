# Spinner

A small animation showing that work is in progress. It runs on a timer
of the widget, so it stops automatically when the widget is removed.

## Usage

``` r
spinner(
  label = "",
  type = "dots",
  interval = 0.1,
  id = NULL,
  classes = NULL,
  style = NULL
)
```

## Arguments

- label:

  Text shown after the spinner.

- type:

  `"dots"`, `"line"` or `"arc"` (ASCII `"line"` is used when the
  terminal cannot show Unicode).

- interval:

  Seconds per frame.

- id:

  Optional identifier.

- classes:

  Optional classes.

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md).

## Value

A `Spinner` with reactive `label` and `spinning`.

## Examples

``` r
spinner("Loading data...")
#> <Spinner>
```
