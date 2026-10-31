# Property mapping

| inkr property | termr style property | Notes |
|---|---|---|
| `color` | `foreground` | Uses `normalize_color()`; termr performs capability downgrade when rendering. |
| `background` | `background` | `transparent` is retained as a named `NULL` layer value so lower fills are cleared and the underlying surface is left unpainted. |
| `text-style` | `bold`, `dim`, `italic`, `underline`, `reverse`, `strike` | The typed flags are applied as a complete value, including explicit `FALSE` flags for `none`. |
| `padding` | `padding` | Four named inkr sides become termr's top/right/bottom/left integer vector. |
| `margin` | `margin` | Same side order; inkr already validates non-negative integer cells. |
| `border` | `border`, `border_color` | `none`, `single`, `double`, `round`, `heavy`; color is separately normalized. |
| `width` | `width` | Fixed cell counts or `auto`; no percentage/fr mapping is needed because inkr does not define those values. |
| `height` | `height` | Fixed cell counts or `auto`. |

Opaque RGB colors and ANSI names flow through termr's existing normalization,
framebuffer and terminal color-mode conversion. `default` maps to terminal
default color. Transparent backgrounds are not converted to black. Alpha hex
colors are rejected with a clear error because the termr framebuffer has no
alpha channel. Other inkr custom registry properties are not mapped.
