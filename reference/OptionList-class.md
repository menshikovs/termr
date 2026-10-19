# OptionList widget

A list of choices. See
[`option_list()`](https://menshikovs.github.io/termr/reference/option_list.md).

## Super classes

[`Widget`](https://menshikovs.github.io/termr/reference/Widget-class.md)
-\> `ListBase` -\> `OptionList`

## Active bindings

- `value`:

  Value of the highlighted choice (`NULL` if none).

- `choices`:

  The choice values.

## Methods

### Public methods

- [`OptionList$new()`](#method-OptionList-initialize)

- [`OptionList$set_choices()`](#method-OptionList-set_choices)

- [`OptionList$item_count()`](#method-OptionList-item_count)

- [`OptionList$item_text()`](#method-OptionList-item_text)

- [`OptionList$on_highlight()`](#method-OptionList-on_highlight)

- [`OptionList$on_activate()`](#method-OptionList-on_activate)

- [`OptionList$clone()`](#method-OptionList-clone)

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
- `ListBase$item_style()`
- `ListBase$on_click()`
- `ListBase$on_mouse_down()`
- `ListBase$on_mouse_scroll()`
- `ListBase$paint()`
- `ListBase$scroll_to_end()`
- `ListBase$scroll_to_item()`

------------------------------------------------------------------------

### `OptionList$new()`

Create an option list. See
[`option_list()`](https://menshikovs.github.io/termr/reference/option_list.md).

#### Usage

    OptionList$new(
      choices,
      id = NULL,
      classes = NULL,
      style = NULL,
      disabled = FALSE
    )

#### Arguments

- `choices`:

  Choices.

- `id, classes, style, disabled`:

  See
  [Widget](https://menshikovs.github.io/termr/reference/Widget-class.md).

------------------------------------------------------------------------

### `OptionList$set_choices()`

Replace the choices.

#### Usage

    OptionList$set_choices(choices)

#### Arguments

- `choices`:

  Character vector (named: names are shown).

------------------------------------------------------------------------

### `OptionList$item_count()`

Number of choices.

#### Usage

    OptionList$item_count()

------------------------------------------------------------------------

### `OptionList$item_text()`

Label of choice `i`.

#### Usage

    OptionList$item_text(i)

#### Arguments

- `i`:

  Index.

------------------------------------------------------------------------

### `OptionList$on_highlight()`

Sends `"option_list.highlighted"`.

#### Usage

    OptionList$on_highlight(i)

#### Arguments

- `i`:

  Index.

------------------------------------------------------------------------

### `OptionList$on_activate()`

Sends `"option_list.selected"`.

#### Usage

    OptionList$on_activate(i)

#### Arguments

- `i`:

  Index.

------------------------------------------------------------------------

### `OptionList$clone()`

The objects of this class are cloneable with this method.

#### Usage

    OptionList$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
