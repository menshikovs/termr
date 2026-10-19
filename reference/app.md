# Create an application

Create an application

## Usage

``` r
app(
  ...,
  bindings = list(),
  actions = list(),
  title = NULL,
  mouse = TRUE,
  stylesheet = NULL,
  theme = "default",
  debug = FALSE,
  reduce_motion = NULL
)
```

## Arguments

- ...:

  Widgets to show, plus optional
  [`on()`](https://menshikovs.github.io/termr/reference/on.md) event
  handlers and
  [`bind()`](https://menshikovs.github.io/termr/reference/bind.md) key
  bindings.

- bindings:

  A list of
  [`bind()`](https://menshikovs.github.io/termr/reference/bind.md) key
  bindings.

- actions:

  A named list of action functions `function(app)` that bindings can
  refer to by name.

- title:

  Optional title.

- mouse:

  Enable mouse input (clicks, wheel, hover)?

- stylesheet:

  A
  [`stylesheet()`](https://menshikovs.github.io/termr/reference/stylesheet.md),
  stylesheet text, a file path, or a list of them.

- theme:

  A
  [`termr_theme()`](https://menshikovs.github.io/termr/reference/termr_theme.md)
  or a built-in theme name (`"default"`, `"dark"`, `"light"`).

- debug:

  Bind F12 to a debug overlay (focused and hovered widget, last event,
  repaint statistics)?

- reduce_motion:

  Turn decorative animation off? `NULL` follows
  [`motion_reduced()`](https://menshikovs.github.io/termr/reference/motion_reduced.md).

## Value

An [App](https://menshikovs.github.io/termr/reference/App-class.md).
Start it with
[`run()`](https://menshikovs.github.io/termr/reference/run.md).

Built-in bindings: `tab` / `shift+tab` move focus, `ctrl+c` quits.

## Examples

``` r
hello <- app(
  vertical(
    label("What is your name?"),
    input(id = "name"),
    button("Say hello", id = "hello"),
    label("", id = "output")
  ),
  on("button.pressed", "#hello", function(event, app) {
    name <- app$query_one("#name")$value
    app$query_one("#output")$update(paste("Hello", name))
  }),
  bind("escape", "quit")
)
if (interactive()) run(hello)
```
