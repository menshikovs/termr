# TextArea widget

A multi-line text editor. See
[`text_area()`](https://menshikovs.github.io/termr/reference/text_area.md).

## Super class

[`Widget`](https://menshikovs.github.io/termr/reference/Widget-class.md)
-\> `TextArea`

## Public fields

- `focusable`:

  Text areas can be focused.

- `placeholder`:

  Text shown while the area is empty.

- `line_numbers`:

  Show a line number gutter?

- `wrap`:

  Wrap long lines (`TRUE`) or scroll horizontally?

- `read_only`:

  Block editing (cursor, selection, copy and search still work)?

- `language`:

  Optional language name passed to the configured highlighter.

- `tab_size`:

  Spaces inserted by Tab (and used for tabs in loaded text).

- `tab_behavior`:

  `"focus"`: Tab moves focus (default, safe in forms); `"indent"`: Tab
  inserts spaces and Shift+Tab removes them.

- `auto_indent`:

  Copy the indentation of the current line on Enter?

- `highlighter`:

  Optional function `(lines, state)` returning a list of per-line data
  frames with 1-based inclusive `start`, `end`, `token`.

- `validate`:

  `NULL` or `function(value)` returning `NULL` (valid) or an error
  message.

## Active bindings

- `value`:

  The text. Assigning replaces it (see `set_text()`).

- `text`:

  The text (read-only alias of `value`).

- `lines`:

  The lines as a character vector.

- `n_lines`:

  Number of lines.

- `cursor_row, cursor_column`:

  Cursor position, 1-based (column 1 is before the first character).

- `selection`:

  The selected text (`""` if none).

- `can_undo, can_redo`:

  Is there something to undo / redo?

- `history_size`:

  Characters held by the undo history.

- `match_count`:

  Number of matches of the current search.

- `find_open`:

  Is the find bar open?

- `valid`:

  Does the value pass `validate`?

- `error`:

  The validation message, or `NULL`.

## Methods

### Public methods

- [`TextArea$new()`](#method-TextArea-initialize)

- [`TextArea$default_style()`](#method-TextArea-default_style)

- [`TextArea$pseudo_states()`](#method-TextArea-pseudo_states)

- [`TextArea$default_bindings()`](#method-TextArea-default_bindings)

- [`TextArea$on_key()`](#method-TextArea-on_key)

- [`TextArea$on_paste()`](#method-TextArea-on_paste)

- [`TextArea$on_mouse_down()`](#method-TextArea-on_mouse_down)

- [`TextArea$on_mouse_move()`](#method-TextArea-on_mouse_move)

- [`TextArea$on_mouse_up()`](#method-TextArea-on_mouse_up)

- [`TextArea$on_mouse_scroll()`](#method-TextArea-on_mouse_scroll)

- [`TextArea$set_text()`](#method-TextArea-set_text)

- [`TextArea$insert()`](#method-TextArea-insert)

- [`TextArea$select_range()`](#method-TextArea-select_range)

- [`TextArea$goto_line()`](#method-TextArea-goto_line)

- [`TextArea$cursor_position()`](#method-TextArea-cursor_position)

- [`TextArea$copy()`](#method-TextArea-copy)

- [`TextArea$cut()`](#method-TextArea-cut)

- [`TextArea$undo()`](#method-TextArea-undo)

- [`TextArea$redo()`](#method-TextArea-redo)

- [`TextArea$find()`](#method-TextArea-find)

- [`TextArea$find_next()`](#method-TextArea-find_next)

- [`TextArea$find_previous()`](#method-TextArea-find_previous)

- [`TextArea$replace()`](#method-TextArea-replace)

- [`TextArea$replace_all()`](#method-TextArea-replace_all)

- [`TextArea$clear_find()`](#method-TextArea-clear_find)

- [`TextArea$action_cursor_left()`](#method-TextArea-action_cursor_left)

- [`TextArea$action_cursor_right()`](#method-TextArea-action_cursor_right)

- [`TextArea$action_cursor_up()`](#method-TextArea-action_cursor_up)

- [`TextArea$action_cursor_down()`](#method-TextArea-action_cursor_down)

- [`TextArea$action_line_start()`](#method-TextArea-action_line_start)

- [`TextArea$action_line_end()`](#method-TextArea-action_line_end)

- [`TextArea$action_document_start()`](#method-TextArea-action_document_start)

- [`TextArea$action_document_end()`](#method-TextArea-action_document_end)

- [`TextArea$action_word_left()`](#method-TextArea-action_word_left)

- [`TextArea$action_word_right()`](#method-TextArea-action_word_right)

- [`TextArea$action_page_up()`](#method-TextArea-action_page_up)

- [`TextArea$action_page_down()`](#method-TextArea-action_page_down)

- [`TextArea$action_select_left()`](#method-TextArea-action_select_left)

- [`TextArea$action_select_right()`](#method-TextArea-action_select_right)

- [`TextArea$action_select_up()`](#method-TextArea-action_select_up)

- [`TextArea$action_select_down()`](#method-TextArea-action_select_down)

- [`TextArea$action_select_line_start()`](#method-TextArea-action_select_line_start)

- [`TextArea$action_select_line_end()`](#method-TextArea-action_select_line_end)

- [`TextArea$action_select_document_start()`](#method-TextArea-action_select_document_start)

- [`TextArea$action_select_document_end()`](#method-TextArea-action_select_document_end)

- [`TextArea$action_select_word_left()`](#method-TextArea-action_select_word_left)

- [`TextArea$action_select_word_right()`](#method-TextArea-action_select_word_right)

- [`TextArea$action_select_page_up()`](#method-TextArea-action_select_page_up)

- [`TextArea$action_select_page_down()`](#method-TextArea-action_select_page_down)

- [`TextArea$action_select_all()`](#method-TextArea-action_select_all)

- [`TextArea$action_newline()`](#method-TextArea-action_newline)

- [`TextArea$action_delete_left()`](#method-TextArea-action_delete_left)

- [`TextArea$action_delete_right()`](#method-TextArea-action_delete_right)

- [`TextArea$action_delete_word_left()`](#method-TextArea-action_delete_word_left)

- [`TextArea$action_delete_word_right()`](#method-TextArea-action_delete_word_right)

- [`TextArea$action_delete_to_line_start()`](#method-TextArea-action_delete_to_line_start)

- [`TextArea$action_delete_to_line_end()`](#method-TextArea-action_delete_to_line_end)

- [`TextArea$action_paste()`](#method-TextArea-action_paste)

- [`TextArea$action_indent()`](#method-TextArea-action_indent)

- [`TextArea$action_dedent()`](#method-TextArea-action_dedent)

- [`TextArea$action_undo()`](#method-TextArea-action_undo)

- [`TextArea$action_redo()`](#method-TextArea-action_redo)

- [`TextArea$action_open_find()`](#method-TextArea-action_open_find)

- [`TextArea$action_find_next()`](#method-TextArea-action_find_next)

- [`TextArea$action_find_previous()`](#method-TextArea-action_find_previous)

- [`TextArea$action_open_replace()`](#method-TextArea-action_open_replace)

- [`TextArea$action_open_goto()`](#method-TextArea-action_open_goto)

- [`TextArea$content_width()`](#method-TextArea-content_width)

- [`TextArea$content_height()`](#method-TextArea-content_height)

- [`TextArea$paint()`](#method-TextArea-paint)

- [`TextArea$clone()`](#method-TextArea-clone)

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
- [`Widget$query()`](https://menshikovs.github.io/termr/reference/Widget.html#method-query)
- [`Widget$query_one()`](https://menshikovs.github.io/termr/reference/Widget.html#method-query_one)
- [`Widget$refresh()`](https://menshikovs.github.io/termr/reference/Widget.html#method-refresh)
- [`Widget$release_mouse()`](https://menshikovs.github.io/termr/reference/Widget.html#method-release_mouse)
- [`Widget$remove()`](https://menshikovs.github.io/termr/reference/Widget.html#method-remove)
- [`Widget$remove_children()`](https://menshikovs.github.io/termr/reference/Widget.html#method-remove_children)
- [`Widget$remove_class()`](https://menshikovs.github.io/termr/reference/Widget.html#method-remove_class)
- [`Widget$render()`](https://menshikovs.github.io/termr/reference/Widget.html#method-render)
- [`Widget$render_lines()`](https://menshikovs.github.io/termr/reference/Widget.html#method-render_lines)
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

### `TextArea$new()`

Create a text area.

#### Usage

    TextArea$new(
      value = "",
      placeholder = "",
      id = NULL,
      classes = NULL,
      style = NULL,
      disabled = FALSE,
      line_numbers = FALSE,
      wrap = TRUE,
      read_only = FALSE,
      language = NULL,
      tab_size = 4L,
      tab_behavior = "focus",
      auto_indent = FALSE,
      validate = NULL,
      max_history = 200L,
      highlighter = NULL
    )

#### Arguments

- `value`:

  Initial text.

- `placeholder`:

  Placeholder text.

- `id, classes, style, disabled`:

  See
  [Widget](https://menshikovs.github.io/termr/reference/Widget-class.md).

- `line_numbers, wrap, read_only, language, tab_size, tab_behavior, auto_indent`:

  See the fields.

- `validate`:

  Validation function.

- `max_history`:

  Maximum number of undo steps.

- `highlighter`:

  Optional function `(lines, state)` returning a list of per-line data
  frames with 1-based inclusive `start`, `end`, `token`.

------------------------------------------------------------------------

### `TextArea$default_style()`

The built-in style.

#### Usage

    TextArea$default_style()

------------------------------------------------------------------------

### `TextArea$pseudo_states()`

Active states: focus, hover, disabled and invalid.

#### Usage

    TextArea$pseudo_states()

------------------------------------------------------------------------

### `TextArea$default_bindings()`

Editing key bindings.

#### Usage

    TextArea$default_bindings()

------------------------------------------------------------------------

### `TextArea$on_key()`

Printable keys replace the selection or are inserted at the cursor;
Ctrl+C / Ctrl+X copy / cut a selection. While the find bar is open, keys
edit the search text.

#### Usage

    TextArea$on_key(event)

#### Arguments

- `event`:

  A `KeyEvent`.

------------------------------------------------------------------------

### `TextArea$on_paste()`

Pasted text is inserted as one undo step; line breaks are kept.

#### Usage

    TextArea$on_paste(event)

#### Arguments

- `event`:

  A `PasteEvent`.

------------------------------------------------------------------------

### `TextArea$on_mouse_down()`

Click to place the cursor, shift+click and drag to select.

#### Usage

    TextArea$on_mouse_down(event)

#### Arguments

- `event`:

  A `MouseEvent`.

------------------------------------------------------------------------

### `TextArea$on_mouse_move()`

Dragging with the left button extends the selection.

#### Usage

    TextArea$on_mouse_move(event)

#### Arguments

- `event`:

  A `MouseEvent`.

------------------------------------------------------------------------

### `TextArea$on_mouse_up()`

Ends a drag selection.

#### Usage

    TextArea$on_mouse_up(event)

#### Arguments

- `event`:

  A `MouseEvent`.

------------------------------------------------------------------------

### `TextArea$on_mouse_scroll()`

The mouse wheel scrolls three rows.

#### Usage

    TextArea$on_mouse_scroll(event)

#### Arguments

- `event`:

  A `MouseEvent`.

------------------------------------------------------------------------

### `TextArea$set_text()`

Replace the whole text. Clears the undo history and moves the cursor to
the start.

#### Usage

    TextArea$set_text(text)

#### Arguments

- `text`:

  A string (or character vector of lines).

------------------------------------------------------------------------

### `TextArea$insert()`

Insert text at the cursor, replacing the selection.

#### Usage

    TextArea$insert(text, kind = NULL)

#### Arguments

- `text`:

  A string; line breaks are kept.

- `kind`:

  Internal: `"type"` merges into undo groups, `"paste"` does not.

------------------------------------------------------------------------

### `TextArea$select_range()`

Select a range (1-based rows and columns; column 1 is before the first
character).

#### Usage

    TextArea$select_range(start_row, start_column, end_row, end_column)

#### Arguments

- `start_row, start_column, end_row, end_column`:

  The range.

------------------------------------------------------------------------

### `TextArea$goto_line()`

Move the cursor to a line.

#### Usage

    TextArea$goto_line(row, column = 1L)

#### Arguments

- `row`:

  Line number (1-based).

- `column`:

  Column (1-based).

------------------------------------------------------------------------

### `TextArea$cursor_position()`

Cursor position. Columns count grapheme clusters and terminal display
cells, both 1-based.

#### Usage

    TextArea$cursor_position()

------------------------------------------------------------------------

### `TextArea$copy()`

Copy the selection to the app clipboard (and the system clipboard via
OSC 52 when `system = TRUE` and supported).

#### Usage

    TextArea$copy(system = TRUE)

#### Arguments

- `system`:

  Also write to the system clipboard?

------------------------------------------------------------------------

### `TextArea$cut()`

Copy the selection and delete it.

#### Usage

    TextArea$cut(system = TRUE)

#### Arguments

- `system`:

  Also write to the system clipboard?

------------------------------------------------------------------------

### `TextArea$undo()`

Undo the last edit group.

#### Usage

    TextArea$undo()

------------------------------------------------------------------------

### `TextArea$redo()`

Redo the last undone edit.

#### Usage

    TextArea$redo()

------------------------------------------------------------------------

### `TextArea$find()`

Search for text and select the first match at or after the cursor.

#### Usage

    TextArea$find(query, case_sensitive = FALSE, regex = FALSE)

#### Arguments

- `query`:

  Text or regular expression (PCRE).

- `case_sensitive`:

  Match case?

- `regex`:

  Is `query` a regular expression? Invalid expressions raise an error.

#### Returns

`TRUE` if there is a match (invisibly).

------------------------------------------------------------------------

### `TextArea$find_next()`

Select the next match (wrapping around).

#### Usage

    TextArea$find_next()

------------------------------------------------------------------------

### `TextArea$find_previous()`

Select the previous match (wrapping around).

#### Usage

    TextArea$find_previous()

------------------------------------------------------------------------

### `TextArea$replace()`

Replace the current search match, or find `query` and replace its next
match.

#### Usage

    TextArea$replace(
      replacement,
      query = NULL,
      case_sensitive = FALSE,
      regex = FALSE
    )

#### Arguments

- `replacement`:

  Replacement text.

- `query`:

  Optional search text; defaults to the active search.

- `case_sensitive, regex`:

  Search options used when `query` is given.

------------------------------------------------------------------------

### `TextArea$replace_all()`

Replace all matches in one document edit. If the edit is larger than the
bounded undo budget, it is applied without retaining an undo record.

#### Usage

    TextArea$replace_all(query, replacement, case_sensitive = FALSE, regex = FALSE)

#### Arguments

- `query`:

  Search text or regular expression.

- `replacement`:

  Replacement text.

- `case_sensitive`:

  Match case?

- `regex`:

  Interpret `query` as a regular expression?

------------------------------------------------------------------------

### `TextArea$clear_find()`

Remove the search highlights and close the find bar.

#### Usage

    TextArea$clear_find()

------------------------------------------------------------------------

### `TextArea$action_cursor_left()`

Move one character left.

#### Usage

    TextArea$action_cursor_left()

------------------------------------------------------------------------

### `TextArea$action_cursor_right()`

Move one character right.

#### Usage

    TextArea$action_cursor_right()

------------------------------------------------------------------------

### `TextArea$action_cursor_up()`

Move one row up.

#### Usage

    TextArea$action_cursor_up()

------------------------------------------------------------------------

### `TextArea$action_cursor_down()`

Move one row down.

#### Usage

    TextArea$action_cursor_down()

------------------------------------------------------------------------

### `TextArea$action_line_start()`

Move to the start of the line.

#### Usage

    TextArea$action_line_start()

------------------------------------------------------------------------

### `TextArea$action_line_end()`

Move to the end of the line.

#### Usage

    TextArea$action_line_end()

------------------------------------------------------------------------

### `TextArea$action_document_start()`

Move to the start of the text.

#### Usage

    TextArea$action_document_start()

------------------------------------------------------------------------

### `TextArea$action_document_end()`

Move to the end of the text.

#### Usage

    TextArea$action_document_end()

------------------------------------------------------------------------

### `TextArea$action_word_left()`

Move to the previous word.

#### Usage

    TextArea$action_word_left()

------------------------------------------------------------------------

### `TextArea$action_word_right()`

Move to the next word.

#### Usage

    TextArea$action_word_right()

------------------------------------------------------------------------

### `TextArea$action_page_up()`

Move one page up.

#### Usage

    TextArea$action_page_up()

------------------------------------------------------------------------

### `TextArea$action_page_down()`

Move one page down.

#### Usage

    TextArea$action_page_down()

------------------------------------------------------------------------

### `TextArea$action_select_left()`

Extend the selection left.

#### Usage

    TextArea$action_select_left()

------------------------------------------------------------------------

### `TextArea$action_select_right()`

Extend the selection right.

#### Usage

    TextArea$action_select_right()

------------------------------------------------------------------------

### `TextArea$action_select_up()`

Extend the selection up.

#### Usage

    TextArea$action_select_up()

------------------------------------------------------------------------

### `TextArea$action_select_down()`

Extend the selection down.

#### Usage

    TextArea$action_select_down()

------------------------------------------------------------------------

### `TextArea$action_select_line_start()`

Select to the start of the line.

#### Usage

    TextArea$action_select_line_start()

------------------------------------------------------------------------

### `TextArea$action_select_line_end()`

Select to the end of the line.

#### Usage

    TextArea$action_select_line_end()

------------------------------------------------------------------------

### `TextArea$action_select_document_start()`

Select to the start of the text.

#### Usage

    TextArea$action_select_document_start()

------------------------------------------------------------------------

### `TextArea$action_select_document_end()`

Select to the end of the text.

#### Usage

    TextArea$action_select_document_end()

------------------------------------------------------------------------

### `TextArea$action_select_word_left()`

Select to the previous word.

#### Usage

    TextArea$action_select_word_left()

------------------------------------------------------------------------

### `TextArea$action_select_word_right()`

Select to the next word.

#### Usage

    TextArea$action_select_word_right()

------------------------------------------------------------------------

### `TextArea$action_select_page_up()`

Extend the selection one page up.

#### Usage

    TextArea$action_select_page_up()

------------------------------------------------------------------------

### `TextArea$action_select_page_down()`

Extend the selection one page down.

#### Usage

    TextArea$action_select_page_down()

------------------------------------------------------------------------

### `TextArea$action_select_all()`

Select everything.

#### Usage

    TextArea$action_select_all()

------------------------------------------------------------------------

### `TextArea$action_newline()`

Insert a line break (keeping the indentation when `auto_indent` is on).

#### Usage

    TextArea$action_newline()

------------------------------------------------------------------------

### `TextArea$action_delete_left()`

Delete the selection or the character before the cursor.

#### Usage

    TextArea$action_delete_left()

------------------------------------------------------------------------

### `TextArea$action_delete_right()`

Delete the selection or the character at the cursor.

#### Usage

    TextArea$action_delete_right()

------------------------------------------------------------------------

### `TextArea$action_delete_word_left()`

Delete the word before the cursor.

#### Usage

    TextArea$action_delete_word_left()

------------------------------------------------------------------------

### `TextArea$action_delete_word_right()`

Delete the word after the cursor.

#### Usage

    TextArea$action_delete_word_right()

------------------------------------------------------------------------

### `TextArea$action_delete_to_line_start()`

Delete from the start of the line to the cursor.

#### Usage

    TextArea$action_delete_to_line_start()

------------------------------------------------------------------------

### `TextArea$action_delete_to_line_end()`

Delete from the cursor to the end of the line (or the line break when
the cursor is at the end).

#### Usage

    TextArea$action_delete_to_line_end()

------------------------------------------------------------------------

### `TextArea$action_paste()`

Insert the app clipboard.

#### Usage

    TextArea$action_paste()

------------------------------------------------------------------------

### `TextArea$action_indent()`

Insert spaces up to the next tab stop (or indent the selected lines).

#### Usage

    TextArea$action_indent()

------------------------------------------------------------------------

### `TextArea$action_dedent()`

Remove up to one tab stop of leading spaces.

#### Usage

    TextArea$action_dedent()

------------------------------------------------------------------------

### `TextArea$action_undo()`

Undo.

#### Usage

    TextArea$action_undo()

------------------------------------------------------------------------

### `TextArea$action_redo()`

Redo.

#### Usage

    TextArea$action_redo()

------------------------------------------------------------------------

### `TextArea$action_open_find()`

Open the find bar (Ctrl+F).

#### Usage

    TextArea$action_open_find()

------------------------------------------------------------------------

### `TextArea$action_find_next()`

Select the next match (F3).

#### Usage

    TextArea$action_find_next()

------------------------------------------------------------------------

### `TextArea$action_find_previous()`

Select the previous match (Shift+F3).

#### Usage

    TextArea$action_find_previous()

------------------------------------------------------------------------

### `TextArea$action_open_replace()`

Open the find and replace bar (Ctrl+H).

#### Usage

    TextArea$action_open_replace()

------------------------------------------------------------------------

### `TextArea$action_open_goto()`

Open the go-to-line bar (Ctrl+G).

#### Usage

    TextArea$action_open_goto()

------------------------------------------------------------------------

### `TextArea$content_width()`

Natural width: the longest line (at most 120 columns).

#### Usage

    TextArea$content_width()

------------------------------------------------------------------------

### `TextArea$content_height()`

Natural height: the number of lines (at most 1000).

#### Usage

    TextArea$content_height(width)

#### Arguments

- `width`:

  Content width.

------------------------------------------------------------------------

### `TextArea$paint()`

Draw the visible part of the text.

#### Usage

    TextArea$paint(buffer, area, st)

#### Arguments

- `buffer`:

  A
  [ScreenBuffer](https://menshikovs.github.io/termr/reference/ScreenBuffer.md).

- `area`:

  Visible part of the region.

- `st`:

  Computed style.

------------------------------------------------------------------------

### `TextArea$clone()`

The objects of this class are cloneable with this method.

#### Usage

    TextArea$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
