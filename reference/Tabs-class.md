# Tabs widget

Tabbed content. See
[`tabs()`](https://menshikovs.github.io/termr/reference/tabs.md).

## Super class

[`Widget`](https://menshikovs.github.io/termr/reference/Widget-class.md)
-\> `Tabs`

## Public fields

- `focusable`:

  The tab bar can take focus (Left/Right switch tabs).

## Active bindings

- `active`:

  Index of the active tab (assign to switch).

- `active_tab`:

  The active
  [TabPane](https://menshikovs.github.io/termr/reference/TabPane.md), or
  `NULL`.

- `tab_count`:

  Number of tabs.

## Methods

### Public methods

- [`Tabs$new()`](#method-Tabs-initialize)

- [`Tabs$default_style()`](#method-Tabs-default_style)

- [`Tabs$default_bindings()`](#method-Tabs-default_bindings)

- [`Tabs$add_tab()`](#method-Tabs-add_tab)

- [`Tabs$remove_tab()`](#method-Tabs-remove_tab)

- [`Tabs$activate()`](#method-Tabs-activate)

- [`Tabs$action_next_tab()`](#method-Tabs-action_next_tab)

- [`Tabs$action_previous_tab()`](#method-Tabs-action_previous_tab)

- [`Tabs$on_mouse_down()`](#method-Tabs-on_mouse_down)

- [`Tabs$arrange_children()`](#method-Tabs-arrange_children)

- [`Tabs$child_clip()`](#method-Tabs-child_clip)

- [`Tabs$content_width()`](#method-Tabs-content_width)

- [`Tabs$content_height()`](#method-Tabs-content_height)

- [`Tabs$paint()`](#method-Tabs-paint)

- [`Tabs$clone()`](#method-Tabs-clone)

Inherited methods

- [`Widget$add_class()`](https://menshikovs.github.io/termr/reference/Widget.html#method-add_class)
- [`Widget$ancestors()`](https://menshikovs.github.io/termr/reference/Widget.html#method-ancestors)
- [`Widget$animate()`](https://menshikovs.github.io/termr/reference/Widget.html#method-animate)
- [`Widget$bind()`](https://menshikovs.github.io/termr/reference/Widget.html#method-bind)
- [`Widget$bind_reactive()`](https://menshikovs.github.io/termr/reference/Widget.html#method-bind_reactive)
- [`Widget$bindings()`](https://menshikovs.github.io/termr/reference/Widget.html#method-bindings)
- [`Widget$blur()`](https://menshikovs.github.io/termr/reference/Widget.html#method-blur)
- [`Widget$capture_mouse()`](https://menshikovs.github.io/termr/reference/Widget.html#method-capture_mouse)
- [`Widget$clear()`](https://menshikovs.github.io/termr/reference/Widget.html#method-clear)
- [`Widget$computed_style()`](https://menshikovs.github.io/termr/reference/Widget.html#method-computed_style)
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
- [`Widget$post_message()`](https://menshikovs.github.io/termr/reference/Widget.html#method-post_message)
- [`Widget$print()`](https://menshikovs.github.io/termr/reference/Widget.html#method-print)
- [`Widget$pseudo_states()`](https://menshikovs.github.io/termr/reference/Widget.html#method-pseudo_states)
- [`Widget$query()`](https://menshikovs.github.io/termr/reference/Widget.html#method-query)
- [`Widget$query_one()`](https://menshikovs.github.io/termr/reference/Widget.html#method-query_one)
- [`Widget$refresh()`](https://menshikovs.github.io/termr/reference/Widget.html#method-refresh)
- [`Widget$release_mouse()`](https://menshikovs.github.io/termr/reference/Widget.html#method-release_mouse)
- [`Widget$remove()`](https://menshikovs.github.io/termr/reference/Widget.html#method-remove)
- [`Widget$remove_children()`](https://menshikovs.github.io/termr/reference/Widget.html#method-remove_children)
- [`Widget$remove_class()`](https://menshikovs.github.io/termr/reference/Widget.html#method-remove_class)
- [`Widget$render()`](https://menshikovs.github.io/termr/reference/Widget.html#method-render)
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

### `Tabs$new()`

Create tabs. See
[`tabs()`](https://menshikovs.github.io/termr/reference/tabs.md).

#### Usage

    Tabs$new(
      ...,
      active = 1L,
      id = NULL,
      classes = NULL,
      style = NULL,
      disabled = FALSE
    )

#### Arguments

- `...`:

  [`tab()`](https://menshikovs.github.io/termr/reference/tabs.md) panes.

- `active`:

  Index or id of the initially active tab.

- `id, classes, style, disabled`:

  See
  [Widget](https://menshikovs.github.io/termr/reference/Widget-class.md).

------------------------------------------------------------------------

### `Tabs$default_style()`

The built-in style.

#### Usage

    Tabs$default_style()

------------------------------------------------------------------------

### `Tabs$default_bindings()`

Left/Right switch tabs when the bar is focused; Ctrl+PageUp /
Ctrl+PageDown switch from anywhere inside.

#### Usage

    Tabs$default_bindings()

------------------------------------------------------------------------

### `Tabs$add_tab()`

Add a tab at the end.

#### Usage

    Tabs$add_tab(pane, activate = FALSE)

#### Arguments

- `pane`:

  A [`tab()`](https://menshikovs.github.io/termr/reference/tabs.md) (or
  any widget, wrapped in a tab named after its id).

- `activate`:

  Make it the active tab?

------------------------------------------------------------------------

### `Tabs$remove_tab()`

Remove a tab.

#### Usage

    Tabs$remove_tab(which)

#### Arguments

- `which`:

  Index or id of the tab.

------------------------------------------------------------------------

### `Tabs$activate()`

Show a tab.

#### Usage

    Tabs$activate(which)

#### Arguments

- `which`:

  Index or id of the tab.

------------------------------------------------------------------------

### `Tabs$action_next_tab()`

Show the next tab.

#### Usage

    Tabs$action_next_tab()

------------------------------------------------------------------------

### `Tabs$action_previous_tab()`

Show the previous tab.

#### Usage

    Tabs$action_previous_tab()

------------------------------------------------------------------------

### `Tabs$on_mouse_down()`

Clicking a label shows its tab.

#### Usage

    Tabs$on_mouse_down(event)

#### Arguments

- `event`:

  A `MouseEvent`.

------------------------------------------------------------------------

### `Tabs$arrange_children()`

Panes go below the tab bar.

#### Usage

    Tabs$arrange_children(children, inner, st)

#### Arguments

- `children`:

  Visible children.

- `inner`:

  Content rectangle.

- `st`:

  Computed style.

------------------------------------------------------------------------

### `Tabs$child_clip()`

Panes are clipped below the tab bar.

#### Usage

    Tabs$child_clip(st)

#### Arguments

- `st`:

  Computed style.

------------------------------------------------------------------------

### `Tabs$content_width()`

Natural width: the widest of the bar and the panes.

#### Usage

    Tabs$content_width()

------------------------------------------------------------------------

### `Tabs$content_height()`

Natural height: bar, rule and the active pane.

#### Usage

    Tabs$content_height(width)

#### Arguments

- `width`:

  Content width.

------------------------------------------------------------------------

### `Tabs$paint()`

Paint the tab bar.

#### Usage

    Tabs$paint(buffer, area, st)

#### Arguments

- `buffer`:

  A
  [ScreenBuffer](https://menshikovs.github.io/termr/reference/ScreenBuffer.md).

- `area`:

  Visible part of the region.

- `st`:

  Computed style.

------------------------------------------------------------------------

### `Tabs$clone()`

The objects of this class are cloneable with this method.

#### Usage

    Tabs$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
