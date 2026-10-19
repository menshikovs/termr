# Render a static frame as SVG

Render a static frame as SVG

## Usage

``` r
render_svg(
  x,
  width = 80,
  height = 24,
  cell_width = 9,
  line_height = 18,
  font_family = "monospace",
  color = TRUE
)
```

## Arguments

- x:

  A widget,
  [Screen](https://menshikovs.github.io/termr/reference/Screen.md),
  [App](https://menshikovs.github.io/termr/reference/App-class.md), or
  [ScreenBuffer](https://menshikovs.github.io/termr/reference/ScreenBuffer.md).

- width, height:

  Frame size in cells.

- cell_width:

  Width of a terminal cell in SVG user units.

- line_height:

  Height of a row in SVG user units.

- font_family:

  CSS font family.

- color:

  Include framebuffer colours?

## Value

An SVG document string.
