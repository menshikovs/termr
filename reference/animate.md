# Animate a widget field

Changes a numeric field of a widget (e.g. `value` of a
[`progress_bar()`](https://menshikovs.github.io/termr/reference/progress_bar.md),
`offset_y` of a
[`scroll_view()`](https://menshikovs.github.io/termr/reference/scroll_view.md),
`count` of a custom widget) smoothly from its current value to `to`.
Starting a new animation of the same field replaces the running one.
Animations stop when the widget is removed or the app exits.

## Usage

``` r
animate(
  widget,
  property,
  to,
  duration = 0.3,
  easing = "out_cubic",
  from = NULL,
  on_complete = NULL
)
```

## Arguments

- widget:

  A widget attached to a running app.

- property:

  Name of a numeric field.

- to:

  Target value.

- duration:

  Seconds.

- easing:

  `"linear"`, `"in_quad"`, `"out_quad"`, `"in_out_quad"`, `"in_cubic"`,
  `"out_cubic"` (default) or `"in_out_cubic"`.

- from:

  Start value (default: the current value).

- on_complete:

  Optional `function(widget, app)`.

## Value

An `Animation` handle with `cancel()`.

## Examples

``` r
bar <- progress_bar(id = "progress")
pilot <- test_app(app(bar), width = 30, height = 1)
animate(pilot$query_one("#progress"), "value", to = 1, duration = 0.5)
pilot$advance(1)
bar$value
#> [1] 1
pilot$stop()
```
