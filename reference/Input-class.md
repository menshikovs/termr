# Input widget

A single-line text input. See
[`input()`](https://menshikovs.github.io/termr/reference/input.md).

## Super class

[`Widget`](https://menshikovs.github.io/termr/reference/Widget-class.md)
-\> `Input`

## Public fields

- `paint_states`:

  Cursor and selection changes only repaint.

- `focusable`:

  Inputs can be focused.

- `placeholder`:

  Text shown while the input is empty.

- `password`:

  Show bullets instead of the characters?

- `max_length`:

  Maximum number of characters, or `NULL`.

- `validate`:

  `NULL` or `function(value)` returning `NULL` (valid) or an error
  message.

## Active bindings

- `value`:

  The text (reactive). Assigning moves the cursor to the end and sends
  `"input.changed"`.

- `cursor_position`:

  Cursor position in characters (0 = start).

- `selection`:

  The selected text (`""` if none).

- `valid`:

  Does the value pass `validate`?

- `error`:

  The validation message, or `NULL`.

## Methods

### Public methods

- [`Input$new()`](#method-Input-initialize)

- [`Input$default_style()`](#method-Input-default_style)

- [`Input$pseudo_states()`](#method-Input-pseudo_states)

- [`Input$default_bindings()`](#method-Input-default_bindings)

- [`Input$on_key()`](#method-Input-on_key)

- [`Input$on_mouse_down()`](#method-Input-on_mouse_down)

- [`Input$on_mouse_move()`](#method-Input-on_mouse_move)

- [`Input$on_paste()`](#method-Input-on_paste)

- [`Input$insert()`](#method-Input-insert)

- [`Input$clear()`](#method-Input-clear)

- [`Input$select_range()`](#method-Input-select_range)

- [`Input$copy()`](#method-Input-copy)

- [`Input$action_cursor_left()`](#method-Input-action_cursor_left)

- [`Input$action_cursor_right()`](#method-Input-action_cursor_right)

- [`Input$action_cursor_home()`](#method-Input-action_cursor_home)

- [`Input$action_cursor_end()`](#method-Input-action_cursor_end)

- [`Input$action_word_left()`](#method-Input-action_word_left)

- [`Input$action_word_right()`](#method-Input-action_word_right)

- [`Input$action_select_left()`](#method-Input-action_select_left)

- [`Input$action_select_right()`](#method-Input-action_select_right)

- [`Input$action_select_home()`](#method-Input-action_select_home)

- [`Input$action_select_end()`](#method-Input-action_select_end)

- [`Input$action_select_word_left()`](#method-Input-action_select_word_left)

- [`Input$action_select_word_right()`](#method-Input-action_select_word_right)

- [`Input$action_select_all()`](#method-Input-action_select_all)

- [`Input$action_delete_left()`](#method-Input-action_delete_left)

- [`Input$action_delete_right()`](#method-Input-action_delete_right)

- [`Input$action_delete_word_left()`](#method-Input-action_delete_word_left)

- [`Input$action_delete_word_right()`](#method-Input-action_delete_word_right)

- [`Input$action_delete_to_start()`](#method-Input-action_delete_to_start)

- [`Input$action_delete_to_end()`](#method-Input-action_delete_to_end)

- [`Input$action_paste()`](#method-Input-action_paste)

- [`Input$action_submit()`](#method-Input-action_submit)

- [`Input$content_width()`](#method-Input-content_width)

- [`Input$render_lines()`](#method-Input-render_lines)

- [`Input$clone()`](#method-Input-clone)

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
- [`Widget$content_height()`](https://menshikovs.github.io/termr/reference/Widget.html#method-content_height)
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

### `Input$new()`

Create an input.

#### Usage

    Input$new(
      value = "",
      placeholder = "",
      id = NULL,
      classes = NULL,
      style = NULL,
      disabled = FALSE,
      password = FALSE,
      max_length = NULL,
      validate = NULL
    )

#### Arguments

- `value`:

  Initial text.

- `placeholder`:

  Placeholder text.

- `id, classes, style, disabled`:

  See
  [Widget](https://menshikovs.github.io/termr/reference/Widget-class.md).

- `password`:

  Mask the characters?

- `max_length`:

  Maximum number of characters.

- `validate`:

  Validation function.

------------------------------------------------------------------------

### `Input$default_style()`

The built-in style.

#### Usage

    Input$default_style()

------------------------------------------------------------------------

### `Input$pseudo_states()`

Active states: focus, hover, disabled and invalid.

#### Usage

    Input$pseudo_states()

------------------------------------------------------------------------

### `Input$default_bindings()`

Editing key bindings.

#### Usage

    Input$default_bindings()

------------------------------------------------------------------------

### `Input$on_key()`

Printable keys replace the selection or are inserted at the cursor.
Ctrl+C / Ctrl+X copy / cut when text is selected (otherwise Ctrl+C keeps
its app meaning).

#### Usage

    Input$on_key(event)

#### Arguments

- `event`:

  A `KeyEvent`.

------------------------------------------------------------------------

### `Input$on_mouse_down()`

Clicking places the cursor; shift+click and dragging select.

#### Usage

    Input$on_mouse_down(event)

#### Arguments

- `event`:

  A `MouseEvent`.

------------------------------------------------------------------------

### `Input$on_mouse_move()`

Dragging with the left button extends the selection.

#### Usage

    Input$on_mouse_move(event)

#### Arguments

- `event`:

  A `MouseEvent`.

------------------------------------------------------------------------

### `Input$on_paste()`

Pasted text is inserted as one edit. An Input is a single line, so line
breaks in the paste become spaces.

#### Usage

    Input$on_paste(event)

#### Arguments

- `event`:

  A `PasteEvent`.

------------------------------------------------------------------------

### `Input$insert()`

Insert text at the cursor (replacing the selection).

#### Usage

    Input$insert(text)

#### Arguments

- `text`:

  A string.

------------------------------------------------------------------------

### `Input$clear()`

Remove all text.

#### Usage

    Input$clear()

------------------------------------------------------------------------

### `Input$select_range()`

Select a range of characters.

#### Usage

    Input$select_range(start, end)

#### Arguments

- `start, end`:

  Positions (0 = before the first character).

------------------------------------------------------------------------

### `Input$copy()`

Copy the selection to the app clipboard (and, when `system = TRUE` and
supported, to the system clipboard via OSC 52).

#### Usage

    Input$copy(system = TRUE)

#### Arguments

- `system`:

  Also write to the system clipboard?

------------------------------------------------------------------------

### `Input$action_cursor_left()`

Move one character left.

#### Usage

    Input$action_cursor_left()

------------------------------------------------------------------------

### `Input$action_cursor_right()`

Move one character right.

#### Usage

    Input$action_cursor_right()

------------------------------------------------------------------------

### `Input$action_cursor_home()`

Move to the start.

#### Usage

    Input$action_cursor_home()

------------------------------------------------------------------------

### `Input$action_cursor_end()`

Move to the end.

#### Usage

    Input$action_cursor_end()

------------------------------------------------------------------------

### `Input$action_word_left()`

Move to the previous word.

#### Usage

    Input$action_word_left()

------------------------------------------------------------------------

### `Input$action_word_right()`

Move to the next word.

#### Usage

    Input$action_word_right()

------------------------------------------------------------------------

### `Input$action_select_left()`

Extend the selection left.

#### Usage

    Input$action_select_left()

------------------------------------------------------------------------

### `Input$action_select_right()`

Extend the selection right.

#### Usage

    Input$action_select_right()

------------------------------------------------------------------------

### `Input$action_select_home()`

Select to the start.

#### Usage

    Input$action_select_home()

------------------------------------------------------------------------

### `Input$action_select_end()`

Select to the end.

#### Usage

    Input$action_select_end()

------------------------------------------------------------------------

### `Input$action_select_word_left()`

Select to the previous word.

#### Usage

    Input$action_select_word_left()

------------------------------------------------------------------------

### `Input$action_select_word_right()`

Select to the next word.

#### Usage

    Input$action_select_word_right()

------------------------------------------------------------------------

### `Input$action_select_all()`

Select everything.

#### Usage

    Input$action_select_all()

------------------------------------------------------------------------

### `Input$action_delete_left()`

Delete the selection or the character before the cursor.

#### Usage

    Input$action_delete_left()

------------------------------------------------------------------------

### `Input$action_delete_right()`

Delete the selection or the character at the cursor.

#### Usage

    Input$action_delete_right()

------------------------------------------------------------------------

### `Input$action_delete_word_left()`

Delete the word before the cursor.

#### Usage

    Input$action_delete_word_left()

------------------------------------------------------------------------

### `Input$action_delete_word_right()`

Delete the word after the cursor.

#### Usage

    Input$action_delete_word_right()

------------------------------------------------------------------------

### `Input$action_delete_to_start()`

Delete everything before the cursor.

#### Usage

    Input$action_delete_to_start()

------------------------------------------------------------------------

### `Input$action_delete_to_end()`

Delete everything after the cursor.

#### Usage

    Input$action_delete_to_end()

------------------------------------------------------------------------

### `Input$action_paste()`

Insert the app clipboard.

#### Usage

    Input$action_paste()

------------------------------------------------------------------------

### `Input$action_submit()`

Send an `"input.submitted"` message (Enter).

#### Usage

    Input$action_submit()

------------------------------------------------------------------------

### `Input$content_width()`

Natural content width.

#### Usage

    Input$content_width()

------------------------------------------------------------------------

### `Input$render_lines()`

The visible part of the text, scrolled so the cursor is visible, with
the cursor drawn in reverse video and the selection highlighted when
focused.

#### Usage

    Input$render_lines(width = NA_integer_)

#### Arguments

- `width`:

  Content width.

------------------------------------------------------------------------

### `Input$clone()`

The objects of this class are cloneable with this method.

#### Usage

    Input$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
