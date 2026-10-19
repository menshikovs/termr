# Tree node

A node of a tree shown by
[`tree_view()`](https://menshikovs.github.io/termr/reference/tree_view.md).
See
[`tree_node()`](https://menshikovs.github.io/termr/reference/tree_node.md).

## Public fields

- `label`:

  Text shown for the node.

- `data`:

  Any R value attached to the node.

- `id`:

  Optional identifier.

- `loader`:

  `NULL` or `function(node)` returning children, called the first time
  the node is expanded.

- `loaded`:

  Has the loader run?

## Active bindings

- `parent`:

  The parent node (read-only).

- `children`:

  Child nodes (read-only).

- `expanded`:

  Is the node expanded? (assign to expand / collapse)

## Methods

### Public methods

- [`TreeNode$new()`](#method-TreeNode-initialize)

- [`TreeNode$add()`](#method-TreeNode-add)

- [`TreeNode$remove()`](#method-TreeNode-remove)

- [`TreeNode$clear()`](#method-TreeNode-clear)

- [`TreeNode$expand()`](#method-TreeNode-expand)

- [`TreeNode$collapse()`](#method-TreeNode-collapse)

- [`TreeNode$toggle()`](#method-TreeNode-toggle)

- [`TreeNode$expandable()`](#method-TreeNode-expandable)

- [`TreeNode$depth()`](#method-TreeNode-depth)

- [`TreeNode$ancestors()`](#method-TreeNode-ancestors)

- [`TreeNode$path()`](#method-TreeNode-path)

- [`TreeNode$walk()`](#method-TreeNode-walk)

- [`TreeNode$find()`](#method-TreeNode-find)

- [`TreeNode$changed()`](#method-TreeNode-changed)

- [`TreeNode$print()`](#method-TreeNode-print)

- [`TreeNode$clone()`](#method-TreeNode-clone)

------------------------------------------------------------------------

### `TreeNode$new()`

Create a node. See
[`tree_node()`](https://menshikovs.github.io/termr/reference/tree_node.md).

#### Usage

    TreeNode$new(
      label,
      children = list(),
      data = NULL,
      expanded = FALSE,
      id = NULL,
      loader = NULL
    )

#### Arguments

- `label`:

  Label.

- `children`:

  Child nodes (or labels).

- `data`:

  Attached value.

- `expanded`:

  Start expanded?

- `id`:

  Identifier.

- `loader`:

  Lazy loader.

------------------------------------------------------------------------

### `TreeNode$add()`

Add a child.

#### Usage

    TreeNode$add(node, data = NULL, expanded = FALSE)

#### Arguments

- `node`:

  A `TreeNode` or a label.

- `data`:

  Data for a node created from a label.

- `expanded`:

  Expanded state for a node created from a label.

#### Returns

The child node.

------------------------------------------------------------------------

### `TreeNode$remove()`

Detach the node from its parent.

#### Usage

    TreeNode$remove()

------------------------------------------------------------------------

### `TreeNode$clear()`

Remove all children.

#### Usage

    TreeNode$clear()

------------------------------------------------------------------------

### `TreeNode$expand()`

Expand the node (running the loader if needed).

#### Usage

    TreeNode$expand()

------------------------------------------------------------------------

### `TreeNode$collapse()`

Collapse the node.

#### Usage

    TreeNode$collapse()

------------------------------------------------------------------------

### `TreeNode$toggle()`

Toggle between expanded and collapsed.

#### Usage

    TreeNode$toggle()

------------------------------------------------------------------------

### `TreeNode$expandable()`

Can the node be expanded?

#### Usage

    TreeNode$expandable()

------------------------------------------------------------------------

### `TreeNode$depth()`

Depth below the root (the root is 0).

#### Usage

    TreeNode$depth()

------------------------------------------------------------------------

### `TreeNode$ancestors()`

Parent, grandparent, ... up to the root.

#### Usage

    TreeNode$ancestors()

------------------------------------------------------------------------

### `TreeNode$path()`

Labels from the root to this node.

#### Usage

    TreeNode$path()

------------------------------------------------------------------------

### `TreeNode$walk()`

This node and all descendants (depth first).

#### Usage

    TreeNode$walk()

------------------------------------------------------------------------

### `TreeNode$find()`

Find a descendant by id.

#### Usage

    TreeNode$find(id)

#### Arguments

- `id`:

  Identifier.

------------------------------------------------------------------------

### `TreeNode$changed()`

Notify the tree view that the node changed.

#### Usage

    TreeNode$changed()

------------------------------------------------------------------------

### `TreeNode$print()`

Print the subtree.

#### Usage

    TreeNode$print(...)

#### Arguments

- `...`:

  Ignored.

------------------------------------------------------------------------

### `TreeNode$clone()`

The objects of this class are cloneable with this method.

#### Usage

    TreeNode$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
