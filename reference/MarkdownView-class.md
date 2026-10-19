# MarkdownView widget

A read-only Markdown document. See
[`markdown_view()`](https://menshikovs.github.io/termr/reference/markdown_view.md).

## Super class

[`Widget`](https://menshikovs.github.io/termr/reference/Widget-class.md)
-\> `MarkdownView`

## Active bindings

- `markdown`:

  The source text (assigning calls `set_markdown()`).

- `links`:

  The links in the document: a data frame (`text`, `url`).

## Methods

### Public methods

- [`MarkdownView$new()`](#method-MarkdownView-initialize)

- [`MarkdownView$default_style()`](#method-MarkdownView-default_style)

- [`MarkdownView$set_markdown()`](#method-MarkdownView-set_markdown)

- [`MarkdownView$render_lines()`](#method-MarkdownView-render_lines)

- [`MarkdownView$content_width()`](#method-MarkdownView-content_width)

- [`MarkdownView$content_height()`](#method-MarkdownView-content_height)

- [`MarkdownView$clone()`](#method-MarkdownView-clone)

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

### `MarkdownView$new()`

Create a Markdown view.

#### Usage

    MarkdownView$new(text = "", id = NULL, classes = NULL, style = NULL)

#### Arguments

- `text`:

  Markdown source.

- `id, classes, style`:

  See
  [Widget](https://menshikovs.github.io/termr/reference/Widget-class.md).

------------------------------------------------------------------------

### `MarkdownView$default_style()`

The built-in style.

#### Usage

    MarkdownView$default_style()

------------------------------------------------------------------------

### `MarkdownView$set_markdown()`

Replace the document.

#### Usage

    MarkdownView$set_markdown(text)

#### Arguments

- `text`:

  Markdown source.

------------------------------------------------------------------------

### `MarkdownView$render_lines()`

The rendered lines for a width.

#### Usage

    MarkdownView$render_lines(width = NA_integer_)

#### Arguments

- `width`:

  Content width.

------------------------------------------------------------------------

### `MarkdownView$content_width()`

Natural width.

#### Usage

    MarkdownView$content_width()

------------------------------------------------------------------------

### `MarkdownView$content_height()`

Natural height for a width.

#### Usage

    MarkdownView$content_height(width)

#### Arguments

- `width`:

  Content width.

------------------------------------------------------------------------

### `MarkdownView$clone()`

The objects of this class are cloneable with this method.

#### Usage

    MarkdownView$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
