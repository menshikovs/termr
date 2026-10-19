# Snapshot the safe, structural parts of a widget tree

Arbitrary widget state and field values are intentionally omitted, so
passwords, database credentials, and worker data are not serialized.

## Usage

``` r
widget_snapshot(x)
```

## Arguments

- x:

  A widget,
  [Screen](https://menshikovs.github.io/termr/reference/Screen.md), or
  [App](https://menshikovs.github.io/termr/reference/App-class.md).

## Value

A deterministic nested list of widget descriptions.
