# Key bindings

`bind()` maps a key (or several keys separated by commas) to an action.
Bindings can be attached to the app
([`app()`](https://menshikovs.github.io/termr/reference/app.md)), to the
screen, to a widget type
([`widget()`](https://menshikovs.github.io/termr/reference/widget.md))
or to a single widget (`widget$bind()`). When a key is pressed, bindings
are searched from the focused widget up to the app, so the most local
binding wins.

## Usage

``` r
bind(key, action, description = NULL)
```

## Arguments

- key:

  Key name such as `"q"`, `"ctrl+c"`, `"shift+tab"`, `"f1"`, or several
  keys: `"q,escape"`.

- action:

  Action name or a function. Functions bound on the app are called as
  `action(app)`; functions bound on a widget as `action(widget, app)`.

- description:

  Optional human readable description (for help screens and footers).

## Value

An object of class `termr_binding`.

## Details

An action is either the name of an action or a function. Named actions
are looked up on the widget that owns the binding, then on its
ancestors, then on the app. Prefix a name with `"app."` to call an app
action directly. Built-in app actions are `"quit"`, `"focus_next"`,
`"focus_previous"` and `"refresh"`.

## Examples

``` r
bind("q", "quit")
#> <binding q -> quit>
bind("ctrl+r", function(app) app$refresh(), "Redraw")
#> <binding ctrl+r -> <function>>
```
