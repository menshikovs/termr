# LogView widget

See
[`log_view()`](https://menshikovs.github.io/termr/reference/log_view.md).

## Super classes

[`Widget`](https://menshikovs.github.io/termr/reference/Widget-class.md)
-\> `ListBase` -\> `LogView`

## Public fields

- `has_cursor`:

  Log views scroll; they have no cursor.

- `max_lines`:

  Lines kept (older lines are dropped).

- `timestamps`:

  Prefix lines with the time?

- `auto_scroll`:

  Follow new lines while scrolled to the end?

## Active bindings

- `lines`:

  The current lines.

- `paused`:

  Is following paused?

## Methods

### Public methods

- [`LogView$new()`](#method-LogView-initialize)

- [`LogView$write()`](#method-LogView-write)

- [`LogView$clear()`](#method-LogView-clear)

- [`LogView$pause()`](#method-LogView-pause)

- [`LogView$resume()`](#method-LogView-resume)

- [`LogView$at_end()`](#method-LogView-at_end)

- [`LogView$item_count()`](#method-LogView-item_count)

- [`LogView$item_text()`](#method-LogView-item_text)

- [`LogView$item_style()`](#method-LogView-item_style)

- [`LogView$clone()`](#method-LogView-clone)

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
- `ListBase$action_list_activate()`
- `ListBase$action_list_down()`
- `ListBase$action_list_first()`
- `ListBase$action_list_last()`
- `ListBase$action_list_page_down()`
- `ListBase$action_list_page_up()`
- `ListBase$action_list_up()`
- `ListBase$content_height()`
- `ListBase$content_width()`
- `ListBase$default_bindings()`
- `ListBase$default_style()`
- `ListBase$highlight()`
- `ListBase$on_activate()`
- `ListBase$on_click()`
- `ListBase$on_highlight()`
- `ListBase$on_mouse_down()`
- `ListBase$on_mouse_scroll()`
- `ListBase$paint()`
- `ListBase$scroll_to_end()`
- `ListBase$scroll_to_item()`

------------------------------------------------------------------------

### `LogView$new()`

Create a log view. See
[`log_view()`](https://menshikovs.github.io/termr/reference/log_view.md).

#### Usage

    LogView$new(
      max_lines = 1000L,
      timestamps = FALSE,
      auto_scroll = TRUE,
      id = NULL,
      classes = NULL,
      style = NULL
    )

#### Arguments

- `max_lines, timestamps, auto_scroll`:

  See fields.

- `id, classes, style`:

  See
  [Widget](https://menshikovs.github.io/termr/reference/Widget-class.md).

------------------------------------------------------------------------

### `LogView$write()`

Add lines.

#### Usage

    LogView$write(..., level = "info")

#### Arguments

- `...`:

  Text, pasted together; newlines start new lines.

- `level`:

  `"debug"`, `"info"`, `"success"`, `"warning"` or `"error"`.

------------------------------------------------------------------------

### `LogView$clear()`

Remove all lines.

#### Usage

    LogView$clear()

------------------------------------------------------------------------

### `LogView$pause()`

Stop following new lines.

#### Usage

    LogView$pause()

------------------------------------------------------------------------

### `LogView$resume()`

Follow new lines again (and jump to the end).

#### Usage

    LogView$resume()

------------------------------------------------------------------------

### `LogView$at_end()`

Is the view scrolled to the last line?

#### Usage

    LogView$at_end()

------------------------------------------------------------------------

### `LogView$item_count()`

Number of lines.

#### Usage

    LogView$item_count()

------------------------------------------------------------------------

### `LogView$item_text()`

Text of line `i`.

#### Usage

    LogView$item_text(i)

#### Arguments

- `i`:

  Index.

------------------------------------------------------------------------

### `LogView$item_style()`

Style of line `i` (by level).

#### Usage

    LogView$item_style(i)

#### Arguments

- `i`:

  Index.

------------------------------------------------------------------------

### `LogView$clone()`

The objects of this class are cloneable with this method.

#### Usage

    LogView$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
