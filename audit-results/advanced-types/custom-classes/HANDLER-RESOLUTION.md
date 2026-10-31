# Handler Resolution

1. **Specialized termr handlers.** Existing adapters for binary, spatial, labelled, measurement, date/time, factor and primitive types keep their precedence and dedicated edit rules.
2. **S3/vctrs compatibility.** Other classed objects use pillar's `type_sum()` or vctrs' `vec_ptype_abbr()` for a compact type name. For cells, a class-chain `pillar_shaft()` method is used when present; otherwise the class-chain `format()` method is tried.
3. **Read-only fallback.** Errors, warnings during casts, malformed method results, and classes without a safe directed text cast fall back to bounded class labels or read-only editing.
4. **Bare list/base fallback.** Bare list columns retain the existing bounded summary and read-only behavior. Objects outside recognized vector paths keep the safe base fallback.

The resolver is deterministic because the adapter list is ordered and private. Specialized matches precede the generic class adapter. Standard S3 inheritance remains available to pillar and `format()`; vctrs cast dispatch uses its own class-pair methods, so termr tests the actual character-to-prototype direction instead of assuming that an arbitrary `vec_cast()` is a parser.

Failure isolation catches formatter, type-summary, cast and missing-value method errors at the adapter boundary. Method outputs must have the expected scalar/row shape. Formatting never executes text as R code. Assignment verifies that `typeof`, full class and attributes remain equal to the column before replacing table state.
