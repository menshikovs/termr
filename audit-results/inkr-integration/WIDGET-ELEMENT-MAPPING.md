# Widget to inkr element mapping

| Widget data | inkr element field |
|---|---|
| `widget$type` (first R6 class name) | `type` |
| `widget$id` | `id` |
| `widget$classes` | `classes` |
| `widget$pseudo_states()` | `states` |
| `widget$parent` through the root screen | `parent` chain |

The chain is built root-to-target. Current termr states include focus, hover,
disabled and widget-specific states such as pressed and invalid. State changes
are represented in the path cache key. Screens and the toast layer are ordinary
parent elements in the inkr path, so descendant selectors span nested
containers, charts and DataTable widgets.

Identifiers that are accepted by termr but rejected by inkr's stricter element
validator produce the inkr validation error during style computation; termr
does not silently rewrite selector names.
