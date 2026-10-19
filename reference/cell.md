# A single terminal cell

Cells are the unit of the virtual screen. Each cell holds one character
(a wide character such as a CJK ideograph occupies two cells; the second
one is a continuation cell whose `char` is `""`), colours and text
attributes.

## Usage

``` r
cell(
  char = " ",
  fg = NULL,
  bg = NULL,
  bold = FALSE,
  italic = FALSE,
  underline = FALSE,
  reverse = FALSE,
  dim = FALSE,
  strike = FALSE
)
```

## Arguments

- char:

  A single character.

- fg, bg:

  Foreground and background colours. `NULL` means the terminal default.
  See [`style()`](https://menshikovs.github.io/termr/reference/style.md)
  for accepted colour formats.

- bold, italic, underline, reverse, dim, strike:

  Text attributes.

## Value

An object of class `termr_cell`.

## Details

The framebuffer stores cells column-wise in matrices for speed; `cell()`
is the value-level representation used for inspection and tests.

## Examples

``` r
cell("A", fg = "red", bold = TRUE)
#> <cell "A" fg=red bg=default bold>
```
