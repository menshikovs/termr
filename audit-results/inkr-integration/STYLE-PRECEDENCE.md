# Style precedence

The effective order is:

| Priority | Layer |
|---:|---|
| 1 | Widget type defaults and their state styles |
| 2 | Existing termr RTCSS rules |
| 3 | Explicit inkr declarations and applicable inherited values |
| 4 | Widget inline style |
| 5 | Widget inline state style |
| 6 | Existing termr strong-focus / monochrome focus-border override |

This keeps the existing inline override contract. Inkr's registry `initial`
values are omitted unless the winning declaration explicitly uses `initial`.
For inheritable properties, a computed `inherited` value is applied only when
an ancestor's provenance names a rule. Thus an empty inkr sheet does not replace
termr foregrounds, surfaces, spacing or widget defaults.

The final focus-border adjustment is existing termr theme behavior applied
after `resolve_style()`; it is not an inkr cascade rule.

The bridge maps the inkr result into a partial `termr_style` and passes it
through termr's existing `merge_styles()` and `resolve_style()` path. No CSS
cascade is duplicated in termr.
