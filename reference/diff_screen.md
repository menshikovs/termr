# Compare two screen buffers

Computes the minimal set of horizontal runs of cells that must be
rewritten to turn the screen `old` into `new`. Nearby runs on the same
row are merged when rewriting the unchanged cells between them is
cheaper than an extra cursor movement.

## Usage

``` r
diff_screen(old, new, merge_gap = 3L)
```

## Arguments

- old, new:

  [ScreenBuffer](https://menshikovs.github.io/termr/reference/ScreenBuffer.md)
  objects (`old` may be `NULL`).

- merge_gap:

  Runs separated by at most this many unchanged cells are merged.

## Value

A `termr_patch`: a list with `full` (logical), `width`, `height` and
`runs`, a list of runs. Each run has `y`, `x` and vectors `chars`, `fg`,
`bg`, `attrs` copied from `new`.

## Details

If `old` is `NULL` or has different dimensions, the patch covers every
non-blank cell of `new` and is marked `full = TRUE`; the renderer then
clears the screen first.

## Examples

``` r
a <- screen_buffer(10, 2)
b <- a$copy()
b$put_text(3, 2, "hi")
diff_screen(a, b)
#> <patch 10x2: 1 run(s), 2 cell(s)>
```
