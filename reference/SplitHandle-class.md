# Split handle

The draggable divider of a
[`split_pane()`](https://menshikovs.github.io/termr/reference/split_pane.md).

## Super class

[`Widget`](https://menshikovs.github.io/termr/reference/Widget-class.md)
-\> `SplitHandle`

## Public fields

- `focusable`:

  The divider can be moved with the keyboard.

## Methods

### Public methods

- [`SplitHandle$default_style()`](#method-SplitHandle-default_style)

- [`SplitHandle$default_bindings()`](#method-SplitHandle-default_bindings)

- [`SplitHandle$action_split_less()`](#method-SplitHandle-action_split_less)

- [`SplitHandle$action_split_more()`](#method-SplitHandle-action_split_more)

- [`SplitHandle$action_split_less_far()`](#method-SplitHandle-action_split_less_far)

- [`SplitHandle$action_split_more_far()`](#method-SplitHandle-action_split_more_far)

- [`SplitHandle$action_split_min()`](#method-SplitHandle-action_split_min)

- [`SplitHandle$action_split_max()`](#method-SplitHandle-action_split_max)

- [`SplitHandle$on_drag_move()`](#method-SplitHandle-on_drag_move)

- [`SplitHandle$on_mouse_down()`](#method-SplitHandle-on_mouse_down)

- [`SplitHandle$on_drag_end()`](#method-SplitHandle-on_drag_end)

- [`SplitHandle$paint()`](#method-SplitHandle-paint)

- [`SplitHandle$clone()`](#method-SplitHandle-clone)

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
- [`Widget$initialize()`](https://menshikovs.github.io/termr/reference/Widget.html#method-initialize)
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

### `SplitHandle$default_style()`

The built-in style.

#### Usage

    SplitHandle$default_style()

------------------------------------------------------------------------

### `SplitHandle$default_bindings()`

Arrow keys move the divider (Shift: ten cells).

#### Usage

    SplitHandle$default_bindings()

------------------------------------------------------------------------

### `SplitHandle$action_split_less()`

Move the divider towards the first pane.

#### Usage

    SplitHandle$action_split_less()

------------------------------------------------------------------------

### `SplitHandle$action_split_more()`

Move the divider towards the second pane.

#### Usage

    SplitHandle$action_split_more()

------------------------------------------------------------------------

### `SplitHandle$action_split_less_far()`

Move the divider ten cells towards the first pane.

#### Usage

    SplitHandle$action_split_less_far()

------------------------------------------------------------------------

### `SplitHandle$action_split_more_far()`

Move the divider ten cells towards the second pane.

#### Usage

    SplitHandle$action_split_more_far()

------------------------------------------------------------------------

### `SplitHandle$action_split_min()`

Give the first pane its smallest size.

#### Usage

    SplitHandle$action_split_min()

------------------------------------------------------------------------

### `SplitHandle$action_split_max()`

Give the first pane its largest size.

#### Usage

    SplitHandle$action_split_max()

------------------------------------------------------------------------

### `SplitHandle$on_drag_move()`

Dragging the divider resizes the panes.

#### Usage

    SplitHandle$on_drag_move(event)

#### Arguments

- `event`:

  A `MouseEvent`.

------------------------------------------------------------------------

### `SplitHandle$on_mouse_down()`

A press on the divider starts a drag.

#### Usage

    SplitHandle$on_mouse_down(event)

#### Arguments

- `event`:

  A `MouseEvent`.

------------------------------------------------------------------------

### `SplitHandle$on_drag_end()`

Announce the new size when a drag ends.

#### Usage

    SplitHandle$on_drag_end(event)

#### Arguments

- `event`:

  A `MouseEvent`.

------------------------------------------------------------------------

### `SplitHandle$paint()`

Draw the divider line.

#### Usage

    SplitHandle$paint(buffer, area, st)

#### Arguments

- `buffer`:

  A
  [ScreenBuffer](https://menshikovs.github.io/termr/reference/ScreenBuffer.md).

- `area`:

  Visible part of the region.

- `st`:

  Computed style.

------------------------------------------------------------------------

### `SplitHandle$clone()`

The objects of this class are cloneable with this method.

#### Usage

    SplitHandle$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
