# Tree view

Shows a
[`tree_node()`](https://menshikovs.github.io/termr/reference/tree_node.md)
hierarchy with expand/collapse arrows and guide lines. Only visible
lines are painted, and children can be loaded lazily.

## Usage

``` r
tree_view(
  root,
  show_root = TRUE,
  guides = TRUE,
  id = NULL,
  classes = NULL,
  style = NULL
)
```

## Arguments

- root:

  The root
  [`tree_node()`](https://menshikovs.github.io/termr/reference/tree_node.md).

- show_root:

  Show the root itself (otherwise its children are the top level and it
  is always expanded).

- guides:

  Draw guide lines?

- id:

  Optional identifier.

- classes:

  Optional classes.

- style:

  A [`style()`](https://menshikovs.github.io/termr/reference/style.md).

## Value

A `TreeView` widget with method `select(node)` and fields `root`,
`cursor_node`, `visible_count`.

## Details

Keys: Up/Down/Page Up/Page Down/Home/End move; Right expands (or goes to
the first child); Left collapses (or goes to the parent); Space toggles;
Enter toggles and sends `"tree.node_activated"`. Clicking selects a
node; clicking its arrow toggles it.

Messages (`event$data`: `node`, `label`, `data`, `id`):
`"tree.node_selected"`, `"tree.node_expanded"`, `"tree.node_collapsed"`,
`"tree.node_activated"`.

## Examples

``` r
root <- tree_node("Project", tree_node("R", "app.R", "widget.R", expanded = TRUE),
                  "README.md", expanded = TRUE)
render_widget(tree_view(root), 24, 5)
#> <ScreenBuffer 24x5>
#> +------------------------+
#> |▼ Project               |
#> |├─▼ R                   |
#> |│ ├─  app.R             |
#> |│ └─  widget.R          |
#> |└─  README.md           |
#> +------------------------+
```
