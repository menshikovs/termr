# Tree nodes

Tree nodes

## Usage

``` r
tree_node(label, ..., data = NULL, expanded = FALSE, id = NULL, loader = NULL)
```

## Arguments

- label:

  Text shown for the node.

- ...:

  Child nodes, or strings (leaf nodes).

- data:

  Any R value attached to the node (e.g. a file path).

- expanded:

  Start expanded?

- id:

  Optional identifier (see `node$find(id)`).

- loader:

  Optional `function(node)` returning child nodes (or labels), called
  the first time the node is expanded. Use it for large or expensive
  trees such as file systems.

## Value

A `TreeNode`.

## Examples

``` r
root <- tree_node("Project", tree_node("R", "app.R", "widget.R"), "README.md", expanded = TRUE)
root
#> - Project
#>   + R
#>       app.R
#>       widget.R
#>     README.md
```
