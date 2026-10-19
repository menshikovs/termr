# Styled text

`span()` creates a piece of text with its own style. Spans can be
combined with [`c()`](https://rdrr.io/r/base/c.html) and returned from a
widget's `render` function or passed to
[`label()`](https://menshikovs.github.io/termr/reference/label.md).
Newlines start new lines.

## Usage

``` r
span(x = "", style = NULL, link = NULL)

# S3 method for class 'termr_text'
c(...)
```

## Arguments

- x:

  Text. A character vector is joined with newlines. May also be spans,
  to nest styles.

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md);
  only colours and text attributes are used.

- link:

  Optional link target (a URL or any string). Stored as metadata on the
  text for widgets that support it; not rendered yet.

- ...:

  Spans or character strings to combine.

## Value

An object of class `termr_text`.

## Details

Spans nest: `span(c(span("a"), span("b", s1)), s2)` applies `s2` to both
pieces, with the inner style taking precedence.

## Examples

``` r
c(span("Status: "), span("OK", style(foreground = "green", bold = TRUE)))
#> <span "Status: OK">
span(c(span("bold "), span("and red", style(foreground = "red"))), style(bold = TRUE))
#> <span "bold and red">
```
