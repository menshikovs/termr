# Tabs

`tabs()` shows one of several panes, with a tab bar on top. Only the
active pane is laid out, painted and part of the focus chain. Switch
tabs by clicking a label, with Left/Right while the tab bar has focus,
or with Ctrl+PageUp / Ctrl+PageDown from anywhere inside. Switching
sends a `"tabs.changed"` message (`event$data`: `index`, `previous`,
`id`, `label`).

## Usage

``` r
tabs(..., active = 1L, id = NULL, classes = NULL, style = NULL)

tab(label, ..., id = NULL, classes = NULL, style = NULL)
```

## Arguments

- ...:

  `tab()` panes.

- active:

  Index or id of the initially active tab.

- id:

  Optional identifier.

- classes:

  Optional classes.

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md).

- label:

  Tab label.

## Value

A `Tabs` widget with methods `activate()`, `add_tab()`, `remove_tab()`
and fields `active`, `active_tab`, `tab_count`.

## Examples

``` r
ui <- tabs(
  tab("Overview", label("Summary")),
  tab("Logs", label("No logs yet"), id = "logs")
)
render_widget(ui, 30, 4)
#> <ScreenBuffer 30x4>
#> +------------------------------+
#> | Overview   Logs              |
#> |━━━━━━━━━━────────────────────|
#> |Summary                       |
#> |                              |
#> +------------------------------+
```
