# Reactive values, computed values and watchers

A small reactive graph for application state. `signal()` holds a value,
`computed()` derives a value from signals (lazily, cached), and
`watch()` runs code whenever the signals it reads change. Widgets can be
created from functions that read signals - `label(function() ...)` - and
are re-rendered automatically.

## Usage

``` r
signal(value = NULL, name = NULL)

computed(fn, name = NULL)

watch(fn, name = NULL)

dispose(x)

batch(expr)

peek(x)

untracked(expr)

update_signal(x, fn)
```

## Arguments

- value:

  Initial value of a signal.

- name:

  Optional graph label used in diagnostics and cycle paths.

- fn:

  Function applied to the current value.

- x:

  A signal or computed.

- expr:

  An expression.

## Value

`signal()` and `computed()` return functions (classes `termr_signal` /
`termr_computed`); `watch()` returns a handle with a `$dispose()`
method.

## Details

- Read a signal with `x()`, write it with `x(value)`. Writing the same
  value ([`identical()`](https://rdrr.io/r/base/identical.html)) does
  nothing. Collections are replaced as a whole:
  `items(c(items(), "new"))` - changes made *inside* an object are not
  noticed.

- `computed(fn)` re-evaluates only when read after a dependency changed.
  A computed that depends on itself raises an error.

- `watch(fn)` runs `fn` now and again after its dependencies changed, in
  creation order. If it writes signals, the watchers depending on them
  run afterwards; a loop is stopped with an error. Use `dispose()` to
  stop it.

- `batch(expr)` defers watchers until `expr` is done, so several writes
  cause one run. Event handlers of an app run in a batch automatically.

- `peek(x)` reads a signal or computed without creating a dependency;
  `untracked(expr)` does the same for an expression.

- Watchers and bound widgets keep their signals' subscriber lists alive;
  call `dispose()` (or remove the widget) when they are no longer
  needed.

This graph is independent of the widget-level
[`reactive()`](https://menshikovs.github.io/termr/reference/reactive.md)
fields. It is **experimental**.

## Examples

``` r
count <- signal(1)
double <- computed(function() count() * 2)
seen <- c()
w <- watch(function() seen <<- c(seen, double()))
count(2)
batch({ count(3); count(4) })
seen
#> [1] 2 4 8
dispose(w)
```
