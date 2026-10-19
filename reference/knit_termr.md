# Render a static representation for knitr or Quarto

Render a static representation for knitr or Quarto

## Usage

``` r
knit_termr(x, width = 80, height = 24, format = c("markdown", "html"))
```

## Arguments

- x:

  A widget,
  [Screen](https://menshikovs.github.io/termr/reference/Screen.md),
  [App](https://menshikovs.github.io/termr/reference/App-class.md), or
  [ScreenBuffer](https://menshikovs.github.io/termr/reference/ScreenBuffer.md).

- width, height:

  Frame size in cells.

- format:

  Explicit output format: `markdown` or `html`.

## Value

A
[`knitr::asis_output()`](https://rdrr.io/pkg/knitr/man/asis_output.html)
object.
