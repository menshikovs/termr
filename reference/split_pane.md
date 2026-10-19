# Split pane

Two panes separated by a divider the user can drag with the mouse (press
on the divider, move, release) or move with the keyboard (focus the
divider with Tab; arrows move it, Shift+arrows ten cells, Home / End to
the ends). Typical uses: a tree next to a preview, a table above a
detail view, an editor above its output.

## Usage

``` r
split_pane(
  first,
  second,
  direction = "horizontal",
  ratio = 0.5,
  min_size = 3L,
  id = NULL,
  classes = NULL,
  style = NULL
)
```

## Arguments

- first, second:

  The two panes.

- direction:

  `"horizontal"`: panes side by side, divider vertical; `"vertical"`:
  stacked panes.

- ratio:

  Share of the first pane, between 0 and 1.

- min_size:

  Smallest pane size in cells.

- id:

  Optional identifier.

- classes:

  Optional classes.

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md).

## Value

A `SplitPane` widget with `$ratio` and `$sizes`.

## Details

The panes fill their share of the space regardless of their own size
styles. `ratio` is the share of the first pane; `min_size` keeps both
panes from collapsing. The pane sends `"splitpane.resized"` (`ratio`)
when the user finishes moving the divider. **Experimental.**

## Examples

``` r
ui <- split_pane(label("left"), label("right"), ratio = 0.4)
render_widget(ui, 20, 2)$to_text()
#> [1] "left    │right      " "        │           "
```
