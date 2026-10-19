# ScrollView widget

A container whose content can be larger than the widget. See
[`scroll_view()`](https://menshikovs.github.io/termr/reference/scroll_view.md).

## Super class

[`Widget`](https://menshikovs.github.io/termr/reference/Widget-class.md)
-\> `ScrollView`

## Public fields

- `focusable`:

  Scroll views can take focus so they can be scrolled with the keyboard
  even without focusable children.

- `direction`:

  `"vertical"`, `"horizontal"` or `"both"`.

- `scrollbars`:

  Draw scroll bars when the content overflows?

## Active bindings

- `offset_x, offset_y`:

  Scroll offsets in cells (reactive).

- `viewport`:

  The visible content rectangle (after the last layout).

- `virtual_size`:

  Size of the scrollable content: `c(width, height)`.

- `max_scroll`:

  Largest offsets: `c(x, y)`.

## Methods

### Public methods

- [`ScrollView$new()`](#method-ScrollView-initialize)

- [`ScrollView$default_style()`](#method-ScrollView-default_style)

- [`ScrollView$default_bindings()`](#method-ScrollView-default_bindings)

- [`ScrollView$scroll_to()`](#method-ScrollView-scroll_to)

- [`ScrollView$scroll_by()`](#method-ScrollView-scroll_by)

- [`ScrollView$scroll_home()`](#method-ScrollView-scroll_home)

- [`ScrollView$scroll_end()`](#method-ScrollView-scroll_end)

- [`ScrollView$scroll_into_view()`](#method-ScrollView-scroll_into_view)

- [`ScrollView$on_mouse_scroll()`](#method-ScrollView-on_mouse_scroll)

- [`ScrollView$action_scroll_up()`](#method-ScrollView-action_scroll_up)

- [`ScrollView$action_scroll_down()`](#method-ScrollView-action_scroll_down)

- [`ScrollView$action_scroll_left()`](#method-ScrollView-action_scroll_left)

- [`ScrollView$action_scroll_right()`](#method-ScrollView-action_scroll_right)

- [`ScrollView$action_page_up()`](#method-ScrollView-action_page_up)

- [`ScrollView$action_page_down()`](#method-ScrollView-action_page_down)

- [`ScrollView$action_scroll_home()`](#method-ScrollView-action_scroll_home)

- [`ScrollView$action_scroll_end()`](#method-ScrollView-action_scroll_end)

- [`ScrollView$arrange_children()`](#method-ScrollView-arrange_children)

- [`ScrollView$layout_descend()`](#method-ScrollView-layout_descend)

- [`ScrollView$child_clip()`](#method-ScrollView-child_clip)

- [`ScrollView$paint()`](#method-ScrollView-paint)

- [`ScrollView$clone()`](#method-ScrollView-clone)

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

------------------------------------------------------------------------

### `ScrollView$new()`

Create a scroll view. See
[`scroll_view()`](https://menshikovs.github.io/termr/reference/scroll_view.md).

#### Usage

    ScrollView$new(
      ...,
      direction = "vertical",
      scrollbars = TRUE,
      focusable = TRUE,
      id = NULL,
      classes = NULL,
      style = NULL,
      disabled = FALSE
    )

#### Arguments

- `...`:

  Child widgets.

- `direction`:

  Scroll direction.

- `scrollbars`:

  Show scroll bars?

- `focusable`:

  Can the scroll view itself be focused?

- `id, classes, style, disabled`:

  See
  [Widget](https://menshikovs.github.io/termr/reference/Widget-class.md).

------------------------------------------------------------------------

### `ScrollView$default_style()`

The built-in style.

#### Usage

    ScrollView$default_style()

------------------------------------------------------------------------

### `ScrollView$default_bindings()`

Arrow keys, Page Up/Down and Home/End scroll.

#### Usage

    ScrollView$default_bindings()

------------------------------------------------------------------------

### `ScrollView$scroll_to()`

Scroll to an absolute position (in cells). Positions are clamped to the
scrollable range at the next layout.

#### Usage

    ScrollView$scroll_to(x = NULL, y = NULL)

#### Arguments

- `x, y`:

  New offsets; `NULL` keeps the current one.

------------------------------------------------------------------------

### `ScrollView$scroll_by()`

Scroll relative to the current position.

#### Usage

    ScrollView$scroll_by(dx = 0L, dy = 0L)

#### Arguments

- `dx, dy`:

  Cells to scroll (negative: up/left).

------------------------------------------------------------------------

### `ScrollView$scroll_home()`

Scroll to the top (and left).

#### Usage

    ScrollView$scroll_home()

------------------------------------------------------------------------

### `ScrollView$scroll_end()`

Scroll to the bottom.

#### Usage

    ScrollView$scroll_end()

------------------------------------------------------------------------

### `ScrollView$scroll_into_view()`

Scroll so that a descendant is fully visible (as far as possible). Uses
the last layout; the app re-lays out afterwards.

#### Usage

    ScrollView$scroll_into_view(widget)

#### Arguments

- `widget`:

  A descendant widget.

#### Returns

`TRUE` if the offsets changed.

------------------------------------------------------------------------

### `ScrollView$on_mouse_scroll()`

The mouse wheel scrolls by three lines. When the view cannot scroll
further, the event bubbles to outer scroll views.

#### Usage

    ScrollView$on_mouse_scroll(event)

#### Arguments

- `event`:

  A `MouseEvent`.

------------------------------------------------------------------------

### `ScrollView$action_scroll_up()`

Scroll one line up.

#### Usage

    ScrollView$action_scroll_up()

------------------------------------------------------------------------

### `ScrollView$action_scroll_down()`

Scroll one line down.

#### Usage

    ScrollView$action_scroll_down()

------------------------------------------------------------------------

### `ScrollView$action_scroll_left()`

Scroll one column left.

#### Usage

    ScrollView$action_scroll_left()

------------------------------------------------------------------------

### `ScrollView$action_scroll_right()`

Scroll one column right.

#### Usage

    ScrollView$action_scroll_right()

------------------------------------------------------------------------

### `ScrollView$action_page_up()`

Scroll one page up.

#### Usage

    ScrollView$action_page_up()

------------------------------------------------------------------------

### `ScrollView$action_page_down()`

Scroll one page down.

#### Usage

    ScrollView$action_page_down()

------------------------------------------------------------------------

### `ScrollView$action_scroll_home()`

Scroll to the top.

#### Usage

    ScrollView$action_scroll_home()

------------------------------------------------------------------------

### `ScrollView$action_scroll_end()`

Scroll to the bottom.

#### Usage

    ScrollView$action_scroll_end()

------------------------------------------------------------------------

### `ScrollView$arrange_children()`

Lay the children out in a virtual area, shifted by the scroll offsets;
reserves space for scroll bars when needed.

#### Usage

    ScrollView$arrange_children(children, inner, st)

#### Arguments

- `children`:

  Visible children.

- `inner`:

  Content rectangle.

- `st`:

  Computed style.

------------------------------------------------------------------------

### `ScrollView$layout_descend()`

Children entirely outside the viewport are not laid out in detail
(unless a complete layout is needed, e.g. to scroll a focused widget
into view).

#### Usage

    ScrollView$layout_descend(rects)

#### Arguments

- `rects`:

  Child rectangles.

------------------------------------------------------------------------

### `ScrollView$child_clip()`

Children are clipped to the viewport.

#### Usage

    ScrollView$child_clip(st)

#### Arguments

- `st`:

  Computed style.

------------------------------------------------------------------------

### `ScrollView$paint()`

Paint background, border and scroll bars.

#### Usage

    ScrollView$paint(buffer, area, st)

#### Arguments

- `buffer`:

  A
  [ScreenBuffer](https://menshikovs.github.io/termr/reference/ScreenBuffer.md).

- `area`:

  Visible part of the region.

- `st`:

  Computed style.

------------------------------------------------------------------------

### `ScrollView$clone()`

The objects of this class are cloneable with this method.

#### Usage

    ScrollView$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
