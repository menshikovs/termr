# Single-line text input

A focusable text field.

## Usage

``` r
input(
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
```

## Arguments

- value:

  Initial text.

- placeholder:

  Text shown while the input is empty.

- id:

  Optional identifier (for `#id` selectors).

- classes:

  Optional classes (for `.class` selectors).

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md).

- disabled:

  Disabled inputs cannot be focused or edited.

- password:

  Show bullets instead of the typed characters.

- max_length:

  Maximum number of characters.

- validate:

  Optional `function(value)` returning `NULL` (or `TRUE`) when the value
  is valid, or an error message.

## Value

An `Input` widget. Read or set the text with `$value`; see also
`$valid`, `$error`, `$selection`, `$select_range()`.

## Details

Keys: typing inserts at the cursor (replacing a selection);
Left/Right/Home/End move (Ctrl+E: end); Ctrl+Left/Right move by word;
Shift (+Ctrl) with those keys selects; Ctrl+A selects all;
Backspace/Delete delete a character or the selection; Ctrl+Backspace /
Alt+Backspace / Ctrl+W and Ctrl+Delete / Alt+D delete a word; Ctrl+U /
Ctrl+K delete to the start / end; Ctrl+C, Ctrl+X and Ctrl+V copy, cut
and paste with the app clipboard (`app$clipboard`; Ctrl+C without a
selection keeps its app meaning, quit by default). The mouse places the
cursor; shift+click and dragging select.

Messages (`event$data`): `"input.changed"` (`value`, `valid`) on every
change, `"input.submitted"` (`value`, `valid`) on Enter, and
`"input.valid"` / `"input.invalid"` (`value`, `error`) when the result
of `validate` changes. Invalid inputs have the `:invalid` state (red
border by default).

## Examples

``` r
name <- input(placeholder = "Your name", id = "name",
              validate = function(x) if (!nzchar(x)) "Required")
name$valid
#> [1] FALSE
name$value <- "Ada"
name$valid
#> [1] TRUE
```
