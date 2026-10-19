# Scrollable container

Shows content that is larger than the available space. The content is
laid out at its natural size and the visible part (the viewport) is
shifted by the scroll offsets; everything outside is clipped. Scroll
bars appear when the content overflows.

## Usage

``` r
scroll_view(
  ...,
  direction = "vertical",
  scrollbars = TRUE,
  focusable = TRUE,
  id = NULL,
  classes = NULL,
  style = NULL
)
```

## Arguments

- ...:

  Child widgets.

- direction:

  `"vertical"` (default), `"horizontal"` or `"both"`.

- scrollbars:

  Draw scroll bars when the content overflows?

- focusable:

  Can the scroll view take focus itself?

- id:

  Optional identifier.

- classes:

  Optional classes.

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md);
  by default the view fills its parent.

## Value

A `ScrollView` widget with methods `scroll_to(x, y)`,
`scroll_by(dx, dy)`, `scroll_home()`, `scroll_end()` and
`scroll_into_view(widget)`, and fields `offset_x`, `offset_y`,
`viewport`, `virtual_size` and `max_scroll`.

## Details

Keys (when the scroll view or an unfocusable descendant has focus, or a
focused child does not use the key itself): arrows scroll by one cell,
Page Up / Page Down by a page, Home / End to the start / end. When focus
moves to a widget inside a scroll view, the view scrolls to reveal it.
Offset changes send a `"scroll.changed"` message.

## Examples

``` r
items <- lapply(1:100, function(i) label(paste("Item", i)))
view <- scroll_view(items, id = "list")
view$scroll_to(y = 50)
```
