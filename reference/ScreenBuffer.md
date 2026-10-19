# Virtual screen (framebuffer)

A `ScreenBuffer` is an in-memory grid of terminal cells. Widgets are
painted into a buffer, buffers are compared with
[`diff_screen()`](https://menshikovs.github.io/termr/reference/diff_screen.md)
and only the differences are sent to the terminal.

Cells are stored in four `height x width` matrices (`chars`, `fg`, `bg`,
`attrs`) indexed as `[row, column]`. A wide character occupies two
columns: the first holds the character, the second holds `""` (a
continuation cell). All writes keep this invariant, so a wide character
is never left half-overwritten.

Use
[`screen_buffer()`](https://menshikovs.github.io/termr/reference/screen_buffer.md)
to create one.

## Public fields

- `width`:

  Number of columns.

- `height`:

  Number of rows.

- `chars`:

  Character matrix of cell contents.

- `fg`:

  Character matrix of canonical foreground colours.

- `bg`:

  Character matrix of canonical background colours.

- `attrs`:

  Integer matrix of attribute bit masks.

## Methods

### Public methods

- [`ScreenBuffer$new()`](#method-ScreenBuffer-initialize)

- [`ScreenBuffer$clear()`](#method-ScreenBuffer-clear)

- [`ScreenBuffer$bounds()`](#method-ScreenBuffer-bounds)

- [`ScreenBuffer$get_cell()`](#method-ScreenBuffer-get_cell)

- [`ScreenBuffer$set_cell()`](#method-ScreenBuffer-set_cell)

- [`ScreenBuffer$fill()`](#method-ScreenBuffer-fill)

- [`ScreenBuffer$paint_background()`](#method-ScreenBuffer-paint_background)

- [`ScreenBuffer$put_text()`](#method-ScreenBuffer-put_text)

- [`ScreenBuffer$resize()`](#method-ScreenBuffer-resize)

- [`ScreenBuffer$copy()`](#method-ScreenBuffer-copy)

- [`ScreenBuffer$equals()`](#method-ScreenBuffer-equals)

- [`ScreenBuffer$to_text()`](#method-ScreenBuffer-to_text)

- [`ScreenBuffer$print()`](#method-ScreenBuffer-print)

- [`ScreenBuffer$clone()`](#method-ScreenBuffer-clone)

------------------------------------------------------------------------

### `ScreenBuffer$new()`

Create a blank buffer.

#### Usage

    ScreenBuffer$new(width, height)

#### Arguments

- `width, height`:

  Size in cells.

------------------------------------------------------------------------

### `ScreenBuffer$clear()`

Reset every cell to a blank default cell.

#### Usage

    ScreenBuffer$clear()

------------------------------------------------------------------------

### `ScreenBuffer$bounds()`

The full-buffer rectangle.

#### Usage

    ScreenBuffer$bounds()

------------------------------------------------------------------------

### `ScreenBuffer$get_cell()`

Read one cell.

#### Usage

    ScreenBuffer$get_cell(x, y)

#### Arguments

- `x, y`:

  Column and row.

------------------------------------------------------------------------

### `ScreenBuffer$set_cell()`

Write one cell (see
[`cell()`](https://menshikovs.github.io/termr/reference/cell.md)).

#### Usage

    ScreenBuffer$set_cell(x, y, cell)

#### Arguments

- `x, y`:

  Column and row.

- `cell`:

  A `termr_cell`.

------------------------------------------------------------------------

### `ScreenBuffer$fill()`

Fill a region with one character and style.

#### Usage

    ScreenBuffer$fill(region = NULL, char = " ", fg = NULL, bg = NULL, attrs = 0L)

#### Arguments

- `region`:

  A
  [`region()`](https://menshikovs.github.io/termr/reference/region.md);
  defaults to the whole buffer.

- `char`:

  A single-width character.

- `fg, bg`:

  Colours (see
  [`style()`](https://menshikovs.github.io/termr/reference/style.md)).

- `attrs`:

  Attribute bit mask.

------------------------------------------------------------------------

### `ScreenBuffer$paint_background()`

Set only the background colour of a region.

#### Usage

    ScreenBuffer$paint_background(region, bg)

#### Arguments

- `region`:

  A
  [`region()`](https://menshikovs.github.io/termr/reference/region.md).

- `bg`:

  Colour.

------------------------------------------------------------------------

### `ScreenBuffer$put_text()`

Write a single line of text.

Text is clipped to `clip` (and to the buffer). A wide character that
would straddle the clip edge is replaced by a space. Control characters
are removed.

#### Usage

    ScreenBuffer$put_text(
      x,
      y,
      text,
      fg = NULL,
      bg = NULL,
      attrs = 0L,
      clip = NULL
    )

#### Arguments

- `x, y`:

  Column and row of the first character.

- `text`:

  A single string (no newlines).

- `fg`:

  Foreground colour.

- `bg`:

  Background colour. `NULL` keeps the existing background, so text can
  be drawn over a painted widget background.

- `attrs`:

  Attribute bit mask.

- `clip`:

  Optional clipping
  [`region()`](https://menshikovs.github.io/termr/reference/region.md).

#### Returns

The column after the last character, invisibly.

------------------------------------------------------------------------

### `ScreenBuffer$resize()`

Change the buffer size, keeping the top-left content.

#### Usage

    ScreenBuffer$resize(width, height)

#### Arguments

- `width, height`:

  New size.

------------------------------------------------------------------------

### `ScreenBuffer$copy()`

An independent copy of the buffer.

#### Usage

    ScreenBuffer$copy()

------------------------------------------------------------------------

### `ScreenBuffer$equals()`

Do two buffers hold exactly the same cells?

#### Usage

    ScreenBuffer$equals(other)

#### Arguments

- `other`:

  Another `ScreenBuffer`.

------------------------------------------------------------------------

### `ScreenBuffer$to_text()`

The buffer as plain text, one string per row.

#### Usage

    ScreenBuffer$to_text()

------------------------------------------------------------------------

### `ScreenBuffer$print()`

Print the buffer contents framed by a border.

#### Usage

    ScreenBuffer$print(...)

#### Arguments

- `...`:

  Ignored.

------------------------------------------------------------------------

### `ScreenBuffer$clone()`

The objects of this class are cloneable with this method.

#### Usage

    ScreenBuffer$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
