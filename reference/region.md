# Screen regions

A region (rectangle) describes a region of the terminal in cells.
Coordinates are 1-based, like R indices and ANSI cursor positions: `x`
is the column and `y` is the row of the top-left cell.

## Usage

``` r
region(x = 1L, y = 1L, width = 0L, height = 0L)
```

## Arguments

- x, y:

  Column and row of the top-left cell.

- width, height:

  Size in cells. Negative sizes are clamped to zero.

## Value

An object of class `termr_rect`.

## Details

Rectangles are plain values (lists with class `termr_rect`), so they can
be compared with [`identical()`](https://rdrr.io/r/base/identical.html)
and are cheap to create during layout.

## Examples

``` r
r <- region(1, 1, 40, 5)
r
#> <rect x=1 y=1 width=40 height=5>
```
