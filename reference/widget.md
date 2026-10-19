# Define a custom widget type

`widget()` creates a new widget type and returns its constructor. All
behaviour is given as plain functions that receive the widget as their
first argument, `self`.

## Usage

``` r
widget(
  name,
  state = list(),
  render = NULL,
  compose = NULL,
  bindings = list(),
  actions = list(),
  on = list(),
  methods = list(),
  style = NULL,
  focusable = FALSE,
  inherit = Widget
)
```

## Arguments

- name:

  Type name (used by type selectors, e.g. `app$query("Counter")`).

- state:

  A named list of state fields. Values created with
  [`reactive()`](https://menshikovs.github.io/termr/reference/reactive.md)
  can have a watcher; plain values are reactive too. Fields are read and
  assigned as `self$<name>`.

- render:

  `function(self)` returning the content: a string, a character vector
  of lines or
  [`span()`](https://menshikovs.github.io/termr/reference/span.md)s.

- compose:

  `function(self)` returning a list of child widgets.

- bindings:

  A list of
  [`bind()`](https://menshikovs.github.io/termr/reference/bind.md) key
  bindings.

- actions:

  A named list of `function(self)`; bindings refer to them by name.

- on:

  A named list of event handlers `function(self, event)`, e.g.
  `list(mount = ..., "button.pressed" = ...)`.

- methods:

  A named list of extra methods `function(self, ...)`, callable as
  `widget$<name>(...)`.

- style:

  Default
  [`style()`](https://menshikovs.github.io/termr/reference/style.md) of
  the type.

- focusable:

  Can widgets of this type receive focus?

- inherit:

  Parent class:
  [Widget](https://menshikovs.github.io/termr/reference/Widget-class.md),
  [Vertical](https://menshikovs.github.io/termr/reference/Vertical-class.md)
  or
  [Horizontal](https://menshikovs.github.io/termr/reference/Horizontal-class.md).

## Value

A constructor function
`function(..., id = NULL, classes = NULL, style = NULL, disabled = FALSE)`.
Named arguments in `...` set initial state values; unnamed arguments are
child widgets.

## Examples

``` r
Counter <- widget(
  "Counter",
  state = list(count = reactive(0L)),
  render = function(self) sprintf("Count: %d", self$count),
  bindings = list(bind("up", "increment"), bind("down", "decrement")),
  actions = list(
    increment = function(self) self$count <- self$count + 1L,
    decrement = function(self) self$count <- self$count - 1L
  ),
  focusable = TRUE
)
counter <- Counter(count = 5L)
counter$count
#> [1] 5
render_widget(counter, 12, 1)
#> <ScreenBuffer 12x1>
#> +------------+
#> |Count: 5    |
#> +------------+
```
