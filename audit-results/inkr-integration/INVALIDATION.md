# Invalidation

| Change | Effect |
|---|---|
| Focus, hover, disabled, pressed or invalid state | State changes alter the target or ancestor path signature; the affected style is recomputed. |
| `add_class()` / `remove_class()` | Termr bumps its style epoch; changed classes alter path signatures. |
| Reparent/move | Parent path changes; unmount clears the app cache before the next layout. |
| Stylesheet replacement/removal | Compile succeeds first, then generation increments and both inkr-derived caches reset. |
| Termr theme replacement | Termr style epoch invalidates resolved widget styles. Inkr compiled colors stay constant and can reuse their mapped value. |
| Widget unmount/screen removal | Removed widgets' provenance cache is cleared and the bounded app cache resets. |

Direct assignment to `widget$classes` now parses and invalidates like
`add_class()`/`remove_class()`. Assigning `widget$id` validates the identifier,
checks uniqueness within the current root and invalidates selectors.
