# Write a static rendering to a UTF-8 file

Write a static rendering to a UTF-8 file

## Usage

``` r
write_rendered(
  x,
  file,
  format = c("text", "markdown", "html", "svg", "json"),
  width = 80,
  height = 24
)
```

## Arguments

- x:

  A widget,
  [Screen](https://menshikovs.github.io/termr/reference/Screen.md),
  [App](https://menshikovs.github.io/termr/reference/App-class.md), or
  [ScreenBuffer](https://menshikovs.github.io/termr/reference/ScreenBuffer.md).

- file:

  Output path.

- format:

  One of `text`, `markdown`, `html`, `svg`, or `json`.

- width, height:

  Frame size in cells.
