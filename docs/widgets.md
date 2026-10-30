# Widgets

Widgets expose common `id`, `classes`, `style`, `visible` and `disabled`
fields as appropriate; their state fields are reactive, so assigning a new
value repaints the widget.

## Text

| Widget       | Notes                                                                   |
|--------------|-------------------------------------------------------------------------|
| `label(text, wrap = )` | `$update()`, `$text`; text can be `span()`s; `wrap = "word"`/`"char"` |
| `rule(orientation, title)` | horizontal or vertical separator                           |
| `key_value(list(...))` | aligned names and values; `$data`                              |
| `log_view(max_lines, timestamps)` | `$write(..., level =)`, `$clear()`, `$pause()`, `$resume()`; bounded memory |

Styled text: `c(span("CPU "), span("92%", style(foreground = "red", bold = TRUE)))`.
Spans nest and can carry `link =` metadata.

| `markdown_view(text)` | headings, lists, quotes, code, tables, links; `$set_markdown()`, `$links` |
| `process_view(command, args)` | program output with status; see [workers.md](workers.md) |

## Controls

| Widget | Messages (`event$data`) |
|--------|--------------------------|
| `button(label, variant = "primary")` | `button.pressed` (`label`) |
| `input(value, placeholder, password, max_length, validate)` | `input.changed`, `input.submitted` (`value`, `valid`), `input.valid` / `input.invalid` (`value`, `error`) |
| `checkbox(label, value)` | `checkbox.changed` (`value`) |
| `radio_set(radio_button(label, value), ..., selected)` | `radio_set.changed` (`value`, `index`, `label`) |
| `dropdown(choices, value, prompt)` | `dropdown.changed` (`value`, `label`) |
| `option_list(choices)` | `option_list.highlighted`, `option_list.selected` (`index`, `value`, `label`) |

| `text_area(value, line_numbers, wrap, read_only)` | multi-line editor; see [text-area.md](text-area.md); `textarea.changed`, `textarea.selection_changed` |

`input()` and `text_area()` share the validator protocol: `validate =
function(value)` returns `NULL` / `TRUE` (valid), `FALSE` or a message.
`button(on_press = )` takes a callback; `label()`, `button()`,
`progress_bar()`, `metric()`, `sparkline()` and `key_value()` accept a function
that re-evaluates when the [signals](reactivity.md) it reads change.

The data and developer workflow widgets are described in
[data-workflows.md](data-workflows.md), including reactive selection patterns,
profile semantics and lazy JSON expansion.

Input keys: Left/Right/Home/End, Ctrl+Left/Right (words), Shift+... to
select, Ctrl+A select all, Backspace/Delete, Ctrl+Backspace/Ctrl+W and
Ctrl+Delete (words), Ctrl+U/K, Ctrl+C/X/V with the app clipboard.

## Containers

| Widget | Notes |
|--------|-------|
| `vertical(...)`, `horizontal(...)` | stack children |
| `grid_layout(..., columns, rows, gap)` | grid with spans |
| `scroll_view(..., direction)` | `$scroll_to()`, `$scroll_by()`, `$scroll_home()`, `$scroll_end()`, `$scroll_into_view()`; `scroll.changed` |
| `panel(..., title)` | bordered group with a title |
| `split_pane(first, second, direction, ratio)` | draggable divider (mouse or keyboard); `splitpane.resized` |
| `tabs(tab("Label", ...), ...)` | `$activate()`, `$add_tab()`, `$remove_tab()`; `tabs.changed` |

## Data and status

| Widget | Notes |
|--------|-------|
| `data_table(df, ...)` | see [data.md](data.md) |
| `tree_view(tree_node(...))` | lazy `loader =`; `tree.node_selected`, `_expanded`, `_collapsed`, `_activated` |
| `status_bar(left, center, right)` | one-line three-region status display |
| `property_grid(data)` | scrollable, read-only key/value inspector; values wrap |
| `record_view(data)` | named list/vector or one-row data frame via `property_grid()` |
| `data_profile(x)` | R vector summary with a compact numeric distribution |
| `json_view(x)` | collapsible R list/vector tree with paged lazy children |
| `metric(label, value, delta)` | `$update(value, delta)` |
| `sparkline(x)` | `$push(values)` for streams |
| `progress_bar(value, total)` | `NA` for indeterminate; `$advance()` |
| `spinner(label)` | animated by a widget timer |

Three widgets show names and values. Use `key_value()` for a few known
values shown in full, such as a summary panel: it is not focusable, does not
scroll and does not wrap. Use `property_grid()` to inspect many or arbitrary
named values: it is focusable and scrollable, wraps long values, formats
vectors and lists compactly and accepts a `format` function. Use
`record_view()` for exactly one record, such as the selected row of a
`data_table()`; it is `property_grid()` with record input (a one-row data
frame, named list or vector).

## Dynamic trees

Every widget has a reactive `$visible` field. Hide or show a mounted widget
with `widget$visible <- FALSE` or `widget$set(visible = TRUE)`. The initial
`visible` argument is available on `label()`, `vertical()`, `horizontal()`
and `grid_layout()`; custom constructors returned by `widget()` also accept
it. Other convenience constructors keep their own focused arguments, and
their widgets can be hidden immediately after construction through `$visible`.
The argument is appended to the relevant constructor signatures so existing
positional calls keep their meaning. See the
[compact form example](../inst/examples/compact-form.R) for a checkbox that
shows and hides a wrapped label.

```r
container$mount(widget)                    # append
container$mount(widget, before = other)    # or after = , or an index
widget$remove()
container$replace(new1, new2)
container$clear()
```

Mount and unmount events are sent, focus moves on when the focused widget
is removed, and the timers and workers owned by removed widgets stop. Ids
must be unique within a screen.
