# Render a styled HTML fragment

Render a styled HTML fragment

## Usage

``` r
render_html(x, width = 80, height = 24, color = TRUE, trim = TRUE)
```

## Arguments

- x:

  A widget,
  [Screen](https://menshikovs.github.io/termr/reference/Screen.md),
  [App](https://menshikovs.github.io/termr/reference/App-class.md), or
  [ScreenBuffer](https://menshikovs.github.io/termr/reference/ScreenBuffer.md).

- width, height:

  Frame size in cells.

- color:

  Include framebuffer colours even when `NO_COLOR` is set?

- trim:

  Remove trailing spaces from each line?

## Value

An embeddable `<pre>` fragment. Styling is approximate and depends on
the browser's monospace font and CSS environment.

## Examples

``` r
cat(render_html(label("Ready", style = style(foreground = "green", bold = TRUE))))
#> <pre class="termr-screen" style="font-family:monospace;white-space:pre;"><span style="color:#00cd00;font-weight:bold">Ready</span>
#> 
#> 
#> 
#> 
#> 
#> 
#> 
#> 
#> 
#> 
#> 
#> 
#> 
#> 
#> 
#> 
#> 
#> 
#> 
#> 
#> 
#> 
#> </pre>
```
