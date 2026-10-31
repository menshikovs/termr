# inkr API compatibility

Inspected and installed the official sibling checkout at
`C:/programming_pj/ink-for-r`, version `0.1.0` (Git HEAD `3a19331`), using
Windows R 4.6.1. The required functions are exported in `inkr`'s NAMESPACE.
`DESCRIPTION` now declares `Suggests: inkr (>= 0.1.0)`.

Relevant public formals observed:

| Function | Formals |
|---|---|
| `ink_parse` | `text, source = "<text>"` |
| `ink_read` | `path` |
| `ink_compile` | `ast, registry = ink_registry()` |
| `ink_element` | `type, id = NULL, classes = character(), states = character(), parent = NULL` |
| `ink_match` | `sheet, element` |
| `ink_compute` | `sheet, element` |
| `ink_explain` | `sheet, element, property` |
| `ink_session` | `sheet` |
| `ink_session_set` | `session, key, type, id = NULL, classes = character(), states = character(), parent_key = NULL` |
| `ink_session_compute` | `session, key` |
| `ink_session_remove` | `session, key` |
| `ink_session_stats` | `session` |

The built-in registry has `color`, `background`, `text-style`, `padding`,
`margin`, `border`, `width` and `height`. `color` and `text-style` inherit;
the other properties do not. The typed value structures follow the public
`ink_values` documentation.

The adapter uses exported `ink_parse`, `ink_read`, `ink_compile`,
`ink_element`, `ink_compute` and `ink_explain`. It does not use `inkr:::` or
modify the inkr checkout. The exported session API was inspected but not used
for the app cache; see [SESSION-CACHE.md](SESSION-CACHE.md).
