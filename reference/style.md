# Widget styles

`style()` describes how a widget looks and how much space it takes. Only
the properties you set are stored, so styles can be layered: a widget's
built-in default style is overridden by the style passed to its
constructor, and state styles (`focus`, `disabled`, ...) are applied on
top while the widget is in that state.

## Usage

``` r
style(
  width = NULL,
  height = NULL,
  min_width = NULL,
  max_width = NULL,
  min_height = NULL,
  max_height = NULL,
  margin = NULL,
  padding = NULL,
  border = NULL,
  border_color = NULL,
  align = NULL,
  valign = NULL,
  wrap = NULL,
  layout = NULL,
  foreground = NULL,
  background = NULL,
  bold = NULL,
  italic = NULL,
  underline = NULL,
  reverse = NULL,
  dim = NULL,
  strike = NULL,
  grid_columns = NULL,
  grid_rows = NULL,
  grid_gap = NULL,
  column_span = NULL,
  row_span = NULL,
  focus = NULL,
  hover = NULL,
  disabled = NULL,
  states = NULL
)
```

## Arguments

- width, height:

  Size, see above.

- min_width, max_width, min_height, max_height:

  Size limits in cells.

- margin, padding:

  Space outside / inside the border. One value (all sides), two values
  (vertical, horizontal) or four values (top, right, bottom, left).

- border:

  Border type: `"none"`, `"ascii"`, `"single"`, `"round"`, `"double"`,
  `"heavy"` or `"blank"`.

- border_color:

  Border colour (defaults to the foreground colour).

- align:

  Horizontal alignment of text, or of children inside a container:
  `"left"`, `"center"` or `"right"`.

- valign:

  Vertical alignment: `"top"`, `"middle"` or `"bottom"`.

- wrap:

  How text that is wider than the widget is wrapped: `"none"` (clip, the
  default), `"word"` or `"char"`. Wrapped text makes `"auto"` heights
  grow.

- layout:

  How a container arranges its children: `"vertical"` or `"horizontal"`.

- foreground, background:

  Text and background colours.

- bold, italic, underline, reverse, dim, strike:

  Text attributes.

- grid_columns, grid_rows:

  Grid tracks for `layout = "grid"`: a number of equal columns, or a
  vector of sizes such as `c("auto", "1fr", 20)`. Rows default to
  `"auto"` and are added as needed.

- grid_gap:

  Space between grid cells: one value, or `c(rows, columns)`.

- column_span, row_span:

  How many grid cells a child occupies.

- focus, hover, disabled:

  Styles applied while the widget has focus, is under the mouse pointer,
  or is disabled.

- states:

  A named list of styles for other widget states, e.g.
  `list(pressed = style(reverse = TRUE))` for buttons.

## Value

An object of class `termr_style`.

## Details

### Sizes

`width` and `height` accept:

- a number: a fixed number of cells;

- `"auto"`: the natural size of the content;

- `"<n>fr"`: a share of the remaining space (e.g. `"1fr"`, `"2fr"`);

- `"<n>%"`: a percentage of the parent's content area.

### Colours

`foreground`, `background` and `border_color` accept ANSI names
(`"red"`, `"bright_blue"`, `"grey"`), integers 0-255 (xterm palette),
hex strings (`"#ff8700"`) and R colour names (`"steelblue"`).

## Examples

``` r
style(width = 20, padding = c(0, 1), border = "round",
      foreground = "white", background = "blue", bold = TRUE,
      focus = style(background = "bright_blue"))
#> <style width = 20, padding = 0 1 0 1, border = "round", foreground = "white", background = "blue", bold = TRUE, focus = <style background = "bright_blue">>
```
