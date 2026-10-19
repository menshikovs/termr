# PropertyGrid widget

See
[`property_grid()`](https://menshikovs.github.io/termr/reference/property_grid.md).

## Super classes

[`Widget`](https://menshikovs.github.io/termr/reference/Widget-class.md)
-\>
[`ScrollView`](https://menshikovs.github.io/termr/reference/ScrollView-class.md)
-\> `PropertyGrid`

## Public fields

- `max_key_width`:

  Maximum key width in terminal cells.

- `formatter`:

  Optional `function(name, value)`.

## Active bindings

- `data`:

  The current named data (reactive).

## Methods

### Public methods

- [`PropertyGrid$new()`](#method-PropertyGrid-initialize)

- [`PropertyGrid$default_style()`](#method-PropertyGrid-default_style)

- [`PropertyGrid$set_data()`](#method-PropertyGrid-set_data)

- [`PropertyGrid$clone()`](#method-PropertyGrid-clone)

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
- [`ScrollView$action_page_down()`](https://menshikovs.github.io/termr/reference/ScrollView.html#method-action_page_down)
- [`ScrollView$action_page_up()`](https://menshikovs.github.io/termr/reference/ScrollView.html#method-action_page_up)
- [`ScrollView$action_scroll_down()`](https://menshikovs.github.io/termr/reference/ScrollView.html#method-action_scroll_down)
- [`ScrollView$action_scroll_end()`](https://menshikovs.github.io/termr/reference/ScrollView.html#method-action_scroll_end)
- [`ScrollView$action_scroll_home()`](https://menshikovs.github.io/termr/reference/ScrollView.html#method-action_scroll_home)
- [`ScrollView$action_scroll_left()`](https://menshikovs.github.io/termr/reference/ScrollView.html#method-action_scroll_left)
- [`ScrollView$action_scroll_right()`](https://menshikovs.github.io/termr/reference/ScrollView.html#method-action_scroll_right)
- [`ScrollView$action_scroll_up()`](https://menshikovs.github.io/termr/reference/ScrollView.html#method-action_scroll_up)
- [`ScrollView$arrange_children()`](https://menshikovs.github.io/termr/reference/ScrollView.html#method-arrange_children)
- [`ScrollView$child_clip()`](https://menshikovs.github.io/termr/reference/ScrollView.html#method-child_clip)
- [`ScrollView$default_bindings()`](https://menshikovs.github.io/termr/reference/ScrollView.html#method-default_bindings)
- [`ScrollView$layout_descend()`](https://menshikovs.github.io/termr/reference/ScrollView.html#method-layout_descend)
- [`ScrollView$on_mouse_scroll()`](https://menshikovs.github.io/termr/reference/ScrollView.html#method-on_mouse_scroll)
- [`ScrollView$paint()`](https://menshikovs.github.io/termr/reference/ScrollView.html#method-paint)
- [`ScrollView$scroll_by()`](https://menshikovs.github.io/termr/reference/ScrollView.html#method-scroll_by)
- [`ScrollView$scroll_end()`](https://menshikovs.github.io/termr/reference/ScrollView.html#method-scroll_end)
- [`ScrollView$scroll_home()`](https://menshikovs.github.io/termr/reference/ScrollView.html#method-scroll_home)
- [`ScrollView$scroll_into_view()`](https://menshikovs.github.io/termr/reference/ScrollView.html#method-scroll_into_view)
- [`ScrollView$scroll_to()`](https://menshikovs.github.io/termr/reference/ScrollView.html#method-scroll_to)

------------------------------------------------------------------------

### `PropertyGrid$new()`

Create a property grid. See
[`property_grid()`](https://menshikovs.github.io/termr/reference/property_grid.md).

#### Usage

    PropertyGrid$new(
      data = list(),
      formatter = NULL,
      max_key_width = 20L,
      id = NULL,
      classes = NULL,
      style = NULL,
      disabled = FALSE
    )

#### Arguments

- `data`:

  Named list/vector or data frame.

- `formatter`:

  Optional value formatter.

- `max_key_width`:

  Maximum key width.

- `id, classes, style, disabled`:

  See
  [`property_grid()`](https://menshikovs.github.io/termr/reference/property_grid.md).

------------------------------------------------------------------------

### `PropertyGrid$default_style()`

The built-in scrollable style.

#### Usage

    PropertyGrid$default_style()

------------------------------------------------------------------------

### `PropertyGrid$set_data()`

Replace all rows.

#### Usage

    PropertyGrid$set_data(data)

#### Arguments

- `data`:

  New named data.

------------------------------------------------------------------------

### `PropertyGrid$clone()`

The objects of this class are cloneable with this method.

#### Usage

    PropertyGrid$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
