# Convert a screen patch to ANSI escape sequences

Each run becomes a cursor movement followed by the run's characters. An
SGR (style) sequence is emitted only when the style differs from the
previous cell. The output always ends with a style reset.

## Usage

``` r
patch_to_ansi(patch, color_mode = "truecolor")
```

## Arguments

- patch:

  A patch from
  [`diff_screen()`](https://menshikovs.github.io/termr/reference/diff_screen.md).

- color_mode:

  One of `"truecolor"`, `"256"`, `"16"` or `"none"`.

## Value

A single string.

## Examples

``` r
a <- screen_buffer(10, 1)
b <- a$copy()
b$put_text(1, 1, "hi", fg = "red")
patch_to_ansi(diff_screen(a, b))
#> [1] "\033[1;1H\033[0;31mhi\033[0m"
```
