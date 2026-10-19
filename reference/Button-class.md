# Button widget

A focusable button. See
[`button()`](https://menshikovs.github.io/termr/reference/button.md).

## Super class

[`Widget`](https://menshikovs.github.io/termr/reference/Widget-class.md)
-\> `Button`

## Public fields

- `paint_states`:

  Pressing only repaints.

- `focusable`:

  Buttons can be focused.

- `variant`:

  Colour variant.

- `press_duration`:

  Seconds the pressed state stays visible.

## Active bindings

- `label`:

  The button text (reactive).

- `pressed`:

  Is the button showing its pressed state?

## Methods

### Public methods

- [`Button$new()`](#method-Button-initialize)

- [`Button$default_style()`](#method-Button-default_style)

- [`Button$default_bindings()`](#method-Button-default_bindings)

- [`Button$render()`](#method-Button-render)

- [`Button$press()`](#method-Button-press)

- [`Button$on_click()`](#method-Button-on_click)

- [`Button$action_press()`](#method-Button-action_press)

- [`Button$pseudo_states()`](#method-Button-pseudo_states)

- [`Button$clone()`](#method-Button-clone)

Inherited methods

- [`Widget$add_class()`](https://menshikovs.github.io/termr/reference/Widget.html#method-add_class)
- [`Widget$ancestors()`](https://menshikovs.github.io/termr/reference/Widget.html#method-ancestors)
- [`Widget$animate()`](https://menshikovs.github.io/termr/reference/Widget.html#method-animate)
- [`Widget$arrange_children()`](https://menshikovs.github.io/termr/reference/Widget.html#method-arrange_children)
- [`Widget$bind()`](https://menshikovs.github.io/termr/reference/Widget.html#method-bind)
- [`Widget$bind_reactive()`](https://menshikovs.github.io/termr/reference/Widget.html#method-bind_reactive)
- [`Widget$bindings()`](https://menshikovs.github.io/termr/reference/Widget.html#method-bindings)
- [`Widget$blur()`](https://menshikovs.github.io/termr/reference/Widget.html#method-blur)
- [`Widget$capture_mouse()`](https://menshikovs.github.io/termr/reference/Widget.html#method-capture_mouse)
- [`Widget$child_clip()`](https://menshikovs.github.io/termr/reference/Widget.html#method-child_clip)
- [`Widget$clear()`](https://menshikovs.github.io/termr/reference/Widget.html#method-clear)
- [`Widget$computed_style()`](https://menshikovs.github.io/termr/reference/Widget.html#method-computed_style)
- [`Widget$content_height()`](https://menshikovs.github.io/termr/reference/Widget.html#method-content_height)
- [`Widget$content_width()`](https://menshikovs.github.io/termr/reference/Widget.html#method-content_width)
- [`Widget$focus()`](https://menshikovs.github.io/termr/reference/Widget.html#method-focus)
- [`Widget$format()`](https://menshikovs.github.io/termr/reference/Widget.html#method-format)
- [`Widget$get_state()`](https://menshikovs.github.io/termr/reference/Widget.html#method-get_state)
- [`Widget$has_class()`](https://menshikovs.github.io/termr/reference/Widget.html#method-has_class)
- [`Widget$invalidate()`](https://menshikovs.github.io/termr/reference/Widget.html#method-invalidate)
- [`Widget$invalidate_paint()`](https://menshikovs.github.io/termr/reference/Widget.html#method-invalidate_paint)
- [`Widget$is_displayed()`](https://menshikovs.github.io/termr/reference/Widget.html#method-is_displayed)
- [`Widget$is_enabled()`](https://menshikovs.github.io/termr/reference/Widget.html#method-is_enabled)
- [`Widget$layout_descend()`](https://menshikovs.github.io/termr/reference/Widget.html#method-layout_descend)
- [`Widget$layout_differs()`](https://menshikovs.github.io/termr/reference/Widget.html#method-layout_differs)
- [`Widget$matches()`](https://menshikovs.github.io/termr/reference/Widget.html#method-matches)
- [`Widget$mount()`](https://menshikovs.github.io/termr/reference/Widget.html#method-mount)
- [`Widget$on()`](https://menshikovs.github.io/termr/reference/Widget.html#method-on)
- [`Widget$paint()`](https://menshikovs.github.io/termr/reference/Widget.html#method-paint)
- [`Widget$post_message()`](https://menshikovs.github.io/termr/reference/Widget.html#method-post_message)
- [`Widget$print()`](https://menshikovs.github.io/termr/reference/Widget.html#method-print)
- [`Widget$query()`](https://menshikovs.github.io/termr/reference/Widget.html#method-query)
- [`Widget$query_one()`](https://menshikovs.github.io/termr/reference/Widget.html#method-query_one)
- [`Widget$refresh()`](https://menshikovs.github.io/termr/reference/Widget.html#method-refresh)
- [`Widget$release_mouse()`](https://menshikovs.github.io/termr/reference/Widget.html#method-release_mouse)
- [`Widget$remove()`](https://menshikovs.github.io/termr/reference/Widget.html#method-remove)
- [`Widget$remove_children()`](https://menshikovs.github.io/termr/reference/Widget.html#method-remove_children)
- [`Widget$remove_class()`](https://menshikovs.github.io/termr/reference/Widget.html#method-remove_class)
- [`Widget$render_lines()`](https://menshikovs.github.io/termr/reference/Widget.html#method-render_lines)
- [`Widget$replace()`](https://menshikovs.github.io/termr/reference/Widget.html#method-replace)
- [`Widget$run_action()`](https://menshikovs.github.io/termr/reference/Widget.html#method-run_action)
- [`Widget$run_process()`](https://menshikovs.github.io/termr/reference/Widget.html#method-run_process)
- [`Widget$run_worker()`](https://menshikovs.github.io/termr/reference/Widget.html#method-run_worker)
- [`Widget$set()`](https://menshikovs.github.io/termr/reference/Widget.html#method-set)
- [`Widget$set_interval()`](https://menshikovs.github.io/termr/reference/Widget.html#method-set_interval)
- [`Widget$set_state()`](https://menshikovs.github.io/termr/reference/Widget.html#method-set_state)
- [`Widget$set_timeout()`](https://menshikovs.github.io/termr/reference/Widget.html#method-set_timeout)
- [`Widget$toggle_class()`](https://menshikovs.github.io/termr/reference/Widget.html#method-toggle_class)
- [`Widget$walk()`](https://menshikovs.github.io/termr/reference/Widget.html#method-walk)

------------------------------------------------------------------------

### `Button$new()`

Create a button.

#### Usage

    Button$new(
      label = "Button",
      id = NULL,
      classes = NULL,
      style = NULL,
      disabled = FALSE,
      variant = "default"
    )

#### Arguments

- `label`:

  Button text, or a function of no arguments that returns it
  (re-evaluated when the
  [`signal()`](https://menshikovs.github.io/termr/reference/signals.md)s
  it reads change).

- `id, classes, style, disabled`:

  See
  [Widget](https://menshikovs.github.io/termr/reference/Widget-class.md).

- `variant`:

  One of `"default"`, `"primary"`, `"success"`, `"warning"`, `"error"`.

------------------------------------------------------------------------

### `Button$default_style()`

The built-in style.

#### Usage

    Button$default_style()

------------------------------------------------------------------------

### `Button$default_bindings()`

Enter and space press the button.

#### Usage

    Button$default_bindings()

------------------------------------------------------------------------

### `Button$render()`

The button text.

#### Usage

    Button$render()

------------------------------------------------------------------------

### `Button$press()`

Press the button: shows the pressed state briefly and sends a
`"button.pressed"` message. Does nothing when disabled.

#### Usage

    Button$press()

#### Returns

`TRUE` if the button was pressed.

------------------------------------------------------------------------

### `Button$on_click()`

A left click presses the button.

#### Usage

    Button$on_click(event)

#### Arguments

- `event`:

  A `MouseEvent`.

------------------------------------------------------------------------

### `Button$action_press()`

Action used by the default bindings.

#### Usage

    Button$action_press()

------------------------------------------------------------------------

### `Button$pseudo_states()`

Active states: focus, disabled and pressed.

#### Usage

    Button$pseudo_states()

------------------------------------------------------------------------

### `Button$clone()`

The objects of this class are cloneable with this method.

#### Usage

    Button$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
