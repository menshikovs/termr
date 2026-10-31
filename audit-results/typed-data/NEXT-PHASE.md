# Next phase

1. Run the existing A2 plan for the next set of typed dataframe operations
   after reviewing the results in `TYPE-MATRIX.md` and `KNOWN-LIMITATIONS.md`.
2. When `hms`, `bit64`, and `dplyr` are available in CI, run their optional
   adapter/grouped-frame cases on Windows and Linux.
3. Consider source-specific typed metadata for lazy sources in a separately
   scoped change; do not infer or restore arbitrary backend classes.
4. Revisit exact integer64 range filters only with typed bounds and tests that
   prove there is no double conversion.

No user-facing handler registration API is proposed for this phase.
