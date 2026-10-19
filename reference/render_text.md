# Render a widget tree as plain text

Static renderers use the normal layout and paint pipeline and do not
start an event loop or write to a terminal.

## Usage

``` r
render_text(x, width = 80, height = 24, trim = TRUE)

render_lines(x, width = 80, height = 24, trim = TRUE)
```

## Arguments

- x:

  A widget,
  [Screen](https://menshikovs.github.io/termr/reference/Screen.md),
  [App](https://menshikovs.github.io/termr/reference/App-class.md), or
  [ScreenBuffer](https://menshikovs.github.io/termr/reference/ScreenBuffer.md).

- width, height:

  Frame size in cells.

- trim:

  Remove trailing spaces from each line?

## Value

`render_text()` returns one string separated by newlines;
`render_lines()` returns one string per row.

## Examples

``` r
render_text(panel(label("Finished"), title = "Job"), width = 20, height = 5)
#> [1] "╭ Job ─────────────╮\n│ Finished         │\n╰──────────────────╯\n\n"
```
