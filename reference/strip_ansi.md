# Remove ANSI escape sequences from a string

Remove ANSI escape sequences from a string

## Usage

``` r
strip_ansi(x)
```

## Arguments

- x:

  A character vector.

## Value

`x` without CSI/OSC escape sequences.

## Examples

``` r
strip_ansi("\033[1mbold\033[0m")
#> [1] "bold"
```
