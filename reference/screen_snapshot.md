# Create a deterministic screen snapshot

The returned base R list is independent of `jsonlite` and has a stable
`schema_version` field. Runs are row-major and represent adjacent cells
with the same foreground, background, and attribute mask.

## Usage

``` r
screen_snapshot(x, width = 80, height = 24)
```

## Arguments

- x:

  A widget,
  [Screen](https://menshikovs.github.io/termr/reference/Screen.md),
  [App](https://menshikovs.github.io/termr/reference/App-class.md), or
  [ScreenBuffer](https://menshikovs.github.io/termr/reference/ScreenBuffer.md).

- width, height:

  Frame size in cells.

## Value

A `termr_screen_snapshot` list.

## Examples

``` r
screen_snapshot(label("Hello"), width = 20, height = 2)
#> $schema_version
#> [1] 1
#> 
#> $width
#> [1] 20
#> 
#> $height
#> [1] 2
#> 
#> $lines
#> [1] "Hello               " "                    "
#> 
#> $runs
#> $runs[[1]]
#> $runs[[1]]$x
#> [1] 1
#> 
#> $runs[[1]]$y
#> [1] 1
#> 
#> $runs[[1]]$width
#> [1] 20
#> 
#> $runs[[1]]$text
#> [1] "Hello               "
#> 
#> $runs[[1]]$fg
#> [1] ""
#> 
#> $runs[[1]]$bg
#> [1] ""
#> 
#> $runs[[1]]$attrs
#> [1] 0
#> 
#> 
#> $runs[[2]]
#> $runs[[2]]$x
#> [1] 1
#> 
#> $runs[[2]]$y
#> [1] 2
#> 
#> $runs[[2]]$width
#> [1] 20
#> 
#> $runs[[2]]$text
#> [1] "                    "
#> 
#> $runs[[2]]$fg
#> [1] ""
#> 
#> $runs[[2]]$bg
#> [1] ""
#> 
#> $runs[[2]]$attrs
#> [1] 0
#> 
#> 
#> 
#> attr(,"class")
#> [1] "termr_screen_snapshot"
```
