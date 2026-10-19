# Inspect one node in the experimental signal graph

Return dependency and subscriber names, lifecycle state, and cumulative
counters for a signal, computed value, or watcher.

## Usage

``` r
inspect_signal(x)
```

## Arguments

- x:

  A
  [`signal()`](https://menshikovs.github.io/termr/reference/signals.md),
  [`computed()`](https://menshikovs.github.io/termr/reference/signals.md),
  or
  [`watch()`](https://menshikovs.github.io/termr/reference/signals.md)
  result.

## Value

A list describing the node and its direct graph edges.
