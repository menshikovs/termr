# A2.6 Implementation

Implemented an ordered specialized → generic-class → safe-fallback resolution path without adding a public handler API.

- Class summaries use `pillar::type_sum()` when available, then `vctrs::vec_ptype_abbr()` when pillar is unavailable, and finally a sanitized class label.
- Custom class display uses a registered class-chain `pillar_shaft()` method when present, otherwise an S3 `format()` method. Errors, malformed output and long/control-character output are isolated, sanitized and bounded.
- Unknown classes are read-only by default. A `vctrs_vctr` can be edited only after a zero-length directed character cast proves that the class supports the parsing direction and preserves its prototype. Each input cast is checked again for warnings, length, storage type, class and attributes.
- Existing one-cell assignment checks run after vctrs restoration, so a custom `vec_restore()` that changes metadata rejects the edit without mutating table state.
- DataTable width sampling now slices with the existing vctrs-aware slice helper. Generic-class width estimation formats at most the existing 1,000-row sample; rendering formats only the requested slice.
- Generic class missing-value methods are guarded for errors, wrong result type and wrong length.

Changed for A2.6: `R/datatable-typed.R`, `R/widget-datatable.R`, `docs/data.md`, `NEWS.md`, and `tests/testthat/test-datatable-custom-classes.R`. This phase adds no dependencies or exports and changes no `NAMESPACE` entries, native code, or generated `man/` topics; earlier phase changes remain intact.
