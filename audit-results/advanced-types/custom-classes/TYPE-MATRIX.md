# Type Compatibility Matrix

| Class family | Type metadata | Display | Text editing | Failure behavior |
|---|---|---|---|---|
| Existing specialized termr adapters | Existing compact type and adapter metadata | Existing bounded formatter | Existing type-specific rules | Existing adapter errors remain atomic |
| Custom S3 with `pillar_shaft()` | `pillar::type_sum()` if valid | Class-chain pillar method on sampled/visible values | Read-only unless it is also a qualifying vctrs vector | Error or malformed output becomes a class label |
| Custom S3 with `format()` only | `type_sum()`, then `vec_ptype_abbr()`, then class label | S3 `format()` on sampled/visible values | Read-only | Error or wrong-length result becomes a class label |
| Custom vctrs vector with compatible cast | `type_sum()` / `vec_ptype_abbr()` | Pillar/format class methods | Editable only with successful character-to-prototype cast and exact invariant restoration | Rejected cast, warning, changed metadata or failed assignment leaves data unchanged |
| Unknown vctrs vector without text cast | Compact type summary when available | Standard bounded methods | Read-only | Safe fallback |
| Unknown S4 / other classed object | Best-effort type summary/class label | Best-effort S3/base formatting | Read-only | Safe fallback |
| Bare list / list-column | `list` / existing summary | Bounded nested-value summary | Read-only | Existing list adapter |

`pillar` and `vctrs` remain optional Suggests. The custom S3 display path also has a base `format()` fallback when pillar is not installed. No custom class is automatically assigned a parser, missing-value meaning, or restoration rule.
