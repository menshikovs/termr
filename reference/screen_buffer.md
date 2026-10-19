# Create a virtual screen buffer

Create a virtual screen buffer

## Usage

``` r
screen_buffer(width, height)
```

## Arguments

- width, height:

  Size in cells.

## Value

A
[ScreenBuffer](https://menshikovs.github.io/termr/reference/ScreenBuffer.md).

## Examples

``` r
buf <- screen_buffer(10, 2)
buf$put_text(2, 1, "hello", fg = "red")
buf$to_text()
#> [1] " hello    " "          "
```
