# Multi-line text editor

An editable text area with a cursor, selection, undo/redo, search and
scrolling. Text is stored as a vector of lines and edited by logical
(row, grapheme) positions, so emoji, accents and CJK text are never
split, and only the visible lines are formatted when drawing.

## Usage

``` r
text_area(
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
```

## Arguments

- value:

  Initial text.

- placeholder:

  Text shown while the area is empty.

- id:

  Optional identifier.

- classes:

  Optional classes.

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md).

- disabled:

  Disabled areas cannot be focused or edited.

- line_numbers:

  Show line numbers?

- wrap:

  Wrap long lines? If `FALSE` the view scrolls horizontally.

- read_only:

  Block editing?

- language:

  Optional language label supplied to the highlighter.

- tab_size:

  Spaces per tab stop.

- tab_behavior:

  `"focus"` (Tab moves focus) or `"indent"`.

- auto_indent:

  Keep the indentation on Enter?

- validate:

  Optional `function(value)` returning `NULL`/`TRUE` when valid or a
  message.

- max_history:

  Maximum number of undo steps.

- highlighter:

  Optional viewport-first syntax highlighter; see
  [`r_highlighter()`](https://menshikovs.github.io/termr/reference/r_highlighter.md).

## Value

A `TextArea` widget. Useful members: `$value`, `$set_text()`,
`$insert()`, `$selection`, `$cursor_row`, `$cursor_column`,
`$goto_line()`, `$cursor_position()`, `$undo()`, `$redo()`, `$find()`,
`$replace()`, `$replace_all()`, `$find_next()`, `$find_previous()`,
`$match_count`.

## Details

Keys: arrows, Home/End, Ctrl+Home/End, Ctrl+Left/Right (words),
PageUp/PageDown, Shift+ to select, Ctrl+A select all, Enter, Backspace,
Delete, Ctrl+Backspace / Ctrl+Delete (words), Ctrl+U / Ctrl+K (to line
start / end), Ctrl+C / Ctrl+X / Ctrl+V (copy, cut, paste with the app
clipboard; copy also reaches the system clipboard via OSC 52 when the
terminal supports it), Ctrl+Z undo, Ctrl+Y redo, Ctrl+F find (Enter /
Down next, Up previous, Ctrl+R regex, Alt+C case, Esc close), F3 /
Shift+F3 next / previous match. Tab moves focus unless
`tab_behavior = "indent"`. The mouse places the cursor, drags select and
the wheel scrolls. A bracketed paste is one undo step.

Messages (`event$data`): `"textarea.changed"` (`version`, `lines`,
`valid`; read the text with `$value`), `"textarea.selection_changed"`
(`empty`, `start_row`, `start_column`, `end_row`, `end_column`) and
`"textarea.valid"` / `"textarea.invalid"` (`error`).

Editing groups: typing is merged into undo steps per word, paste,
delete-selection and line operations are single steps. The history is
bounded (`max_history` steps and about 2 million characters). Tabs in
text are expanded to spaces. This widget is **experimental**.

## Examples

``` r
ed <- text_area("Hello\nworld", id = "editor", line_numbers = TRUE)
ed$insert("!")
ed$value
#> [1] "!Hello\nworld"
ed$find("wor")
ed$selection
#> [1] "wor"
```
