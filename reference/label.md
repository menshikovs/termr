# Text label

Text label

## Usage

``` r
label(text = "", id = NULL, classes = NULL, style = NULL, wrap = NULL)
```

## Arguments

- text:

  A string, a character vector (one element per line), a number, or
  [`span()`](https://menshikovs.github.io/termr/reference/span.md)s for
  styled text. A function of no arguments is re-evaluated whenever the
  [`signal()`](https://menshikovs.github.io/termr/reference/signals.md)s
  it reads change.

- id:

  Optional identifier (for `#id` selectors).

- classes:

  Optional classes (for `.class` selectors).

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md).

- wrap:

  Shortcut for `style(wrap = )`: `"none"`, `"word"` or `"char"`.

## Value

A `Label` widget. Change its text with `$update()` or by assigning
`$text`.

## Examples

``` r
lbl <- label("Hello", style = style(bold = TRUE))
lbl$update("Goodbye")
render_widget(lbl, 10, 1)
#> <ScreenBuffer 10x1>
#> +----------+
#> |Goodbye   |
#> +----------+
```
