# Sparkline widget

See
[`sparkline()`](https://menshikovs.github.io/termr/reference/sparkline.md).

## Super class

[`Widget`](https://menshikovs.github.io/termr/reference/Widget-class.md)
-\> `Sparkline`

## Public fields

- `min, max`:

  Fixed scale limits, or `NULL` to use the data range.

- `max_length`:

  Values kept by `push()`.

- `summary`:

  How to fit more values than columns: `"tail"` (latest values) or
  `"mean"` (average buckets).

## Active bindings

- `data`:

  The values (reactive).

## Methods

### Public methods

- [`Sparkline$new()`](#method-Sparkline-initialize)

- [`Sparkline$default_style()`](#method-Sparkline-default_style)

- [`Sparkline$push()`](#method-Sparkline-push)

- [`Sparkline$render_lines()`](#method-Sparkline-render_lines)

- [`Sparkline$content_width()`](#method-Sparkline-content_width)

- [`Sparkline$clone()`](#method-Sparkline-clone)

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
- [`Widget$default_bindings()`](https://menshikovs.github.io/termr/reference/Widget.html#method-default_bindings)
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
- [`Widget$pseudo_states()`](https://menshikovs.github.io/termr/reference/Widget.html#method-pseudo_states)
- [`Widget$query()`](https://menshikovs.github.io/termr/reference/Widget.html#method-query)
- [`Widget$query_one()`](https://menshikovs.github.io/termr/reference/Widget.html#method-query_one)
- [`Widget$refresh()`](https://menshikovs.github.io/termr/reference/Widget.html#method-refresh)
- [`Widget$release_mouse()`](https://menshikovs.github.io/termr/reference/Widget.html#method-release_mouse)
- [`Widget$remove()`](https://menshikovs.github.io/termr/reference/Widget.html#method-remove)
- [`Widget$remove_children()`](https://menshikovs.github.io/termr/reference/Widget.html#method-remove_children)
- [`Widget$remove_class()`](https://menshikovs.github.io/termr/reference/Widget.html#method-remove_class)
- [`Widget$render()`](https://menshikovs.github.io/termr/reference/Widget.html#method-render)
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

### `Sparkline$new()`

Create a sparkline. See
[`sparkline()`](https://menshikovs.github.io/termr/reference/sparkline.md).

#### Usage

    Sparkline$new(
      data = numeric(),
      min = NULL,
      max = NULL,
      summary = "tail",
      max_length = 1000L,
      id = NULL,
      classes = NULL,
      style = NULL
    )

#### Arguments

- `data`:

  Numbers.

- `min, max`:

  Scale limits.

- `summary`:

  Fitting strategy.

- `max_length`:

  Values kept by `push()`.

- `id, classes, style`:

  See
  [Widget](https://menshikovs.github.io/termr/reference/Widget-class.md).

------------------------------------------------------------------------

### `Sparkline$default_style()`

The built-in style.

#### Usage

    Sparkline$default_style()

------------------------------------------------------------------------

### `Sparkline$push()`

Append values (keeping at most `max_length`).

#### Usage

    Sparkline$push(x)

#### Arguments

- `x`:

  Numbers.

------------------------------------------------------------------------

### `Sparkline$render_lines()`

The bars for a given width.

#### Usage

    Sparkline$render_lines(width = NA_integer_)

#### Arguments

- `width`:

  Content width.

------------------------------------------------------------------------

### `Sparkline$content_width()`

Natural width: one column per value.

#### Usage

    Sparkline$content_width()

------------------------------------------------------------------------

### `Sparkline$clone()`

The objects of this class are cloneable with this method.

#### Usage

    Sparkline$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
