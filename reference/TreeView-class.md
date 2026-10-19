# TreeView widget

Shows a tree of
[`tree_node()`](https://menshikovs.github.io/termr/reference/tree_node.md)s.
See
[`tree_view()`](https://menshikovs.github.io/termr/reference/tree_view.md).

## Super class

[`Widget`](https://menshikovs.github.io/termr/reference/Widget-class.md)
-\> `TreeView`

## Public fields

- `paint_states`:

  Cursor and scroll changes only repaint.

- `focusable`:

  Trees can be focused.

- `show_root`:

  Show the root node?

- `guides`:

  Draw guide lines?

## Active bindings

- `root`:

  The root node.

- `cursor_node`:

  The node under the cursor, or `NULL`.

- `visible_count`:

  Number of visible (expanded) lines.

- `offset`:

  First visible line minus one.

## Methods

### Public methods

- [`TreeView$new()`](#method-TreeView-initialize)

- [`TreeView$default_style()`](#method-TreeView-default_style)

- [`TreeView$default_bindings()`](#method-TreeView-default_bindings)

- [`TreeView$tree_changed()`](#method-TreeView-tree_changed)

- [`TreeView$select()`](#method-TreeView-select)

- [`TreeView$action_cursor_up()`](#method-TreeView-action_cursor_up)

- [`TreeView$action_cursor_down()`](#method-TreeView-action_cursor_down)

- [`TreeView$action_page_up()`](#method-TreeView-action_page_up)

- [`TreeView$action_page_down()`](#method-TreeView-action_page_down)

- [`TreeView$action_first()`](#method-TreeView-action_first)

- [`TreeView$action_last()`](#method-TreeView-action_last)

- [`TreeView$action_expand_or_child()`](#method-TreeView-action_expand_or_child)

- [`TreeView$action_collapse_or_parent()`](#method-TreeView-action_collapse_or_parent)

- [`TreeView$action_toggle()`](#method-TreeView-action_toggle)

- [`TreeView$action_activate()`](#method-TreeView-action_activate)

- [`TreeView$on_mouse_down()`](#method-TreeView-on_mouse_down)

- [`TreeView$on_mouse_scroll()`](#method-TreeView-on_mouse_scroll)

- [`TreeView$content_width()`](#method-TreeView-content_width)

- [`TreeView$content_height()`](#method-TreeView-content_height)

- [`TreeView$paint()`](#method-TreeView-paint)

- [`TreeView$clone()`](#method-TreeView-clone)

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

------------------------------------------------------------------------

### `TreeView$new()`

Create a tree view. See
[`tree_view()`](https://menshikovs.github.io/termr/reference/tree_view.md).

#### Usage

    TreeView$new(
      root,
      show_root = TRUE,
      guides = TRUE,
      id = NULL,
      classes = NULL,
      style = NULL,
      disabled = FALSE
    )

#### Arguments

- `root`:

  The root
  [TreeNode](https://menshikovs.github.io/termr/reference/TreeNode.md).

- `show_root, guides`:

  See fields.

- `id, classes, style, disabled`:

  See
  [Widget](https://menshikovs.github.io/termr/reference/Widget-class.md).

------------------------------------------------------------------------

### `TreeView$default_style()`

The built-in style.

#### Usage

    TreeView$default_style()

------------------------------------------------------------------------

### `TreeView$default_bindings()`

Navigation keys.

#### Usage

    TreeView$default_bindings()

------------------------------------------------------------------------

### `TreeView$tree_changed()`

Called by nodes when the tree changes.

#### Usage

    TreeView$tree_changed()

------------------------------------------------------------------------

### `TreeView$select()`

Move the cursor to a node (expanding its ancestors).

#### Usage

    TreeView$select(node)

#### Arguments

- `node`:

  A node of this tree.

------------------------------------------------------------------------

### `TreeView$action_cursor_up()`

Move up.

#### Usage

    TreeView$action_cursor_up()

------------------------------------------------------------------------

### `TreeView$action_cursor_down()`

Move down.

#### Usage

    TreeView$action_cursor_down()

------------------------------------------------------------------------

### `TreeView$action_page_up()`

Move a page up.

#### Usage

    TreeView$action_page_up()

------------------------------------------------------------------------

### `TreeView$action_page_down()`

Move a page down.

#### Usage

    TreeView$action_page_down()

------------------------------------------------------------------------

### `TreeView$action_first()`

Go to the first node.

#### Usage

    TreeView$action_first()

------------------------------------------------------------------------

### `TreeView$action_last()`

Go to the last visible node.

#### Usage

    TreeView$action_last()

------------------------------------------------------------------------

### `TreeView$action_expand_or_child()`

Expand, or go to the first child.

#### Usage

    TreeView$action_expand_or_child()

------------------------------------------------------------------------

### `TreeView$action_collapse_or_parent()`

Collapse, or go to the parent.

#### Usage

    TreeView$action_collapse_or_parent()

------------------------------------------------------------------------

### `TreeView$action_toggle()`

Toggle the cursor node.

#### Usage

    TreeView$action_toggle()

------------------------------------------------------------------------

### `TreeView$action_activate()`

Toggle and send `"tree.node_activated"`.

#### Usage

    TreeView$action_activate()

------------------------------------------------------------------------

### `TreeView$on_mouse_down()`

Clicking selects; clicking the arrow toggles.

#### Usage

    TreeView$on_mouse_down(event)

#### Arguments

- `event`:

  A `MouseEvent`.

------------------------------------------------------------------------

### `TreeView$on_mouse_scroll()`

The wheel scrolls three lines.

#### Usage

    TreeView$on_mouse_scroll(event)

#### Arguments

- `event`:

  A `MouseEvent`.

------------------------------------------------------------------------

### `TreeView$content_width()`

Natural width: the widest visible line.

#### Usage

    TreeView$content_width()

------------------------------------------------------------------------

### `TreeView$content_height()`

Natural height: visible lines (at most 1000).

#### Usage

    TreeView$content_height(width)

#### Arguments

- `width`:

  Content width.

------------------------------------------------------------------------

### `TreeView$paint()`

Draw the visible lines.

#### Usage

    TreeView$paint(buffer, area, st)

#### Arguments

- `buffer`:

  A
  [ScreenBuffer](https://menshikovs.github.io/termr/reference/ScreenBuffer.md).

- `area`:

  Visible part of the region.

- `st`:

  Computed style.

------------------------------------------------------------------------

### `TreeView$clone()`

The objects of this class are cloneable with this method.

#### Usage

    TreeView$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
