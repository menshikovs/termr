# Render widgets to a virtual screen

Lays out and paints a widget tree into a
[ScreenBuffer](https://menshikovs.github.io/termr/reference/ScreenBuffer.md)
without a terminal. Useful for snapshot tests and for checking layouts
interactively.

## Usage

``` r
render_widget(x, width = 80L, height = 24L)
```

## Arguments

- x:

  A widget, a
  [Screen](https://menshikovs.github.io/termr/reference/Screen.md) or an
  [App](https://menshikovs.github.io/termr/reference/App-class.md).

- width, height:

  Screen size in cells.

## Value

A
[ScreenBuffer](https://menshikovs.github.io/termr/reference/ScreenBuffer.md);
use `$to_text()` for plain text.

## Examples

``` r
buf <- render_widget(vertical(label("a"), label("b")), 10, 2)
buf$to_text()
#> [1] "a         " "b         "
```
