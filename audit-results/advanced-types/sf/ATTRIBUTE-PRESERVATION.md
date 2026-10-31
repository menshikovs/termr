# Attribute Preservation

The attribute edit path modifies only the requested column on a local data copy and restores the original top-level attributes before returning. Tests verify the sf class, column names, row count, active geometry name and values, CRS, and unrelated columns across character, numeric, factor, and Date edits. The implementation checks these invariants rather than reconstructing or guessing missing attributes.

Sorting geometry columns is rejected. Filtering and row selection continue to operate on table rows, so attributes and geometry remain associated. Multiple geometry columns and a non-default active geometry column are covered by tests.

Feature geometry itself is read-only. This avoids attempting to parse arbitrary geometry text or silently changing CRS, dimensions, precision, or topology through cell editing.
