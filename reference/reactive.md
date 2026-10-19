# Reactive state fields

`reactive()` declares a state field of a custom widget (see
[`widget()`](https://menshikovs.github.io/termr/reference/widget.md)).
Reading the field returns its value; assigning a different value
(`self$count <- self$count + 1L`) invalidates the widget and schedules a
repaint. Repaints are batched: any number of assignments in one
event-loop tick produce a single render and a single screen diff.

## Usage

``` r
reactive(value = NULL, watch = NULL)
```

## Arguments

- value:

  Initial value.

- watch:

  Optional `function(self, value, old)` called after the value changed,
  e.g. to post a message or update other widgets.

## Value

An object of class `termr_reactive`.

## Examples

``` r
reactive(0L)
#> <reactive 0>
reactive("", watch = function(self, value, old) message("now ", value))
#> <reactive "" (watched)>
```
