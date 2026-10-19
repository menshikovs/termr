# Render a terminal frame as a Markdown code block

Render a terminal frame as a Markdown code block

## Usage

``` r
render_markdown(x, width = 80, height = 24, trim = TRUE)
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

A fenced Markdown text block.

## Examples

``` r
cat(render_markdown(label("Hello"), width = 20, height = 2))
#> ```text
#> Hello
#> 
#> ```
```
