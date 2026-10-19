# Reduced motion

Decorative animation
([`animate()`](https://menshikovs.github.io/termr/reference/animate.md)
transitions, indeterminate progress shimmer, spinners) is turned off
when motion is reduced:
[`animate()`](https://menshikovs.github.io/termr/reference/animate.md)
jumps to the final value at once, spinners show a still symbol. Timers,
events and real progress updates are unaffected. Motion is reduced when
`app(reduce_motion = TRUE)`, `options(termr.reduce_motion = TRUE)` or
the environment variable `TERMR_REDUCE_MOTION=1` is set (in that order
of precedence).

## Usage

``` r
motion_reduced(app = NULL)
```

## Arguments

- app:

  An app, or `NULL` to look at the options only.

## Value

`TRUE` or `FALSE`.

## Examples

``` r
motion_reduced()
#> [1] FALSE
```
