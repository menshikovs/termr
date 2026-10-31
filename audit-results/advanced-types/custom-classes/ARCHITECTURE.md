# A2.6 Architecture

Typed Data Foundation keeps its package-owned adapters in one private, ordered list. The resolver selects the first matching specialized termr handler. Objects not covered by those handlers reach a compatibility adapter for classed S3/vctrs objects; bare lists and the final base fallback remain separate.

```text
value / column
  ├─ first matching specialized termr adapter
  ├─ generic class compatibility adapter
  │    ├─ type: pillar::type_sum() → vctrs::vec_ptype_abbr() → class label
  │    ├─ display: class-chain pillar_shaft() → S3 format() → safe class label
  │    └─ edit: vctrs character → prototype cast, then invariant checks
  ├─ bare list summary (read-only)
  └─ safe base fallback (read-only)
```

The compatibility layer uses existing R, vctrs and pillar methods. It does not create a public registration function or process-global mutable registry. Dispatch is resolved from the current class and method tables; no result depending on class registration or object contents is cached.

Formatters receive only the current sample or requested slice. A custom pillar method is selected through the S3 class chain when one exists. Otherwise base `format()` is attempted. Errors, invalid lengths, and non-character results degrade to a compact class label. Output is control-character sanitized and clipped to a bounded width before it reaches the cell painter.

Editing stays read-only unless a class inherits `vctrs_vctr` and its directed empty character-to-prototype cast succeeds while restoring the exact prototype type, class, and attributes. Each submitted string is cast and validated again. Assignment goes through `vctrs::vec_assign()` and the same storage/class/attribute invariants as existing handlers. A failed parse, warning, cast, restore or invariant check leaves the table data untouched.
