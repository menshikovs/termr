# Lightweight R syntax highlighter

Returns a viewport-first tokenizer for
[`text_area()`](https://menshikovs.github.io/termr/reference/text_area.md).
It highlights common R keywords, strings, comments, numeric constants,
operators, and function names. It uses tolerant regular expressions and
accepts incomplete syntax. Each line produces grapheme-indexed spans
with `start`, `end`, and `token`.

## Usage

``` r
r_highlighter()
```

## Value

A function `(lines, state = NULL)` suitable for
[`text_area()`](https://menshikovs.github.io/termr/reference/text_area.md).
