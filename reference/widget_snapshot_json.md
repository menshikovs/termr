# Serialize a structural widget snapshot as JSON

The JSON form of
[`widget_snapshot()`](https://menshikovs.github.io/termr/reference/widget_snapshot.md).
Requires the optional `jsonlite` package.

## Usage

``` r
widget_snapshot_json(x, pretty = TRUE)
```

## Arguments

- x:

  A widget,
  [Screen](https://menshikovs.github.io/termr/reference/Screen.md), or
  [App](https://menshikovs.github.io/termr/reference/App-class.md).

- pretty:

  Format JSON for readability?

## Value

A JSON string.
