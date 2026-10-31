# Next Phase

The Typed Data Foundation now has specialized handlers for its supported built-in and optional classes, plus a bounded standard-method fallback for third-party classes. New public exports are not required for ordinary S3/pillar display or vctrs-directed editing.

Before considering a public registration API, collect concrete third-party use cases that need metadata, parser, validator or assignment behavior beyond the standard methods. Any future extension point should define precedence against specialized adapters, namespace lifetime, method error isolation, prototype and attribute invariants, and compatibility guarantees before implementation.

Potential follow-up work is to gather timings across more third-party vector packages and R versions, especially custom vctrs classes whose `vec_restore()` metadata depends on the data. Such classes should remain read-only unless a reproducible, type-stable contract is demonstrated.
