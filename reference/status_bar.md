# One-line status bar

Displays left, centered and right status text in one terminal row. On a
narrow screen it preserves the left region first, then the right region,
and truncates the center region first. Truncation respects terminal cell
widths and grapheme boundaries. Each value may be a no-argument reactive
function that reads
[`signal()`](https://menshikovs.github.io/termr/reference/signals.md)s.

## Usage

``` r
status_bar(
  left = "",
  center = "",
  right = "",
  id = NULL,
  classes = NULL,
  style = NULL,
  disabled = FALSE
)
```

## Arguments

- left, center, right:

  Text for the three regions.

- id:

  Optional identifier.

- classes:

  Optional classes.

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md).

- disabled:

  Disable the widget?

## Value

A `StatusBar` widget with reactive `left`, `center`, and `right` fields.

## Examples

``` r
status_bar("SQLite :memory:", "127 rows", "8 ms")
#> <StatusBar>
```
