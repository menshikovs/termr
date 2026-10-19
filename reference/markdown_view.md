# Markdown view

Shows Markdown text: headings, paragraphs, **bold**, *italic*,
\~~strikethrough\~~, `inline code`, fenced code blocks, bullet and
numbered lists, block quotes, horizontal rules, simple pipe tables and
links. It is meant for help screens, release notes and dialogs; there is
no HTML and the parser is not CommonMark-complete. Text is wrapped to
the width of the view.

## Usage

``` r
markdown_view(text, id = NULL, classes = NULL, style = NULL, scroll = TRUE)
```

## Arguments

- text:

  Markdown source (a character vector is joined with newlines).

- id:

  Optional identifier.

- classes:

  Optional classes.

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md).

- scroll:

  Wrap the view in a scrollable container?

## Value

A
[`scroll_view()`](https://menshikovs.github.io/termr/reference/scroll_view.md)
containing a `MarkdownView` (or the `MarkdownView` itself with
`scroll = FALSE`). Change the text with `$set_markdown()`; the
`MarkdownView` is the first child of the scroll view.

## Details

With `scroll = TRUE` (the default) the view is placed in a
[`scroll_view()`](https://menshikovs.github.io/termr/reference/scroll_view.md)
that fills its parent; use `scroll = FALSE` for short text inside your
own layout.

## Examples

``` r
md <- markdown_view("# Title\n\nSome *emphasis* and `code`.\n\n- one\n- two",
                    scroll = FALSE)
render_widget(md, 40, 8)$to_text()
#> [1] "Title                                   "
#> [2] "════════════════════════════════════════"
#> [3] "                                        "
#> [4] "Some emphasis and code.                 "
#> [5] "                                        "
#> [6] "• one                                   "
#> [7] "• two                                   "
#> [8] "                                        "
```
