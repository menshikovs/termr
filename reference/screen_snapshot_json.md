# Serialize a screen snapshot as JSON

The JSON form of
[`screen_snapshot()`](https://menshikovs.github.io/termr/reference/screen_snapshot.md).
Requires the optional `jsonlite` package.

## Usage

``` r
screen_snapshot_json(x, width = 80, height = 24, pretty = TRUE)
```

## Arguments

- x:

  A widget,
  [Screen](https://menshikovs.github.io/termr/reference/Screen.md),
  [App](https://menshikovs.github.io/termr/reference/App-class.md), or
  [ScreenBuffer](https://menshikovs.github.io/termr/reference/ScreenBuffer.md).

- width, height:

  Frame size in cells.

- pretty:

  Format the JSON for readability?

## Value

A JSON string.
